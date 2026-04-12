import 'package:flutter/foundation.dart';
import '../core/models/app_user.dart';
import '../core/services/firestore_service.dart';

enum AuthStatus { unauthenticated, loading, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;

  AuthStatus _status  = AuthStatus.unauthenticated;
  AppUser?   _user;
  String?    _error;

  AuthStatus get status        => _status;
  AppUser?   get currentUser   => _user;
  String?    get error         => _error;
  bool       get isLoggedIn    => _status == AuthStatus.authenticated;
  bool       get isLoading     => _status == AuthStatus.loading;
  String     get userId        => _user?.id ?? '';
  String     get userName      => _user?.name ?? '';

  Future<bool> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _error  = null;
    notifyListeners();
    try {
      _user   = await _firestore.loginUser(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error  = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String name,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _error  = null;
    notifyListeners();
    try {
      _user   = await _firestore.registerUser(email: email, name: name, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error  = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _user   = null;
    _status = AuthStatus.unauthenticated;
    _error  = null;
    notifyListeners();
  }

  void clearError() {
    _error  = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
