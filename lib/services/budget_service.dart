import '../models/evidence_log.dart';
import 'local_database_service.dart';

class BudgetService {
  Future<BudgetTransaction> addTransaction({
    required String userId,
    required double amount,
    required String category,
    required String description,
    bool isIncome = false,
    bool isHidden = false,
  }) async {
    final transactionId = await LocalDatabaseService.saveBudgetTransaction(userId, {
      'amount': amount,
      'category': category,
      'description': description,
      'is_income': isIncome,
      'is_hidden': isHidden,
      'date': DateTime.now().toIso8601String(),
    });

    return BudgetTransaction(
      id: transactionId,
      userId: userId,
      date: DateTime.now(),
      amount: amount,
      category: category,
      description: description,
      isIncome: isIncome,
      isHidden: isHidden,
    );
  }

  Future<List<BudgetTransaction>> getAllTransactions(String userId, {bool includeHidden = true}) async {
    final transactions = await LocalDatabaseService.getBudgetTransactions(userId, includeHidden: includeHidden);
    return transactions.map((t) {
      return BudgetTransaction(
        id: t['id'] as String,
        userId: t['user_id'] as String,
        date: DateTime.parse(t['date'] as String),
        amount: (t['amount'] as num).toDouble(),
        category: t['category'] as String,
        description: t['description'] as String,
        isIncome: t['is_income'] as bool,
        isHidden: t['is_hidden'] as bool,
      );
    }).toList();
  }

  Future<double> getTotalIncome(String userId, {int months = 1}) async {
    final summary = await LocalDatabaseService.getBudgetSummary(userId);
    return summary['income'] ?? 0.0;
  }

  Future<double> getTotalExpenses(String userId, {int months = 1}) async {
    final summary = await LocalDatabaseService.getBudgetSummary(userId);
    return summary['expenses'] ?? 0.0;
  }

  Future<Map<String, double>> getExpensesByCategory(String userId) async {
    final transactions = await getAllTransactions(userId, includeHidden: false);
    final expenses = transactions.where((t) => !t.isIncome);

    final Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }

    return categoryTotals;
  }

  List<String> getExpenseCategories() {
    return ['Housing', 'Food', 'Transportation', 'Healthcare', 'Education', 'Personal', 'Other'];
  }

  List<String> getIncomeCategories() {
    return ['Salary', 'Business', 'Gifts', 'Benefits', 'Other'];
  }

  Future<List<BudgetTransaction>> getHiddenTransactions(String userId) async {
    final transactions = await LocalDatabaseService.getBudgetTransactions(userId, includeHidden: true);
    return transactions
        .where((t) => t['is_hidden'] == true)
        .map((t) {
      return BudgetTransaction(
        id: t['id'] as String,
        userId: t['user_id'] as String,
        date: DateTime.parse(t['date'] as String),
        amount: (t['amount'] as num).toDouble(),
        category: t['category'] as String,
        description: t['description'] as String,
        isIncome: t['is_income'] as bool,
        isHidden: t['is_hidden'] as bool,
      );
    }).toList();
  }
}
