import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class StorageService {
  static const String _keyUsers = 'juntada_users';
  static const String _keyExpenses = 'juntada_expenses';
  static const String _keyShoppingUsers = 'juntada_shopping_users';
  static const String _keyMasterDiners = 'juntada_master_diners';
  static const String _keyMeatGrams = 'juntada_meat_grams';
  static const String _keyShowChorizos = 'juntada_show_chorizos';
  static const String _keyShowMorcillas = 'juntada_show_morcillas';
  static const String _keyBreadCount = 'juntada_bread_count';
  static const String _keyShowTomato = 'juntada_show_tomato';
  static const String _keyShowLettuce = 'juntada_show_lettuce';
  static const String _keyShowOnion = 'juntada_show_onion';
  static const String _keyShowRussianSalad = 'juntada_show_russian_salad';
  static const String _keyShowMayonnaise = 'juntada_show_mayonnaise';
  static const String _keyShowSoda = 'juntada_show_soda';

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

  static Future<void> saveShoppingUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = jsonEncode(users.map((u) => u.toMap()).toList());
    await prefs.setString(_keyShoppingUsers, usersJson);
  }

  static Future<List<User>> loadShoppingUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_keyShoppingUsers);
    if (usersStr == null) return [];
    final List decoded = jsonDecode(usersStr);
    return decoded.map((m) => User.fromMap(m)).toList();
  }

  static Future<void> clearShopping() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyShoppingUsers);
  }

  static Future<void> saveMasterDiners(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = jsonEncode(users.map((u) => u.toMap()).toList());
    await prefs.setString(_keyMasterDiners, usersJson);
  }

  static Future<List<User>> loadMasterDiners() async {
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_keyMasterDiners);
    if (usersStr == null) return [];
    final List decoded = jsonDecode(usersStr);
    return decoded.map((m) => User.fromMap(m)).toList();
  }

  static Future<void> saveAsadoConfig(int grams, bool chorizos, bool morcillas, int breads, bool tomato, bool lettuce, bool onion, bool russian, bool mayo, bool soda) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMeatGrams, grams);
    await prefs.setBool(_keyShowChorizos, chorizos);
    await prefs.setBool(_keyShowMorcillas, morcillas);
    await prefs.setInt(_keyBreadCount, breads);
    await prefs.setBool(_keyShowTomato, tomato);
    await prefs.setBool(_keyShowLettuce, lettuce);
    await prefs.setBool(_keyShowOnion, onion);
    await prefs.setBool(_keyShowRussianSalad, russian);
    await prefs.setBool(_keyShowMayonnaise, mayo);
    await prefs.setBool(_keyShowSoda, soda);
  }

  static Future<Map<String, dynamic>> loadAsadoConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'grams': prefs.getInt(_keyMeatGrams) ?? 500,
      'chorizos': prefs.getBool(_keyShowChorizos) ?? false,
      'morcillas': prefs.getBool(_keyShowMorcillas) ?? false,
      'breads': prefs.getInt(_keyBreadCount) ?? 4,
      'tomato': prefs.getBool(_keyShowTomato) ?? false,
      'lettuce': prefs.getBool(_keyShowLettuce) ?? false,
      'onion': prefs.getBool(_keyShowOnion) ?? false,
      'russian': prefs.getBool(_keyShowRussianSalad) ?? false,
      'mayo': prefs.getBool(_keyShowMayonnaise) ?? false,
      'soda': prefs.getBool(_keyShowSoda) ?? false,
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsers);
    await prefs.remove(_keyExpenses);
  }
}
