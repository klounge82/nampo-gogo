from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List

class UserBase(BaseModel):
    email: EmailStr
    nickname: str
    profile_image_url: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserOut(UserBase):
    id: str
    role: str
    status: str
    current_points: int
    language_code: str
    created_at: datetime
    updated_at: datetime
    last_login_at: Optional[datetime] = None

    class Config:
        from_attributes = True
        orm_mode = True

class UserUpdate(BaseModel):
    nickname: Optional[str] = None

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

class ProfileImageUploadRequest(BaseModel):
    filename: str
    base64_data: str

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str
    user: UserOut

# --- PLACE / STORE SCHEMAS ---

class StoreBase(BaseModel):
    name: str
    category: str
    rating: float
    address: str
    description: str
    image_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    name_en: Optional[str] = None
    name_ja: Optional[str] = None
    name_zh: Optional[str] = None
    description_en: Optional[str] = None
    description_ja: Optional[str] = None
    description_zh: Optional[str] = None
    status: Optional[str] = "영업중"
    operating_hours: Optional[str] = "09:00 - 22:00"
    phone_number: Optional[str] = "051-123-4567"
    homepage_url: Optional[str] = None
    review_verification_type: Optional[str] = "BUSINESS_QR"
    review_location_radius_m: Optional[int] = 300
    manual_visit_allowed: Optional[bool] = True

class StoreCreate(StoreBase):
    pass

