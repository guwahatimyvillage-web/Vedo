import 'package:flutter/foundation.dart';

enum UserRole { student, teacher, owner, parent }

extension UserRoleX on UserRole {
  String get key => name;

  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.owner:
        return 'Institute Owner';
      case UserRole.parent:
        return 'Parent';
    }
  }
}

class AuthResult {
  final bool ok;
  final String? message;
  final bool alreadyExisted;
  const AuthResult({required this.ok, this.message, this.alreadyExisted = false});
}

class PendingGoogleUser {
  final String email;
  const PendingGoogleUser(this.email);
}

class AuthProvider extends ChangeNotifier {
  PendingGoogleUser? _pendingGoogleUser;
  PendingGoogleUser? get pendingGoogleUser => _pendingGoogleUser;

  Future<AuthResult> login(String email, String password, UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty || password.isEmpty) {
      return const AuthResult(ok: false, message: 'Enter email and password.');
    }
    return const AuthResult(ok: true);
  }

  Future<AuthResult> signup({
    required String email,
    required String password,
    required UserRole role,
    required String name,
    String? instituteName,
    String? city,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (password.length < 6) {
      return const AuthResult(ok: false, message: 'Password must be at least 6 characters.');
    }
    return const AuthResult(ok: true);
  }

  Future<AuthResult> loginWithGoogle(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const AuthResult(ok: true);
  }

  Future<AuthResult> startGoogleSignup(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _pendingGoogleUser = const PendingGoogleUser('demo@gmail.com');
    notifyListeners();
    return const AuthResult(ok: true, alreadyExisted: false);
  }

  Future<AuthResult> completeGoogleSignup({
    required String password,
    required String name,
    String? instituteName,
    String? city,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _pendingGoogleUser = null;
    notifyListeners();
    return const AuthResult(ok: true);
  }

  void cancelGoogleSignup() {
    _pendingGoogleUser = null;
    notifyListeners();
  }
}
