import 'package:flutter/material.dart';
import 'package:mi_game_ui/mi_game_ui.dart';
import 'math_supermarket_session.dart';

/// Math Supermarket screen – shows shopping scenarios with item shelves,
/// a cart, budget display, and feedback. Child taps items to add/remove from
/// cart, then confirms purchase.
class MathSupermarketScreen extends StatefulWidget {
  const MathSupermarketScreen({
    super.key,
    required this.session,
    required this.locale,
    this.onComplete,
  });

  final MathSupermarketSession session;
  final String locale;
  final VoidCallback? onComplete;

  @override
  State<MathSupermarketScreen> createState() => _MathSupermarketScreenState();
}

class _MathSupermarketScreenState extends State<MathSupermarketScreen> {
  MathSupermarketSession get _session => widget.session;

  @override
  Widget build(BuildContext context) {
    if (_session.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete?.call();
      });
    }

    final scenario = _session.currentScenario;

    return GameScaffold(
      title: 'Math Supermarket',
      score: _session.score,
      onHint: _handleHint,
      child: scenario == null
          ? const Center(child: Text('No more scenarios!'))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildBudgetBar(),
                  const SizedBox(height: 8),
                  _buildInstruction(),
                  const SizedBox(height: 12),
                  _buildItemShelf(scenario),
                  const Spacer(),
                  _buildCartSummary(scenario),
                  const SizedBox(height: 8),
                  _buildFeedback(),
                  const SizedBox(height: 8),
                  _buildCheckButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildBudgetBar() {
    final remaining = _session.remainingBudget;
    final total = _session.budget;
    final unit = _session.currencyUnit;
    final pct = total > 0 ? remaining / total : 0.0;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.account_balance_wallet, size: 20),
                Text(
                  'Budget: $remaining$unit / $total$unit',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade300,
              color: pct > 0.3 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction() {
    final text = _session.scenarioInstruction(widget.locale);
    final scenarioNum = _session.scenarioIndex + 1;
    final totalScenarios = _session.scenarios.length;

    return QuestionCard(
      text: text ?? '...',
      questionNumber: scenarioNum,
      totalQuestions: totalScenarios,
    );
  }

  Widget _buildItemShelf(dynamic scenario) {
    // Use the scenario's items list (accessed through the session).
    final items = _session.currentScenario?.items ?? [];
    final cart = _session.cart;

    return Expanded(
      child: GridView.builder(
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final inCart = cart.contains(index);
          final canAfford = item.price <= _session.remainingBudget;

          return GestureDetector(
            onTap: canAfford
                ? (inCart
                    ? () => _handleRemoveFromCart(index)
                    : () => _handleAddToCart(index))
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: inCart
                    ? Colors.green.shade100
                    : canAfford
                        ? Colors.white
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: inCart ? Colors.green : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.price}${_session.currencyUnit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: canAfford ? Colors.blue : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (inCart)
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartSummary(dynamic scenario) {
    final cart = _session.cart;
    final items = _session.currentScenario?.items ?? [];
    if (cart.isEmpty) {
      return const Text('Cart is empty – tap items to add!',
          style: TextStyle(fontSize: 13, color: Colors.grey));
    }

    final cartItems =
        cart.map((idx) => items[idx]).toList();
    final totalSpent =
        cartItems.fold<int>(0, (sum, item) => sum + item.price);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🛒 Cart (${cart.length} items) – Spent: $totalSpent${_session.currencyUnit}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: cartItems
                .map((item) => Chip(
                      label: Text('${item.emoji} ${item.name}',
                          style: const TextStyle(fontSize: 11)),
                      onDeleted: () {
                        final idx = items.indexOf(item);
                        if (idx >= 0) _handleRemoveFromCart(idx);
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _session.cart.isNotEmpty ? _handleCheck : null,
        icon: const Icon(Icons.shopping_bag_checkout),
        label: const Text('Check My Cart'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final fb = _session.feedback;
    if (fb == null) return const SizedBox.shrink();

    IconData icon;
    Color color;
    String message;

    switch (fb) {
      case 'correct':
        icon = Icons.check_circle;
        color = Colors.green;
        message = 'Correct purchase!';
      case 'missing_items':
        icon = Icons.error_outline;
        color = Colors.orange;
        message = 'You are missing required items. Try again!';
      case 'over_budget':
        icon = Icons.money_off;
        color = Colors.red;
        message = 'Over budget! Remove some items.';
      case 'not_enough_budget':
        icon = Icons.block;
        color = Colors.red;
        message = 'Not enough budget for this item.';
      case 'added_to_cart':
        return const SizedBox.shrink();
      case 'removed_from_cart':
        return const SizedBox.shrink();
      case 'hint':
        icon = Icons.lightbulb;
        color = Colors.blue;
        message = 'Look at what you still need to buy!';
      default:
        return const SizedBox.shrink();
    }

    return AnimatedFeedback(
      icon: icon,
      color: color,
      message: message,
    );
  }

  void _handleAddToCart(int index) {
    setState(() => _session.addToCart(index));
  }

  void _handleRemoveFromCart(int index) {
    setState(() => _session.removeFromCart(index));
  }

  void _handleCheck() {
    setState(() => _session.checkAnswer());
  }

  void _handleHint() {
    setState(() => _session.showHint());
  }
}
