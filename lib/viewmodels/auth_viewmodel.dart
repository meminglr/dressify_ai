import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/services/supabase_service.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseClient _supabaseClient = SupabaseService.instance.client;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthViewModel() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _currentUser = _supabaseClient.auth.currentUser;
    notifyListeners();

    _supabaseClient.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setGoogleLoading(true);
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']!;
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID']!;

      final googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize(
        serverClientId: webClientId,
        clientId: iosClientId,
      );

      late final GoogleSignInAccount googleUser;
      try {
        googleUser = await googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          // Kullanıcı giriş yapmaktan vazgeçti
          _setGoogleLoading(false);
          return false;
        }
        rethrow;
      }

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      /// Authorization is required to obtain the access token
      final authorization =
          await googleUser.authorizationClient.authorizationForScopes([
            'email',
            'profile',
          ]) ??
          await googleUser.authorizationClient.authorizeScopes([
            'email',
            'profile',
          ]);

      if (idToken == null) {
        throw const AuthException('Google ID Token bulunamadı.');
      }

      await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );

      _setGoogleLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }

  void _setGoogleLoading(bool value) {
    _isGoogleLoading = value;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _isLoading = false;
    _isGoogleLoading = false;
    _errorMessage = _getFriendlyErrorMessage(error);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getFriendlyErrorMessage(String error) {
    final lowerError = error.toLowerCase();
    
    // AuthException translations
    if (lowerError.contains('invalid login credentials')) {
      return 'E-posta adresi veya şifre hatalı.';
    } else if (lowerError.contains('user already registered')) {
      return 'Bu e-posta adresi zaten kullanımda.';
    } else if (lowerError.contains('password should be at least 6 characters')) {
      return 'Şifreniz en az 6 karakter olmalıdır.';
    } else if (lowerError.contains('email not confirmed')) {
      return 'Lütfen e-posta adresinizi doğrulayın.';
    }
    
    // Network/System exceptions
    if (lowerError.contains('failed host lookup') || lowerError.contains('socketexception')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }
    
    return 'Bir hata oluştu: $error';
  }
}
