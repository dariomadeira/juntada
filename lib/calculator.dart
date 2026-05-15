import 'models.dart';

class JuntadaCalculator {
  static List<Transaction> calculateSettlements(
    List<Expense> expenses,
    List<User> allUsers, {
    double roundTo = 10, // Default to rounding to the nearest $10
  }) {
    if (allUsers.isEmpty) return [];

    // 1. Calculate total paid by each user
    final Map<String, double> userPaidMap = {};
    for (var user in allUsers) {
      userPaidMap[user.id] = 0.0;
    }

    for (var expense in expenses) {
      userPaidMap[expense.userId] =
          (userPaidMap[expense.userId] ?? 0.0) + expense.amount;
    }

    // 2. Calculate total spent and fair share
    final double totalSpent = expenses.fold(
      0,
      (sum, item) => sum + item.amount,
    );
    
    double fairShare = totalSpent / allUsers.length;
    
    // Round fair share to simplify calculations
    if (roundTo > 0) {
      fairShare = (fairShare / roundTo).roundToDouble() * roundTo;
    }

    // 3. Calculate balances (Paid - FairShare)
    final List<_UserBalance> balances = allUsers.map((user) {
      return _UserBalance(
        userName: user.name,
        balance: userPaidMap[user.id]! - fairShare,
      );
    }).toList();

    final List<Transaction> transactions = [];
    
    // Filter debtors and creditors
    // We use a small epsilon for floating point comparison
    final List<_UserBalance> debtors = balances
        .where((b) => b.balance < -0.1)
        .toList();
    final List<_UserBalance> creditors = balances
        .where((b) => b.balance > 0.1)
        .toList();

    // Sort to minimize transactions
    debtors.sort((a, b) => a.balance.compareTo(b.balance));
    creditors.sort((a, b) => b.balance.compareTo(a.balance));

    int dIdx = 0;
    int cIdx = 0;

    while (dIdx < debtors.length && cIdx < creditors.length) {
      final debtor = debtors[dIdx];
      final creditor = creditors[cIdx];

      double amountToPay = _min(debtor.balance.abs(), creditor.balance.abs());

      // Round the transaction amount
      if (roundTo > 0) {
        amountToPay = (amountToPay / roundTo).roundToDouble() * roundTo;
      }

      if (amountToPay > 0.1) {
        transactions.add(
          Transaction(
            fromUser: debtor.userName,
            toUser: creditor.userName,
            amount: amountToPay,
          ),
        );
      }

      debtor.balance += amountToPay;
      creditor.balance -= amountToPay;

      // Move to next if balance is settled
      if (debtor.balance.abs() < 1.0) dIdx++;
      if (creditor.balance.abs() < 1.0) cIdx++;
    }

    return transactions;
  }

  static double _min(double a, double b) => a < b ? a : b;
}

class _UserBalance {
  final String userName;
  double balance;

  _UserBalance({required this.userName, required this.balance});
}
