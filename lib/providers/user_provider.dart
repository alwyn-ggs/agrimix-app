import 'package:flutter/foundation.dart';
import '../repositories/users_repo.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  final UsersRepo _repo;
  AppUser? _currentUser;
  bool _loading = false;
  String? _error;

  UserProvider(this._repo);

  AppUser? get currentUser => _currentUser;
  bool get loading => _loading;
  String? get error => _error;
  String? get userRole => _currentUser?.role;
  bool get isApproved => _currentUser?.approved ?? false;

  Future<void> loadUser(String uid) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _repo.getUser(uid);
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> updateUser(AppUser user) async {
    try {
      await _repo.updateUser(user);
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearUser() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
}