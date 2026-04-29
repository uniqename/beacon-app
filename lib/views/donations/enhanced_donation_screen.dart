import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethod;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../models/beacon_division.dart';
import '../../models/donation.dart';
import '../../services/app_config_service.dart';
import '../../services/donation_service.dart';
import '../../services/auth_service.dart';

class EnhancedDonationScreen extends StatefulWidget {
  final BeaconDivision division;
  final int? suggestedAmount;

  const EnhancedDonationScreen({
    super.key,
    required this.division,
    this.suggestedAmount,
  });

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
  String _selectedCurrency = 'GHS';
  String _selectedPaymentMethod = 'paystack_card';
  String _selectedMomoNetwork = 'MTN';
  bool _isAnonymous = false;
  bool _agreeToTerms = false;
  int? _selectedAmount;
  final Map<String, List<int>> _quickAmounts = {
    'GHS': [100, 200, 500, 1000, 2000, 5000],
    'USD': [25, 50, 100, 250, 500, 1000],
    'EUR': [10, 25, 50, 100, 250, 500],
    'GBP': [10, 25, 50, 100, 250, 500],
  };

  final Map<String, List<Map<String, String>>> _paymentMethods = {
    'GHS': [
      {'id': 'paystack_card', 'name': 'Card / Bank (Paystack)', 'icon': 'card'},
      {'id': 'momo', 'name': 'Mobile Money', 'icon': 'phone_android'},
      {'id': 'bank_transfer', 'name': 'Bank Transfer', 'icon': 'account_balance'},
    ],
    'USD': [
      {'id': 'stripe_card', 'name': 'Card / Apple Pay / Google Pay', 'icon': 'credit_card'},
      {'id': 'paypal', 'name': 'PayPal', 'icon': 'account_balance_wallet'},
      {'id': 'bank_transfer', 'name': 'Bank Transfer', 'icon': 'account_balance'},
    ],
    'EUR': [
      {'id': 'stripe_card', 'name': 'Card / Apple Pay / Google Pay', 'icon': 'credit_card'},
      {'id': 'bank_transfer', 'name': 'Bank Transfer', 'icon': 'account_balance'},
    ],
    'GBP': [
      {'id': 'stripe_card', 'name': 'Card / Apple Pay / Google Pay', 'icon': 'credit_card'},
      {'id': 'bank_transfer', 'name': 'Bank Transfer', 'icon': 'account_balance'},
    ],
  };

