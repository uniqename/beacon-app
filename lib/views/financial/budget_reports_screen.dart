import 'package:flutter/material.dart';
import '../../services/app_config_service.dart';
import '../../services/budget_service.dart';

class BudgetReportsScreen extends StatefulWidget {
  final String userId;

  const BudgetReportsScreen({super.key, required this.userId});

  @override
  State<BudgetReportsScreen> createState() => _BudgetReportsScreenState();
}

class _BudgetReportsScreenState extends State<BudgetReportsScreen> {
  final BudgetService _service = BudgetService();
  String get _cs => AppConfigService.instance.config.currencySymbol;
  Map<String, double> _categoryExpenses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final expenses = await _service.getExpensesByCategory(widget.userId);
    setState(() {
      _categoryExpenses = expenses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _categoryExpenses.values.fold<double>(0, (sum, amount) => sum + amount);

    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Reports'),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spending by Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Total: $_cs ${totalExpenses.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[600])),
                        SizedBox(height: 20),
                        if (_categoryExpenses.isEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No expense data', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else
                          SizedBox(
                            height: 200,
                            child: _buildExpenseChart(totalExpenses),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        ..._categoryExpenses.entries.map((entry) {
                          final percentage = totalExpenses > 0 ? (entry.value / totalExpenses * 100) : 0.0;
                          return _buildCategoryRow(entry.key, entry.value, percentage);
                        }),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                            SizedBox(width: 12),
                            Text('Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 16),
                        ..._getInsights().map((insight) => Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('•', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                  Expanded(child: Text(insight)),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExpenseChart(double total) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _categoryExpenses.length,
      itemBuilder: (context, index) {
        final entry = _categoryExpenses.entries.elementAt(index);
        final height = total > 0 ? (entry.value / total * 180) : 0.0;

        return Container(
          width: 60,
          margin: EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$_cs${entry.value.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Container(
                width: 50,
                height: height,
                decoration: BoxDecoration(
                  color: _getCategoryColor(entry.key),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
              SizedBox(height: 8),
              Text(
                entry.key,
                style: TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryRow(String category, double amount, double percentage) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Text(
                '$_cs ${amount.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(category)),
                  minHeight: 8,
                ),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food': Colors.orange,
      'Transport': Colors.blue,
      'Housing': Colors.purple,
      'Healthcare': Colors.red,
      'Education': Colors.green,
      'Utilities': Colors.teal,
      'Other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  List<String> _getInsights() {
    if (_categoryExpenses.isEmpty) {
      return ['Start tracking your expenses to see personalized insights here.'];
    }

    final insights = <String>[];
    final sortedEntries = _categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.isNotEmpty) {
      final top = sortedEntries.first;
      final total = _categoryExpenses.values.fold<double>(0, (sum, amount) => sum + amount);
      final percentage = (top.value / total * 100).toStringAsFixed(0);
      insights.add('${top.key} is your highest expense category at $percentage% of total spending.');
    }

    if (sortedEntries.length >= 3) {
      final topThree = sortedEntries.take(3).map((e) => e.key).join(', ');
      insights.add('Your top 3 spending categories are: $topThree.');
    }

    insights.add('Consider setting budget limits for your top expense categories to better manage your finances.');

    return insights;
  }
}
