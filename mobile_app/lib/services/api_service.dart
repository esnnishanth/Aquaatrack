import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String _serverUrl = 'https://aquatrack-orpin.vercel.app';
  static const String _api = '$_serverUrl/api';

  Future<Map<String, String>> _jsonHeaders() async {
    return {'Content-Type': 'application/json'};
  }

  // ─── Email OTP ────────────────────────────────────────────────────────

  Future<void> sendOtpEmail(String email) async {
    final response = await http.post(
      Uri.parse('$_serverUrl/api/send-otp'),
      headers: await _jsonHeaders(),
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to send OTP');
    }
  }

  Future<void> verifyEmailOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$_serverUrl/api/verify-otp'),
      headers: await _jsonHeaders(),
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Invalid OTP');
    }
  }

  // ─── Real-time streams (polling-based, replaces Firestore snapshots) ──

  Stream<Manager?> watchManager(String managerId) {
    final controller = StreamController<Manager?>();
    Timer? pollTimer;

    Future<void> poll() async {
      if (controller.isClosed) return;
      try {
        final manager = await fetchManager(managerId);
        if (!controller.isClosed) controller.add(manager);
      } catch (_) {}
    }

    poll();
    pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => poll());

    controller.onCancel = () {
      pollTimer?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Stream<List<Manager>> watchManagers({String? ownerId}) {
    final controller = StreamController<List<Manager>>();
    Timer? pollTimer;

    Future<void> poll() async {
      if (controller.isClosed) return;
      try {
        final managers = await fetchManagers(ownerId: ownerId);
        if (!controller.isClosed) controller.add(managers);
      } catch (_) {}
    }

    poll();
    pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => poll());

    controller.onCancel = () {
      pollTimer?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  // ─── One-shot fetches ───────────────────────────────────────────────

  Future<List<Manager>> fetchManagers({String? ownerId}) async {
    final uri = Uri.parse('$_api/managers').replace(
      queryParameters: ownerId != null ? {'ownerId': ownerId} : null,
    );
    final response = await http.get(uri, headers: await _jsonHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch managers');
    }
    final body = jsonDecode(response.body);
    final List<dynamic> data = body['data'] as List<dynamic>;
    return data.map((json) => Manager.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Manager> fetchManager(String managerId) async {
    final response = await http.get(
      Uri.parse('$_api/managers/$managerId'),
      headers: await _jsonHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Manager not found');
    }
    final body = jsonDecode(response.body);
    return Manager.fromJson(body as Map<String, dynamic>);
  }

  Future<Manager?> findManagerByVehicleNumber(String vehicleNumber) async {
    final response = await http.get(
      Uri.parse('$_api/managers/vehicle/$vehicleNumber'),
      headers: await _jsonHeaders(),
    );
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body);
    if (body == null) return null;
    return Manager.fromJson(body as Map<String, dynamic>);
  }

  // ─── Owner CRUD ──────────────────────────────────────────────────────

  Future<bool> ownerExists(String email) async {
    final response = await http.get(
      Uri.parse('$_api/owners?email=$email'),
      headers: await _jsonHeaders(),
    );
    if (response.statusCode != 200) return false;
    final body = jsonDecode(response.body);
    return body != null;
  }

  Future<bool> ownerExistsByPhone(String phone) async {
    final response = await http.get(
      Uri.parse('$_api/owners?phone=$phone'),
      headers: await _jsonHeaders(),
    );
    if (response.statusCode != 200) return false;
    final body = jsonDecode(response.body);
    return body != null;
  }

  Future<void> createOwner({
    required String id,
    required String name,
    required String email,
  }) async {
    await http.post(
      Uri.parse('$_api/owners'),
      headers: await _jsonHeaders(),
      body: jsonEncode({'id': id, 'name': name, 'email': email}),
    );
  }

  Future<Map<String, dynamic>?> getOwner(String ownerId) async {
    final response = await http.get(
      Uri.parse('$_api/owners/$ownerId'),
      headers: await _jsonHeaders(),
    );
    if (response.statusCode != 200) return null;
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateOwner(String ownerId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_api/owners/$ownerId'),
      headers: await _jsonHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to update owner');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifySpin(String ownerId, String spin) async {
    final response = await http.post(
      Uri.parse('$_api/owners/$ownerId/verify-spin'),
      headers: await _jsonHeaders(),
      body: jsonEncode({'spin': spin}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to verify SPIN');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteOwner(String ownerId) async {
    await http.delete(
      Uri.parse('$_api/owners/$ownerId'),
      headers: await _jsonHeaders(),
    );
  }

  // ─── Manager CRUD ────────────────────────────────────────────────────

  Future<Manager> createManager({
    required String name,
    required String vehicleNumber,
    required String password,
    String? ownerId,
  }) async {
    final response = await http.post(
      Uri.parse('$_api/managers'),
      headers: await _jsonHeaders(),
      body: jsonEncode({
        'name': name,
        'vehicleNumber': vehicleNumber,
        'password': password,
        if (ownerId != null) 'ownerId': ownerId,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create manager');
    }
    final body = jsonDecode(response.body);
    return fetchManager(body['id'] as String);
  }

  Future<void> updateManager({
    required String managerId,
    required String name,
    required String vehicleNumber,
    String? password,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'vehicleNumber': vehicleNumber,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    await http.put(
      Uri.parse('$_api/managers/$managerId'),
      headers: await _jsonHeaders(),
      body: jsonEncode(body),
    );
  }

  Future<void> deleteManager(String managerId) async {
    await http.delete(
      Uri.parse('$_api/managers/$managerId'),
      headers: await _jsonHeaders(),
    );
  }

  // ─── Agent CRUD ──────────────────────────────────────────────────────

  Future<void> addAgent({required String managerId, required String name}) async {
    final response = await http.post(
      Uri.parse('$_api/managers/$managerId/agents'),
      headers: await _jsonHeaders(),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add agent');
    }
  }

  Future<void> updateAgent({required String managerId, required String agentId, required String name}) async {
    await http.put(
      Uri.parse('$_api/managers/$managerId/agents/$agentId'),
      headers: await _jsonHeaders(),
      body: jsonEncode({'name': name}),
    );
  }

  Future<void> deleteAgent({required String managerId, required String agentId}) async {
    await http.delete(
      Uri.parse('$_api/managers/$managerId/agents/$agentId'),
      headers: await _jsonHeaders(),
    );
  }

  // ─── Bore CRUD ───────────────────────────────────────────────────────

  Future<void> addBore({
    required String managerId,
    required DateTime date,
    required String boreNumber,
    required double totalFeet,
    required double pricePerFeet,
    required double agentCommissionPerFeet,
    required double agentCommissionPerPipeFoot,
    required List<PipeEntry> pipesUsed,
    required List<FeetEntry> feetEntries,
    required String agentName,
    required double totalBill,
    required double initialPayment,
    required List<PipeLog> pipeLogs,
    double steelFeet = 0,
    double steelPricePerFeet = 0,
    double steelAgentCommission = 0,
    double steelWeldingCharge = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$_api/managers/$managerId/bores'),
      headers: await _jsonHeaders(),
      body: jsonEncode({
        'date': date.toIso8601String(),
        'boreNumber': boreNumber,
        'totalFeet': totalFeet,
        'pricePerFeet': pricePerFeet,
        'agentCommissionPerFeet': agentCommissionPerFeet,
        'agentCommissionPerPipeFoot': agentCommissionPerPipeFoot,
        'pipesUsed': pipesUsed.map((p) => p.toJson()).toList(),
        'feetEntries': feetEntries.map((f) => f.toJson()).toList(),
        'agentName': agentName,
        'totalBill': totalBill,
        'initialPayment': initialPayment,
        'pipeLogs': pipeLogs.map((l) => l.toJson()).toList(),
        'steelFeet': steelFeet,
        'steelPricePerFeet': steelPricePerFeet,
        'steelAgentCommission': steelAgentCommission,
        'steelWeldingCharge': steelWeldingCharge,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add bore');
    }
  }

  Future<void> updateBore({
    required String managerId,
    required String boreId,
    required DateTime date,
    required String boreNumber,
    required double totalFeet,
    required double pricePerFeet,
    required double agentCommissionPerFeet,
    required double agentCommissionPerPipeFoot,
    required List<PipeEntry> pipesUsed,
    required List<FeetEntry> feetEntries,
    required String agentName,
    required double totalBill,
    required double initialPayment,
    required List<PipeLog> pipeLogs,
    double steelFeet = 0,
    double steelPricePerFeet = 0,
    double steelAgentCommission = 0,
    double steelWeldingCharge = 0,
  }) async {
    final response = await http.put(
      Uri.parse('$_api/managers/$managerId/bores/$boreId'),
      headers: await _jsonHeaders(),
      body: jsonEncode({
        'date': date.toIso8601String(),
        'boreNumber': boreNumber,
        'totalFeet': totalFeet,
        'pricePerFeet': pricePerFeet,
        'agentCommissionPerFeet': agentCommissionPerFeet,
        'agentCommissionPerPipeFoot': agentCommissionPerPipeFoot,
        'pipesUsed': pipesUsed.map((p) => p.toJson()).toList(),
        'feetEntries': feetEntries.map((f) => f.toJson()).toList(),
        'agentName': agentName,
        'totalBill': totalBill,
        'initialPayment': initialPayment,
        'pipeLogs': pipeLogs.map((l) => l.toJson()).toList(),
        'steelFeet': steelFeet,
        'steelPricePerFeet': steelPricePerFeet,
        'steelAgentCommission': steelAgentCommission,
        'steelWeldingCharge': steelWeldingCharge,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update bore');
    }
  }

  Future<void> deleteBore({required String managerId, required String boreId}) async {
    await http.delete(
      Uri.parse('$_api/managers/$managerId/bores/$boreId'),
      headers: await _jsonHeaders(),
    );
  }

  Future<void> settleCommission({required String managerId, required String boreId}) async {
    await http.put(
      Uri.parse('$_api/managers/$managerId/bores/$boreId/settle'),
      headers: await _jsonHeaders(),
    );
  }

  Future<void> unsettleCommission({required String managerId, required String boreId}) async {
    await http.put(
      Uri.parse('$_api/managers/$managerId/bores/$boreId/unsettle'),
      headers: await _jsonHeaders(),
    );
  }

  Future<void> addPayment({required String managerId, required String boreId, required double amount, required DateTime date}) async {
    final response = await http.post(
      Uri.parse('$_api/managers/$managerId/bores/$boreId/payments'),
      headers: await _jsonHeaders(),
      body: jsonEncode({'amount': amount, 'date': date.toIso8601String()}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add payment');
    }
  }

  Future<void> deletePayment({required String managerId, required String boreId, required String paymentId}) async {
    await http.delete(
      Uri.parse('$_api/managers/$managerId/bores/$boreId/payments/$paymentId'),
      headers: await _jsonHeaders(),
    );
  }

  // ─── Normal Expense CRUD ─────────────────────────────────────────────

  Future<void> addNormalExpense({required String managerId, required String description, required double amount, required DateTime date, String createdBy = 'manager'}) async {
    final response = await http.post(
      Uri.parse('$_api/managers/$managerId/normal-expenses'),
      headers: await _jsonHeaders(),
      body: jsonEncode({
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'createdBy': createdBy,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add expense');
    }
  }

  Future<void> deleteNormalExpense({required String managerId, required String expenseId}) async {
    await http.delete(
      Uri.parse('$_api/managers/$managerId/normal-expenses/$expenseId'),
      headers: await _jsonHeaders(),
    );
  }

  // ─── Labour Payment CRUD ─────────────────────────────────────────────

  Future<void> addLabourPayment({required String managerId, required String workerId, required double amount, required DateTime date, String createdBy = 'manager'}) async {
    final response = await http.post(
      Uri.parse('$_api/managers/$managerId/labour-payments'),
      headers: await _jsonHeaders(),
      body: jsonEncode({
        'workerId': workerId,
        'amount': amount,
        'date': date.toIso8601String(),
        'createdBy': createdBy,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add labour payment');
    }
  }

  Future<void> deleteLabourPayment({required String managerId, required String paymentId}) async {
    await http.delete(
      Uri.parse('$_api/managers/$managerId/labour-payments/$paymentId'),
      headers: await _jsonHeaders(),
    );
  }

  // ─── Pipe Stock CRUD ─────────────────────────────────────────────────

  Future<void> addPipeStock({required String managerId, required double size, required int quantity}) async {
    final response = await http.post(
      Uri.parse('$_api/managers/$managerId/pipe-stock'),
      headers: await _jsonHeaders(),
      body: jsonEncode({'size': size, 'quantity': quantity}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to add pipe stock');
    }
  }

  Future<void> updatePipeStock({required String managerId, required double size, required int quantity}) async {
    await http.put(
      Uri.parse('$_api/managers/$managerId/pipe-stock/$size'),
      headers: await _jsonHeaders(),
      body: jsonEncode({'quantity': quantity}),
    );
  }

  Future<void> deletePipeStock({required String managerId, required double size}) async {
    await http.delete(
      Uri.parse('$_api/managers/$managerId/pipe-stock/$size'),
      headers: await _jsonHeaders(),
    );
  }

  // ─── Worker CRUD ─────────────────────────────────────────────────────

  Future<void> addWorker({required String managerId, required String name, required String place, required double monthlySalary, int monthsWorked = 12, DateTime? joiningDate}) async {
    final response = await http.post(
      Uri.parse('$_api/managers/$managerId/workers'),
      headers: await _jsonHeaders(),
      body: jsonEncode({
        'name': name,
        'place': place,
        'monthlySalary': monthlySalary,
        'monthsWorked': monthsWorked,
        'joiningDate': joiningDate?.toIso8601String(),
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add worker');
    }
  }

  Future<void> updateWorker({required String managerId, required String workerId, required String name, required String place, required double monthlySalary, int monthsWorked = 12, DateTime? joiningDate}) async {
    final response = await http.put(
      Uri.parse('$_api/managers/$managerId/workers/$workerId'),
      headers: await _jsonHeaders(),
      body: jsonEncode({
        'name': name,
        'place': place,
        'monthlySalary': monthlySalary,
        'monthsWorked': monthsWorked,
        'joiningDate': joiningDate?.toIso8601String(),
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update worker');
    }
  }

  Future<void> deleteWorker({required String managerId, required String workerId}) async {
    await http.delete(
      Uri.parse('$_api/managers/$managerId/workers/$workerId'),
      headers: await _jsonHeaders(),
    );
  }

  Future<void> addWorkerAbsence({required String managerId, required String workerId, required DateTime fromDate, required DateTime toDate}) async {
    final response = await http.post(
      Uri.parse('$_api/managers/$managerId/workers/$workerId/absences'),
      headers: await _jsonHeaders(),
      body: jsonEncode({
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add absence');
    }
  }

  Future<void> deleteWorkerAbsence({required String managerId, required String workerId, required String absenceId}) async {
    await http.delete(
      Uri.parse('$_api/managers/$managerId/workers/$workerId/absences/$absenceId'),
      headers: await _jsonHeaders(),
    );
  }
}
