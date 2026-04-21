import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/beacon_division.dart';
import '../../models/donation.dart';
import '../../services/donation_service.dart';
import '../../services/auth_service.dart';

class DonationScreen extends StatefulWidget {
  final BeaconDivision division;
  final int? suggestedAmount;

  const DonationScreen({
    super.key,
    required this.division,
    this.suggestedAmount,
  });

  @override
  _DonationScreenState createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedFrequency = 'one-time';
  final String _selectedCurrency = 'USD';
  final String _selectedPaymentMethod = 'card';
  bool _isAnonymous = false;
  bool _agreeToTerms = false;
  int? _selectedAmount;
  bool _isLoading = false;

  final Map<String, List<int>> _quickAmounts = {
    'USD': [25, 50, 100, 250, 500, 1000],
    'GHS': [100, 200, 500, 1000, 2000, 5000],
  };

  final Map<String, List<String>> _paymentMethods = {
    'USD': ['card', 'paypal', 'bank_transfer', 'apple_pay', 'google_pay'],
    'GHS': ['card', 'momo', 'bank_transfer'],
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDivisionInfo(primaryColor),
              SizedBox(height: 20),
              _buildAmountSelection(primaryColor),
              SizedBox(height: 20),
              _buildFrequencySelection(primaryColor),
              SizedBox(height: 20),
              _buildDonorInfo(primaryColor),
              SizedBox(height: 20),
              _buildTermsAndConditions(),
              SizedBox(height: 100), // Space for floating button
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agreeToTerms ? () => _processDonation(primaryColor) : null,
        backgroundColor: _agreeToTerms ? primaryColor : Colors.grey,
        icon: Icon(Icons.favorite, color: Colors.white),
        label: Text(
          'Donate Now',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDivisionInfo(Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withAlpha(26), primaryColor.withAlpha(13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.division.icon,
                  style: TextStyle(fontSize: 24),
                ),
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
                      'Making a difference in people\'s lives',
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
          SizedBox(height: 16),
          Text(
            widget.division.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSelection(Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Choose an amount or enter a custom amount:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: (_quickAmounts[_selectedCurrency] ?? []).map((amount) {
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
                    '₵$amount',
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
              labelText: 'Custom Amount (₵)',
              prefixIcon: Icon(Icons.money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid amount';
              }
              if (double.parse(value) < 1) {
                return 'Minimum donation amount is ₵1';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _selectedAmount = null; // Clear quick selection
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySelection(Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: _selectedFrequency,
            onChanged: (value) {
              setState(() {
                _selectedFrequency = value!;
              });
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text('One-time donation'),
                  subtitle: Text('Make a single donation'),
                  value: 'one-time',
                  activeColor: primaryColor,
                ),
                RadioListTile<String>(
                  title: Text('Monthly donation'),
                  subtitle: Text('Automatic monthly contributions'),
                  value: 'monthly',
                  activeColor: primaryColor,
                ),
              ],
            ),
          ),
          if (_selectedFrequency == 'monthly')
            Container(
              margin: EdgeInsets.only(top: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Monthly donations help us plan better and provide consistent support.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDonorInfo(Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 16),
          CheckboxListTile(
            title: Text('Donate anonymously'),
            subtitle: Text('Your name will not be shared publicly'),
            value: _isAnonymous,
            activeColor: primaryColor,
            onChanged: (value) {
              setState(() {
                _isAnonymous = value!;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (!_isAnonymous) ...[
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
              validator: (value) {
                if (!_isAnonymous && (value == null || value.isEmpty)) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
          ],
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor),
              ),
              helperText: 'For donation receipt and updates',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms & Conditions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF0562D),
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Beacon of New Beginnings is a registered non-profit organisation. '
                    'This is a voluntary charitable donation. Donors receive no digital '
                    'content, features, or services within the app in return. '
                    'All app features remain free to all users.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          CheckboxListTile(
            title: Text('I agree to the terms and conditions'),
            subtitle: Text(
              'By checking this box, you agree that your donation will be used to support ${widget.division.shortName} charitable activities.',
            ),
            value: _agreeToTerms,
            activeColor: Color(0xFFF0562D),
            onChanged: (value) {
              setState(() {
                _agreeToTerms = value!;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.green[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your donation is secure and will be processed safely. You will receive a confirmation email.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _processDonation(Color primaryColor) async {
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

    setState(() => _isLoading = true);

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
        isAnonymous: _isAnonymous,
      );

      setState(() => _isLoading = false);

      // Process payment
      if (!mounted) return;

      setState(() => _isLoading = true);
      final result = await donationService.processDonationPayment(
        context: context,
        donation: donation,
      );
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result.success) {
        _showSuccessDialog(result.transactionId!, primaryColor);
      } else {
        _showErrorDialog(result.message ?? 'Payment failed. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog(String transactionId, Color primaryColor) {
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
            Text(
              'A receipt has been sent to your email. Your generosity helps us support domestic violence survivors in Ghana.',
              style: TextStyle(fontSize: 14),
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
              backgroundColor: primaryColor,
            ),
            child: Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
              _processDonation(Colors.red);
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}