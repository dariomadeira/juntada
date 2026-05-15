import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'calculator.dart';
import 'theme.dart';
import 'storage_service.dart';
import 'widgets/expense_card.dart';
import 'widgets/add_expense_modal.dart';
import 'widgets/result_modal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = JuntadaProvider();
  await provider.init();
  runApp(JuntadaApp(provider: provider));
}

class JuntadaApp extends StatelessWidget {
  final JuntadaProvider provider;
  const JuntadaApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juntada',
      debugShowCheckedModeBanner: false,
      theme: JuntadaTheme.dark,
      home: LandingPage(provider: provider),
    );
  }
}

class JuntadaProvider extends ChangeNotifier {
  List<User> _users = [];
  List<Expense> _expenses = [];

  List<User> get users => List.unmodifiable(_users);
  List<Expense> get expenses => List.unmodifiable(_expenses);

  double get totalSpent => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  Future<void> init() async {
    final data = await StorageService.loadJuntada();
    _users = data['users'];
    _expenses = data['expenses'];
    notifyListeners();
  }

  void _saveToDisk() {
    StorageService.saveJuntada(_users, _expenses);
  }

  void addExpense({
    required String name,
    required double amount,
    String description = '',
  }) {
    // Find or create user
    User user;
    final existingUserIndex = _users.indexWhere((u) => u.name.toLowerCase() == name.toLowerCase());
    
    if (existingUserIndex != -1) {
      user = _users[existingUserIndex];
    } else {
      user = User(name: name);
      _users.add(user);
    }

    // Add expense at the top
    _expenses.insert(0, Expense(
      userId: user.id,
      userName: user.name,
      amount: amount,
      description: description,
    ));

    _saveToDisk();
    notifyListeners();
  }

  void removeExpense(String id) {
    final expense = _expenses.firstWhere((e) => e.id == id);
    final userId = expense.userId;
    _expenses.removeWhere((e) => e.id == id);
    
    final hasMoreExpenses = _expenses.any((e) => e.userId == userId);
    if (!hasMoreExpenses) {
      _users.removeWhere((u) => u.id == userId);
    }
    
    _saveToDisk();
    notifyListeners();
  }

  void restoreExpense(Expense expense, User? user) {
    if (user != null && !_users.any((u) => u.id == user.id)) {
      _users.add(user);
    }
    _expenses.add(expense);
    _saveToDisk();
    notifyListeners();
  }

  List<Transaction> calculate() {
    return JuntadaCalculator.calculateSettlements(_expenses, _users, roundTo: 100);
  }

  void clear() {
    _users.clear();
    _expenses.clear();
    StorageService.clear();
    notifyListeners();
  }
}

class LandingPage extends StatelessWidget {
  final JuntadaProvider provider;

  const LandingPage({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Juntada',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
                  Text(
                    '¿Qué vamos a calcular hoy?',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: JuntadaTheme.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 60),
                  _buildMenuCard(
                    context,
                    title: 'Cálculos de compras',
                    subtitle: 'Divide el ticket del súper, carnicería o bebidas.',
                    icon: Icons.shopping_cart_outlined,
                    color: const Color(0xFF6366F1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ShoppingPage()),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 24),
                  _buildMenuCard(
                    context,
                    title: 'Cálculos de gastos',
                    subtitle: 'Divide gastos generales, alquiler o comida.',
                    icon: Icons.payments_outlined,
                    color: JuntadaTheme.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ExpensesPage(provider: provider)),
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: JuntadaTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: JuntadaTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: JuntadaTheme.textSecondary.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Compras', style: GoogleFonts.outfit(color: Colors.white)),
      ),
      body: Center(
        child: Text(
          'Próximamente...',
          style: GoogleFonts.inter(color: JuntadaTheme.textSecondary),
        ),
      ),
    );
  }
}

class ExpensesPage extends StatefulWidget {
  final JuntadaProvider provider;

