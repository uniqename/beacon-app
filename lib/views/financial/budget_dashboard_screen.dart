import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/evidence_log.dart';
import '../../services/budget_service.dart';
import 'add_transaction_screen.dart';

// ─── Data models stored in SharedPreferences ──────────────────────────────────

class DebtEntry {
  final String id;
  String name;
  double totalAmount;
  double remaining;
  double interestRate;
  double minimumPayment;

  DebtEntry({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.remaining,
    required this.interestRate,
    required this.minimumPayment,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalAmount': totalAmount,
        'remaining': remaining,
        'interestRate': interestRate,
        'minimumPayment': minimumPayment,
      };

  factory DebtEntry.fromJson(Map<String, dynamic> j) => DebtEntry(
        id: j['id'] as String,
        name: j['name'] as String,
        totalAmount: (j['totalAmount'] as num).toDouble(),
        remaining: (j['remaining'] as num).toDouble(),
        interestRate: (j['interestRate'] as num).toDouble(),
        minimumPayment: (j['minimumPayment'] as num).toDouble(),
      );
}

class AssetEntry {
  final String id;
  String name;
  double amount;
  String type; // savings, property, investment, vehicle, other

  AssetEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'type': type,
      };

  factory AssetEntry.fromJson(Map<String, dynamic> j) => AssetEntry(
        id: j['id'] as String,
        name: j['name'] as String,
        amount: (j['amount'] as num).toDouble(),
        type: j['type'] as String? ?? 'savings',
      );
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class BudgetDashboardScreen extends StatefulWidget {
  final String userId;
  const BudgetDashboardScreen({super.key, required this.userId});

  @override
  State<BudgetDashboardScreen> createState() => _BudgetDashboardScreenState();
}

class _BudgetDashboardScreenState extends State<BudgetDashboardScreen>
    with TickerProviderStateMixin {
  final BudgetService _service = BudgetService();

  // ─ Transaction data ─
  List<BudgetTransaction> _transactions = [];
  double _totalIncome = 0;
  double _totalExpenses = 0;

  // ─ Goals/settings ─
  double _monthlyBudgetGoal = 0;
  double _savingsGoal = 0;
  double _monthlyExpensesTarget = 0; // for emergency fund calc
  double _freedomNumber = 0; // FIRE target

  // ─ Freedom data ─
  List<DebtEntry> _debts = [];
  List<AssetEntry> _assets = [];

  bool _showHidden = false;
  bool _isLoading = true;
  int _selectedTab = 0; // 0=overview 1=transactions 2=freedom 3=debts 4=goals

  late AnimationController _animController;
  late Animation<double> _barAnim;

  static const _darkBg = Color(0xFF0A0E1A);
  static const _cardBg = Color(0xFF141929);
  static const _accent = Color(0xFF00D4AA);
  static const _accentGold = Color(0xFFFFB347);
  static const _accentRed = Color(0xFFFF5C7A);
  static const _accentPurple = Color(0xFF9B59B6);
  static const _accentBlue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _barAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _monthlyBudgetGoal =
          prefs.getDouble('budget_goal_${widget.userId}') ?? 0;
      _savingsGoal = prefs.getDouble('savings_goal_${widget.userId}') ?? 0;
      _monthlyExpensesTarget =
          prefs.getDouble('monthly_exp_${widget.userId}') ?? 0;
      _freedomNumber =
          prefs.getDouble('freedom_number_${widget.userId}') ?? 0;

      // Load debts
      final debtsJson = prefs.getString('debts_${widget.userId}') ?? '[]';
      final debtsList = jsonDecode(debtsJson) as List;
      _debts = debtsList
          .map((e) => DebtEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      // Load assets
      final assetsJson = prefs.getString('assets_${widget.userId}') ?? '[]';
      final assetsList = jsonDecode(assetsJson) as List;
      _assets = assetsList
          .map((e) => AssetEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      final transactions = await _service.getAllTransactions(widget.userId);
      final income = await _service.getTotalIncome(widget.userId);
      final expenses = await _service.getTotalExpenses(widget.userId);

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _totalIncome = income;
          _totalExpenses = expenses;
          _isLoading = false;
        });
        _animController.forward(from: 0);
      }
    } catch (e) {
      developer.log('Budget error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_goal_${widget.userId}', _monthlyBudgetGoal);
    await prefs.setDouble('savings_goal_${widget.userId}', _savingsGoal);
    await prefs.setDouble(
        'monthly_exp_${widget.userId}', _monthlyExpensesTarget);
    await prefs.setDouble('freedom_number_${widget.userId}', _freedomNumber);
    await prefs.setString(
        'debts_${widget.userId}', jsonEncode(_debts.map((d) => d.toJson()).toList()));
    await prefs.setString(
        'assets_${widget.userId}', jsonEncode(_assets.map((a) => a.toJson()).toList()));
  }

  // ─── Computed properties ───────────────────────────────────────────────────

  double get _balance => _totalIncome - _totalExpenses;

  double get _totalDebt =>
      _debts.fold(0.0, (s, d) => s + d.remaining);

  double get _totalAssets =>
      _assets.fold(0.0, (s, a) => s + a.amount) + (_balance > 0 ? _balance : 0);

  double get _netWorth => _totalAssets - _totalDebt;

  double get _savingsRate =>
      _totalIncome > 0 ? (_balance / _totalIncome * 100).clamp(0, 100) : 0;

  double get _monthlyExpenses {
    if (_monthlyExpensesTarget > 0) return _monthlyExpensesTarget;
    return _totalExpenses;
  }

  double get _emergencyFundMonths {
    if (_monthlyExpenses == 0) return 0;
    final savings = _totalAssets;
    return (savings / _monthlyExpenses).clamp(0, 24);
  }

  // Financial Health Score 0-100
  int get _healthScore {
    int score = 0;
    // Savings rate (max 25 pts)
    if (_savingsRate >= 20) score += 25;
    else if (_savingsRate >= 10) score += 15;
    else if (_savingsRate > 0) score += 8;

    // Emergency fund (max 25 pts)
    if (_emergencyFundMonths >= 6) score += 25;
    else if (_emergencyFundMonths >= 3) score += 15;
    else if (_emergencyFundMonths >= 1) score += 8;

    // Debt-to-income ratio (max 25 pts)
    if (_totalDebt == 0) {
      score += 25;
    } else {
      final dti = _totalIncome > 0 ? _totalDebt / _totalIncome : 1.0;
      if (dti < 0.2) score += 20;
      else if (dti < 0.5) score += 12;
      else if (dti < 1.0) score += 6;
    }

    // Positive net worth (max 25 pts)
    if (_netWorth > 0) {
      final ratio = _freedomNumber > 0
          ? (_netWorth / _freedomNumber * 25).clamp(0, 25).toInt()
          : 20;
      score += ratio;
    }

    return score.clamp(0, 100);
  }

  String get _scoreLabel {
    final s = _healthScore;
    if (s >= 80) return 'Excellent';
    if (s >= 60) return 'Good';
    if (s >= 40) return 'Fair';
    if (s >= 20) return 'Needs Work';
    return 'Getting Started';
  }

  Color get _scoreColor {
    final s = _healthScore;
    if (s >= 80) return _accent;
    if (s >= 60) return _accentGold;
    if (s >= 40) return _accentBlue;
    return _accentRed;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final visibleTransactions = _showHidden
        ? _transactions
        : _transactions.where((t) => !t.isHidden).toList();

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: _accent,
                    backgroundColor: _cardBg,
                    child: IndexedStack(
                      index: _selectedTab,
                      children: [
                        _buildOverview(),
                        _buildTransactionsList(visibleTransactions),
                        _buildFreedomTab(),
                        _buildDebtsTab(),
                        _buildGoalsTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildFab(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _cardBg,
      elevation: 0,
      title: const Text(
        'Financial Freedom Planner',
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: Icon(
              _showHidden ? Icons.visibility_off : Icons.visibility,
              color: Colors.white60),
          tooltip: 'Toggle hidden savings',
          onPressed: () => setState(() => _showHidden = !_showHidden),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart, color: Colors.white60),
          onPressed: () => Navigator.pushNamed(context, '/budget_reports'),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      (Icons.dashboard_rounded, 'Overview'),
      (Icons.receipt_long, 'History'),
      (Icons.auto_graph, 'Freedom'),
      (Icons.credit_card_off, 'Debts'),
      (Icons.flag_rounded, 'Goals'),
    ];
    return Container(
      color: _cardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((e) {
            final selected = _selectedTab == e.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = e.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: selected ? _accent : Colors.transparent,
                        width: 2.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.value.$1,
                        size: 14,
                        color: selected ? _accent : Colors.white38),
                    const SizedBox(width: 5),
                    Text(
                      e.value.$2,
                      style: TextStyle(
                        color: selected ? _accent : Colors.white38,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFab() {
    if (_selectedTab == 3) {
      // Debts tab — add debt
      return FloatingActionButton.extended(
        onPressed: _showAddDebtDialog,
        backgroundColor: _accentRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label:
            const Text('Add Debt', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    if (_selectedTab == 2) {
      // Freedom tab — add asset
      return FloatingActionButton.extended(
        onPressed: _showAddAssetDialog,
        backgroundColor: _accentPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Asset',
            style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return FloatingActionButton.extended(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddTransactionScreen(userId: widget.userId)),
        );
        _loadData();
      },
      backgroundColor: _accent,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add),
      label:
          const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // ─── Overview Tab ──────────────────────────────────────────────────────────

  Widget _buildOverview() {
    final budgetUsed = _monthlyBudgetGoal > 0
        ? (_totalExpenses / _monthlyBudgetGoal).clamp(0.0, 1.0)
        : 0.0;
    final savingsProgress = _savingsGoal > 0
        ? (_balance / _savingsGoal).clamp(0.0, 1.0)
        : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBalanceHero(),
        const SizedBox(height: 16),
        _buildIncomeExpenseCards(),
        const SizedBox(height: 16),
        // Quick freedom snapshot
        _buildQuickFreedomSnapshot(),
        const SizedBox(height: 16),
        if (_monthlyBudgetGoal > 0) ...[
          _buildProgressCard(
            label: 'Monthly Budget Used',
            current: _totalExpenses,
            goal: _monthlyBudgetGoal,
            progress: budgetUsed,
            color: budgetUsed > 0.85 ? _accentRed : _accent,
            icon: Icons.account_balance_wallet,
            suffix: budgetUsed > 0.85
                ? 'You\'re near your limit!'
                : 'You\'re on track',
          ),
          const SizedBox(height: 12),
        ],
        if (_savingsGoal > 0) ...[
          _buildProgressCard(
            label: 'Savings Goal Progress',
            current: _balance > 0 ? _balance : 0,
            goal: _savingsGoal,
            progress: savingsProgress,
            color: _accentGold,
            icon: Icons.star,
            suffix: savingsProgress >= 1.0
                ? 'Goal reached! Well done!'
                : '${(savingsProgress * 100).toInt()}% of your goal',
          ),
          const SizedBox(height: 12),
        ],
        _buildCategoryBreakdown(),
        const SizedBox(height: 12),
        _build5030Rule(),
        const SizedBox(height: 12),
        _buildEmpowermentTip(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBalanceHero() {
    final isPositive = _balance >= 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF00897B), const Color(0xFF00695C)]
              : [const Color(0xFFC62828), const Color(0xFF8B0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (isPositive ? _accent : _accentRed).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            'Current Balance',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'GH₵ ${_balance.abs().toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: -1),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _heroStat('Net Worth', 'GH₵ ${_netWorth.toStringAsFixed(0)}',
                  _netWorth >= 0 ? Colors.white : _accentRed),
              Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.3)),
              _heroStat('Health Score', '$_healthScore/100', _scoreColor),
              Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.3)),
              _heroStat('Savings Rate', '${_savingsRate.toInt()}%',
                  _savingsRate >= 20 ? Colors.white : Colors.white70),
            ],
          ),
          if (!isPositive) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Deficit — review your expenses',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
      ],
    );
  }

  Widget _buildQuickFreedomSnapshot() {
    final emergencyMonths = _emergencyFundMonths;
    final fireProgress = _freedomNumber > 0
        ? (_netWorth / _freedomNumber).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: _accentPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph, color: _accentPurple, size: 18),
              const SizedBox(width: 8),
              const Text('Freedom Snapshot',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 2),
                child: const Text('Full View →',
                    style:
                        TextStyle(color: _accentPurple, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _snapStat(
                      'Emergency Fund',
                      '${emergencyMonths.toStringAsFixed(1)} mo',
                      emergencyMonths >= 6
                          ? _accent
                          : emergencyMonths >= 3
                              ? _accentGold
                              : _accentRed,
                      Icons.shield)),
              const SizedBox(width: 10),
              Expanded(
                  child: _snapStat(
                      'Total Debt',
                      'GH₵ ${_totalDebt.toStringAsFixed(0)}',
                      _totalDebt == 0 ? _accent : _accentRed,
                      Icons.credit_card_off)),
              const SizedBox(width: 10),
              Expanded(
                  child: _snapStat(
                      'FIRE Progress',
                      _freedomNumber > 0
                          ? '${(fireProgress * 100).toInt()}%'
                          : 'Set target',
                      _accentGold,
                      Icons.bolt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _snapStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _build5030Rule() {
    if (_totalIncome == 0) return const SizedBox.shrink();
    final needsPct = _totalExpenses / _totalIncome * 100;
    // We approximate: needs=expenses, wants=unknown, savings=balance
    final savingsPct = _savingsRate;
    final wantsPct = (100 - needsPct - savingsPct).clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: _accentGold, size: 16),
              SizedBox(width: 8),
              Text('50/30/20 Budget Rule',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
              '50% needs · 30% wants · 20% savings — the road to financial freedom',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 14),
          _buildRuleBar(
              'Needs / Expenses', needsPct, 50, _accentRed),
          const SizedBox(height: 8),
          _buildRuleBar(
              'Wants / Discretionary', wantsPct, 30, _accentBlue),
          const SizedBox(height: 8),
          _buildRuleBar('Savings / Investment', savingsPct, 20, _accent),
        ],
      ),
    );
  }

  Widget _buildRuleBar(
      String label, double actual, double target, Color color) {
    final pct = (actual / 100).clamp(0.0, 1.0);
    final over = actual > target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11))),
            Text('${actual.toInt()}% ',
                style: TextStyle(
                    color: over ? _accentRed : color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            Text('(target ${target.toInt()}%)',
                style: const TextStyle(
                    color: Colors.white30, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _barAnim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct * _barAnim.value,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor:
                  AlwaysStoppedAnimation<Color>(over ? _accentRed : color),
              minHeight: 7,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Financial Freedom Tab ─────────────────────────────────────────────────

  Widget _buildFreedomTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHealthScoreCard(),
        const SizedBox(height: 16),
        _buildNetWorthCard(),
        const SizedBox(height: 16),
        _buildFireCard(),
        const SizedBox(height: 16),
        _buildEmergencyFundCard(),
        const SizedBox(height: 16),
        _buildAssetsSection(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildHealthScoreCard() {
    final score = _healthScore;
    final color = _scoreColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart, size: 18, color: Colors.white60),
              const SizedBox(width: 8),
              const Text('Financial Health Score',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(_scoreLabel,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _barAnim,
                      builder: (_, __) => CircularProgressIndicator(
                        value: score / 100 * _barAnim.value,
                        strokeWidth: 10,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.08),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$score',
                            style: TextStyle(
                                color: color,
                                fontSize: 28,
                                fontWeight: FontWeight.bold)),
                        Text('/100',
                            style: TextStyle(
                                color: color.withValues(alpha: 0.6),
                                fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _scoreFactorRow(
                        'Savings Rate (${_savingsRate.toInt()}%)',
                        _savingsRate >= 20
                            ? 25
                            : _savingsRate >= 10
                                ? 15
                                : 8,
                        25,
                        _accent),
                    _scoreFactorRow(
                        'Emergency Fund (${_emergencyFundMonths.toStringAsFixed(1)} mo)',
                        _emergencyFundMonths >= 6
                            ? 25
                            : _emergencyFundMonths >= 3
                                ? 15
                                : 8,
                        25,
                        _accentBlue),
                    _scoreFactorRow(
                        'Debt Load',
                        _totalDebt == 0
                            ? 25
                            : _totalIncome > 0 &&
                                    _totalDebt / _totalIncome < 0.2
                                ? 20
                                : _totalIncome > 0 &&
                                        _totalDebt / _totalIncome < 0.5
                                    ? 12
                                    : 6,
                        25,
                        _accentRed),
                    _scoreFactorRow(
                        'Net Worth',
                        _netWorth > 0
                            ? (_freedomNumber > 0
                                    ? (_netWorth / _freedomNumber * 25)
                                        .clamp(0, 25)
                                        .toInt()
                                    : 15)
                            : 0,
                        25,
                        _accentGold),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _healthAdvice(),
            style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 12,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _scoreFactorRow(
      String label, int earned, int max, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 10))),
          Text('$earned/$max',
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _healthAdvice() {
    final s = _healthScore;
    if (s >= 80) {
      return 'Outstanding financial health! Keep compounding your investments and you\'ll reach full financial freedom faster than you think.';
    } else if (s >= 60) {
      return 'You\'re on the right path. Focus on boosting your savings rate above 20% and clearing remaining debts to level up.';
    } else if (s >= 40) {
      return 'Good start! Build a 3-month emergency fund next — it\'s the foundation of financial freedom. Then tackle your highest-interest debts.';
    } else if (_totalIncome == 0) {
      return 'Start by logging your income and expenses. You can\'t manage what you don\'t measure. Even small amounts matter.';
    } else {
      return 'Every journey begins with one step. Log daily transactions, set a savings goal — even GH₵ 50/month builds the habit of financial freedom.';
    }
  }

  Widget _buildNetWorthCard() {
    final isPositive = _netWorth >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (isPositive ? _accent : _accentRed)
                .withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance,
                  color: isPositive ? _accent : _accentRed, size: 18),
              const SizedBox(width: 8),
              const Text('Net Worth Statement',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _netWorthSide(
                    'Assets', _totalAssets, _accent, Icons.arrow_upward),
              ),
              Container(width: 1, height: 60, color: Colors.white12),
              const SizedBox(width: 16),
              Expanded(
                child: _netWorthSide(
                    'Liabilities', _totalDebt, _accentRed, Icons.arrow_downward),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('NET WORTH',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              Text(
                '${isPositive ? '+' : '-'}GH₵ ${_netWorth.abs().toStringAsFixed(2)}',
                style: TextStyle(
                    color: isPositive ? _accent : _accentRed,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _netWorthSide(
      String label, double amount, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Text('GH₵ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFireCard() {
    final fireProgress = _freedomNumber > 0
        ? (_netWorth / _freedomNumber).clamp(0.0, 1.0)
        : 0.0;
    // Monthly income needed to be invested: 25x annual expenses (4% rule)
    final suggestedFire = _monthlyExpenses * 12 * 25;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: _accentGold, size: 20),
              const SizedBox(width: 8),
              const Text('Financial Independence (FIRE)',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
              'The 4% rule: your freedom number = 25× annual expenses',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 14),
          if (suggestedFire > 0)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _accentGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: _accentGold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Based on your expenses: suggested FIRE number is GH₵ ${suggestedFire.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: _accentGold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          // Set freedom number
          Row(
            children: [
              const Text('My FIRE Target:  GH₵ ',
                  style: TextStyle(color: Colors.white60, fontSize: 14)),
              Expanded(
                child: _inlineNumberField(
                  value: _freedomNumber,
                  hint: suggestedFire > 0
                      ? suggestedFire.toStringAsFixed(0)
                      : '500000',
                  color: _accentGold,
                  onSave: (v) async {
                    setState(() => _freedomNumber = v);
                    await _savePrefs();
                  },
                ),
              ),
            ],
          ),
          if (_freedomNumber > 0) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _barAnim,
              builder: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${(fireProgress * 100).toInt()}% towards financial freedom',
                          style: const TextStyle(
                              color: _accentGold, fontSize: 12)),
                      Text(
                          'GH₵ ${(_freedomNumber - _netWorth).clamp(0, double.infinity).toStringAsFixed(0)} to go',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fireProgress * _barAnim.value,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.08),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_accentGold),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmergencyFundCard() {
    final months = _emergencyFundMonths;
    final target = 6.0;
    final progress = (months / target).clamp(0.0, 1.0);
    final statusColor = months >= 6
        ? _accent
        : months >= 3
            ? _accentGold
            : _accentRed;
    final statusText = months >= 6
        ? 'Fully funded! Keep maintaining it.'
        : months >= 3
            ? 'Halfway there — aim for 6 months.'
            : months >= 1
                ? 'Build it up — you need more cushion.'
                : 'Priority #1: build your emergency fund.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: statusColor, size: 18),
              const SizedBox(width: 8),
              const Text('Emergency Fund',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const Spacer(),
              Text('${months.toStringAsFixed(1)} / 6 months',
                  style:
                      TextStyle(color: statusColor, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Target: 6 months of living expenses',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 14),
          // Monthly expenses input
          Row(
            children: [
              const Text('Monthly expenses:  GH₵ ',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
              Expanded(
                child: _inlineNumberField(
                  value: _monthlyExpensesTarget,
                  hint: _totalExpenses > 0
                      ? _totalExpenses.toStringAsFixed(0)
                      : '0',
                  color: statusColor,
                  onSave: (v) async {
                    setState(() => _monthlyExpensesTarget = v);
                    await _savePrefs();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _barAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress * _barAnim.value,
                backgroundColor:
                    Colors.white.withValues(alpha: 0.08),
                valueColor:
                    AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(statusText,
              style: TextStyle(
                  color: statusColor, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildAssetsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: _accentPurple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, color: _accentPurple, size: 18),
              const SizedBox(width: 8),
              const Text('Assets',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const Spacer(),
              GestureDetector(
                onTap: _showAddAssetDialog,
                child: const Icon(Icons.add_circle,
                    color: _accentPurple, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_assets.isEmpty)
            const Text(
                'No assets added yet. Tap + to add savings accounts, property, investments etc.',
                style: TextStyle(color: Colors.white38, fontSize: 12))
          else
            ..._assets.map((a) => _buildAssetTile(a)),
          const Divider(color: Colors.white12, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cash Balance',
                  style:
                      TextStyle(color: Colors.white60, fontSize: 13)),
              Text('GH₵ ${(_balance > 0 ? _balance : 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL ASSETS',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5)),
              Text('GH₵ ${_totalAssets.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: _accentPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetTile(AssetEntry a) {
    final icon = _assetIcon(a.type);
    final color = _assetColor(a.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(a.type.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Text('GH₵ ${a.amount.toStringAsFixed(2)}',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () async {
              setState(() => _assets.removeWhere((x) => x.id == a.id));
              await _savePrefs();
            },
            child: const Icon(Icons.close,
                color: Colors.white24, size: 16),
          ),
        ],
      ),
    );
  }

  IconData _assetIcon(String type) {
    switch (type) {
      case 'property': return Icons.home;
      case 'investment': return Icons.trending_up;
      case 'vehicle': return Icons.directions_car;
      case 'business': return Icons.store;
      default: return Icons.account_balance;
    }
  }

  Color _assetColor(String type) {
    switch (type) {
      case 'property': return _accentBlue;
      case 'investment': return _accentGold;
      case 'vehicle': return _accentPurple;
      case 'business': return _accent;
      default: return const Color(0xFF64B5F6);
    }
  }

  // ─── Debt Tracker Tab ──────────────────────────────────────────────────────

  Widget _buildDebtsTab() {
    final totalRemaining =
        _debts.fold(0.0, (s, d) => s + d.remaining);
    final totalOriginal =
        _debts.fold(0.0, (s, d) => s + d.totalAmount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_debts.isNotEmpty) _buildDebtSummaryCard(totalRemaining, totalOriginal),
        if (_debts.isNotEmpty) const SizedBox(height: 16),
        _buildDebtStrategyCard(),
        const SizedBox(height: 16),
        if (_debts.isEmpty)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.credit_score,
                    size: 64, color: Colors.white12),
                const SizedBox(height: 16),
                const Text('No debts tracked',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 16)),
                const SizedBox(height: 8),
                const Text(
                    'Add loans, credit cards, or any debt to track payoff progress',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white30, fontSize: 13)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showAddDebtDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Your First Debt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentRed,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          ..._debts.map((d) => _buildDebtCard(d)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDebtSummaryCard(double remaining, double original) {
    final paidOff = original - remaining;
    final progress =
        original > 0 ? (paidOff / original).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentRed.withValues(alpha: 0.15),
            _accentRed.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Debt Remaining',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 13)),
              Text('GH₵ ${remaining.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: _accentRed,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _barAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress * _barAnim.value,
                backgroundColor:
                    Colors.white.withValues(alpha: 0.08),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(_accent),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paid off: GH₵ ${paidOff.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: _accent, fontSize: 11)),
              Text('${(progress * 100).toInt()}% cleared',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtStrategyCard() {
    if (_debts.isEmpty) return const SizedBox.shrink();
    // Snowball (smallest first) vs Avalanche (highest rate first)
    final snowballOrder = [..._debts]
      ..sort((a, b) => a.remaining.compareTo(b.remaining));
    final avalancheOrder = [..._debts]
      ..sort((a, b) => b.interestRate.compareTo(a.interestRate));
    final topSnowball = snowballOrder.isNotEmpty ? snowballOrder.first : null;
    final topAvalanche = avalancheOrder.isNotEmpty ? avalancheOrder.first : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accentBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates, color: _accentBlue, size: 16),
              SizedBox(width: 8),
              Text('Debt Payoff Strategy',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _strategyPill(
                  'Snowball',
                  'Pay smallest debt first. Builds momentum.',
                  topSnowball?.name ?? '-',
                  _accent,
                  Icons.ac_unit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _strategyPill(
                  'Avalanche',
                  'Pay highest interest first. Saves most money.',
                  topAvalanche?.name ?? '-',
                  _accentGold,
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _strategyPill(String name, String desc, String focusDebt,
      Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(name,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 6),
          Text('Focus: $focusDebt',
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDebtCard(DebtEntry d) {
    final progress =
        d.totalAmount > 0 ? ((d.totalAmount - d.remaining) / d.totalAmount).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: _accentRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(d.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
              Text('${d.interestRate.toStringAsFixed(1)}% p.a.',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showUpdateDebtDialog(d),
                child: const Icon(Icons.edit,
                    color: Colors.white30, size: 16),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () async {
                  setState(() =>
                      _debts.removeWhere((x) => x.id == d.id));
                  await _savePrefs();
                },
                child: const Icon(Icons.delete_outline,
                    color: Colors.white24, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _barAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress * _barAnim.value,
                backgroundColor:
                    Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1 ? _accent : _accentRed),
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  'Remaining: GH₵ ${d.remaining.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: _accentRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              Text('Min: GH₵ ${d.minimumPayment.toStringAsFixed(0)}/mo',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
              Text('${(progress * 100).toInt()}% paid',
                  style: const TextStyle(
                      color: _accent, fontSize: 11)),
            ],
          ),
          if (d.remaining <= 0)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('PAID OFF!',
                  style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11)),
            ),
        ],
      ),
    );
  }

  // ─── Goals Tab ─────────────────────────────────────────────────────────────

  Widget _buildGoalsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGoalSetting(
          title: 'Monthly Budget Goal',
          subtitle: 'Maximum you plan to spend each month',
          icon: Icons.account_balance_wallet,
          color: _accent,
          currentValue: _monthlyBudgetGoal,
          onSave: (v) async {
            setState(() => _monthlyBudgetGoal = v);
            await _savePrefs();
          },
        ),
        const SizedBox(height: 16),
        _buildGoalSetting(
          title: 'Savings Goal',
          subtitle: 'Total amount you want to accumulate',
          icon: Icons.savings,
          color: _accentGold,
          currentValue: _savingsGoal,
          onSave: (v) async {
            setState(() => _savingsGoal = v);
            await _savePrefs();
          },
        ),
        const SizedBox(height: 16),
        _buildGoalSetting(
          title: 'Financial Freedom Number (FIRE)',
          subtitle: '25× annual expenses — your independence target',
          icon: Icons.bolt,
          color: _accentGold,
          currentValue: _freedomNumber,
          onSave: (v) async {
            setState(() => _freedomNumber = v);
            await _savePrefs();
          },
        ),
        const SizedBox(height: 16),
        _buildGoalSetting(
          title: 'Monthly Living Expenses',
          subtitle: 'Used for emergency fund calculation',
          icon: Icons.home,
          color: _accentBlue,
          currentValue: _monthlyExpensesTarget,
          onSave: (v) async {
            setState(() => _monthlyExpensesTarget = v);
            await _savePrefs();
          },
        ),
        const SizedBox(height: 24),
        _buildHiddenSavingsCard(),
        const SizedBox(height: 24),
        _buildFreedomMilestones(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildFreedomMilestones() {
    final milestones = [
      _milestone('Save 1 Month Emergency Fund',
          _emergencyFundMonths >= 1, Icons.shield_outlined),
      _milestone('Clear Any High-Interest Debt (>20%)',
          !_debts.any((d) => d.interestRate > 20), Icons.credit_card_off),
      _milestone('Save 3 Month Emergency Fund',
          _emergencyFundMonths >= 3, Icons.shield),
      _milestone('Reach 10% Savings Rate',
          _savingsRate >= 10, Icons.savings),
      _milestone('Pay Off All Debts',
          _totalDebt == 0 && _debts.isNotEmpty, Icons.check_circle),
      _milestone('Save 6 Month Emergency Fund',
          _emergencyFundMonths >= 6, Icons.security),
      _milestone('Reach 20% Savings Rate',
          _savingsRate >= 20, Icons.trending_up),
      _milestone('Positive Net Worth',
          _netWorth > 0, Icons.account_balance),
      _milestone(
          '25% of FIRE Number',
          _freedomNumber > 0 && _netWorth >= _freedomNumber * 0.25,
          Icons.bolt),
      _milestone(
          '50% of FIRE Number',
          _freedomNumber > 0 && _netWorth >= _freedomNumber * 0.5,
          Icons.bolt),
      _milestone(
          'Financial Freedom!',
          _freedomNumber > 0 && _netWorth >= _freedomNumber,
          Icons.star),
    ];

    final completed = milestones.where((m) => m.$2).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentGold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: _accentGold, size: 20),
              const SizedBox(width: 8),
              const Text('Freedom Milestones',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const Spacer(),
              Text('$completed / ${milestones.length}',
                  style: const TextStyle(
                      color: _accentGold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          ...milestones.map((m) => _buildMilestoneTile(m.$1, m.$2, m.$3)),
        ],
      ),
    );
  }

  (String, bool, IconData) _milestone(String title, bool done, IconData icon) =>
      (title, done, icon);

  Widget _buildMilestoneTile(String title, bool done, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? _accent : Colors.white24,
            size: 18,
          ),
          const SizedBox(width: 10),
          Icon(icon,
              color: done ? _accentGold : Colors.white24, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color: done ? Colors.white : Colors.white38,
                    fontSize: 13,
                    decoration:
                        done ? TextDecoration.none : null)),
          ),
          if (done)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Done',
                  style: TextStyle(
                      color: _accent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // ─── Shared Widgets ────────────────────────────────────────────────────────

  Widget _inlineNumberField({
    required double value,
    required String hint,
    required Color color,
    required Future<void> Function(double) onSave,
  }) {
    final ctrl = TextEditingController(
        text: value > 0 ? value.toStringAsFixed(0) : '');
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: TextStyle(
          color: color, fontSize: 15, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: color.withValues(alpha: 0.4)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: color.withValues(alpha: 0.4))),
        focusedBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: color)),
        suffixIcon: GestureDetector(
          onTap: () async {
            final v = double.tryParse(ctrl.text) ?? 0;
            await onSave(v);
            _animController.forward(from: 0);
          },
          child: Icon(Icons.check, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildGoalSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double currentValue,
    required Future<void> Function(double) onSave,
  }) {
    final controller = TextEditingController(
        text: currentValue > 0 ? currentValue.toStringAsFixed(0) : '');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('GH₵ ',
                  style: TextStyle(
                      color: Colors.white60, fontSize: 16)),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(color: Colors.white24),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: color.withValues(alpha: 0.4))),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: color)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  final val =
                      double.tryParse(controller.text) ?? 0;
                  await onSave(val);
                  _animController.forward(from: 0);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title saved'),
                        backgroundColor: color,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                child: const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenSavingsCard() {
    final hiddenTotal = _transactions
        .where((t) => t.isHidden && t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final hiddenExpenses = _transactions
        .where((t) => t.isHidden && !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: _accentGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline, color: _accentGold, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hidden Safety Savings',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text(
                        'Private funds not visible unless you toggle Show Hidden',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _statPill('Saved',
                      'GH₵ ${hiddenTotal.toStringAsFixed(2)}', _accent)),
              const SizedBox(width: 10),
              Expanded(
                  child: _statPill('Spent',
                      'GH₵ ${hiddenExpenses.toStringAsFixed(2)}',
                      _accentRed)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/hidden_savings')
                      .then((_) => _loadData()),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('Manage Hidden Savings'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accentGold,
                side: const BorderSide(color: _accentGold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Transactions List ─────────────────────────────────────────────────────

  Widget _buildTransactionsList(List<BudgetTransaction> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.white12),
            const SizedBox(height: 16),
            const Text('No transactions yet',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tap + to add your first entry',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildTransactionTile(list[i]),
    );
  }

  Widget _buildTransactionTile(BudgetTransaction t) {
    final color = t.isIncome ? _accent : _accentRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Icon(
                t.isIncome
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: color,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(t.description,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ),
                    if (t.isHidden)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Hidden',
                            style: TextStyle(
                                color: _accentGold,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                    '${t.category} · ${t.date.toString().substring(0, 10)}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${t.isIncome ? '+' : '-'}GH₵ ${t.amount.toStringAsFixed(2)}',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─── Shared helper widgets ─────────────────────────────────────────────────

  Widget _buildIncomeExpenseCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Total Income',
            amount: _totalIncome,
            icon: Icons.arrow_downward_rounded,
            color: _accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Total Expenses',
            amount: _totalExpenses,
            icon: Icons.arrow_upward_rounded,
            color: _accentRed,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      {required String label,
      required double amount,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'GH₵ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required String label,
    required double current,
    required double goal,
    required double progress,
    required Color color,
    required IconData icon,
    required String suffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
              Text(
                'GH₵ ${current.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)}',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _barAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress * _barAnim.value,
                backgroundColor:
                    Colors.white.withValues(alpha: 0.08),
                valueColor:
                    AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(suffix,
              style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final Map<String, double> byCategory = {};
    for (final t in _transactions.where((t) => !t.isIncome)) {
      byCategory[t.category] =
          (byCategory[t.category] ?? 0) + t.amount;
    }
    if (byCategory.isEmpty) return const SizedBox.shrink();

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _totalExpenses > 0 ? _totalExpenses : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Expense Breakdown',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 14),
          ...sorted.take(5).map((e) {
            final pct = e.value / total;
            final color = _categoryColor(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(e.key,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12))),
                      Text(
                          'GH₵ ${e.value.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _barAnim,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct * _barAnim.value,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.06),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color),
                        minHeight: 5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _categoryColor(String cat) {
    const map = {
      'Food': Color(0xFF4CAF50),
      'Transport': Color(0xFF2196F3),
      'Housing': Color(0xFFFF9800),
      'Health': Color(0xFFE91E63),
      'Education': Color(0xFF9C27B0),
      'Utilities': Color(0xFF00BCD4),
      'Income': Color(0xFF00D4AA),
    };
    final key = map.keys.firstWhere(
        (k) => cat.toLowerCase().contains(k.toLowerCase()),
        orElse: () => '');
    return map[key] ?? const Color(0xFF607D8B);
  }

  Widget _buildEmpowermentTip() {
    String tip;
    Color tipColor;
    IconData tipIcon;

    if (_balance > 0 && _totalIncome > 0) {
      final savingsRate = _balance / _totalIncome * 100;
      tip =
          'You\'re saving ${savingsRate.toStringAsFixed(0)}% of your income. Financial freedom starts here — every cedi saved is a step forward.';
      tipColor = _accent;
      tipIcon = Icons.trending_up;
    } else if (_totalIncome == 0) {
      tip =
          'Start by logging any income — even small amounts. Tracking is the first step toward financial independence.';
      tipColor = _accentGold;
      tipIcon = Icons.lightbulb_outline;
    } else {
      tip =
          'Expenses are exceeding income this period. Review your spending categories and identify areas to reduce — you have the power to change this.';
      tipColor = _accentRed;
      tipIcon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: tipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(tipIcon, color: tipColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tip,
                style: TextStyle(
                    color: tipColor, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _showAddDebtDialog() {
    final nameCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    final remainingCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final minCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: const Text('Add Debt',
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameCtrl, 'Debt name (e.g. Student Loan)',
                  Colors.white),
              const SizedBox(height: 10),
              _dialogField(totalCtrl, 'Total original amount',
                  _accentRed, isNumber: true),
              const SizedBox(height: 10),
              _dialogField(remainingCtrl, 'Amount still owed',
                  _accentRed, isNumber: true),
              const SizedBox(height: 10),
              _dialogField(rateCtrl, 'Interest rate % per year',
                  _accentGold, isNumber: true),
              const SizedBox(height: 10),
              _dialogField(minCtrl, 'Minimum monthly payment',
                  _accentBlue, isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final total =
                  double.tryParse(totalCtrl.text) ?? 0;
              final remaining =
                  double.tryParse(remainingCtrl.text) ?? total;
              final rate = double.tryParse(rateCtrl.text) ?? 0;
              final min = double.tryParse(minCtrl.text) ?? 0;
              final entry = DebtEntry(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text,
                totalAmount: total,
                remaining: remaining,
                interestRate: rate,
                minimumPayment: min,
              );
              setState(() => _debts.add(entry));
              await _savePrefs();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _accentRed,
                foregroundColor: Colors.white),
            child: const Text('Add Debt'),
          ),
        ],
      ),
    );
  }

  void _showUpdateDebtDialog(DebtEntry d) {
    final remainingCtrl =
        TextEditingController(text: d.remaining.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text('Update: ${d.name}',
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update remaining balance:',
                style:
                    TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 8),
            _dialogField(remainingCtrl, 'Amount still owed',
                _accentRed, isNumber: true),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              final remaining =
                  double.tryParse(remainingCtrl.text) ?? d.remaining;
              setState(() => d.remaining = remaining);
              await _savePrefs();
              _animController.forward(from: 0);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddAssetDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedType = 'savings';
    final types = [
      'savings',
      'property',
      'investment',
      'vehicle',
      'business',
      'other'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: _cardBg,
          title: const Text('Add Asset',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameCtrl, 'e.g. Savings Account, Land',
                  Colors.white),
              const SizedBox(height: 10),
              _dialogField(amountCtrl, 'Current value (GH₵)',
                  _accentPurple, isNumber: true),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: _cardBg,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Type',
                  labelStyle:
                      const TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: _accentPurple
                              .withValues(alpha: 0.4))),
                  focusedBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: _accentPurple)),
                ),
                items: types
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t[0].toUpperCase() +
                            t.substring(1))))
                    .toList(),
                onChanged: (v) =>
                    setDlgState(() => selectedType = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final amount =
                    double.tryParse(amountCtrl.text) ?? 0;
                final entry = AssetEntry(
                  id: DateTime.now()
                      .millisecondsSinceEpoch
                      .toString(),
                  name: nameCtrl.text,
                  amount: amount,
                  type: selectedType,
                );
                setState(() => _assets.add(entry));
                await _savePrefs();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _accentPurple,
                  foregroundColor: Colors.white),
              child: const Text('Add Asset'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
      TextEditingController ctrl, String hint, Color color,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: color.withValues(alpha: 0.3))),
        focusedBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: color)),
      ),
    );
  }
}
