import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Float, Integer, Text, func, Boolean, UniqueConstraint
from sqlalchemy.orm import relationship
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String(255), unique=True, index=True, nullable=False)
    nickname = Column(String(100), nullable=False)
    role = Column(String(50), nullable=False, default="member") # 'member', 'admin'
    status = Column(String(50), nullable=False, default="active") # 'active', 'blocked'
    current_points = Column(Integer, nullable=False, default=0)
    language_code = Column(String(10), nullable=False, default="ko") # 'ko', 'en', 'ja', 'zh'
    profile_image_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())
    last_login_at = Column(DateTime, nullable=True)

    # One-to-one relationship with UserAuth
    auth = relationship("UserAuth", back_populates="user", uselist=False, cascade="all, delete-orphan")
    # One-to-many relationship with UserMission
    completed_missions = relationship("UserMission", back_populates="user", cascade="all, delete-orphan")
    # One-to-many relationship with PointHistory
    point_histories = relationship("PointHistory", back_populates="user", cascade="all, delete-orphan")
    # One-to-many relationship with UserCoupon
    coupons = relationship("UserCoupon", back_populates="user", cascade="all, delete-orphan")
    # One-to-many relationship with StoreReservation
    reservations = relationship("StoreReservation", back_populates="user", cascade="all, delete-orphan")
    # One-to-many relationship with Review
    reviews = relationship("Review", back_populates="user", cascade="all, delete-orphan")
    # One-to-many relationship with AdminAuditLog
    admin_logs = relationship("AdminAuditLog", back_populates="admin", cascade="all, delete-orphan")
    # One-to-many relationship with UserRecommendation
    recommendations = relationship("UserRecommendation", back_populates="user", cascade="all, delete-orphan")
    # One-to-many relationship with NotificationToken
    notification_tokens = relationship("NotificationToken", back_populates="user", cascade="all, delete-orphan")
    # One-to-many relationship with Notification
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    # One-to-one relationship with NotificationPreference
    notification_preference = relationship("NotificationPreference", back_populates="user", uselist=False, cascade="all, delete-orphan")
    # One-to-many relationship with Favorite
    favorites = relationship("Favorite", back_populates="user", cascade="all, delete-orphan")
    # One-to-many relationship with ActivityLog
    activities = relationship("ActivityLog", back_populates="user", cascade="all, delete-orphan")
    # One-to-one relationship with RecommendationPreference
    recommendation_preference = relationship("RecommendationPreference", back_populates="user", uselist=False, cascade="all, delete-orphan")
    # One-to-many relationship with RecommendationFeedback
    recommendation_feedbacks = relationship("RecommendationFeedback", back_populates="user", cascade="all, delete-orphan")
    # One-to-many relationship with Payment
    payments = relationship("Payment", back_populates="user", cascade="all, delete-orphan")
    # One-to-many relationship with StoreOwner
    store_ownerships = relationship("StoreOwner", back_populates="user", cascade="all, delete-orphan")
    # One-to-many relationship with VisitVerification
    verifications = relationship("VisitVerification", back_populates="user", cascade="all, delete-orphan")
    # Role-based extensions
    roles = relationship("UserRole", back_populates="user", cascade="all, delete-orphan")
    business_applications = relationship("BusinessApplication", foreign_keys="BusinessApplication.user_id", back_populates="user", cascade="all, delete-orphan")
    memberships = relationship("BusinessMembership", back_populates="user", cascade="all, delete-orphan")

class UserAuth(Base):
    __tablename__ = "user_auths"

    auth_id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)
    hashed_password = Column(String(255), nullable=False)

    # Relationship back to User
    user = relationship("User", back_populates="auth")

class UserRole(Base):
    __tablename__ = "user_roles"
    __table_args__ = (
        UniqueConstraint("user_id", "role", name="uq_user_role"),
    )

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    role = Column(String(50), nullable=False) # 'CUSTOMER', 'BUSINESS', 'ADMIN'
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationship to User
    user = relationship("User", back_populates="roles")

