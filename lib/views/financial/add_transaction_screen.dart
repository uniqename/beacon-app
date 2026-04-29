import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/app_config_service.dart';
import '../../services/budget_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final String userId;

  const AddTransactionScreen({super.key, required this.userId});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final BudgetService _service = BudgetService();
  String get _cs => AppConfigService.instance.config.currencySymbol;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isIncome = false;
  bool _isHidden = false;
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final categories = _isIncome
        ? ['Salary', 'Gift', 'Selling Items', 'Other Income']
        : _service.getExpenseCategories();

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Transaction'),
        backgroundColor: Colors.green[700],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transaction Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _isIncome = false;
                              _selectedCategory = 'Food';
                            }),
                            icon: Icon(Icons.remove_circle_outline),
                            label: Text('Expense'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: !_isIncome ? Colors.red[700] : Colors.grey,
                              side: BorderSide(
                                color: !_isIncome ? Colors.red[700]! : Colors.grey[300]!,
                                width: !_isIncome ? 2 : 1,
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _isIncome = true;
                              _selectedCategory = 'Salary';
                            }),
                            icon: Icon(Icons.add_circle_outline),
                            label: Text('Income'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _isIncome ? Colors.green[700] : Colors.grey,
                              side: BorderSide(
                                color: _isIncome ? Colors.green[700]! : Colors.grey[300]!,
                                width: _isIncome ? 2 : 1,
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount ($_cs) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value?.trim().isEmpty ?? true) return 'Amount required';
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) return 'Invalid amount';
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) => value?.trim().isEmpty ?? true ? 'Description required' : null,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.calendar_today),
              title: Text('Date'),
              subtitle: Text(_selectedDate.toString().substring(0, 10)),
              trailing: Icon(Icons.edit),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            SizedBox(height: 16),
            Card(
              color: Colors.orange[50],
              child: SwitchListTile(
                value: _isHidden,
                onChanged: (value) => setState(() => _isHidden = value),
                title: Text('Hidden Savings', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Mark as hidden emergency fund'),
                secondary: Icon(Icons.lock, color: Colors.orange[700]),
              ),
            ),
            if (_isHidden) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hidden transactions won\'t appear in your main balance unless you toggle visibility.',
                        style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _saveTransaction,
              icon: Icon(Icons.check),
              label: Text('Save Transaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _service.addTransaction(
        userId: widget.userId,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        isIncome: _isIncome,
        isHidden: _isHidden,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction saved'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
