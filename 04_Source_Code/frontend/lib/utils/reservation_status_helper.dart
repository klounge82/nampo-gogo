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
        return '예약 승인';
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
        return Colors.orange.shade800;
      case 'APPROVED':
      case 'CONFIRMED':
        return Colors.green.shade700;
      case 'REJECTED':
        return Colors.red.shade700;
      case 'CANCELLED_BY_CUSTOMER':
      case 'CANCELLED_BY_BUSINESS':
      case 'CANCELLED':
        return Colors.grey.shade700;
      case 'COMPLETED':
        return Colors.blue.shade700;
      case 'NO_SHOW':
      case 'NOSHOW':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  /// Formats reservation code cleanly with RES- prefix and 4-char blocks
  static String formatReservationCode(String rawId) {
    if (rawId.isEmpty) return 'RES-0000-0000';
    final clean = rawId.replaceAll('-', '').toUpperCase();
    if (clean.length >= 12) {
      final part1 = clean.substring(0, 4);
      final part2 = clean.substring(4, 8);
      final part3 = clean.substring(8, 12);
      return 'RES-$part1-$part2-$part3';
    } else if (clean.length >= 8) {
      final part1 = clean.substring(0, 4);
      final part2 = clean.substring(4);
      return 'RES-$part1-$part2';
    } else {
      return 'RES-$clean';
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