  const ExpensesPage({super.key, required this.provider});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  late JuntadaProvider provider;
  Expense? _lastDeletedExpense;
  User? _lastDeletedUser;
  bool _showUndoNotification = false;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    provider = widget.provider;
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _showNotification(Expense expense, User user) {
    setState(() {
      _lastDeletedExpense = expense;
      _lastDeletedUser = user;
      _showUndoNotification = true;
    });

    _notificationTimer?.cancel();
    _notificationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showUndoNotification = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildAppBar(context),
                  _buildStats(context),
                  _buildListHeader(context),
                  _buildExpensesList(context),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                ],
              ),
              if (_showUndoNotification && _lastDeletedExpense != null)
                _buildCustomNotification(),
              _buildTopGradient(context),
            ],
          ),
          floatingActionButton: _buildFAB(context),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        centerTitle: false,
        title: Text(
          'Cálculos de gastos',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 22),
        ),
      ),
      actions: [
        if (provider.expenses.isNotEmpty)
          IconButton(
            onPressed: () => _showClearConfirmation(context),
            icon: const Icon(Icons.refresh_rounded, color: JuntadaTheme.textSecondary),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: JuntadaTheme.surface,
        title: const Text('¿Limpiar todo?'),
        content: const Text('Se borrarán todos los gastos y participantes de esta juntada.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: JuntadaTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              provider.clear();
              Navigator.pop(context);
            },
            child: const Text('Limpiar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                JuntadaTheme.primary.withValues(alpha: 0.2),
                JuntadaTheme.accent.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gasto total', style: TextStyle(color: JuntadaTheme.textSecondary)),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(provider.totalSpent),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: JuntadaTheme.primary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildStatItem('Participantes', provider.users.length.toString()),
                  const SizedBox(width: 32),
                  _buildStatItem('Promedio', 
                    currencyFormat.format(provider.users.isEmpty ? 0 : provider.totalSpent / provider.users.length)
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: JuntadaTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildListHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Gastos', style: Theme.of(context).textTheme.headlineMedium),
            Text(
              '${provider.expenses.length} entradas',
              style: const TextStyle(color: JuntadaTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context) {
    if (provider.expenses.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay gastos aún',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '¡Toca el botón + para empezar!',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.15),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final expense = provider.expenses[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ExpenseCard(
              expense: expense,
              onDelete: () => _handleDelete(expense),
            ),
          );
        },
        childCount: provider.expenses.length,
      ),
    );
  }

  void _handleDelete(Expense expense) {
    final user = provider.users.firstWhere((u) => u.id == expense.userId);
    provider.removeExpense(expense.id);
    _showNotification(expense, user);
  }

  Widget _buildCustomNotification() {
    return Positioned(
      bottom: 100,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: JuntadaTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Gasto de ${_lastDeletedExpense?.userName} eliminado',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                if (_lastDeletedExpense != null && _lastDeletedUser != null) {
                  provider.restoreExpense(_lastDeletedExpense!, _lastDeletedUser);
                  setState(() => _showUndoNotification = false);
                }
              },
              child: const Text('Deshacer', style: TextStyle(color: JuntadaTheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.5, end: 0),
    );
  }

  Widget _buildTopGradient(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).padding.top + 60,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                JuntadaTheme.background,
                JuntadaTheme.background.withValues(alpha: 0.9),
                JuntadaTheme.background.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: 'add',
              onPressed: () => _showAddExpense(context),
              label: const Text('Agregar gasto', style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          if (provider.expenses.isNotEmpty) ...[
            const SizedBox(width: 16),
            FloatingActionButton(
              heroTag: 'calculate',
              onPressed: () => _showResults(context),
              backgroundColor: JuntadaTheme.secondary,
              child: const Icon(Icons.calculate_rounded),
            ),
          ],
        ],
      ),
    ).animate().slideY(begin: 1, duration: 600.ms, curve: Curves.easeOutQuart);
  }

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseModal(
        existingNames: provider.users.map((u) => u.name).toList(),
        onAdd: (name, amount, desc) {
          provider.addExpense(name: name, amount: amount, description: desc);
        },
      ),
    );
  }

  void _showResults(BuildContext context) {
    final transactions = provider.calculate();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ResultModal(
        transactions: transactions,
        totalSpent: provider.totalSpent,
        userCount: provider.users.length,
      ),
    );
  }
}
