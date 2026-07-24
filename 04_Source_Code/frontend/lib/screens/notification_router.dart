import 'package:flutter/material.dart';
import 'place_detail_screen.dart';
import 'reservation_detail_screen.dart';
import 'saved_courses_screen.dart';
import 'user_coupon_screen.dart';

class NotificationRouter {
  static void routeToScreen(
    BuildContext context,
    String type,
    Map<String, dynamic> data,
  ) {
    if (!context.mounted) return;

    switch (type) {
      case 'RESERVATION':
        final resId = data['reservation_id'] ?? '';
        if (resId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReservationDetailScreen(reservationId: resId),
            ),
          );
        }
        break;

      case 'COUPON':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserCouponScreen()),
        );
        break;

      case 'AI':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SavedCoursesScreen()),
        );
        break;

      case 'MISSION':
        // Redirect to place detail screen if store_id provided to re-verify mission
        final storeId = data['store_id'] ?? '';
        if (storeId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaceDetailScreen(placeId: storeId),
            ),
          );
        }
        break;

      default:
        // System and generic alerts remain in history screen or default view
        break;
    }
  }
}
