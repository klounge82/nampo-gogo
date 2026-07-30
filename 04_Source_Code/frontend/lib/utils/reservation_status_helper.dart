import 'package:flutter/material.dart';

class ReservationStatusHelper {
  /// Converts any English/legacy reservation status to clear Korean text
  static String getKoreanLabel(String? status) {
    if (status == null || status.isEmpty) return '상태 확인 필요';
    final normalized = status.toUpperCase().trim();
    switch (normalized) {
      case 'PENDING':
        return '승인 대기';
      case 'APPROVED':
      case 'CONFIRMED':
        return '승인 완료';
      case 'REJECTED':
        return '승인 거절';
      case 'CANCELLED_BY_CUSTOMER':
        return '이용자 취소';
      case 'CANCELLED_BY_BUSINESS':
        return '매장 취소';
      case 'CANCELLED':
        return '취소됨';
      case 'COMPLETED':
        return '이용 완료';
      case 'NO_SHOW':
      case 'NOSHOW':
        return '노쇼';
      default:
        if (normalized.contains('CANCEL')) return '취소됨';
        return '상태 확인 필요';
    }
  }

  /// Returns themed status badge color
  static Color getStatusColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey;
    final normalized = status.toUpperCase().trim();
    switch (normalized) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
      case 'CONFIRMED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'CANCELLED_BY_CUSTOMER':
      case 'CANCELLED_BY_BUSINESS':
      case 'CANCELLED':
        return Colors.grey;
      case 'COMPLETED':
        return Colors.blue;
      case 'NO_SHOW':
      case 'NOSHOW':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Formats date and time safely even for null/legacy records
  static String formatDateTimeSafe(String? dateStr, String? timeStr) {
    final date = (dateStr == null || dateStr.isEmpty || dateStr == 'null')
        ? ''
        : dateStr.trim();
    final time = (timeStr == null || timeStr.isEmpty || timeStr == 'null')
        ? ''
        : timeStr.trim();
    if (date.isEmpty && time.isEmpty) return '시간 미정';
    if (date.isEmpty) return time;
    if (time.isEmpty) return '$date (시간 미정)';
    return '$date $time';
  }
}
