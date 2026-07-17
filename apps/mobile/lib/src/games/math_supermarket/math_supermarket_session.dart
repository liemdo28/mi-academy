import 'package:mi_game_core/mi_game_core.dart';

/// Session logic for Math Supermarket – a shopping simulation where the child
/// picks items to buy within a budget. Each level is JSON-driven with
/// vi/en localization, a budget amount, and currency unit.
class MathSupermarketSession {
  MathSupermarketSession({
    required MiLevel level,
    this.childProfileId = 'offline-child',
  }) : _level = level {
    _resetForLevel(level);
  }

  final MiLevel _level;
  final String childProfileId;

  // ---- state ----
  int _score = 0;
  int _attemptsUsed = 0;
  int _hintsUsed = 0;
  bool _completed = false;
  String? _feedback;
  int _remainingBudget = 0;

  // Cart: list of item indices the child has selected.
  final List<int> _cart = [];

  // Current scenario index (some levels have multiple scenarios).
  int _scenarioIndex = 0;

  // ---- parsed data ----
  late final List<_ShoppingScenario> _scenarios;
  late final int _budget;
  late final String _currencyUnit;

  int get score => _score;
  int get attemptsUsed => _attemptsUsed;
  int get hintsUsed => _hintsUsed;
  bool get completed => _completed;
  String? get feedback => _feedback;
  int get remainingBudget => _remainingBudget;
  int get budget => _budget;
  String get currencyUnit => _currencyUnit;
  List<int> get cart => List.unmodifiable(_cart);
  int get scenarioIndex => _scenarioIndex;
  String get levelId => _level.id;

  _ShoppingScenario? get currentScenario =>
      _scenarioIndex < _scenarios.length ? _scenarios[_scenarioIndex] : null;

  List<_ShoppingScenario> get scenarios => List.unmodifiable(_scenarios);

  void _resetForLevel(MiLevel level) {
    final meta = level.metadata;
    _budget = (meta['budget'] as num?)?.toInt() ?? 10000;
    _currencyUnit = (meta['currencyUnit'] as String?) ?? 'đ';

    final content = level.contentForLocale('vi');
    final dynamic raw = content['scenarios'];
    if (raw is List) {
      _scenarios = raw
          .map((e) =>
              _ShoppingScenario.fromJson(Map<dynamic, dynamic>.from(e as Map)))
          .toList();
    } else {
      _scenarios = [];
    }

    _scenarioIndex = 0;
    _remainingBudget = _budget;
    _score = 0;
    _attemptsUsed = 0;
    _hintsUsed = 0;
    _completed = false;
    _feedback = null;
    _cart.clear();
  }

  /// Returns the scenario instruction text for the current locale.
  String? scenarioInstruction(String locale) {
    final s = currentScenario;
    if (s == null) return null;
    final content = _level.contentForLocale(locale);
    final scenarios = content['scenarios'] as List?;
    if (scenarios == null || _scenarioIndex >= scenarios.length) return null;
    final sMap = scenarios[_scenarioIndex] as Map;
    return sMap['instruction'] as String?;
  }

  /// Add an item to cart by index within current scenario.
  void addToCart(int itemIndex) {
    final s = currentScenario;
    if (s == null || _completed) return;

    if (itemIndex < 0 || itemIndex >= s.items.length) return;
    if (_cart.contains(itemIndex)) return; // already in cart

    final item = s.items[itemIndex];
    if (item.price > _remainingBudget) {
      _feedback = 'not_enough_budget';
      return;
    }

    _cart.add(itemIndex);
    _remainingBudget -= item.price;
    _feedback = 'added_to_cart';
  }

  /// Remove an item from cart by index.
  void removeFromCart(int itemIndex) {
    if (!_cart.contains(itemIndex)) return;
    _cart.remove(itemIndex);

    final s = currentScenario;
    if (s != null && itemIndex < s.items.length) {
      _remainingBudget += s.items[itemIndex].price;
    }
    _feedback = 'removed_from_cart';
  }

