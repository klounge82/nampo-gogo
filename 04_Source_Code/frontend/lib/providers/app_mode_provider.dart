import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

enum AppMode { customer, business, admin }

class AppModeProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage;
  AppMode _activeMode = AppMode.customer;

  static const String _modeKey = 'active_app_mode';

  AppModeProvider({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  AppMode get activeMode => _activeMode;

  bool get isCustomerMode => _activeMode == AppMode.customer;
  bool get isBusinessMode => _activeMode == AppMode.business;
  bool get isAdminMode => _activeMode == AppMode.admin;

  Future<void> initMode(User? user) async {
    try {
      final savedMode = await _storage.read(key: _modeKey);
      if (savedMode == 'BUSINESS' && (user?.isApprovedBusiness ?? false)) {
        _activeMode = AppMode.business;
      } else if (savedMode == 'ADMIN' && (user?.isAdmin ?? false)) {
        _activeMode = AppMode.admin;
      } else {
        _activeMode = AppMode.customer;
      }
    } catch (_) {
      _activeMode = AppMode.customer;
    }
    notifyListeners();
  }

  void syncUser(User? user) {
    if (user == null) {
      if (_activeMode != AppMode.customer) {
        _activeMode = AppMode.customer;
        _storage.write(key: _modeKey, value: 'CUSTOMER');
        notifyListeners();
      }
      return;
    }

    if (_activeMode == AppMode.business && !user.isApprovedBusiness) {
      _activeMode = AppMode.customer;
      _storage.write(key: _modeKey, value: 'CUSTOMER');
      notifyListeners();
    } else if (_activeMode == AppMode.admin && !user.isAdmin) {
      _activeMode = AppMode.customer;
      _storage.write(key: _modeKey, value: 'CUSTOMER');
      notifyListeners();
    }
  }

  Future<bool> switchMode(AppMode newMode, User? user) async {
    if (newMode == AppMode.business) {
      if (user == null || !user.isApprovedBusiness) {
        return false;
      }
    } else if (newMode == AppMode.admin) {
      if (user == null || !user.isAdmin) {
        return false;
      }
    }

    _activeMode = newMode;
    final modeStr = newMode == AppMode.business
        ? 'BUSINESS'
        : (newMode == AppMode.admin ? 'ADMIN' : 'CUSTOMER');

    await _storage.write(key: _modeKey, value: modeStr);
    notifyListeners();
    return true;
  }
}