  @override
  void initState() {
    super.initState();
    final cfg = AppConfigService.instance.config;
    _selectedCurrency = cfg.currencyCode;
    _selectedPaymentMethod = cfg.primaryGateway == 'stripe' ? 'stripe_card' : 'paystack_card';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
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
                        color: cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.06),
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
              color: Color(0xFFF0562D),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildCurrencyOption('GHS', '₵', 'Ghana Cedis')),
              SizedBox(width: 10),
              Expanded(child: _buildCurrencyOption('USD', '\$', 'US Dollars')),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildCurrencyOption('EUR', '€', 'Euros')),
              SizedBox(width: 10),
              Expanded(child: _buildCurrencyOption('GBP', '£', 'British Pounds')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyOption(String currency, String symbol, String name) {
    bool isSelected = _selectedCurrency == currency;
    final cs = Theme.of(context).colorScheme;
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
          color: isSelected ? Color(0xFFF0562D).withValues(alpha: 0.12) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFFF0562D) : cs.outlineVariant,
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
                color: isSelected ? Color(0xFFF0562D) : cs.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Color(0xFFF0562D) : cs.onSurfaceVariant,
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
    String currencySymbol = _getCurrencySymbol(_selectedCurrency);
    List<int> amounts = _quickAmounts[_selectedCurrency] ?? _quickAmounts['USD']!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.06),
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
                    color: isSelected ? primaryColor : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? primaryColor : cs.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '$currencySymbol$amount',
                    style: TextStyle(
                      color: isSelected ? Colors.white : cs.onSurface,
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.06),
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
              color: Color(0xFFF0562D),
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
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFrequency = frequency;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFF0562D).withValues(alpha: 0.12) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFFF0562D) : cs.outlineVariant,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Color(0xFFF0562D) : cs.onSurfaceVariant,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Color(0xFFF0562D) : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.06),
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
              color: Color(0xFFF0562D),
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
                    color: isSelected ? Color(0xFFF0562D).withValues(alpha: 0.12) : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Color(0xFFF0562D) : cs.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getPaymentIcon(method['icon']!),
                        color: isSelected ? Color(0xFFF0562D) : cs.onSurfaceVariant,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          method['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Color(0xFFF0562D) : cs.onSurface,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFFF0562D),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String iconName) {
    switch (iconName) {
      case 'card':
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.06),
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
              color: Color(0xFFF0562D),
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
            activeColor: Color(0xFFF0562D),
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
              Text('Mobile Money Network', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
              SizedBox(height: 8),
              Row(
                children: [
                  for (final network in ['MTN', 'Vodafone', 'AirtelTigo'])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: network == 'AirtelTigo' ? 0 : 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMomoNetwork = network),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedMomoNetwork == network ? Color(0xFFF0562D).withValues(alpha: 0.15) : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedMomoNetwork == network ? Color(0xFFF0562D) : cs.outlineVariant,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              network,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _selectedMomoNetwork == network ? Color(0xFFF0562D) : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.06),
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
              color: Color(0xFFF0562D),
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
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
                    color: cs.onSurfaceVariant,
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
            activeColor: Color(0xFFF0562D),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildDonateButton(Color primaryColor) {
    String currencySymbol = _getCurrencySymbol(_selectedCurrency);
    String amount = _amountController.text.isNotEmpty ? _amountController.text : '0';
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.1),
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

  void _processDonation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate MoMo phone number if needed
    if (_selectedPaymentMethod == 'momo') {
      if (_phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter your Mobile Money phone number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final donationService = DonationService();
      final currentUser = authService.currentUser;

      // Parse payment method
      PaymentMethod paymentMethod;
      switch (_selectedPaymentMethod) {
        case 'card':
          paymentMethod = PaymentMethod.card;
          break;
        case 'paystack_card':
          paymentMethod = PaymentMethod.card; // stored as card in DB
          break;
        case 'momo':
          paymentMethod = PaymentMethod.momo;
          break;
        case 'paypal':
          paymentMethod = PaymentMethod.paypal;
          break;
        case 'bank_transfer':
          paymentMethod = PaymentMethod.bankTransfer;
          break;
        case 'apple_pay':
          paymentMethod = PaymentMethod.applePay;
          break;
        case 'google_pay':
          paymentMethod = PaymentMethod.googlePay;
          break;
        default:
          paymentMethod = PaymentMethod.card;
      }

      // Determine MoMo network if applicable
      Map<String, dynamic>? metadata;
      if (_selectedPaymentMethod == 'momo') {
        metadata = {'momo_network': _selectedMomoNetwork};
      }

      // Create donation record
      final donation = await donationService.createDonation(
        userId: currentUser?.id,
        divisionId: widget.division.id,
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        frequency: _selectedFrequency == 'one-time'
          ? DonationFrequency.oneTime
          : DonationFrequency.monthly,
        paymentMethod: paymentMethod,
        donorName: _isAnonymous ? null : _nameController.text,
        donorEmail: _isAnonymous ? null : _emailController.text,
        donorPhone: _selectedPaymentMethod == 'momo' ? _phoneController.text : null,
        isAnonymous: _isAnonymous,
        metadata: metadata,
      );


      // Process payment
      if (!mounted) return;

      // Paystack takes a separate path — opens browser then verify
      if (_selectedPaymentMethod == 'paystack_card') {
          final result = await donationService.processPaystackPayment(
          amount: double.parse(_amountController.text),
          currency: _selectedCurrency,
          customerEmail: _isAnonymous
              ? 'anonymous@beaconnewbeginnings.org'
              : _emailController.text,
          customerName:
              _isAnonymous ? 'Anonymous Donor' : _nameController.text,
          description: 'Donation to Beacon of New Beginnings',
          transactionRef: 'DON-${donation.id}',
        );
          if (!mounted) return;

        if (result.isPending) {
          _showPaystackPendingDialog(result.transactionId!, donationService);
        } else {
          _showErrorDialog(result.message ?? 'Payment failed. Please try again.');
        }
        return;
      }

      // Stripe handles card, Apple Pay, Google Pay for USD/EUR/GBP
      if (_selectedPaymentMethod == 'stripe_card') {
          try {
          await _processStripePayment(
            double.parse(_amountController.text),
            _selectedCurrency,
            donation.id,
          );
              if (!mounted) return;
          _showSuccessDialog('stripe-${donation.id}');
        } on StripeException catch (e) {
              if (!mounted) return;
          if (e.error.code != FailureCode.Canceled) {
            _showErrorDialog(e.error.localizedMessage ?? 'Payment failed. Please try again.');
          }
        } catch (e) {
              if (!mounted) return;
          _showErrorDialog(e.toString());
        }
        return;
      }

      final result = await donationService.processDonationPayment(
        context: context,
        donation: donation,
      );

      if (!mounted) return;

      if (result.success) {
        _showSuccessDialog(result.transactionId!);
      } else {
        _showErrorDialog(result.message ?? 'Payment failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showPaystackPendingDialog(
      String reference, DonationService donationService) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.open_in_browser, color: Color(0xFFF0562D), size: 28),
            SizedBox(width: 12),
            Text('Payment Opened'),
          ],
        ),
        content: const Text(
          'Complete your payment in the browser, then tap \'Verify Payment\' to confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0562D),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
                      final verifyResult =
                  await donationService.verifyPaystackPayment(reference);
                      if (!mounted) return;
              if (verifyResult.success) {
                _showSuccessDialog(verifyResult.transactionId ?? reference);
              } else {
                _showErrorDialog(
                    verifyResult.message ?? 'Verification failed.');
              }
            },
            child: const Text('Verify Payment'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32),
            SizedBox(width: 12),
            Text('Thank You!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your donation has been processed successfully!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Transaction ID:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(
              transactionId,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
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
                    'What happens next:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• You will receive an email receipt\n• Your donation supports ${widget.division.shortName}\n• Monthly donations process automatically\n• Tax receipts available upon request',
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
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close donation screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF0562D),
              foregroundColor: Colors.white,
            ),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      default: return '₵';
    }
  }

  Future<void> _processStripePayment(double amount, String currency, String donationId) async {
    final secretKey = dotenv.env['STRIPE_SECRET_KEY'] ?? '';
    if (secretKey.isEmpty) throw Exception('Stripe not configured');

    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': (amount * 100).round().toString(),
        'currency': currency.toLowerCase(),
        'automatic_payment_methods[enabled]': 'true',
        'automatic_payment_methods[allow_redirects]': 'never',
        'metadata[donation_id]': donationId,
        'metadata[app]': 'beacon',
      },
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['error']?['message'] ?? 'Failed to create payment');
    }

    final data = json.decode(response.body);
    final clientSecret = data['client_secret'] as String;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Beacon of New Beginnings',
        applePay: const PaymentSheetApplePay(merchantCountryCode: 'GH'),
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'GH',
          testEnv: false,
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Payment Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            SizedBox(height: 16),
            Text(
              'Please try again or contact support if the problem persists.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (_selectedPaymentMethod == 'momo') ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tip: Make sure you approved the payment on your phone and have sufficient balance.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processDonation();
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}