import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  static UserRole fromKey(String key) {
    return UserRole.values.firstWhere(
      (r) => r.key == key,
      orElse: () => UserRole.student,
    );
  }
}

class AuthResult {
  final bool ok;
  final String? message;
  final bool alreadyExisted;
  const AuthResult({required this.ok, this.message, this.alreadyExisted = false});
}

class PendingGoogleUser {
  final fb.User firebaseUser;
  final UserRole preferredRole;
  PendingGoogleUser(this.firebaseUser, this.preferredRole);
  String get email => firebaseUser.email ?? '';
}

/// Real Firebase-backed AuthProvider — exact same logic as `AuthProvider`
/// in index.html:
///  - login/signup write & read `users/{uid}` in the SAME Firestore project
///    the web app uses, so accounts are shared across web + app.
///  - login rejects if the account's stored role != the role picked in the
///    dropdown (same "This account is registered as X" message).
///  - Google sign-up: if a profile already exists -> log straight in.
///    If not -> hold the Firebase user in `pendingGoogleUser` and wait for
///    the UI to collect a password (completeGoogleSignup links it).
class AuthProvider extends ChangeNotifier {
  final _auth = fb.FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _google = GoogleSignIn(scopes: ['email']);

  Map<String, dynamic>? profile;
  fb.User? authUser;
  bool loading = true;

  PendingGoogleUser? _pendingGoogleUser;
  PendingGoogleUser? get pendingGoogleUser => _pendingGoogleUser;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(fb.User? user) async {
    authUser = user;
    if (user == null) {
      profile = null;
      loading = false;
      notifyListeners();
      return;
    }
    try {
      final snap = await _db.collection('users').doc(user.uid).get();
      if (!snap.exists) {
        await _auth.signOut();
        profile = null;
      } else {
        profile = {'id': user.uid, ...snap.data()!};
      }
    } catch (_) {
      profile = null;
    }
    loading = false;
    notifyListeners();
  }

  static const _roleLabels = {
    'student': 'Student',
    'teacher': 'Teacher',
    'owner': 'Owner',
    'parent': 'Parent',
  };

