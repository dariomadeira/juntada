import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'widgets/diner_card.dart';
import 'widgets/master_diner_sheet.dart';
import 'widgets/asado_config_modal.dart';

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
  List<User> _shoppingUsers = [];
  List<User> _masterDiners = [];
  int _meatGramsPerPerson = 500;
  bool _showChorizos = false;
  bool _showMorcillas = false;
  int _breadsPerPerson = 4;
  bool _showTomato = false;
  bool _showLettuce = false;
  bool _showOnion = false;
  bool _showRussianSalad = false;
  bool _showMayonnaise = false;
  bool _showSoda = false;

  List<User> get users => List.unmodifiable(_users);
  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<User> get shoppingUsers => List.unmodifiable(_shoppingUsers);
  List<User> get masterDiners => List.unmodifiable(_masterDiners);
  int get meatGramsPerPerson => _meatGramsPerPerson;
  bool get showChorizos => _showChorizos;
  bool get showMorcillas => _showMorcillas;
  int get breadsPerPerson => _breadsPerPerson;
  bool get showTomato => _showTomato;
  bool get showLettuce => _showLettuce;
  bool get showOnion => _showOnion;
  bool get showRussianSalad => _showRussianSalad;
  bool get showMayonnaise => _showMayonnaise;
  bool get showSoda => _showSoda;

  double get totalSpent => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  Future<void> init() async {
    final data = await StorageService.loadJuntada();
    _users = data['users'];
    _expenses = data['expenses'];
    _shoppingUsers = await StorageService.loadShoppingUsers();
    _masterDiners = await StorageService.loadMasterDiners();
    final config = await StorageService.loadAsadoConfig();
    _meatGramsPerPerson = config['grams'];
    _showChorizos = config['chorizos'];
    _showMorcillas = config['morcillas'];
    _breadsPerPerson = config['breads'];
    _showTomato = config['tomato'];
    _showLettuce = config['lettuce'];
    _showOnion = config['onion'];
    _showRussianSalad = config['russian'];
    _showMayonnaise = config['mayo'];
    _showSoda = config['soda'];
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

  void updateExpense({
    required String id,
    required String name,
    required double amount,
    String description = '',
  }) {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      final oldUserId = _expenses[index].userId;
      
      // Find or create user for the NEW name
      User user;
      final existingUserIndex = _users.indexWhere((u) => u.name.toLowerCase() == name.toLowerCase());
      if (existingUserIndex != -1) {
        user = _users[existingUserIndex];
      } else {
        user = User(name: name);
        _users.add(user);
      }

      _expenses[index] = _expenses[index].copyWith(
        userId: user.id,
        userName: user.name,
        amount: amount,
        description: description,
      );

      // Clean up old user if they have no more expenses
      final hasMoreExpenses = _expenses.any((e) => e.userId == oldUserId);
      if (!hasMoreExpenses) {
        _users.removeWhere((u) => u.id == oldUserId);
      }

      _saveToDisk();
      notifyListeners();
    }
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

  // Shopping Methods
  void addShoppingUser(User user) {
    if (_shoppingUsers.any((u) => u.id == user.id)) return;
    _shoppingUsers.add(user);
    StorageService.saveShoppingUsers(_shoppingUsers);
    notifyListeners();
  }

  void removeShoppingUser(String id) {
    _shoppingUsers.removeWhere((u) => u.id == id);
    StorageService.saveShoppingUsers(_shoppingUsers);
    notifyListeners();
  }

  void clearShopping() {
    _shoppingUsers.clear();
    StorageService.clearShopping();
    notifyListeners();
  }

  // Master Diner Methods
  void addMasterDiner(String name) {
    if (name.trim().isEmpty) return;
    _masterDiners.add(User(name: name));
    StorageService.saveMasterDiners(_masterDiners);
    notifyListeners();
  }

  void removeMasterDiner(String id) {
    _masterDiners.removeWhere((u) => u.id == id);
    _shoppingUsers.removeWhere((u) => u.id == id); // Also remove from current list if deleted from master
    StorageService.saveMasterDiners(_masterDiners);
    StorageService.saveShoppingUsers(_shoppingUsers);
    notifyListeners();
  }

  void updateAsadoConfig({int? grams, bool? chorizos, bool? morcillas, int? breads, bool? tomato, bool? lettuce, bool? onion, bool? russian, bool? mayo, bool? soda}) {
    if (grams != null) _meatGramsPerPerson = grams;
    if (chorizos != null) _showChorizos = chorizos;
    if (morcillas != null) _showMorcillas = morcillas;
    if (breads != null) _breadsPerPerson = breads;
    if (tomato != null) _showTomato = tomato;
    if (lettuce != null) _showLettuce = lettuce;
    if (onion != null) _showOnion = onion;
    if (russian != null) _showRussianSalad = russian;
    if (mayo != null) _showMayonnaise = mayo;
    if (soda != null) _showSoda = soda;
    StorageService.saveAsadoConfig(
      _meatGramsPerPerson, 
      _showChorizos, 
      _showMorcillas, 
      _breadsPerPerson,
      _showTomato,
      _showLettuce,
      _showOnion,
      _showRussianSalad,
      _showMayonnaise,
      _showSoda,
    );
    notifyListeners();
  }

  void startExpensesFromShopping() {
    _expenses.clear();
    _users.clear();
    
    for (var user in _shoppingUsers) {
      if (!_users.any((u) => u.id == user.id)) {
        _users.add(user);
      }
      _expenses.add(Expense(
        userId: user.id,
        userName: user.name,
        amount: 0,
        description: 'Carga inicial',
      ));
    }
    _saveToDisk();
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
                    subtitle: 'Calcula la cantidad de Carne, Leña, Pan, etc.',
                    icon: Icons.shopping_cart_outlined,
                    color: const Color(0xFF6366F1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ShoppingPage(provider: provider)),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 24),
                  _buildMenuCard(
                    context,
                    title: 'Cálculos de gastos',
                    subtitle: 'Divide gastos generales entre cada una de las personas que participan.',
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

class ShoppingPage extends StatefulWidget {
  final JuntadaProvider provider;

  const ShoppingPage({super.key, required this.provider});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  late JuntadaProvider provider;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    provider = widget.provider;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }

  void _showResetExpensesConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: JuntadaTheme.surface,
        title: const Text('¿Reiniciar gastos?'),
        content: const Text('Ya tienes gastos cargados. Si continúas, se borrarán todos los tickets actuales y se reiniciarán con los comensales de esta lista.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: JuntadaTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              provider.startExpensesFromShopping();
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExpensesPage(provider: provider)),
              );
            },
            child: const Text('Reiniciar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
                  _buildTopCard(context),
                  _buildSearchBar(context),
                  _buildListHeader(context),
                  _buildDinersList(context),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                ],
              ),
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
          'Compras',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 22),
        ),
      ),
      actions: [
        if (provider.shoppingUsers.isNotEmpty)
          IconButton(
            onPressed: () => _showClearConfirmation(context),
            icon: const Icon(Icons.refresh_rounded, color: JuntadaTheme.textSecondary),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  int _calculateWoodBags(int dinerCount, double meatKilos) {
    if (dinerCount == 0) return 0;
    
    double totalProductKilos = meatKilos;
    if (provider.showChorizos) {
      totalProductKilos += dinerCount * 0.15; // 150g per chorizo
    }
    if (provider.showMorcillas) {
      final morcillas = (dinerCount / 2).ceil();
      totalProductKilos += morcillas * 0.15; // 150g per morcilla
    }
    
    // Standard rule: 3kg of firewood per 1kg of meat
    final woodNeededKilos = totalProductKilos * 3;
    
    // A standard bag of firewood in Argentina is 10kg
    return (woodNeededKilos / 10).ceil();
  }

  void _shareAsadoInfo(BuildContext context) {
    final dinerCount = provider.shoppingUsers.length;
    if (dinerCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega comensales para compartir el cálculo')),
      );
      return;
    }

    final gramsPerPerson = provider.meatGramsPerPerson;
    final meatKilos = (dinerCount * (gramsPerPerson / 1000)).toStringAsFixed(1);
    final woodBags = _calculateWoodBags(dinerCount, double.parse(meatKilos));
    final morcillaCount = (dinerCount / 2).ceil();
    final breadKilos = ((dinerCount * provider.breadsPerPerson * 0.05 * 2).ceil() / 2).toStringAsFixed(1);
    
    String text = "🔥 *Cálculo de Asado - Juntada* 🔥\n\n";
    text += "👥 *Comensales ($dinerCount):*\n";
    for (var user in provider.shoppingUsers) {
      text += "• ${user.name}\n";
    }
    
    text += "\n🛒 *Lista de Compras:*\n";
    text += "🥩 Carne: $meatKilos kg ($gramsPerPerson g/persona)\n";
    text += "🪵 Leña: $woodBags bolsas\n";
    text += "🥖 Pan: $breadKilos kg\n";
    
    if (provider.showChorizos) {
      text += "🌭 Chorizos: $dinerCount unidades\n";
    }
    if (provider.showMorcillas) {
      text += "🩸 Morcillas: $morcillaCount unidades\n";
    }
    if (provider.showSoda) {
      text += "🥤 Gaseosa: ${(dinerCount * 1.0).toStringAsFixed(1)} L\n";
    }
    
    if (provider.showTomato || provider.showLettuce || provider.showOnion || provider.showRussianSalad) {
      text += "\n🥗 *Vegetales:*\n";
      if (provider.showTomato) text += "🍅 Tomates: ${(dinerCount * 0.6).ceil()} unidades\n";
      if (provider.showLettuce) {
        final plants = (dinerCount / 4).ceil();
        text += "🥬 Lechuga: $plants ${plants == 1 ? 'planta' : 'plantas'}\n";
      }
      if (provider.showOnion) text += "🧅 Cebollas: ${(dinerCount / 5).ceil()} unidades\n";
      if (provider.showRussianSalad) {
        final rawPotatoKilos = dinerCount * 0.15;
        final potatoKilos = ((rawPotatoKilos * 2).ceil() / 2).toStringAsFixed(1);
        final carrotCount = (dinerCount / 3).ceil();
        text += "🥔 Papa (Rusa): $potatoKilos kg\n";
        text += "🥕 Zanahoria (Rusa): $carrotCount unidades\n";
        if (provider.showMayonnaise) {
          final mayoSachets = (dinerCount * 0.025 / 0.25).ceil();
          text += "🧴 Mayonesa: $mayoSachets sachet(s)\n";
        }
      }
    }

    text += "\n¡Organizado con *Juntada*! 🚀";

    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cálculo copiado al portapapeles!'),
          backgroundColor: JuntadaTheme.secondary,
        ),
      );
    });
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: JuntadaTheme.surface,
        title: const Text('¿Limpiar comensales?'),
        content: const Text('Se borrarán todos los participantes de esta lista de compras.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: JuntadaTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              provider.clearShopping();
              Navigator.pop(context);
            },
            child: const Text('Limpiar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCard(BuildContext context) {
    final dinerCount = provider.shoppingUsers.length;
    final gramsPerPerson = provider.meatGramsPerPerson;
    final meatKilos = (dinerCount * (gramsPerPerson / 1000)).toStringAsFixed(1);
    final woodBags = _calculateWoodBags(dinerCount, double.parse(meatKilos));
    final morcillaCount = (dinerCount / 2).ceil();
    final breadsPerPerson = provider.breadsPerPerson;
    final rawBreadKilos = dinerCount * breadsPerPerson * 0.05;
    // Round UP to the nearest 0.5kg
    final breadKilos = ((rawBreadKilos * 2).ceil() / 2).toStringAsFixed(1);
    final tomatoCount = (dinerCount * 0.6).ceil();
    final lettucePlants = (dinerCount / 4).ceil();
    final onionCount = (dinerCount / 5).ceil();
    final rawPotatoKilos = dinerCount * 0.15;
    // Round UP to the nearest 0.5kg
    final potatoKilos = ((rawPotatoKilos * 2).ceil() / 2).toStringAsFixed(1);
    final carrotCount = (dinerCount / 3).ceil();
    final mayoSachets = (dinerCount * 0.025 / 0.25).ceil();
    final sodaLiters = (dinerCount * 1.0).toStringAsFixed(1);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                JuntadaTheme.accent.withValues(alpha: 0.2),
                const Color(0xFFF43F5E).withValues(alpha: 0.1),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cálculo de Asado', style: TextStyle(color: JuntadaTheme.textSecondary)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showAsadoConfig(context),
                        icon: const Icon(Icons.settings_outlined, color: JuntadaTheme.accent, size: 20),
                      ),
                      IconButton(
                        onPressed: () => _shareAsadoInfo(context),
                        icon: const Icon(Icons.share_outlined, color: JuntadaTheme.accent, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 0), // Adjust spacing
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    dinerCount == 0 ? '0' : meatKilos,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: JuntadaTheme.accent,
                      fontSize: 48,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'kg de carne',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: JuntadaTheme.textSecondary,
                    ),
                  ),
                ],
              ).animate(key: ValueKey(meatKilos)).fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 32,
                runSpacing: 16,
                children: [
                  _buildStatItem('Leña', dinerCount == 0 ? '0 bolsas' : '$woodBags ${woodBags == 1 ? 'bolsa' : 'bolsas'}'),
                  if (provider.showChorizos)
                    _buildStatItem('Chorizos', dinerCount == 0 ? '0' : '$dinerCount unidades'),
                  if (provider.showMorcillas)
                    _buildStatItem('Morcillas', dinerCount == 0 ? '0' : '$morcillaCount unidades'),
                  _buildStatItem('Pan', dinerCount == 0 ? '0' : '$breadKilos kg'),
                  if (provider.showTomato)
                    _buildStatItem('Tomates', dinerCount == 0 ? '0' : '$tomatoCount unidades'),
                  if (provider.showLettuce)
                    _buildStatItem('Lechuga', dinerCount == 0 ? '0' : '$lettucePlants ${lettucePlants == 1 ? 'planta' : 'plantas'}'),
                  if (provider.showOnion)
                    _buildStatItem('Cebollas', dinerCount == 0 ? '0' : '$onionCount unidades'),
                  if (provider.showSoda && dinerCount > 0)
                    _buildStatItem('Gaseosa', '$sodaLiters L'),
                  if (provider.showRussianSalad && dinerCount > 0) ...[
                    _buildStatItem('Papa (Rusa)', '$potatoKilos kg'),
                    _buildStatItem('Zanahoria (Rusa)', '$carrotCount ${carrotCount == 1 ? 'unidad' : 'unidades'}'),
                    if (provider.showMayonnaise)
                      _buildStatItem('Mayonesa', '$mayoSachets ${mayoSachets == 1 ? 'sachet' : 'sachets'}'),
                  ],
                ],
              ),
              if (dinerCount > 0) ...[
                const SizedBox(height: 24),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (provider.expenses.isNotEmpty) {
                        _showResetExpensesConfirmation(context);
                      } else {
                        provider.startExpensesFromShopping();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ExpensesPage(provider: provider)),
                        );
                      }
                    },
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Comenzar liquidación de gastos', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),
      ),
    );
  }

  void _showAsadoConfig(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AsadoConfigModal(provider: provider),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Container(
          decoration: BoxDecoration(
            color: JuntadaTheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar comensal...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.search_rounded, color: JuntadaTheme.accent.withValues(alpha: 0.5)),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    color: JuntadaTheme.textSecondary,
                  )
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
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
            Text('Comensales', style: Theme.of(context).textTheme.headlineMedium),
            Text(
              '${provider.shoppingUsers.length} personas',
              style: const TextStyle(color: JuntadaTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDinersList(BuildContext context) {
    final filteredUsers = provider.shoppingUsers.where((u) {
      return u.name.toLowerCase().contains(_searchQuery);
    }).toList();

    if (provider.shoppingUsers.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay comensales aún',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '¡Agrega a quienes participan!',
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

    if (filteredUsers.isEmpty && _searchQuery.isNotEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  'No se encontró a "$_searchQuery"',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final user = filteredUsers[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: DinerCard(
              user: user,
              onDelete: () => provider.removeShoppingUser(user.id),
            ),
          );
        },
        childCount: filteredUsers.length,
      ),
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
      child: SizedBox(
        width: double.infinity,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDiner(context),
          backgroundColor: JuntadaTheme.accent,
          label: const Text('Agregar comensal', style: TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.person_add_rounded),
        ),
      ),
    ).animate().slideY(begin: 1, duration: 600.ms, curve: Curves.easeOutQuart);
  }

  void _showAddDiner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MasterDinerSheet(
        provider: provider,
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    provider = widget.provider;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _searchController.dispose();
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

  Widget _buildSearchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Container(
          decoration: BoxDecoration(
            color: JuntadaTheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar gastos o personas...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.search_rounded, color: JuntadaTheme.primary.withValues(alpha: 0.5)),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    color: JuntadaTheme.textSecondary,
                  )
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
      ),
    );
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
                  _buildSearchBar(context),
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
    final expenses = provider.expenses.where((e) {
      return e.userName.toLowerCase().contains(_searchQuery) || 
             e.description.toLowerCase().contains(_searchQuery);
    }).toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Gastos', style: Theme.of(context).textTheme.headlineMedium),
            Text(
              '${expenses.length} entradas',
              style: const TextStyle(color: JuntadaTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context) {
    final expenses = provider.expenses.where((e) {
      return e.userName.toLowerCase().contains(_searchQuery) || 
             e.description.toLowerCase().contains(_searchQuery);
    }).toList();

    if (expenses.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: JuntadaTheme.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _searchQuery.isEmpty ? Icons.receipt_long_rounded : Icons.search_off_rounded,
                  size: 48, 
                  color: JuntadaTheme.primary.withValues(alpha: 0.3)
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty ? 'No hay gastos aún' : 'No se encontraron resultados',
                style: const TextStyle(color: JuntadaTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
              if (_searchQuery.isEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  '¡Toca el botón + para empezar!',
                  style: TextStyle(color: JuntadaTheme.textSecondary, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (itemContext, index) {
            final expense = expenses[index];
            return ExpenseCard(
              expense: expense,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddExpenseModal(
                    provider: provider,
                    initialExpense: expense,
                    onAdd: (name, amount, desc) {
                      provider.updateExpense(
                        id: expense.id,
                        name: name,
                        amount: amount,
                        description: desc,
                      );
                    },
                  ),
                );
              },
              onDelete: () {
                final user = provider.users.firstWhere((u) => u.id == expense.userId);
                provider.removeExpense(expense.id);
                _showNotification(expense, user);
              },
            );
          },
          childCount: expenses.length,
        ),
      ),
    );
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
        provider: provider,
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
