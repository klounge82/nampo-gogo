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
    final rawTime =
        json['reservation_time']?.toString() ??
        (json['reservation_date'] != null && json['start_time'] != null
            ? '${json['reservation_date']}T${json['start_time']}:00'
            : null);

    final parsedTime = rawTime != null
        ? DateTime.tryParse(rawTime) ?? DateTime.now()
        : DateTime.now();

    final storeName =
        json['store_name']?.toString() ??
        (json['store'] is Map ? json['store']['name']?.toString() : null) ??
        '매장 정보 확인 중';

    final parsedStore =
        json['store'] is Map && (json['store'] as Map).isNotEmpty
        ? Place.fromJson(json['store'] as Map<String, dynamic>)
        : Place(
            id: json['store_id']?.toString() ?? '',
            name: storeName.isNotEmpty ? storeName : '매장 정보 확인 중',
            category: '매장',
            rating: 5.0,
            address: '',
            description: '',
            imageUrl: '',
            createdAt: DateTime.now(),
          );

    return Reservation(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      storeId: json['store_id']?.toString() ?? '',
      reservationTime: parsedTime,
      partySize: (json['party_size'] as num?)?.toInt() ?? 1,
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      store: parsedStore,
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