class StoreOut(StoreBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True
        orm_mode = True

# --- MISSION SCHEMAS ---

class MissionBase(BaseModel):
    store_id: str
    title: str
    description: str
    points: int
    auth_type: str  # 'GPS', 'QR', 'PHOTO'
    status: Optional[str] = "active"

class MissionCreate(MissionBase):
    pass

class MissionOut(MissionBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True
        orm_mode = True

# --- POINT SCHEMAS ---

class PointEarnSpend(BaseModel):
    points: int
    activity: str
    user_id: Optional[str] = None

class PointHistoryOut(BaseModel):
    id: str
    user_id: str
    points: int
    activity: str
    created_at: datetime

    class Config:
        from_attributes = True
        orm_mode = True

# --- COUPON SCHEMAS ---

class CouponOut(BaseModel):
    id: str
    title: str
    description: str
    cost_points: int
    image_url: Optional[str] = None
    expiry_days: int
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
        orm_mode = True

class UserCouponOut(BaseModel):
    id: str
    user_id: str
    coupon_id: str
    status: str  # 'unused', 'used', 'expired'
    created_at: datetime
    expires_at: datetime
    used_at: Optional[datetime] = None
    coupon: CouponOut

    class Config:
        from_attributes = True
        orm_mode = True

# --- RESERVATION SCHEMAS ---

class ReservationCreate(BaseModel):
    store_id: str
    reservation_time: datetime
    party_size: int = 2
    user_id: Optional[str] = None

class ReservationOut(BaseModel):
    id: str
    user_id: str
    store_id: str
    reservation_time: datetime
    party_size: int
    status: str  # 'pending', 'confirmed', 'cancelled', 'completed'
    created_at: datetime
    updated_at: datetime
    store: StoreOut

    class Config:
        from_attributes = True
        orm_mode = True

# --- VISIT VERIFICATION SCHEMAS ---

class QRVerifyRequest(BaseModel):
    qr_token: str
    guest_id: Optional[str] = None
    user_id: Optional[str] = None

class LocationVerifyRequest(BaseModel):
    latitude: float
    longitude: float
    guest_id: Optional[str] = None
    user_id: Optional[str] = None

class ManualVisitVerifyRequest(BaseModel):
    visit_date: datetime
    visit_time_slot: Optional[str] = None
    companion_type: Optional[str] = None
    guest_id: Optional[str] = None
    user_id: Optional[str] = None

class VisitVerificationOut(BaseModel):
    id: str
    store_id: str
    user_id: Optional[str] = None
    guest_id: Optional[str] = None
    verification_method: str
    verified_at: datetime
    expires_at: datetime
    review_used_at: Optional[datetime] = None
    visit_date: Optional[datetime] = None
    measured_distance_m: Optional[float] = None
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
        orm_mode = True

# --- REVIEW SCHEMAS ---

class ReviewImageOut(BaseModel):
    id: str
    review_id: str
    image_url: str
    created_at: datetime

    class Config:
        from_attributes = True
        orm_mode = True

class ReviewCreate(BaseModel):
    rating: int # 1 to 5
    content: str
    user_id: Optional[str] = None
    guest_id: Optional[str] = None
    verification_id: Optional[str] = None
    image_urls: Optional[List[str]] = None

class ReviewUpdate(BaseModel):
    rating: Optional[int] = None
    content: Optional[str] = None
    image_urls: Optional[List[str]] = None
    user_id: Optional[str] = None
    guest_id: Optional[str] = None

class ReviewOut(BaseModel):
    id: str
    user_id: Optional[str] = None
    guest_id: Optional[str] = None
    store_id: str
    rating: int
    content: str
    is_deleted: bool
    is_hidden: bool
    verification_id: Optional[str] = None
    verification_method: Optional[str] = None
    verification_badge: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    user: Optional[UserOut] = None
    images: List[ReviewImageOut] = []
    store: StoreOut
    is_owner: bool = False
    can_edit: bool = False
    can_delete: bool = False
    can_restore: bool = False
    can_rewrite: bool = False

    class Config:
        from_attributes = True
        orm_mode = True

# --- ADMIN SCHEMAS ---

class AdminAuditLogOut(BaseModel):
    id: str
    admin_id: Optional[str] = None
    action: str
    target_id: Optional[str] = None
    details: Optional[str] = None
    created_at: datetime
    admin: Optional[UserOut] = None

    class Config:
        from_attributes = True
        orm_mode = True

class AdminStatsOut(BaseModel):
    total_users: int
    total_stores: int
    total_missions: int
    total_reservations: int
    total_reviews: int
    active_reservations: int

class UserStatusUpdate(BaseModel):
    status: str # 'active', 'blocked'

class StoreStatusUpdate(BaseModel):
    status: str # '영업중', '곧 마감', '휴무', 'inactive'

class MissionStatusUpdate(BaseModel):
    status: str # 'active', 'inactive'

class CouponStatusUpdate(BaseModel):
    status: str # 'active', 'inactive'

class CouponCreate(BaseModel):
    title: str
    description: str
    cost_points: int
    image_url: Optional[str] = None
    expiry_days: int = 30
    status: Optional[str] = "active"

class ReservationStatusUpdate(BaseModel):
    status: str # 'pending', 'confirmed', 'cancelled', 'completed'

class ReviewHideUpdate(BaseModel):
    is_hidden: bool

class StoreOwnerCreate(BaseModel):
    store_id: str
    user_id: str
    status: Optional[str] = "active"

class StoreOwnerOut(BaseModel):
    id: str
    store_id: str
    user_id: str
    status: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
        orm_mode = True

# --- AI RECOMMENDATION SCHEMAS ---

class RecommendationRequest(BaseModel):
    user_id: Optional[str] = None
    travel_type: str # 'SOLO', 'COUPLE', 'FAMILY', 'FRIENDS'
    travel_duration: str # 'TWO_HOURS', 'HALF_DAY', 'FULL_DAY'
    categories: List[str] # List of: 'FOOD', 'CAFE', 'TOURISM', 'SHOPPING', 'EXPERIENCE'
    transport_mode: str # 'WALK', 'TRANSIT', 'DRIVE'
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    
    # Personalization options
    use_personalization: Optional[bool] = False
    exclude_visited: Optional[bool] = False
    prefer_new_places: Optional[bool] = False
    prefer_rewards: Optional[bool] = False

class CourseItem(BaseModel):
    store_id: str
    visit_order: int
    recommend_reason_code: str
    store: StoreOut

    class Config:
        from_attributes = True
        orm_mode = True

class RecommendationResult(BaseModel):
    id: str
    travel_type: str
    travel_duration: str
    transport_mode: str
    start_latitude: float
    start_longitude: float
    is_saved: bool
    created_at: datetime
    items: List[CourseItem]

    class Config:
        from_attributes = True
        orm_mode = True

# --- FCM PUSH SCHEMAS ---

class NotificationTokenCreate(BaseModel):
    user_id: Optional[str] = None
    device_id: str
    device_type: str # 'android', 'ios'
    fcm_token: str
    language: Optional[str] = "ko"

class NotificationOut(BaseModel):
    id: str
    user_id: str
    type: str
    priority: str
    title: str
    body: str
    data_json: Optional[str] = None
    is_read: bool
    sent_status: str
    sent_at: Optional[datetime] = None
    read_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True
        orm_mode = True

class NotificationPreferenceOut(BaseModel):
    user_id: str
    reservation_enabled: bool
    mission_enabled: bool
    point_enabled: bool
    coupon_enabled: bool
    ai_enabled: bool
    event_enabled: bool
    marketing_consent: bool

    class Config:
        from_attributes = True
        orm_mode = True

class NotificationPreferenceUpdate(BaseModel):
    reservation_enabled: Optional[bool] = None
    mission_enabled: Optional[bool] = None
    point_enabled: Optional[bool] = None
    coupon_enabled: Optional[bool] = None
    ai_enabled: Optional[bool] = None
    event_enabled: Optional[bool] = None
    marketing_consent: Optional[bool] = None

class AdminSendNotificationRequest(BaseModel):
    target_user_id: Optional[str] = None # Null means send to all
    type: str # 'SYSTEM', 'MARKETING'
    priority: str = "NORMAL" # 'HIGH', 'NORMAL', 'LOW'
    title: str
    body: str
    data_json: Optional[str] = None

# --- LOCALIZATION SCHEMAS ---

class UserLanguageUpdate(BaseModel):
    language_code: str # 'ko', 'en', 'ja', 'zh'


# --- INTEGRATED SEARCH MVP SCHEMAS ---

class SearchResultItem(BaseModel):
    result_type: str # 'PLACE', 'MISSION', 'COUPON', 'RECOMMENDATION', 'CATEGORY'
    id: str
    title: str
    subtitle: str
    image_url: Optional[str] = None
    category: Optional[str] = None
    rating: Optional[float] = 0.0
    distance_meters: Optional[int] = None
    deeplink_type: str
    deeplink_id: str
    score: float = 0.0

class SearchResponse(BaseModel):
    query: str
    page: int
    size: int
    total: int
    items: List[SearchResultItem]

class AutocompleteResponse(BaseModel):
    suggestions: List[str]


# --- INTEGRATED FAVORITE MVP SCHEMAS ---

class FavoriteCreate(BaseModel):
    target_type: str # 'PLACE', 'RECOMMENDATION'
    target_id: str

class FavoriteItemOut(BaseModel):
    id: str
    target_type: str
    target_id: str
    title: str
    subtitle: str
    image_url: Optional[str] = None
    category: Optional[str] = None
    rating: Optional[float] = 0.0
    is_active: bool = True

class FavoriteMergeRequest(BaseModel):
    local_items: List[FavoriteCreate]


# --- INTEGRATED ACTIVITY TIMELINE MVP SCHEMAS ---

class ActivityLogOut(BaseModel):
    id: str
    user_id: str
    activity_type: str
    title: str
    description: str
    target_type: Optional[str] = None
    target_id: Optional[str] = None
    icon: str
    color: str
    created_at: datetime

    class Config:
        from_attributes = True
        orm_mode = True


# --- PERSONALIZED AI RECOMMENDATION MVP SCHEMAS ---

class RecommendationPreferenceUpdate(BaseModel):
    use_personalization: Optional[bool] = None
    prefer_new_places: Optional[bool] = None
    prefer_rewards: Optional[bool] = None
    disliked_categories: Optional[List[str]] = None

class RecommendationPreferenceOut(BaseModel):
    user_id: str
    use_personalization: bool
    prefer_new_places: bool
    prefer_rewards: bool
    disliked_categories: List[str]

    class Config:
        from_attributes = True
        orm_mode = True

class RecommendationFeedbackCreate(BaseModel):
    target_type: str # 'PLACE' or 'RECOMMENDATION'
    target_id: str
    feedback_type: str # 'LIKE', 'DISLIKE', 'DISMISS'

class RecommendationFeedbackOut(BaseModel):
    id: str
    user_id: str
    target_type: str
    target_id: str
    feedback_type: str
    created_at: datetime

    class Config:
        from_attributes = True
        orm_mode = True


# --- OWNER BUSINESS ANALYTICS MVP SCHEMAS ---

class OwnerDashboardOut(BaseModel):
    store_id: str
    today_revenue: int
    this_month_revenue: int
    reservation_count: int
    reservation_complete_rate: float
    ai_recommend_exposed: int
    ai_recommend_clicked: int
    favorite_saved: int
    map_direction_clicked: int
    coupon_used_count: int
    review_count: int
    average_rating: float
    new_customers: int
    returning_customers: int
    
    # Hero Card specific variables
    app_contributed_total_revenue: int
    app_contributed_net_profit: int
    app_usage_fee: int
    reservation_commission: int
    payment_commission: int
    ai_recommend_revenue: int
    roi_percentage: float

class RevenueStatsItem(BaseModel):
    period: str # e.g. '2026-07-15' or 'Week 1' or 'Jul'
    revenue: int

class RevenueStatsOut(BaseModel):
    today: int
    this_week: int
    this_month: int
    this_year: int
    timeline: List[RevenueStatsItem]

class ReservationStatsOut(BaseModel):
    pending_count: int
    confirmed_count: int
    cancelled_count: int
    completed_count: int
    total_count: int
    complete_rate: float

class AIStatsOut(BaseModel):
    generated_count: int
    saved_count: int
    clicked_count: int
    conversion_rate: float

class MapStatsOut(BaseModel):
    google_maps_clicks: int
    naver_maps_clicks: int
    map_views: int

class FavoriteStatsOut(BaseModel):
    added_count: int
    removed_count: int
    current_count: int

class CouponStatsOut(BaseModel):
    exchanged_count: int
    used_count: int
    unused_count: int

class CustomerStatsOut(BaseModel):
    new_customer_count: int
    returning_customer_count: int
    returning_rate: float

class ReviewStatsOut(BaseModel):
    pending_count: int
    confirmed_count: int
    cancelled_count: int
    completed_count: int
    total_count: int
    complete_rate: float


# --- OWNER/USER PAYMENT MVP SCHEMAS ---

class PaymentCreate(BaseModel):
    amount: int
    payment_method: str
    target_type: str
    target_id: str
    idempotency_key: str

class PaymentConfirm(BaseModel):
    payment_id: str
    mock_token: Optional[str] = None

class PaymentCancelRequest(BaseModel):
    payment_id: str
    reason: Optional[str] = None

class PaymentRefundRequest(BaseModel):
    payment_id: str
    refund_amount: int
    reason: str

class PaymentRefundOut(BaseModel):
    id: str
    payment_id: str
    refund_amount: int
    reason: Optional[str] = None
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
        orm_mode = True

class PaymentOut(BaseModel):
    id: str
    user_id: str
    amount: int
    payment_method: str
    target_type: str
    target_id: str
    status: str
    idempotency_key: str
    created_at: datetime
    updated_at: datetime
    refunds: List[PaymentRefundOut] = []

    class Config:
        from_attributes = True
        orm_mode = True

class StoreQrCredentialCreate(BaseModel):
    store_id: str
    token_string: str
    valid_hours: int = 6
    purpose: str = "REVIEW_VISIT"

class StoreQrCredentialOut(BaseModel):
    id: str
    store_id: str
    token_hash: str
    issued_at: datetime
    expires_at: datetime
    status: str
    purpose: str
    created_at: datetime
    revoked_at: Optional[datetime] = None

    class Config:
        from_attributes = True
        orm_mode = True
