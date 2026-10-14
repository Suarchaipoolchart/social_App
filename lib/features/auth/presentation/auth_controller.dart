import 'package:flutter/foundation.dart';
import '../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repo);
  final AuthRepository _repo;

  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  Future<bool> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) =>
      _run(() => _repo.login(email: email, password: password));

  Future<bool> register(String name, String email, String password) => _run(
    () => _repo.register(email: email, password: password, displayName: name),
  );

  Future<bool> resetPassword(String email) =>
      _run(() => _repo.resetPassword(email));

  Future<bool> updateProfile(
    String uid, {
    required String displayName,
    required String bio,
    required bool isPrivate,
    String? photoUrl,
  }) => _run(
    () => _repo.updateProfile(
      uid,
      displayName: displayName,
      bio: bio,
      isPrivate: isPrivate,
      photoUrl: photoUrl,
    ),
  );

  Future<void> logout() => _repo.logout();
}