class BusinessApplication(Base):
    __tablename__ = "business_applications"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    business_name = Column(String(255), nullable=False)
    business_registration_number = Column(String(100), nullable=False)
    representative_name = Column(String(100), nullable=False)
    phone = Column(String(50), nullable=False)
    requested_store_id = Column(String(36), ForeignKey("stores.id", ondelete="SET NULL"), nullable=True)
    status = Column(String(50), nullable=False, default="PENDING") # 'PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED'
    rejection_reason = Column(Text, nullable=True)
    reviewed_by = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    reviewed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", foreign_keys=[user_id], back_populates="business_applications")
    reviewer = relationship("User", foreign_keys=[reviewed_by])
    requested_store = relationship("Store")

class BusinessMembership(Base):
    __tablename__ = "business_memberships"
    __table_args__ = (
        UniqueConstraint("user_id", "store_id", name="uq_user_store_membership"),
    )

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    store_id = Column(String(36), ForeignKey("stores.id", ondelete="CASCADE"), nullable=False, index=True)
    membership_role = Column(String(50), nullable=False, default="OWNER") # 'OWNER', 'MANAGER', 'STAFF'
    status = Column(String(50), nullable=False, default="ACTIVE") # 'ACTIVE', 'SUSPENDED', 'REVOKED'
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="memberships")
    store = relationship("Store", back_populates="memberships")

class Store(Base):
    __tablename__ = "stores"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), nullable=False)
    category = Column(String(50), nullable=False)
    rating = Column(Float, nullable=False, default=0.0)
    address = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    image_url = Column(String(500), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    # Multilingual & Status properties (MAP-001 / ADMIN-001)
    name_en = Column(String(100), nullable=True)
    name_ja = Column(String(100), nullable=True)
    name_zh = Column(String(100), nullable=True)
    description_en = Column(Text, nullable=True)
    description_ja = Column(Text, nullable=True)
    description_zh = Column(Text, nullable=True)
    status = Column(String(50), nullable=True, default="영업중") # '영업중', '곧 마감', '휴무'
    operating_hours = Column(String(100), nullable=True, default="09:00 - 22:00")
    phone_number = Column(String(50), nullable=True, default="051-123-4567")
    homepage_url = Column(String(255), nullable=True)
    review_verification_type = Column(String(50), nullable=True, default="BUSINESS_QR") # 'BUSINESS_QR', 'ATTRACTION_LOCATION', 'OPEN_REVIEW'
    review_location_radius_m = Column(Integer, nullable=True, default=300)
    manual_visit_allowed = Column(Boolean, nullable=True, default=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # One-to-many relationship with Mission
    missions = relationship("Mission", back_populates="store", cascade="all, delete-orphan")
    # One-to-many relationship with StoreReservation
    reservations = relationship("StoreReservation", back_populates="store", cascade="all, delete-orphan")
    # One-to-many relationship with Review
    reviews = relationship("Review", back_populates="store", cascade="all, delete-orphan")
    # One-to-many relationship with UserRecommendationItem
    recommend_items = relationship("UserRecommendationItem", back_populates="store", cascade="all, delete-orphan")
    # One-to-many relationship with StoreOwner
    owners = relationship("StoreOwner", back_populates="store", cascade="all, delete-orphan")
    # One-to-many relationship with VisitVerification
    verifications = relationship("VisitVerification", back_populates="store", cascade="all, delete-orphan")
    # One-to-many relationship with StoreQrCredential
    qr_credentials = relationship("StoreQrCredential", back_populates="store", cascade="all, delete-orphan")
    # One-to-many relationship with BusinessMembership
    memberships = relationship("BusinessMembership", back_populates="store", cascade="all, delete-orphan")

class StoreQrCredential(Base):
    __tablename__ = "store_qr_credentials"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    store_id = Column(String(36), ForeignKey("stores.id", ondelete="CASCADE"), nullable=False, index=True)
    token_hash = Column(String(255), nullable=False, index=True)
    issued_at = Column(DateTime, nullable=False, server_default=func.now())
    expires_at = Column(DateTime, nullable=False)
    status = Column(String(50), nullable=False, default="ACTIVE") # 'ACTIVE', 'EXPIRED', 'REVOKED'
    purpose = Column(String(50), nullable=False, default="REVIEW_VISIT") # 'REVIEW_VISIT', 'TEST_REVIEW_VISIT'
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    revoked_at = Column(DateTime, nullable=True)

    # Relationships
    store = relationship("Store", back_populates="qr_credentials")

class StoreOwner(Base):
    __tablename__ = "store_owners"
    __table_args__ = (
        UniqueConstraint("store_id", "user_id", name="uq_store_owner"),
    )

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    store_id = Column(String(36), ForeignKey("stores.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    status = Column(String(50), nullable=False, default="active") # 'active', 'inactive'
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="store_ownerships")
    store = relationship("Store", back_populates="owners")

class Mission(Base):
    __tablename__ = "missions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    store_id = Column(String(36), ForeignKey("stores.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(100), nullable=False)
    description = Column(Text, nullable=False)
    points = Column(Integer, nullable=False, default=100)
    auth_type = Column(String(50), nullable=False) # 'GPS', 'QR', 'PHOTO'
    status = Column(String(50), nullable=False, default="active") # 'active', 'inactive'
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationship to Store
    store = relationship("Store", back_populates="missions")
    # One-to-many relationship with UserMission
    user_records = relationship("UserMission", back_populates="mission", cascade="all, delete-orphan")

class UserMission(Base):
    __tablename__ = "user_missions"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    mission_id = Column(String(36), ForeignKey("missions.id", ondelete="CASCADE"), nullable=False)
    completed_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="completed_missions")
    mission = relationship("Mission", back_populates="user_records")

class PointHistory(Base):
    __tablename__ = "point_histories"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    points = Column(Integer, nullable=False)
    activity = Column(String(255), nullable=False)
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="point_histories")

