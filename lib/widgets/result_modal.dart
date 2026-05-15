import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../theme.dart';

class ResultModal extends StatelessWidget {
  final List<Transaction> transactions;
  final double totalSpent;
  final int userCount;

  const ResultModal({
    super.key,
    required this.transactions,
    required this.totalSpent,
    required this.userCount,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
    final rawFairShare = userCount == 0 ? 0.0 : totalSpent / userCount;
    final fairShare = (rawFairShare / 100).roundToDouble() * 100;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: JuntadaTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Resultados', style: Theme.of(context).textTheme.headlineMedium),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: JuntadaTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSummary(context, currencyFormat, fairShare),
          const SizedBox(height: 32),
          Text(
            'Transferencias',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: JuntadaTheme.primary.withValues(alpha: 0.8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  '¡Todos están a mano!',
                  style: TextStyle(color: JuntadaTheme.secondary, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: transactions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return _buildTransactionCard(tx, currencyFormat);
                },
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _copyToClipboard(context, currencyFormat, fairShare),
              icon: const Icon(Icons.content_copy_rounded, size: 20),
              label: const Text('Copiar resultados', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: JuntadaTheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, NumberFormat format, double fairShare) {
    String text = "📊 *Resumen Juntada*\n\n";
    text += "💰 Total: ${format.format(totalSpent)}\n";
    text += "👥 Participantes: $userCount\n";
    text += "👤 Por persona: ${format.format(fairShare)}\n\n";
    text += "*Transferencias:*\n";

    if (transactions.isEmpty) {
      text += "✅ ¡Todos están a mano!";
    } else {
      for (var tx in transactions) {
        text += "• ${tx.fromUser} debe pagar a ${tx.toUser} ${format.format(tx.amount)}\n";
      }
    }

    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Resultados copiados al portapapeles',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: JuntadaTheme.secondary,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  Widget _buildSummary(BuildContext context, NumberFormat format, double fairShare) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildSummaryItem('Total', format.format(totalSpent)),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
          _buildSummaryItem('Por persona', format.format(fairShare)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: JuntadaTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction tx, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JuntadaTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.fromUser,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text(
                  'le debe pagar a',
                  style: TextStyle(fontSize: 12, color: JuntadaTheme.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: JuntadaTheme.primary, size: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tx.toUser,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  format.format(tx.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: JuntadaTheme.secondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }
}
