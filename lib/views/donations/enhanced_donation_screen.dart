import 'package:flutter/material.dart';
import '../../models/beacon_division.dart';

class EnhancedDonationScreen extends StatefulWidget {
  final BeaconDivision division;
  final int? suggestedAmount;

  const EnhancedDonationScreen({
    Key? key,
    required this.division,
    this.suggestedAmount,
  }) : super(key: key);

  @override
  _EnhancedDonationScreenState createState() => _EnhancedDonationScreenState();
}

class _EnhancedDonationScreenState extends State<EnhancedDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedFrequency = 'one-time';
  String _selectedCurrency = 'USD';
  String _selectedPaymentMethod = 'card';
  bool _isAnonymous = false;
  bool _agreeToTerms = false;
  int? _selectedAmount;

  final Map<String, List<int>> _quickAmounts = {
    'USD': [25, 50, 100, 250, 500, 1000],
    'GHS': [100, 200, 500, 1000, 2000, 5000],
  };

  final Map<String, List<Map<String, String>>> _paymentMethods = {
    'USD': [
      {'id': 'card', 'name': 'Credit/Debit Card', 'icon': 'credit_card'},
      {'id': 'paypal', 'name': 'PayPal', 'icon': 'account_balance_wallet'},
      {'id': 'bank_transfer', 'name': 'Bank Transfer', 'icon': 'account_balance'},
      {'id': 'apple_pay', 'name': 'Apple Pay', 'icon': 'phone_android'},
      {'id': 'google_pay', 'name': 'Google Pay', 'icon': 'phone_android'},
    ],
    'GHS': [
      {'id': 'card', 'name': 'Visa/MasterCard', 'icon': 'credit_card'},
      {'id': 'momo', 'name': 'Mobile Money', 'icon': 'phone_android'},
      {'id': 'bank_transfer', 'name': 'Bank Transfer', 'icon': 'account_balance'},
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.suggestedAmount != null) {
      _selectedAmount = widget.suggestedAmount;
      _amountController.text = widget.suggestedAmount.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Color(int.parse(widget.division.color.replaceFirst('#', '0xFF')));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Donate to ${widget.division.shortName}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDivisionHeader(primaryColor),
                    SizedBox(height: 24),
                    _buildCurrencySelector(),
                    SizedBox(height: 24),
                    _buildAmountSection(primaryColor),
                    SizedBox(height: 24),
                    _buildFrequencySelector(),
                    SizedBox(height: 24),
                    _buildPaymentMethodSection(),
                    SizedBox(height: 24),
                    _buildDonorInfoSection(),
                    SizedBox(height: 24),
                    _buildTermsSection(),
                    SizedBox(height: 100), // Space for button
                  ],
                ),
              ),
            ),
            _buildDonateButton(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDivisionHeader(Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.division.icon,
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.division.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your donation helps us provide essential services to those in need',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Currency',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E8B57),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCurrencyOption('USD', '\$', 'US Dollars'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildCurrencyOption('GHS', '₵', 'Ghana Cedis'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyOption(String currency, String symbol, String name) {
    bool isSelected = _selectedCurrency == currency;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCurrency = currency;
          _selectedAmount = null;
          _amountController.clear();
          _selectedPaymentMethod = _paymentMethods[currency]![0]['id']!;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2E8B57).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF2E8B57) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Color(0xFF2E8B57) : Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Color(0xFF2E8B57) : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection(Color primaryColor) {
    String currencySymbol = _selectedCurrency == 'USD' ? '\$' : '₵';
    List<int> amounts = _quickAmounts[_selectedCurrency]!;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Donation Amount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: amounts.map((amount) {
              bool isSelected = _selectedAmount == amount;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAmount = amount;
                    _amountController.text = amount.toString();
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '$currencySymbol$amount',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Custom Amount ($currencySymbol)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _selectedAmount = null;
              });
            },
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter an amount';
              if (double.tryParse(value!) == null) return 'Please enter a valid amount';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Donation Frequency',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E8B57),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFrequencyOption('one-time', 'One-time', Icons.payments),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFrequencyOption('monthly', 'Monthly', Icons.repeat),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption(String frequency, String label, IconData icon) {
    bool isSelected = _selectedFrequency == frequency;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFrequency = frequency;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2E8B57).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF2E8B57) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Color(0xFF2E8B57) : Colors.grey[600],
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Color(0xFF2E8B57) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E8B57),
            ),
          ),
          SizedBox(height: 16),
          ..._paymentMethods[_selectedCurrency]!.map((method) {
            bool isSelected = _selectedPaymentMethod == method['id'];
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = method['id']!;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF2E8B57).withOpacity(0.1) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Color(0xFF2E8B57) : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getPaymentIcon(method['icon']!),
                        color: isSelected ? Color(0xFF2E8B57) : Colors.grey[600],
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          method['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Color(0xFF2E8B57) : Colors.grey[700],
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFF2E8B57),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String iconName) {
    switch (iconName) {
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'account_balance':
        return Icons.account_balance;
      case 'phone_android':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  Widget _buildDonorInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Donor Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E8B57),
            ),
          ),
          SizedBox(height: 16),
          CheckboxListTile(
            title: Text('Donate anonymously'),
            subtitle: Text('Your name will not be displayed publicly'),
            value: _isAnonymous,
            onChanged: (value) {
              setState(() {
                _isAnonymous = value ?? false;
              });
            },
            activeColor: Color(0xFF2E8B57),
            contentPadding: EdgeInsets.zero,
          ),
          if (!_isAnonymous) ...[
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (!_isAnonymous && (value?.isEmpty ?? true)) {
                  return 'Name is required for non-anonymous donations';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (!_isAnonymous && (value?.isEmpty ?? true)) {
                  return 'Email is required';
                }
                return null;
              },
            ),
            if (_selectedPaymentMethod == 'momo') ...[
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Mobile Money Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'e.g., 0241234567',
                ),
                validator: (value) {
                  if (_selectedPaymentMethod == 'momo' && (value?.isEmpty ?? true)) {
                    return 'Mobile money number is required';
                  }
                  return null;
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms & Agreement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E8B57),
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Information:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Your donation goes directly to support ${widget.division.name}\n'
                  '• Donations are processed securely\n'
                  '• You will receive an email receipt\n'
                  '• Monthly donations can be cancelled anytime\n'
                  '• Tax receipts available upon request',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          CheckboxListTile(
            title: Text('I agree to the donation terms and conditions'),
            subtitle: Text('Required to process donation'),
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() {
                _agreeToTerms = value ?? false;
              });
            },
            activeColor: Color(0xFF2E8B57),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildDonateButton(Color primaryColor) {
    String currencySymbol = _selectedCurrency == 'USD' ? '\$' : '₵';
    String amount = _amountController.text.isNotEmpty ? _amountController.text : '0';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _agreeToTerms ? _processDonation : null,
            icon: Icon(Icons.favorite, color: Colors.white),
            label: Text(
              'Donate $currencySymbol$amount ${_selectedFrequency == 'monthly' ? '/month' : ''}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }

  void _processDonation() {
    if (_formKey.currentState!.validate()) {
      _showPaymentDialog();
    }
  }

  void _showPaymentDialog() {
    String currencySymbol = _selectedCurrency == 'USD' ? '\$' : '₵';
    String amount = _amountController.text;
    String paymentMethodName = _paymentMethods[_selectedCurrency]!
        .firstWhere((method) => method['id'] == _selectedPaymentMethod)['name']!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: Color(0xFF2E8B57)),
            SizedBox(width: 12),
            Text('Process Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Donation Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Amount: $currencySymbol$amount'),
            Text('Frequency: $_selectedFrequency'),
            Text('Payment Method: $paymentMethodName'),
            Text('Division: ${widget.division.name}'),
            SizedBox(height: 16),
            if (_selectedPaymentMethod == 'momo') ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Money Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1. You will receive an SMS prompt\n2. Enter your PIN to approve\n3. Payment will be processed automatically',
                      style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secure Payment:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'You will be redirected to our secure payment processor to complete your donation.',
                      style: TextStyle(fontSize: 12, color: Colors.green[600]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeDonation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E8B57),
              foregroundColor: Colors.white,
            ),
            child: Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  void _completeDonation() {
    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            SizedBox(width: 12),
            Text('Donation Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Thank you for your generous donation to ${widget.division.name}!'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'What happens next:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• You will receive an email receipt\n• Your donation will directly support our programs\n• Monthly donations will process automatically',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }
}