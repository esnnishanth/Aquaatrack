DateTime parseDate(dynamic value) {
  if (value == null) {
    return DateTime.now();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.parse(value as String);
}

class Worker {
  Worker({
    required this.id,
    required this.name,
    required this.place,
    required this.monthlySalary,
    required this.monthsWorked,
    required this.amountPaid,
    this.joiningDate,
    this.absenceRanges,
  });

  final String id;
  final String name;
  final String place;
  final double monthlySalary;
  final int monthsWorked;
  final double amountPaid;
  final DateTime? joiningDate;
  final List<WorkerAbsenceRange>? absenceRanges;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Worker && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  factory Worker.fromJson(Map<String, dynamic> json) {
    final rawAbsenceRanges = json['absenceRanges'];
    final List<WorkerAbsenceRange>? parsed = rawAbsenceRanges != null
        ? (rawAbsenceRanges as List<dynamic>)
            .map<WorkerAbsenceRange>((entry) => WorkerAbsenceRange.fromJson(entry as Map<String, dynamic>))
            .toList()
        : null;
    return Worker(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      place: (json['place'] ?? '') as String,
      monthlySalary: (json['monthlySalary'] as num?)?.toDouble() ?? 0,
      monthsWorked: (json['monthsWorked'] as num?)?.toInt() ?? 0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
      joiningDate: json['joiningDate'] != null ? DateTime.parse(json['joiningDate'] as String) : null,
      absenceRanges: parsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'place': place,
      'monthlySalary': monthlySalary,
      'monthsWorked': monthsWorked,
      'amountPaid': amountPaid,
      'joiningDate': joiningDate?.toIso8601String(),
      'absenceRanges': absenceRanges?.map((entry) => entry.toJson()).toList(),
    };
  }
}

class WorkerAbsenceRange {
  WorkerAbsenceRange({
    required this.id,
    required this.fromDate,
    required this.toDate,
    required this.workerId,
  });

  final String id;
  final DateTime fromDate;
  final DateTime toDate;
  final String workerId;

  factory WorkerAbsenceRange.fromJson(Map<String, dynamic> json) {
    return WorkerAbsenceRange(
      id: json['id'] as String,
      fromDate: parseDate(json['fromDate']),
      toDate: parseDate(json['toDate']),
      workerId: (json['workerId'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'workerId': workerId,
    };
  }
}

class Payment {
  Payment({
    required this.id,
    required this.date,
    required this.amount,
  });

  final String id;
  final DateTime date;
  final double amount;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      date: parseDate(json['date']),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
    };
  }
}

class PipeEntry {
  PipeEntry({
    required this.size,
    required this.length,
    required this.pricePerPipeFoot,
  });

  final double size;
  final double length;
  final double pricePerPipeFoot;

  factory PipeEntry.fromJson(Map<String, dynamic> json) {
    return PipeEntry(
      size: (json['size'] as num?)?.toDouble() ?? 0,
      length: (json['length'] as num?)?.toDouble() ?? 0,
      pricePerPipeFoot: (json['pricePerPipeFoot'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'length': length,
      'pricePerPipeFoot': pricePerPipeFoot,
    };
  }
}

class FeetEntry {
  FeetEntry({
    required this.length,
    required this.pricePerFeet,
  });

  final double length;
  final double pricePerFeet;

  factory FeetEntry.fromJson(Map<String, dynamic> json) {
    return FeetEntry(
      length: (json['length'] as num?)?.toDouble() ?? 0,
      pricePerFeet: (json['pricePerFeet'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'length': length,
      'pricePerFeet': pricePerFeet,
    };
  }
}

class Bore {
  Bore({
    required this.id,
    required this.date,
    required this.boreNumber,
    required this.totalFeet,
    required this.pricePerFeet,
    required this.agentCommissionPerFeet,
    required this.agentCommissionPerPipeFoot,
    required this.commissionSettled,
    required this.pipesUsed,
    required this.agentName,
    required this.totalBill,
    required this.payments,
    this.feetEntries = const [],
    this.steelFeet = 0,
    this.steelPricePerFeet = 0,
    this.steelAgentCommission = 0,
    this.steelWeldingCharge = 0,
  });

  final String id;
  final DateTime date;
  final String boreNumber;
  final double totalFeet;
  final double pricePerFeet;
  final double agentCommissionPerFeet;
  final double agentCommissionPerPipeFoot;
  final double commissionSettled;
  final List<PipeEntry> pipesUsed;
  final String agentName;
  final double totalBill;
  final List<Payment> payments;
  final List<FeetEntry> feetEntries;
  final double steelFeet;
  final double steelPricePerFeet;
  final double steelAgentCommission;
  final double steelWeldingCharge;

  factory Bore.fromJson(Map<String, dynamic> json) {
    final pipes = (json['pipesUsed'] as List<dynamic>? ?? [])
        .map((entry) => PipeEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
    final payments = (json['payments'] as List<dynamic>? ?? [])
        .map((entry) => Payment.fromJson(entry as Map<String, dynamic>))
        .toList();
    final feetEntries = (json['feetEntries'] as List<dynamic>? ?? [])
        .map((entry) => FeetEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
    return Bore(
      id: json['id'] as String,
      date: parseDate(json['date']),
      boreNumber: (json['boreNumber'] ?? '') as String,
      totalFeet: (json['totalFeet'] as num?)?.toDouble() ?? 0,
      pricePerFeet: (json['pricePerFeet'] as num?)?.toDouble() ?? 0,
      agentCommissionPerFeet: (json['agentCommissionPerFeet'] as num?)?.toDouble() ?? 0,
      agentCommissionPerPipeFoot: (json['agentCommissionPerPipeFoot'] as num?)?.toDouble() ?? 0,
      commissionSettled: (json['commissionSettled'] as num?)?.toDouble() ?? 0,
      pipesUsed: pipes,
      agentName: (json['agentName'] ?? '') as String,
      totalBill: (json['totalBill'] as num?)?.toDouble() ?? 0,
      payments: payments,
      feetEntries: feetEntries,
      steelFeet: (json['steelFeet'] as num?)?.toDouble() ?? 0,
      steelPricePerFeet: (json['steelPricePerFeet'] as num?)?.toDouble() ?? 0,
      steelAgentCommission: (json['steelAgentCommission'] as num?)?.toDouble() ?? 0,
      steelWeldingCharge: (json['steelWeldingCharge'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'boreNumber': boreNumber,
      'totalFeet': totalFeet,
      'pricePerFeet': pricePerFeet,
      'agentCommissionPerFeet': agentCommissionPerFeet,
      'agentCommissionPerPipeFoot': agentCommissionPerPipeFoot,
      'commissionSettled': commissionSettled,
      'pipesUsed': pipesUsed.map((entry) => entry.toJson()).toList(),
      'agentName': agentName,
      'totalBill': totalBill,
      'payments': payments.map((payment) => payment.toJson()).toList(),
      'feetEntries': feetEntries.map((entry) => entry.toJson()).toList(),
      'steelFeet': steelFeet,
      'steelPricePerFeet': steelPricePerFeet,
      'steelAgentCommission': steelAgentCommission,
      'steelWeldingCharge': steelWeldingCharge,
    };
  }
}

class NormalExpense {
  NormalExpense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.createdBy = 'manager',
  });

  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String createdBy;

  factory NormalExpense.fromJson(Map<String, dynamic> json) {
    return NormalExpense(
      id: json['id'] as String,
      description: (json['description'] ?? '') as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: parseDate(json['date']),
      createdBy: (json['createdBy'] as String?) ?? 'manager',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}

class LabourPayment {
  LabourPayment({
    required this.id,
    required this.workerId,
    required this.amount,
    required this.date,
    this.createdBy = 'manager',
  });

  final String id;
  final String workerId;
  final double amount;
  final DateTime date;
  final String createdBy;

  factory LabourPayment.fromJson(Map<String, dynamic> json) {
    return LabourPayment(
      id: json['id'] as String,
      workerId: (json['workerId'] ?? '') as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: parseDate(json['date']),
      createdBy: (json['createdBy'] as String?) ?? 'manager',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerId': workerId,
      'amount': amount,
      'date': date.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}
class PipeLog {
  PipeLog({
    required this.id,
    required this.date,
    required this.type,
    required this.quantity,
    required this.diameter,
    this.relatedBore,
  });

  final String id;
  final DateTime date;
  final String type;
  final int quantity;
  final double diameter;
  final String? relatedBore;

  factory PipeLog.fromJson(Map<String, dynamic> json) {
    return PipeLog(
      id: json['id'] as String,
      date: parseDate(json['date']),
      type: (json['type'] ?? '') as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      diameter: (json['diameter'] as num?)?.toDouble() ?? 0,
      relatedBore: json['relatedBore'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type,
      'quantity': quantity,
      'diameter': diameter,
      'relatedBore': relatedBore,
    };
  }
}

class PipeStockItem {
  PipeStockItem({
    required this.id,
    required this.size,
    required this.quantity,
  });

  final String id;
  final double size;
  final int quantity;

  factory PipeStockItem.fromJson(Map<String, dynamic> json) {
    return PipeStockItem(
      id: json['id'] as String,
      size: (json['size'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'size': size,
      'quantity': quantity,
    };
  }
}

class Agent {
  Agent({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class ManagerData {
  ManagerData({
    required this.workers,
    required this.bores,
    required this.normalExpenses,
    required this.labourPayments,
    required this.pipeLogs,
    required this.agents,
    required this.pipeStock,
  });

  final List<Worker> workers;
  final List<Bore> bores;
  final List<NormalExpense> normalExpenses;
  final List<LabourPayment> labourPayments;
  final List<PipeLog> pipeLogs;
  final List<Agent> agents;
  final List<PipeStockItem> pipeStock;

  factory ManagerData.empty() {
    return ManagerData(
      workers: [],
      bores: [],
      normalExpenses: [],
      labourPayments: [],
      pipeLogs: [],
      agents: [],
      pipeStock: [],
    );
  }

  factory ManagerData.fromJson(Map<String, dynamic> json) {
    return ManagerData(
      workers: (json['workers'] as List<dynamic>? ?? [])
          .map((entry) => Worker.fromJson(entry as Map<String, dynamic>))
          .toList(),
      bores: (json['bores'] as List<dynamic>? ?? [])
          .map((entry) => Bore.fromJson(entry as Map<String, dynamic>))
          .toList(),
      normalExpenses: (json['normalExpenses'] as List<dynamic>? ?? [])
          .map((entry) => NormalExpense.fromJson(entry as Map<String, dynamic>))
          .toList(),
      labourPayments: (json['labourPayments'] as List<dynamic>? ?? [])
          .map((entry) => LabourPayment.fromJson(entry as Map<String, dynamic>))
          .toList(),
      pipeLogs: (json['pipeLogs'] as List<dynamic>? ?? [])
          .map((entry) => PipeLog.fromJson(entry as Map<String, dynamic>))
          .toList(),
      agents: (json['agents'] as List<dynamic>? ?? [])
          .map((entry) => Agent.fromJson(entry as Map<String, dynamic>))
          .toList(),
      pipeStock: (json['pipeStock'] as List<dynamic>? ?? [])
          .map((entry) => PipeStockItem.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Manager {
  Manager({
    required this.id,
    required this.name,
    required this.vehicleNumber,
    required this.data,
    this.password,
    this.frozen = false,
    this.locked = false,
    this.statusReason = '',
    this.ownerId,
  });

  final String id;
  final String name;
  final String vehicleNumber;
  final String? password;
  final bool frozen;
  final bool locked;
  final String statusReason;
  final String? ownerId;
  final ManagerData data;

  factory Manager.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return Manager(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      vehicleNumber: (json['vehicleNumber'] ?? json['email'] ?? '') as String,
      password: json['password'] as String?,
      frozen: json['frozen'] == true,
      locked: json['locked'] == true,
      statusReason: (json['statusReason'] as String?) ?? '',
      ownerId: json['ownerId'] as String?,
      data: dataJson != null
          ? ManagerData.fromJson(dataJson as Map<String, dynamic>)
          : ManagerData.empty(),
    );
  }
}