class Coupon(Base):
    __tablename__ = "coupons"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    cost_points = Column(Integer, nullable=False)
    image_url = Column(String(500), nullable=True)
    expiry_days = Column(Integer, nullable=False, default=30)
    status = Column(String(50), nullable=False, default="active") # 'active', 'inactive'
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # One-to-many relationship with UserCoupon
    user_coupons = relationship("UserCoupon", back_populates="coupon", cascade="all, delete-orphan")

class UserCoupon(Base):
    __tablename__ = "user_coupons"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    coupon_id = Column(String(36), ForeignKey("coupons.id", ondelete="CASCADE"), nullable=False)
    status = Column(String(50), nullable=False, default="unused") # 'unused', 'used', 'expired'
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    expires_at = Column(DateTime, nullable=False)
    used_at = Column(DateTime, nullable=True)

    # Relationships
    user = relationship("User", back_populates="coupons")
    coupon = relationship("Coupon", back_populates="user_coupons")

class StoreReservation(Base):
    __tablename__ = "store_reservations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    store_id = Column(String(36), ForeignKey("stores.id", ondelete="CASCADE"), nullable=False)
    reservation_time = Column(DateTime, nullable=False)
    party_size = Column(Integer, nullable=False, default=2)
    status = Column(String(50), nullable=False, default="pending") # 'pending', 'confirmed', 'cancelled', 'completed'
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="reservations")
    store = relationship("Store", back_populates="reservations")

class Review(Base):
    __tablename__ = "reviews"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=True)
    guest_id = Column(String(255), nullable=True)
    store_id = Column(String(36), ForeignKey("stores.id", ondelete="CASCADE"), nullable=False)
    rating = Column(Integer, nullable=False) # 1 to 5
    content = Column(Text, nullable=False)
    is_deleted = Column(Boolean, nullable=False, default=False)
    is_hidden = Column(Boolean, nullable=False, default=False) # Admin Hide option (ADMIN-001)
    verification_id = Column(String(36), ForeignKey("visit_verifications.id", ondelete="SET NULL"), nullable=True)
    verification_method = Column(String(50), nullable=True)
    verification_badge = Column(String(100), nullable=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())
    deleted_at = Column(DateTime, nullable=True)

    # Relationships
    user = relationship("User", back_populates="reviews")
    store = relationship("Store", back_populates="reviews")
    verification = relationship("VisitVerification", back_populates="reviews")
    images = relationship("ReviewImage", back_populates="review", cascade="all, delete-orphan")