  /// Check if the cart satisfies the current scenario's goal.
  /// Returns true if correct, false otherwise.
  bool checkAnswer() {
    final s = currentScenario;
    if (s == null) return false;

    _attemptsUsed++;
    final totalSpent = _budget - _remainingBudget;

    // Check: did the child buy the required items?
    bool hasAllRequired = true;
    for (final req in s.requiredItems) {
      if (!_cart.any((idx) => s.items[idx].id == req.id)) {
        hasAllRequired = false;
        break;
      }
    }

    // Check: is total within acceptable range?
    final isWithinBudget = totalSpent <= _budget && totalSpent > 0;

    if (hasAllRequired && isWithinBudget) {
      _score += 10;
      _feedback = 'correct';
      _advance();
      return true;
    } else if (!hasAllRequired) {
      _feedback = 'missing_items';
    } else {
      _feedback = 'over_budget';
    }
    return false;
  }

  void showHint() {
    _hintsUsed++;
    final s = currentScenario;
    if (s == null) return;
    _feedback = 'hint';
    // In the UI, this would highlight which required item is missing.
  }

  void _advance() {
    _cart.clear();
    _scenarioIndex++;
    if (_scenarioIndex >= _scenarios.length) {
      _completed = true;
    } else {
      // Reset budget for next scenario.
      _remainingBudget = _budget;
    }
  }

  /// Snapshot for save/restore.
  MiGameSnapshot saveSnapshot() {
    return MiGameSnapshot(
      gameId: 'math_supermarket',
      levelId: _level.id,
      state: {
        'score': _score,
        'attemptsUsed': _attemptsUsed,
        'hintsUsed': _hintsUsed,
        'remainingBudget': _remainingBudget,
        'scenarioIndex': _scenarioIndex,
        'cart': List<int>.from(_cart),
        'completed': _completed,
      },
      score: _score,
      attemptsUsed: _attemptsUsed,
      hintsUsed: _hintsUsed,
    );
  }

  void restoreSnapshot(MiGameSnapshot snapshot) {
    final s = snapshot.state;
    _score = s['score'] as int? ?? 0;
    _attemptsUsed = s['attemptsUsed'] as int? ?? 0;
    _hintsUsed = s['hintsUsed'] as int? ?? 0;
    _remainingBudget = s['remainingBudget'] as int? ?? _budget;
    _scenarioIndex = s['scenarioIndex'] as int? ?? 0;
    _completed = s['completed'] as bool? ?? false;
    _cart
      ..clear()
      ..addAll((s['cart'] as List?)?.cast<int>() ?? []);
  }
}

class _ShoppingScenario {
  _ShoppingScenario({
    required this.instruction,
    required this.items,
    required this.requiredItems,
  });

  final String instruction;
  final List<_ShopItem> items;
  final List<_RequiredItem> requiredItems;

  factory _ShoppingScenario.fromJson(Map<dynamic, dynamic> json) {
    return _ShoppingScenario(
      instruction: json['instruction'] as String? ?? '',
      items: (json['items'] as List?)
              ?.map((e) =>
                  _ShopItem.fromJson(Map<dynamic, dynamic>.from(e as Map)))
              .toList() ??
          [],
      requiredItems: (json['requiredItems'] as List?)
              ?.map((e) =>
                  _RequiredItem.fromJson(Map<dynamic, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }
}

class _ShopItem {
  _ShopItem({
    required this.id,
    required this.name,
    required this.price,
    this.emoji = '🛒',
  });

  final String id;
  final String name;
  final int price;
  final String emoji;

  factory _ShopItem.fromJson(Map<dynamic, dynamic> json) {
    return _ShopItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      emoji: json['emoji'] as String? ?? '🛒',
    );
  }
}

class _RequiredItem {
  _RequiredItem({
    required this.id,
    this.quantity = 1,
  });

  final String id;
  final int quantity;

  factory _RequiredItem.fromJson(Map<dynamic, dynamic> json) {
    return _RequiredItem(
      id: json['id'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
