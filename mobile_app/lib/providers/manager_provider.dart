import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ManagerProvider extends ChangeNotifier {
  ManagerProvider(this._apiService);

  final ApiService _apiService;
  Manager? _manager;
  bool _isLoading = false;
  List<Manager> _managers = [];
  StreamSubscription<Manager?>? _managerSub;
  StreamSubscription<List<Manager>>? _managersSub;

  Manager? get manager => _manager;
  bool get isLoading => _isLoading;
  List<Manager> get managers => _managers;

  void watchManager(String managerId) {
    _managerSub?.cancel();
    _managerSub = _apiService.watchManager(managerId).listen((manager) {
      _manager = manager;
      notifyListeners();
    });
  }

  void watchAllManagers({String? ownerId}) {
    _managersSub?.cancel();
    _managersSub = _apiService.watchManagers(ownerId: ownerId).listen((managers) {
      _managers = managers;
      notifyListeners();
    });
  }

  Future<void> fetchManager(String managerId) async {
    if (_manager == null) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      _manager = await _apiService.fetchManager(managerId);
      watchManager(managerId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllManagers({String? ownerId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _managers = await _apiService.fetchManagers(ownerId: ownerId);
      watchAllManagers(ownerId: ownerId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Manager> createManager({
    required String name,
    required String vehicleNumber,
    required String password,
    String? ownerId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newManager = await _apiService.createManager(
        name: name,
        vehicleNumber: vehicleNumber,
        password: password,
        ownerId: ownerId,
      );
      _manager = newManager;
      watchManager(newManager.id);
      return newManager;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateManager({
    required String managerId,
    required String name,
    required String vehicleNumber,
    String? password,
  }) async {
    await _apiService.updateManager(
      managerId: managerId,
      name: name,
      vehicleNumber: vehicleNumber,
      password: password,
    );
  }

  Future<void> deleteManager(String managerId) async {
    await _apiService.deleteManager(managerId);
    if (_manager?.id == managerId) {
      _manager = null;
      _managerSub?.cancel();
    }
  }

  Future<void> logout() async {
    await StorageService.clearManagerId();
    _managerSub?.cancel();
    _managersSub?.cancel();
    _manager = null;
    _managers = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _managerSub?.cancel();
    _managersSub?.cancel();
    super.dispose();
  }
}
