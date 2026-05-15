import 'package:uuid/uuid.dart';

class User {
  final String id;
  final String name;

  User({
    String? id,
    required this.name,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class Expense {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final String description;
  final DateTime date;

  Expense({
    String? id,
    required this.userId,
    required this.userName,
    required this.amount,
    this.description = '',
    DateTime? date,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      userId: map['userId'],
      userName: map['userName'],
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
    );
  }
}

class Transaction {
  final String fromUser;
  final String toUser;
  final double amount;

  Transaction({
    required this.fromUser,
    required this.toUser,
    required this.amount,
  });
}