  Future<AuthResult> login(String email, String password, UserRole expectedRole) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final snap = await _db.collection('users').doc(cred.user!.uid).get();
      if (!snap.exists) {
        await _auth.signOut();
        return const AuthResult(ok: false, message: 'No account found for this login. Please sign up first.');
      }
      final data = {'id': cred.user!.uid, ...snap.data()!};
      if (data['role'] != expectedRole.key) {
        await _auth.signOut();
        final label = _roleLabels[data['role']] ?? data['role'];
        return AuthResult(ok: false, message: 'This account is registered as "$label". Select that role to log in.');
      }
      profile = data;
      authUser = cred.user;
      notifyListeners();
      return const AuthResult(ok: true);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult(ok: false, message: e.message ?? 'Login failed.');
    } catch (e) {
      return AuthResult(ok: false, message: e.toString());
    }
  }

  Future<AuthResult> signup({
    required String email,
    required String password,
    required UserRole role,
    required String name,
    String? instituteName,
    String? city,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;
      final data = {
        'id': uid,
        'authUid': uid,
        'email': email,
        'name': name,
        'role': role.key,
        'instituteIds': <String>[],
        'classIds': <String>[],
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _db.collection('users').doc(uid).set(data);

      if (role == UserRole.owner && (instituteName?.isNotEmpty ?? false)) {
        await _createInstitute(
          name: instituteName!,
          city: city?.isNotEmpty == true ? city! : 'Pune',
          ownerId: uid,
          ownerName: name,
        );
      }

      profile = data;
      authUser = cred.user;
      notifyListeners();
      return const AuthResult(ok: true);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult(ok: false, message: e.message ?? 'Signup failed.');
    } catch (e) {
      return AuthResult(ok: false, message: e.toString());
    }
  }

  Future<void> _createInstitute({
    required String name,
    required String city,
    required String ownerId,
    required String ownerName,
  }) async {
    final id = _db.collection('institutes').doc().id;
    await _db.collection('institutes').doc(id).set({
      'id': id,
      'name': name,
      'city': city,
      'description': 'New institute created from signup.',
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<AuthResult> _finishGoogleProfile(fb.User user, UserRole? expectedRole) async {
    final snap = await _db.collection('users').doc(user.uid).get();
    if (!snap.exists) {
      await _auth.signOut();
      return const AuthResult(ok: false, message: 'No account found for this Google account. Please sign up first.');
    }
    final data = {'id': user.uid, ...snap.data()!};
    if (expectedRole != null && data['role'] != expectedRole.key) {
      await _auth.signOut();
      final label = _roleLabels[data['role']] ?? data['role'];
      return AuthResult(ok: false, message: 'This Google account is registered as "$label". Select that role to log in.');
    }
    profile = data;
    authUser = user;
    notifyListeners();
    return const AuthResult(ok: true);
  }

  Future<fb.UserCredential?> _signInWithGooglePopup() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) return null; // user cancelled
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// LOGIN with Google — requires an existing profile + matching role.
  Future<AuthResult> loginWithGoogle(UserRole expectedRole) async {
    try {
      final result = await _signInWithGooglePopup();
      if (result == null) return const AuthResult(ok: false, message: 'Google sign-in was cancelled.');
      return await _finishGoogleProfile(result.user!, expectedRole);
    } catch (e) {
      return AuthResult(ok: false, message: 'Google sign-in failed: $e');
    }
  }

  /// STEP 1 of Google SIGN-UP — if profile already exists, log straight in.
  /// Otherwise hold the user and ask the UI for a password.
  Future<AuthResult> startGoogleSignup(UserRole preferredRole) async {
    try {
      final result = await _signInWithGooglePopup();
      if (result == null) return const AuthResult(ok: false, message: 'Google sign-in was cancelled.');
      final user = result.user!;
      final snap = await _db.collection('users').doc(user.uid).get();
      if (snap.exists) {
        final data = {'id': user.uid, ...snap.data()!};
        profile = data;
        authUser = user;
        notifyListeners();
        return const AuthResult(ok: true, alreadyExisted: true);
      }
      _pendingGoogleUser = PendingGoogleUser(user, preferredRole);
      notifyListeners();
      return const AuthResult(ok: true);
    } catch (e) {
      return AuthResult(ok: false, message: 'Google sign-in failed: $e');
    }
  }

  /// STEP 2 of Google SIGN-UP — link a password credential + create profile.
  Future<AuthResult> completeGoogleSignup({
    required String password,
    required String name,
    String? instituteName,
    String? city,
  }) async {
    final pending = _pendingGoogleUser;
    if (pending == null) {
      return const AuthResult(ok: false, message: 'Google sign-in session expired. Please try again.');
    }
    try {
      final credential = fb.EmailAuthProvider.credential(email: pending.email, password: password);
      await pending.firebaseUser.linkWithCredential(credential);

      final data = {
        'id': pending.firebaseUser.uid,
        'authUid': pending.firebaseUser.uid,
        'email': pending.email,
        'name': name.isNotEmpty ? name : (pending.firebaseUser.displayName ?? pending.email),
        'photoURL': pending.firebaseUser.photoURL,
        'role': pending.preferredRole.key,
        'instituteIds': <String>[],
        'classIds': <String>[],
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _db.collection('users').doc(pending.firebaseUser.uid).set(data);

      if (pending.preferredRole == UserRole.owner && (instituteName?.isNotEmpty ?? false)) {
        await _createInstitute(
          name: instituteName!,
          city: city?.isNotEmpty == true ? city! : 'Pune',
          ownerId: pending.firebaseUser.uid,
          ownerName: data['name'] as String,
        );
      }

      profile = data;
      authUser = pending.firebaseUser;
      _pendingGoogleUser = null;
      notifyListeners();
      return const AuthResult(ok: true);
    } catch (e) {
      return AuthResult(ok: false, message: 'Could not set password. Please try again. ($e)');
    }
  }

  void cancelGoogleSignup() {
    if (_pendingGoogleUser != null) {
      _auth.signOut();
    }
    _pendingGoogleUser = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    profile = null;
    authUser = null;
    notifyListeners();
  }
}
