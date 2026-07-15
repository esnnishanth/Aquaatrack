import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class AuthService {
  // Change this to your server's IP/hostname + port
  static const String _serverUrl = 'https://aquatrack-orpin.vercel.app';
  static const String _authBase = '$_serverUrl/api/auth/owner';

  String? _token;
  String? _ownerId;
  String? _ownerEmail;
  String? _ownerName;

  String? get currentOwnerId => _ownerId;
  String? get currentOwnerEmail => _ownerEmail;
  String? get currentOwnerName => _ownerName;
  bool get isSignedIn => _token != null;

  Future<void> _loadSession() async {
    _token = await StorageService.loadOwnerToken();
    _ownerId = await StorageService.loadOwnerId();
    _ownerEmail = await StorageService.loadOwnerEmail();
    _ownerName = await StorageService.loadOwnerName();
  }

  Future<void> _saveSession({
    required String token,
    required String id,
    required String email,
    required String name,
  }) async {
    _token = token;
    _ownerId = id;
    _ownerEmail = email;
    _ownerName = name;
    await StorageService.saveOwnerSession(
      token: token, id: id, email: email, name: name,
    );
  }

  Future<void> _clearSession() async {
    _token = null;
    _ownerId = null;
    _ownerEmail = null;
    _ownerName = null;
    await StorageService.clearOwnerSession();
  }

  Future<void> init() async {
    await _loadSession();
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = _token ?? await StorageService.loadOwnerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<({String id, String name, String email})> signInWithEmail(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$_authBase/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Sign in failed');
    }
    await _saveSession(
      token: body['token'] as String,
      id: body['owner']['id'] as String,
      email: body['owner']['email'] as String,
      name: body['owner']['name'] as String,
    );
    return (
      id: body['owner']['id'] as String,
      name: body['owner']['name'] as String,
      email: body['owner']['email'] as String,
    );
  }

  Future<({String email, String name})?> pickGoogleAccount() async {
    final google = GoogleSignIn(
      serverClientId: '620721606169-bn2tu2get3qef10eebs1ap7k4rbetf12.apps.googleusercontent.com',
    );
    await google.signOut();
    final googleUser = await google.signIn();
    if (googleUser == null) return null;
    return (email: googleUser.email, name: googleUser.displayName ?? 'Owner');
  }

  Future<({String id, String name, String email})> signInWithGoogle() async {
    final google = GoogleSignIn(
      serverClientId: '620721606169-bn2tu2get3qef10eebs1ap7k4rbetf12.apps.googleusercontent.com',
    );
    final googleUser = await google.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw Exception('No ID token from Google');

    final response = await http.post(
      Uri.parse('$_authBase/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Google sign-in failed');
    }
    await _saveSession(
      token: body['token'] as String,
      id: body['owner']['id'] as String,
      email: body['owner']['email'] as String,
      name: body['owner']['name'] as String,
    );
    return (
      id: body['owner']['id'] as String,
      name: body['owner']['name'] as String,
      email: body['owner']['email'] as String,
    );
  }

  Future<({String id, String name, String email, String phone})> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    bool partnership = false,
    List<String> partnerEmails = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$_authBase/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'partnership': partnership,
        'partnerEmails': partnerEmails,
      }),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 201) {
      throw Exception(body['error'] ?? 'Sign up failed');
    }
    await _saveSession(
      token: body['token'] as String,
      id: body['owner']['id'] as String,
      email: body['owner']['email'] as String,
      name: body['owner']['name'] as String,
    );
    return (
      id: body['owner']['id'] as String,
      name: body['owner']['name'] as String,
      email: body['owner']['email'] as String,
      phone: body['owner']['phone'] as String,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final response = await http.post(
      Uri.parse('$_authBase/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to send reset email');
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_authBase/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to reset password');
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse('$_authBase/password'),
      headers: headers,
      body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to update password');
    }
  }

  Future<void> deleteAccount() async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$_authBase/account'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to delete account');
    }
    await _clearSession();
  }

  Future<void> googleSignOut() async {
    final google = GoogleSignIn();
    await google.signOut();
  }

  Future<void> signOut() async {
    await _clearSession();
  }

  Future<bool> verifySession() async {
    final headers = await _authHeaders();
    if (headers['Authorization'] == null) return false;
    try {
      final response = await http.get(
        Uri.parse('$_authBase/me'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _ownerId = body['id'] as String;
        _ownerEmail = body['email'] as String;
        _ownerName = body['name'] as String;
        return true;
      }
      await _clearSession();
      return false;
    } catch (_) {
      return false;
    }
  }
}
