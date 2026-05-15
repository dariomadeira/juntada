import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class StorageService {
  static const String _keyUsers = 'juntada_users';
  static const String _keyExpenses = 'juntada_expenses';

  static Future<void> saveJuntada(List<User> users, List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    
    final usersJson = jsonEncode(users.map((u) => u.toMap()).toList());
    final expensesJson = jsonEncode(expenses.map((e) => e.toMap()).toList());
    
    await prefs.setString(_keyUsers, usersJson);
    await prefs.setString(_keyExpenses, expensesJson);
  }

  static Future<Map<String, dynamic>> loadJuntada() async {
    final prefs = await SharedPreferences.getInstance();
    
    final usersStr = prefs.getString(_keyUsers);
    final expensesStr = prefs.getString(_keyExpenses);
    
    List<User> users = [];
    List<Expense> expenses = [];
    
    if (usersStr != null) {
      final List decoded = jsonDecode(usersStr);
      users = decoded.map((m) => User.fromMap(m)).toList();
    }
    
    if (expensesStr != null) {
      final List decoded = jsonDecode(expensesStr);
      expenses = decoded.map((m) => Expense.fromMap(m)).toList();
    }
    
    return {
      'users': users,
      'expenses': expenses,
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsers);
    await prefs.remove(_keyExpenses);
  }
}
