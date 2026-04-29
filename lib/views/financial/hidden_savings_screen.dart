import 'package:flutter/material.dart';
import '../../models/evidence_log.dart';
import '../../services/app_config_service.dart';
import '../../services/budget_service.dart';

class HiddenSavingsScreen extends StatefulWidget {
  final String userId;

  const HiddenSavingsScreen({super.key, required this.userId});

  @override
  State<HiddenSavingsScreen> createState() => _HiddenSavingsScreenState();
}

class _HiddenSavingsScreenState extends State<HiddenSavingsScreen> {
  final BudgetService _service = BudgetService();
  String get _cs => AppConfigService.instance.config.currencySymbol;
  List<BudgetTransaction> _hiddenTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final transactions = await _service.getHiddenTransactions(widget.userId);
    setState(() {
      _hiddenTransactions = transactions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalSavings = _hiddenTransactions
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hidden Savings'),
        backgroundColor: Colors.orange[700],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[600]!, Colors.orange[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.lock, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Total Hidden Savings',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '$_cs ${totalSavings.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${_hiddenTransactions.where((t) => t.isIncome).length} savings entries',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.amber[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hidden savings are kept separate from your main budget for emergencies. Keep building your safety fund.',
                    style: TextStyle(fontSize: 13, color: Colors.amber[900]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _hiddenTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.savings, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No hidden savings yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Start building your emergency fund by marking transactions as "hidden"',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _hiddenTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _hiddenTransactions[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: transaction.isIncome ? Colors.green[100] : Colors.red[100],
                                child: Icon(
                                  transaction.isIncome ? Icons.add : Icons.remove,
                                  color: transaction.isIncome ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                              title: Text(transaction.description, style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(transaction.category),
                                  SizedBox(height: 2),
                                  Text(
                                    transaction.date.toString().substring(0, 10),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '${transaction.isIncome ? '+' : '-'}$_cs ${transaction.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: transaction.isIncome ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Aim to save at least ${_cs}500 for emergencies',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