class VisitVerification(Base):
    __tablename__ = "visit_verifications"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    store_id = Column(String(36), ForeignKey("stores.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=True)
    guest_id = Column(String(255), nullable=True)
    verification_method = Column(String(50), nullable=False) # 'BUSINESS_QR', 'ATTRACTION_GPS', 'ATTRACTION_MANUAL', 'OPEN'
    qr_code_id = Column(String(36), nullable=True)
    qr_token_hash = Column(String(255), nullable=True)
    verified_at = Column(DateTime, nullable=False, server_default=func.now())
    expires_at = Column(DateTime, nullable=False)
    review_used_at = Column(DateTime, nullable=True)
    visit_date = Column(DateTime, nullable=True)
    measured_distance_m = Column(Float, nullable=True)
    status = Column(String(50), nullable=False, default="ACTIVE") # 'ACTIVE', 'USED', 'EXPIRED', 'REVOKED'
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    store = relationship("Store", back_populates="verifications")
    user = relationship("User", back_populates="verifications")
    reviews = relationship("Review", back_populates="verification")

class ReviewImage(Base):
    __tablename__ = "review_images"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    review_id = Column(String(36), ForeignKey("reviews.id", ondelete="CASCADE"), nullable=False)
    image_url = Column(String(500), nullable=False)
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    review = relationship("Review", back_populates="images")

class AdminAuditLog(Base):
    __tablename__ = "admin_audit_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    admin_id = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    action = Column(String(100), nullable=False) # e.g. 'UPDATE_USER_STATUS', 'HIDE_REVIEW'
    target_id = Column(String(36), nullable=True)
    details = Column(Text, nullable=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationship to User (Admin)
    admin = relationship("User", back_populates="admin_logs")

class UserRecommendation(Base):
    __tablename__ = "user_recommendations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=True)
    guest_id = Column(String(255), nullable=True)
    travel_type = Column(String(50), nullable=False) # 'SOLO', 'COUPLE', 'FAMILY', 'FRIENDS'
    travel_duration = Column(String(50), nullable=False) # 'TWO_HOURS', 'HALF_DAY', 'FULL_DAY'
    transport_mode = Column(String(50), nullable=False) # 'WALK', 'TRANSIT', 'DRIVE'
    start_latitude = Column(Float, nullable=False)
    start_longitude = Column(Float, nullable=False)
    is_saved = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="recommendations")
    items = relationship("UserRecommendationItem", back_populates="recommendation", cascade="all, delete-orphan")

class UserRecommendationItem(Base):
    __tablename__ = "user_recommendation_items"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    recommendation_id = Column(String(36), ForeignKey("user_recommendations.id", ondelete="CASCADE"), nullable=False)
    store_id = Column(String(36), ForeignKey("stores.id", ondelete="CASCADE"), nullable=False)
    visit_order = Column(Integer, nullable=False)
    recommend_reason_code = Column(String(100), nullable=False) # e.g. 'REASON_CLOSE', 'REASON_MISSION'

    # Relationships
    recommendation = relationship("UserRecommendation", back_populates="items")
    store = relationship("Store", back_populates="recommend_items")

class NotificationToken(Base):
    __tablename__ = "notification_tokens"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    device_id = Column(String(255), nullable=False)
    device_type = Column(String(50), nullable=False) # 'android', 'ios'
    fcm_token = Column(String(500), nullable=False)
    language = Column(String(10), nullable=False, default="ko")
    is_active = Column(Boolean, nullable=False, default=True)
    last_used_at = Column(DateTime, nullable=False, server_default=func.now())
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationship to User
    user = relationship("User", back_populates="notification_tokens")

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    type = Column(String(50), nullable=False) # 'RESERVATION', 'MISSION', 'POINT', 'COUPON', 'AI', 'SYSTEM', 'MARKETING'
    priority = Column(String(50), nullable=False, default="NORMAL") # 'HIGH', 'NORMAL', 'LOW'
    title = Column(String(255), nullable=False)
    body = Column(Text, nullable=False)
    data_json = Column(Text, nullable=True) # JSON payload string mapping properties
    is_read = Column(Boolean, nullable=False, default=False)
    sent_status = Column(String(50), nullable=False, default="pending") # 'pending', 'sent', 'failed'
    sent_at = Column(DateTime, nullable=True)
    read_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationship to User
    user = relationship("User", back_populates="notifications")

class NotificationPreference(Base):
    __tablename__ = "notification_preferences"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)
    reservation_enabled = Column(Boolean, nullable=False, default=True)
    mission_enabled = Column(Boolean, nullable=False, default=True)
    point_enabled = Column(Boolean, nullable=False, default=True)
    coupon_enabled = Column(Boolean, nullable=False, default=True)
    ai_enabled = Column(Boolean, nullable=False, default=True)
    event_enabled = Column(Boolean, nullable=False, default=True)
    marketing_consent = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationship to User
    user = relationship("User", back_populates="notification_preference")

class Favorite(Base):
    __tablename__ = "favorites"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    target_type = Column(String(50), nullable=False) # 'PLACE', 'RECOMMENDATION'
    target_id = Column(String(36), nullable=False)
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Complex Unique constraint
    __table_args__ = (
        UniqueConstraint('user_id', 'target_type', 'target_id', name='uq_user_target'),
    )

    # Relationship to User
    user = relationship("User", back_populates="favorites")

class ActivityLog(Base):
    __tablename__ = "activity_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    activity_type = Column(String(50), nullable=False) # Enum: SIGNUP, MISSION, POINT_EARN, POINT_USE, COUPON_EXCHANGE, etc.
    title = Column(String(100), nullable=False)
    description = Column(Text, nullable=False)
    target_type = Column(String(50), nullable=True) # e.g. 'PLACE', 'MISSION', 'COUPON', 'RESERVATION'
    target_id = Column(String(36), nullable=True)
    icon = Column(String(50), nullable=False)
    color = Column(String(50), nullable=False)
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationship to User
    user = relationship("User", back_populates="activities")

class RecommendationPreference(Base):
    __tablename__ = "user_recommendation_preferences"

    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    use_personalization = Column(Boolean, default=True, nullable=False)
    prefer_new_places = Column(Boolean, default=True, nullable=False)
    prefer_rewards = Column(Boolean, default=True, nullable=False)
    disliked_categories = Column(Text, default="[]", nullable=False) # Store JSON string of list

    # Relationship to User
    user = relationship("User", back_populates="recommendation_preference", uselist=False)

class RecommendationFeedback(Base):
    __tablename__ = "user_recommendation_feedbacks"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    target_type = Column(String(50), nullable=False) # 'PLACE' or 'RECOMMENDATION'
    target_id = Column(String(36), nullable=False)
    feedback_type = Column(String(50), nullable=False) # 'LIKE', 'DISLIKE', 'DISMISS'
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationship to User
    user = relationship("User", back_populates="recommendation_feedbacks")


# --- OWNER/USER PAYMENT MVP MODELS ---

class Payment(Base):
    __tablename__ = "payments"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    amount = Column(Integer, nullable=False)
    payment_method = Column(String(50), nullable=False) # 'TOSS', 'KAKAO', 'STRIPE', 'CARD', 'WECHAT', 'ALIPAY'
    target_type = Column(String(50), nullable=False) # 'RESERVATION_DEPOSIT', 'POINT_CHARGE', 'OWNER_SUBSCRIPTION'
    target_id = Column(String(36), nullable=False) # ID of target reservation, points recharge, etc.
    status = Column(String(50), nullable=False, default="pending") # 'pending', 'authorized', 'paid', 'failed', 'cancelled', 'refunded'
    idempotency_key = Column(String(255), nullable=False, unique=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="payments")
    logs = relationship("PaymentLog", back_populates="payment", cascade="all, delete-orphan")
    refunds = relationship("PaymentRefund", back_populates="payment", cascade="all, delete-orphan")

class PaymentLog(Base):
    __tablename__ = "payment_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    payment_id = Column(String(36), ForeignKey("payments.id", ondelete="CASCADE"), nullable=False)
    action = Column(String(50), nullable=False) # 'CREATE', 'CONFIRM', 'CANCEL', 'REFUND', 'FAIL'
    payload_json = Column(Text, nullable=True) # Full PG Response JSON string
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    payment = relationship("Payment", back_populates="logs")

class PaymentRefund(Base):
    __tablename__ = "payment_refunds"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    payment_id = Column(String(36), ForeignKey("payments.id", ondelete="CASCADE"), nullable=False)
    refund_amount = Column(Integer, nullable=False)
    reason = Column(String(255), nullable=True)
    status = Column(String(50), nullable=False, default="completed") # 'requested', 'completed', 'failed'
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    payment = relationship("Payment", back_populates="refunds")
