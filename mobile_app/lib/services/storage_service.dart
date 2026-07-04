import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _managerIdKey = 'loggedInManagerId';
  static const _keepOwnerKey = 'keepOwnerSignedIn';
  static const _ownerTokenKey = 'ownerToken';
  static const _ownerIdKey = 'ownerId';
  static const _ownerEmailKey = 'ownerEmail';
  static const _ownerNameKey = 'ownerName';

  // Manager session
  static Future<void> saveManagerId(String managerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_managerIdKey, managerId);
  }

  static Future<String?> loadManagerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_managerIdKey);
  }

  static Future<void> clearManagerId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_managerIdKey);
  }

  // Owner session
  static Future<void> saveOwnerSession({
    required String token,
    required String id,
    required String email,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ownerTokenKey, token);
    await prefs.setString(_ownerIdKey, id);
    await prefs.setString(_ownerEmailKey, email);
    await prefs.setString(_ownerNameKey, name);
  }

  static Future<String?> loadOwnerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ownerTokenKey);
  }

  static Future<String?> loadOwnerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ownerIdKey);
  }

  static Future<String?> loadOwnerEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ownerEmailKey);
  }

  static Future<String?> loadOwnerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ownerNameKey);
  }

  static Future<void> clearOwnerSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ownerTokenKey);
    await prefs.remove(_ownerIdKey);
    await prefs.remove(_ownerEmailKey);
    await prefs.remove(_ownerNameKey);
  }

  // Keep signed in preference
  static Future<void> saveKeepOwnerSignedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepOwnerKey, value);
  }

  static Future<bool> loadKeepOwnerSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepOwnerKey) ?? false;
  }

  static Future<void> clearKeepOwnerSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keepOwnerKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_managerIdKey);
    await prefs.remove(_ownerTokenKey);
    await prefs.remove(_ownerIdKey);
    await prefs.remove(_ownerEmailKey);
    await prefs.remove(_ownerNameKey);
    await prefs.remove(_keepOwnerKey);
  }
}
