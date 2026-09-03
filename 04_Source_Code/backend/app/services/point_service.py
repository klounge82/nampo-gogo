from typing import Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from .. import models


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
        Does NOT commit internally so caller controls atomic business transaction boundary.
        """
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

        # 2. Check sufficient balance if deducting
        if amount < 0 and (user.current_points + amount < 0):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="보유 포인트가 부족합니다.",
            )

        # 3. Update balance
        user.current_points += amount
        if update_lifetime and amount > 0:
            user.lifetime_earned_points += amount

        # 4. Insert point history ledger record
        history = models.PointHistory(
            user_id=user_id,
            points=amount,
            activity=activity,
            transaction_type=transaction_type,
            source_type=source_type,
            source_id=source_id,
        )
        db.add(history)

        return user
