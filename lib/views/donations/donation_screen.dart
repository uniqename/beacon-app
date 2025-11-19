import 'package:flutter/material.dart';
import '../../models/beacon_division.dart';

class DonationScreen extends StatefulWidget {
  final BeaconDivision division;
  final int? suggestedAmount;

  const DonationScreen({
    Key? key,
    required this.division,
    this.suggestedAmount,
  }) : super(key: key);

  @override
  _DonationScreenState createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
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
            children: _quickAmounts.map((amount) {
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
          RadioListTile<String>(
            title: Text('One-time donation'),
            subtitle: Text('Make a single donation'),
            value: 'one-time',
            groupValue: _selectedFrequency,
            activeColor: primaryColor,
            onChanged: (value) {
              setState(() {
                _selectedFrequency = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: Text('Monthly donation'),
            subtitle: Text('Automatic monthly contributions'),
            value: 'monthly',
            groupValue: _selectedFrequency,
            activeColor: primaryColor,
            onChanged: (value) {
              setState(() {
                _selectedFrequency = value!;
              });
            },
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
              color: Color(0xFF2E8B57),
            ),
          ),
          SizedBox(height: 16),
          CheckboxListTile(
            title: Text('I agree to the terms and conditions'),
            subtitle: Text(
              'By checking this box, you agree that your donation will be used to support ${widget.division.shortName} activities.',
            ),
            value: _agreeToTerms,
            activeColor: Color(0xFF2E8B57),
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

  void _processDonation(Color primaryColor) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Donation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₵${_amountController.text}'),
            Text('Frequency: $_selectedFrequency'),
            Text('To: ${widget.division.name}'),
            if (!_isAnonymous) Text('From: ${_nameController.text}'),
            SizedBox(height: 16),
            Text(
              'This donation will help support ${widget.division.shortName} services.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
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
              _submitDonation(primaryColor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            child: Text(
              'Confirm Donation',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _submitDonation(Color primaryColor) {
    // Simulate donation processing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Donation submitted successfully! Thank you for your support.'),
        backgroundColor: primaryColor,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View Receipt',
          textColor: Colors.white,
          onPressed: () {
            _showReceiptDialog();
          },
        ),
      ),
    );

    // Navigate back after a short delay
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  void _showReceiptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Donation Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thank you for your donation!'),
            SizedBox(height: 16),
            Text('Receipt ID: BCN-${DateTime.now().millisecondsSinceEpoch}'),
            Text('Amount: ₵${_amountController.text}'),
            Text('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
            Text('Division: ${widget.division.name}'),
            SizedBox(height: 16),
            Text(
              'A detailed receipt has been sent to ${_emailController.text}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}