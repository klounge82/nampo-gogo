import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../repositories/profile_repository.dart';
import 'auth_provider.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  ProfileProvider({ProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? ProfileRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // Update Nickname
  Future<User> updateNickname(BuildContext context, String nickname) async {
    _setLoading(true);
    try {
      final user = await _profileRepository.updateNickname(nickname);
      // Sync with global auth state
      final authProvider = context.read<AuthProvider>();
      authProvider.updateUser(user);
      return user;
    } finally {
      _setLoading(false);
    }
  }

  // Upload Profile Image
  Future<String> uploadProfileImage(BuildContext context, File file) async {
    _setLoading(true);
    try {
      final url = await _profileRepository.uploadProfileImage(file);
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        final updatedUser = authProvider.currentUser!.copyWith(profileImageUrl: url);
        authProvider.updateUser(updatedUser);
      }
      return url;
    } finally {
      _setLoading(false);
    }
  }

  // Remove Profile Image
  Future<User> removeProfileImage(BuildContext context) async {
    _setLoading(true);
    try {
      final user = await _profileRepository.removeProfileImage();
      final authProvider = context.read<AuthProvider>();
      authProvider.updateUser(user);
      return user;
    } finally {
      _setLoading(false);
    }
  }

  // Change Password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    try {
      await _profileRepository.changePassword(currentPassword, newPassword);
    } finally {
      _setLoading(false);
    }
  }

  // Withdraw Account
  Future<void> withdrawAccount(BuildContext context) async {
    _setLoading(true);
    try {
      await _profileRepository.withdrawAccount();
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
    } finally {
      _setLoading(false);
    }
  }
}
