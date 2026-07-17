import 'place.dart';

class Reservation {
  final String id;
  final String userId;
  final String storeId;
  final DateTime reservationTime;
  final int partySize;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final DateTime createdAt;
  final DateTime updatedAt;
  final Place store;

  Reservation({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.reservationTime,
    required this.partySize,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.store,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      storeId: json['store_id'] as String? ?? '',
      reservationTime: json['reservation_time'] != null
          ? DateTime.parse(json['reservation_time'] as String)
          : DateTime.now(),
      partySize: json['party_size'] as int? ?? 2,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      store: Place.fromJson(json['store'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'store_id': storeId,
      'reservation_time': reservationTime.toIso8601String(),
      'party_size': partySize,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'store': store.toJson(),
    };
  }
}
