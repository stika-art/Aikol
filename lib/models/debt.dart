enum DebtType { owe, owed }

class Debt {
  final String id;
  final String userId;
  final String personName;
  final String phoneNumber;
  final double amount;
  final String description;
  final DateTime date;
  final DebtType type;
  final bool isPaid;
  final bool isDeleted;

  Debt({
    required this.id,
    required this.userId,
    required this.personName,
    this.phoneNumber = '',
    required this.amount,
    this.description = '',
    required this.date,
    required this.type,
    this.isPaid = false,
    this.isDeleted = false,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    // Очищаем сумму от пробелов и лишних символов (например, "1 451" -> 1451.0)
    String rawAmount = (json['Долг'] ?? '0').toString();
    double parsedAmount = double.tryParse(rawAmount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    return Debt(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      personName: json['Имя'] ?? '',
      phoneNumber: json['Телефон'] ?? '',
      amount: parsedAmount,
      description: json['description'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      type: json['type'] == 'owe' ? DebtType.owe : DebtType.owed,
      isPaid: json['is_paid'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'Имя': personName,
      'Телефон': phoneNumber,
      'Долг': amount.toString(), // Сохраняем как строку для соответствия типу в БД
      'description': description,
      'date': date.toIso8601String(),
      'type': type == DebtType.owe ? 'owe' : 'owed',
      'is_paid': isPaid,
      'is_deleted': isDeleted,
    };
  }

  Debt copyWith({
    String? id,
    String? userId,
    String? personName,
    String? phoneNumber,
    double? amount,
    String? description,
    DateTime? date,
    DebtType? type,
    bool? isPaid,
    bool? isDeleted,
  }) {
    return Debt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      personName: personName ?? this.personName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      isPaid: isPaid ?? this.isPaid,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
