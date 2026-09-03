from typing import Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from .. import models


class GiftExpiredException(HTTPException):
    def __init__(self, detail: str = "수령 유효기간(7일)이 만료된 선물입니다."):
        super().__init__(status_code=400, detail=detail)

class PointService:
    """
    Stage 0 Central Point Service.
    Enforces row locking (with_for_update), non-negative balance checks,
    and atomic balance + PointHistory (+ optional ActivityLog) transaction consistency.
    """

    @staticmethod
    def mutate_points(
        db: Session,
        user_id: str,
        amount: int,
        activity: str,
        transaction_type: Optional[str] = None,
        source_type: Optional[str] = None,
        source_id: Optional[str] = None,
        update_lifetime: bool = False,
    ) -> models.User:
        """
        Executes a locked, transactional point mutation on target user.
        Raises HTTPException(400) if spend causes balance to fall below 0.
        Integrates with PointLot (FEFO consumption & lot creation), PointOperation,
        and PointAllocation while maintaining synchronized User.current_points cache.
        Does NOT commit internally so caller controls atomic business transaction boundary.
        """
        import uuid
        from datetime import datetime, timedelta
        from sqlalchemy import or_

        if amount == 0:
            user = db.query(models.User).filter(models.User.id == user_id).first()
            if not user:
                raise HTTPException(status_code=404, detail="해당 사용자를 찾을 수 없습니다.")
            return user

        # 1. Lock user row
        user = (
            db.query(models.User)
            .filter(models.User.id == user_id)
            .with_for_update()
            .first()
        )
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="해당 사용자를 찾을 수 없습니다.",
            )

        now = datetime.utcnow()
        op_type = "EARN" if amount > 0 else "SPEND"
        if transaction_type:
            if "COUPON" in transaction_type:
                op_type = "COUPON_REDEEM"
            elif "CHARGE" in transaction_type:
                op_type = "PAYMENT"
            elif "REFUND" in transaction_type:
                op_type = "REFUND"

        op_id = str(uuid.uuid4())
        operation = models.PointOperation(
            id=op_id,
            actor_user_id=user_id,
            operation_type=op_type,
            status="STARTED"
        )
        db.add(operation)
        db.flush()

        # 2. Spend Path (amount < 0)
        if amount < 0:
            spend_needed = -amount

            # Lock eligible PointLots in canonical FEFO order
            # Finite expires_at ASC (NULLS LAST), created_at ASC, id ASC
            lots = (
                db.query(models.PointLot)
                .filter(
                    models.PointLot.user_id == user_id,
                    models.PointLot.status == "ACTIVE",
                    (models.PointLot.remaining_points - models.PointLot.reserved_points) > 0,
                    or_(
                        models.PointLot.expires_at == None,
                        models.PointLot.expires_at > now
                    )
                )
                .order_by(
                    models.PointLot.expires_at.asc().nullslast(),
                    models.PointLot.created_at.asc(),
                    models.PointLot.id.asc()
                )
                .with_for_update()
                .all()
            )

            total_available = sum(lot.remaining_points - lot.reserved_points for lot in lots)
            if len(lots) == 0 and user.current_points >= spend_needed:
                # User has legacy balance without lot record: create legacy lot on-the-fly to maintain lot SOT
                leg_lot = models.PointLot(
                    id=str(uuid.uuid4()),
                    user_id=user_id,
                    source_type="LEGACY_MIGRATION",
                    original_points=user.current_points,
                    remaining_points=user.current_points,
                    reserved_points=0,
                    expires_at=None,
                    is_transferable=False,
                    status="ACTIVE",
                    created_at=now
                )
                db.add(leg_lot)
                db.flush()
                lots = [leg_lot]
                total_available = leg_lot.remaining_points

            if total_available < spend_needed:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="보유 포인트가 부족합니다.",
                )

            # Consume across lots in FEFO order
            rem_spend = spend_needed
            for lot in lots:
                avail = lot.remaining_points - lot.reserved_points
                consume_part = min(avail, rem_spend)

                lot.remaining_points -= consume_part
                if lot.remaining_points == 0:
                    lot.status = "EXHAUSTED"

                alloc = models.PointAllocation(
                    id=str(uuid.uuid4()),
                    lot_id=lot.id,
                    operation_id=op_id,
                    points=consume_part,
                    allocation_type="CONSUMPTION"
                )
                db.add(alloc)

                rem_spend -= consume_part
                if rem_spend == 0:
                    break

        # 3. Earn Path (amount > 0)
        else:
            # Policy mapping for positive lots
            st = source_type.upper() if source_type else "GENERAL"
            is_transferable = True
            expires_days = 365

            if st == "SIGNUP":
                is_transferable = False
                expires_days = 365

            lot_source_type = source_type or "MISSION"
            if st in ["PAYMENT", "API", "GENERAL"]:
                lot_source_type = "MISSION" if st in ["API", "GENERAL"] else "PAYMENT"

            lot_id = str(uuid.uuid4())
            new_lot = models.PointLot(
                id=lot_id,
                user_id=user_id,
                source_history_id=None,
                operation_id=op_id,
                source_type=lot_source_type,
                original_points=amount,
                remaining_points=amount,
                reserved_points=0,
                expires_at=now + timedelta(days=expires_days),
                is_transferable=is_transferable,
                status="ACTIVE",
                created_at=now
            )
            db.add(new_lot)

        # 4. Synchronize User current_points cache and lifetime_earned_points
        user.current_points += amount
        if update_lifetime and amount > 0:
            user.lifetime_earned_points += amount

        # 5. Insert PointHistory record
        history_id = str(uuid.uuid4())
        history = models.PointHistory(
            id=history_id,
            user_id=user_id,
            points=amount,
            activity=activity,
            transaction_type=transaction_type,
            source_type=source_type,
            source_id=source_id,
        )
        db.add(history)

        operation.status = "COMPLETED"
        operation.completed_at = now

        return user

    @staticmethod
    def get_authoritative_usable_points(db: Session, user_id: str) -> int:
        """
        Calculates the authoritative spendable point balance from active point_lots.
        Usable condition:
        - status == 'ACTIVE'
        - expires_at IS NULL (no-expiry legacy) OR expires_at > current_time
        - remaining_points - reserved_points > 0
        If the user has point_lots records, the sum of usable lot points is authoritative.
        If no point_lots exist yet (e.g. pre-migration or zero lots), falls back to User.current_points.
        """
        from datetime import datetime
        from sqlalchemy import or_, func, and_

        lots_count = db.query(func.count(models.PointLot.id)).filter(models.PointLot.user_id == user_id).scalar() or 0
        if lots_count == 0:
            user = db.query(models.User).filter(models.User.id == user_id).first()
            return user.current_points if user else 0

        now = datetime.utcnow()
        usable_sum = (
            db.query(func.coalesce(func.sum(models.PointLot.remaining_points - models.PointLot.reserved_points), 0))
            .filter(
                models.PointLot.user_id == user_id,
                models.PointLot.status == "ACTIVE",
                or_(
                    models.PointLot.expires_at == None,
                    models.PointLot.expires_at > now
                )
            )
            .scalar()
        )
        return int(usable_sum)

    @staticmethod
    def get_transferable_usable_points(db: Session, user_id: str) -> int:
        from datetime import datetime
        from sqlalchemy import or_, func
        now = datetime.utcnow()
        transferable_sum = (
            db.query(func.coalesce(func.sum(models.PointLot.remaining_points - models.PointLot.reserved_points), 0))
            .filter(
                models.PointLot.user_id == user_id,
                models.PointLot.status == "ACTIVE",
                models.PointLot.is_transferable == True,
                or_(
                    models.PointLot.expires_at == None,
                    models.PointLot.expires_at > now
                )
            )
            .scalar()
        )
        return int(transferable_sum)

    @staticmethod
    def create_gift(
        db: Session,
        sender_id: str,
        gross_points: int,
        idempotency_key: Optional[str] = None
    ) -> dict:
        import uuid
        import secrets
        import hashlib
        from datetime import datetime, timedelta
        from sqlalchemy import or_, func

        # 1. Validation of gift amount constraints
        if gross_points < 100:
            raise HTTPException(status_code=400, detail="최소 선물 가능 포인트는 100P입니다.")
        if gross_points % 10 != 0:
            raise HTTPException(status_code=400, detail="선물 포인트는 10P 단위여야 합니다.")
        if gross_points > 5000:
            raise HTTPException(status_code=400, detail="1회 최대 선물 가능 포인트는 5,000P입니다.")

        # 2. Idempotency Check
        if idempotency_key:
            existing_op = (
                db.query(models.PointOperation)
                .filter(
                    models.PointOperation.actor_user_id == sender_id,
                    models.PointOperation.operation_type == "GIFT_CREATE",
                    models.PointOperation.idempotency_key == idempotency_key
                )
                .first()
            )
            if existing_op and existing_op.status == "COMPLETED":
                existing_gift = db.query(models.PointGift).filter(models.PointGift.create_operation_id == existing_op.id).first()
                if existing_gift:
                    return {
                        "gift_id": existing_gift.id,
                        "gross_points": existing_gift.gross_points,
                        "net_points": existing_gift.net_points,
                        "fee_points": existing_gift.fee_points,
                        "status": existing_gift.status,
                        "expires_at": existing_gift.expires_at.isoformat() if existing_gift.expires_at else None,
                        "idempotent_replay": True
                    }

        # 3. Lock Sender row
        sender = db.query(models.User).filter(models.User.id == sender_id).with_for_update().first()
        if not sender:
            raise HTTPException(status_code=404, detail="발신 사용자를 찾을 수 없습니다.")

        now = datetime.utcnow()
        # 4. FEFO transferable lot selection with row locking
        # Finite expires_at ASC (NULLS LAST), then created_at ASC, id ASC
        lots = (
            db.query(models.PointLot)
            .filter(
                models.PointLot.user_id == sender_id,
                models.PointLot.status == "ACTIVE",
                models.PointLot.is_transferable == True,
                (models.PointLot.remaining_points - models.PointLot.reserved_points) > 0,
                or_(
                    models.PointLot.expires_at == None,
                    models.PointLot.expires_at > now
                )
            )
            .order_by(
                models.PointLot.expires_at.asc().nullslast(),
                models.PointLot.created_at.asc(),
                models.PointLot.id.asc()
            )
            .with_for_update()
            .all()
        )

        total_available = sum(lot.remaining_points - lot.reserved_points for lot in lots)
        if total_available < gross_points:
            raise HTTPException(status_code=400, detail="선물 가능한 양도 가능 포인트가 부족합니다.")

        # 5. Create Operation
        op_id = str(uuid.uuid4())
        operation = models.PointOperation(
            id=op_id,
            actor_user_id=sender_id,
            operation_type="GIFT_CREATE",
            idempotency_key=idempotency_key,
            status="STARTED"
        )
        db.add(operation)
        db.flush()

        # 6. Reserve Points across lots
        needed = gross_points
        for lot in lots:
            avail = lot.remaining_points - lot.reserved_points
            reserve_amount = min(avail, needed)
            lot.reserved_points += reserve_amount

            alloc = models.PointAllocation(
                id=str(uuid.uuid4()),
                lot_id=lot.id,
                operation_id=op_id,
                points=reserve_amount,
                allocation_type="RESERVATION"
            )
            db.add(alloc)

            needed -= reserve_amount
            if needed == 0:
                break

        # 7. Generate Token and create PointGift record
        raw_token = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
        fee_points = int(gross_points * 30 / 100)
        net_points = int(gross_points * 70 / 100)
        gift_id = str(uuid.uuid4())
        expires_at = now + timedelta(days=7)

        gift = models.PointGift(
            id=gift_id,
            sender_id=sender_id,
            recipient_id=None,
            create_operation_id=op_id,
            gift_token_hash=token_hash,
            gross_points=gross_points,
            fee_points=fee_points,
            net_points=net_points,
            status="PENDING",
            expires_at=expires_at
        )
        db.add(gift)

        operation.status = "COMPLETED"
        operation.completed_at = now

        return {
            "gift_id": gift.id,
            "gift_token": raw_token,
            "gross_points": gross_points,
            "net_points": net_points,
            "fee_points": fee_points,
            "status": "PENDING",
            "expires_at": expires_at.isoformat()
        }

    @staticmethod
    def claim_gift(
        db: Session,
        recipient_id: str,
        gift_token: str,
        idempotency_key: Optional[str] = None
    ) -> dict:
        import uuid
        import hashlib
        from datetime import datetime, timedelta
        from sqlalchemy import func

        token_hash = hashlib.sha256(gift_token.encode("utf-8")).hexdigest()

        # 1. Lock Gift row
        gift = (
            db.query(models.PointGift)
            .filter(models.PointGift.gift_token_hash == token_hash)
            .with_for_update()
            .first()
        )
        if not gift:
            raise HTTPException(status_code=404, detail="유효하지 않은 선물 토큰입니다.")

        # Self-gift prohibition
        if gift.sender_id == recipient_id:
            raise HTTPException(status_code=400, detail="본인이 보낸 선물은 직접 수령할 수 없습니다.")

        now = datetime.utcnow()

        # 2. Check Expiry
        if gift.status == "PENDING" and gift.expires_at < now:
            PointService.process_expired_gift(db, gift.id)
            raise GiftExpiredException()

        if gift.status == "CANCELLED":
            raise HTTPException(status_code=400, detail="발신자가 취소한 선물입니다.")
        if gift.status == "EXPIRED":
            raise HTTPException(status_code=400, detail="유효기간이 만료된 선물입니다.")
        if gift.status == "ACCEPTED":
            if gift.recipient_id == recipient_id:
                return {
                    "gift_id": gift.id,
                    "recipient_id": recipient_id,
                    "net_points": gift.net_points,
                    "status": "ACCEPTED",
                    "idempotent_replay": True
                }
            raise HTTPException(status_code=400, detail="이미 다른 사용자가 수령한 선물입니다.")

        # 3. Daily Limits Verification on Sender (at acceptance time)
        # SOT check: max 3 successful (ACCEPTED) gifts / day, max 5000 gross points / day
        start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
        daily_accepted_count = (
            db.query(func.count(models.PointGift.id))
            .filter(
                models.PointGift.sender_id == gift.sender_id,
                models.PointGift.status == "ACCEPTED",
                models.PointGift.accepted_at >= start_of_day
            )
            .scalar() or 0
        )
        if daily_accepted_count >= 3:
            raise HTTPException(status_code=400, detail="발신자의 일일 선물 수령 완료 횟수 한도(3회)를 초과하여 수령할 수 없습니다.")

        daily_accepted_gross = (
            db.query(func.coalesce(func.sum(models.PointGift.gross_points), 0))
            .filter(
                models.PointGift.sender_id == gift.sender_id,
                models.PointGift.status == "ACCEPTED",
                models.PointGift.accepted_at >= start_of_day
            )
            .scalar() or 0
        )
        if daily_accepted_gross + gift.gross_points > 5000:
            raise HTTPException(status_code=400, detail="발신자의 일일 선물 한도(5,000P)를 초과하여 수령할 수 없습니다.")

        # 4. Lock Recipient and Sender User rows
        recipient = db.query(models.User).filter(models.User.id == recipient_id).with_for_update().first()
        if not recipient:
            raise HTTPException(status_code=404, detail="수신 사용자를 찾을 수 없습니다.")

        sender = db.query(models.User).filter(models.User.id == gift.sender_id).with_for_update().first()

        # 5. Create Claim Operation
        op_id = str(uuid.uuid4())
        claim_op = models.PointOperation(
            id=op_id,
            actor_user_id=recipient_id,
            operation_type="GIFT_ACCEPT",
            idempotency_key=idempotency_key,
            status="STARTED"
        )
        db.add(claim_op)
        db.flush()

        # 6. Settle Sender Reservations -> Consumptions
        # Fetch reservation allocations from creation operation
        res_allocs = (
            db.query(models.PointAllocation)
            .filter(
                models.PointAllocation.operation_id == gift.create_operation_id,
                models.PointAllocation.allocation_type == "RESERVATION"
            )
            .all()
        )

        for r_alloc in res_allocs:
            lot = db.query(models.PointLot).filter(models.PointLot.id == r_alloc.lot_id).with_for_update().first()
            lot.reserved_points -= r_alloc.points
            lot.remaining_points -= r_alloc.points
            if lot.remaining_points == 0:
                lot.status = "EXHAUSTED"

            cons_alloc = models.PointAllocation(
                id=str(uuid.uuid4()),
                lot_id=lot.id,
                operation_id=op_id,
                points=r_alloc.points,
                allocation_type="CONSUMPTION"
            )
            db.add(cons_alloc)

        # Update Sender cache & ledger history
        sender.current_points -= gift.gross_points
        sender_history = models.PointHistory(
            user_id=sender.id,
            points=-gift.gross_points,
            activity="포인트 선물 발송 완료",
            transaction_type="GIFT_SENT",
            source_type="GIFT",
            source_id=gift.id
        )
        db.add(sender_history)

        # 7. Credit Recipient: Create Received Lot (90 days, non-transferable)
        rcv_lot_id = str(uuid.uuid4())
        rcv_expires = now + timedelta(days=90)
        rcv_lot = models.PointLot(
            id=rcv_lot_id,
            user_id=recipient_id,
            source_history_id=None,
            operation_id=op_id,
            source_type="GIFT_RECEIVED",
            original_points=gift.net_points,
            remaining_points=gift.net_points,
            reserved_points=0,
            expires_at=rcv_expires,
            is_transferable=False,
            status="ACTIVE",
            created_at=now
        )
        db.add(rcv_lot)

        # Update Recipient cache & ledger history
        recipient.current_points += gift.net_points
        recipient.lifetime_earned_points += gift.net_points
        recipient_history = models.PointHistory(
            user_id=recipient_id,
            points=gift.net_points,
            activity="포인트 선물 수령",
            transaction_type="GIFT_RECEIVED",
            source_type="GIFT",
            source_id=gift.id
        )
        db.add(recipient_history)

        # 8. Mark Gift Accepted
        gift.recipient_id = recipient_id
        gift.accept_operation_id = op_id
        gift.status = "ACCEPTED"
        gift.accepted_at = now

        claim_op.status = "COMPLETED"
        claim_op.completed_at = now

        return {
            "gift_id": gift.id,
            "recipient_id": recipient_id,
            "gross_points": gift.gross_points,
            "net_points": gift.net_points,
            "fee_points": gift.fee_points,
            "status": "ACCEPTED",
            "accepted_at": now.isoformat()
        }

    @staticmethod
    def cancel_gift(db: Session, sender_id: str, gift_id: str) -> dict:
        import uuid
        from datetime import datetime

        gift = db.query(models.PointGift).filter(models.PointGift.id == gift_id).with_for_update().first()
        if not gift:
            raise HTTPException(status_code=404, detail="해당 선물을 찾을 수 없습니다.")

        if gift.sender_id != sender_id:
            raise HTTPException(status_code=403, detail="본인이 생성한 선물만 취소할 수 있습니다.")

        if gift.status == "ACCEPTED":
            raise HTTPException(status_code=400, detail="이미 수령 완료된 선물은 취소할 수 없습니다.")
        if gift.status == "EXPIRED":
            raise HTTPException(status_code=400, detail="이미 만료된 선물입니다.")
        if gift.status == "CANCELLED":
            return {"gift_id": gift.id, "status": "CANCELLED", "idempotent_replay": True}

        now = datetime.utcnow()
        cancel_op = models.PointOperation(
            id=str(uuid.uuid4()),
            actor_user_id=sender_id,
            operation_type="GIFT_CANCEL",
            status="STARTED"
        )
        db.add(cancel_op)
        db.flush()

        # Release Reservations
        res_allocs = (
            db.query(models.PointAllocation)
            .filter(
                models.PointAllocation.operation_id == gift.create_operation_id,
                models.PointAllocation.allocation_type == "RESERVATION"
            )
            .all()
        )

        for r_alloc in res_allocs:
            lot = db.query(models.PointLot).filter(models.PointLot.id == r_alloc.lot_id).with_for_update().first()
            lot.reserved_points -= r_alloc.points

            rel_alloc = models.PointAllocation(
                id=str(uuid.uuid4()),
                lot_id=lot.id,
                operation_id=cancel_op.id,
                points=r_alloc.points,
                allocation_type="RESERVATION_RELEASE"
            )
            db.add(rel_alloc)

        gift.status = "CANCELLED"
        gift.cancelled_at = now
        cancel_op.status = "COMPLETED"
        cancel_op.completed_at = now

        return {"gift_id": gift.id, "status": "CANCELLED", "cancelled_at": now.isoformat()}

    @staticmethod
    def process_expired_gift(db: Session, gift_id: str) -> bool:
        import uuid
        from datetime import datetime

        gift = db.query(models.PointGift).filter(models.PointGift.id == gift_id).with_for_update().first()
        if not gift or gift.status != "PENDING":
            return False

        now = datetime.utcnow()
        if gift.expires_at > now:
            return False

        exp_op = models.PointOperation(
            id=str(uuid.uuid4()),
            actor_user_id=gift.sender_id,
            operation_type="EXPIRATION",
            status="STARTED"
        )
        db.add(exp_op)
        db.flush()

        # Release Reservations
        res_allocs = (
            db.query(models.PointAllocation)
            .filter(
                models.PointAllocation.operation_id == gift.create_operation_id,
                models.PointAllocation.allocation_type == "RESERVATION"
            )
            .all()
        )

        for r_alloc in res_allocs:
            lot = db.query(models.PointLot).filter(models.PointLot.id == r_alloc.lot_id).with_for_update().first()
            lot.reserved_points -= r_alloc.points

            rel_alloc = models.PointAllocation(
                id=str(uuid.uuid4()),
                lot_id=lot.id,
                operation_id=exp_op.id,
                points=r_alloc.points,
                allocation_type="RESERVATION_RELEASE"
            )
            db.add(rel_alloc)

        gift.status = "EXPIRED"
        exp_op.status = "COMPLETED"
        exp_op.completed_at = now
        return True

    @staticmethod
    def list_user_gifts(
        db: Session,
        user_id: str,
        limit: int = 20,
        offset: int = 0
    ) -> dict:
        """
        Lists customer-safe gift history for the authenticated user.
        Includes sent gifts (sender_id == user_id) and received gifts (recipient_id == user_id).
        Excludes raw tokens, token hashes, and internal operation IDs.
        Provides bounded pagination (default limit 20, max 100).
        """
        from datetime import datetime
        from sqlalchemy import or_

        bounded_limit = max(1, min(limit, 100))
        bounded_offset = max(0, offset)
        now = datetime.utcnow()

        query = (
            db.query(models.PointGift)
            .filter(
                or_(
                    models.PointGift.sender_id == user_id,
                    models.PointGift.recipient_id == user_id
                )
            )
            .order_by(models.PointGift.created_at.desc())
        )

        total_count = query.count()
        gifts = query.offset(bounded_offset).limit(bounded_limit).all()

        results = []
        for g in gifts:
            direction = "SENT" if g.sender_id == user_id else "RECEIVED"
            # Read-only safe representation of status: if pending but expired, display EXPIRED
            effective_status = g.status
            if effective_status == "PENDING" and g.expires_at < now:
                effective_status = "EXPIRED"

            results.append({
                "gift_id": g.id,
                "direction": direction,
                "gross_points": g.gross_points,
                "net_points": g.net_points,
                "fee_points": g.fee_points,
                "status": effective_status,
                "created_at": g.created_at.isoformat() if g.created_at else None,
                "expires_at": g.expires_at.isoformat() if g.expires_at else None,
                "accepted_at": g.accepted_at.isoformat() if g.accepted_at else None,
                "cancelled_at": g.cancelled_at.isoformat() if g.cancelled_at else None,
            })

        return {
            "total_count": total_count,
            "limit": bounded_limit,
            "offset": bounded_offset,
            "gifts": results
        }
