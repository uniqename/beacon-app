import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisguiseLoginScreen extends StatefulWidget {
  const DisguiseLoginScreen({super.key});

  @override
  State<DisguiseLoginScreen> createState() => _DisguiseLoginScreenState();
}

class _DisguiseLoginScreenState extends State<DisguiseLoginScreen> {
  final _passcodeController = TextEditingController();
  bool _isSetup = false;
  String? _savedPasscode;

  @override
  void initState() {
    super.initState();
    _loadPasscode();
  }

  Future<void> _loadPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPasscode = prefs.getString('disguise_passcode');
      _isSetup = _savedPasscode != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.white70),
                SizedBox(height: 24),
                Text(
                  _isSetup ? 'Enter Passcode' : 'Set Disguise Passcode',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 12),
                Text(
                  _isSetup
                      ? 'Enter your 4-digit passcode to access disguised features'
                      : 'Create a 4-digit passcode to protect disguised features',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 40),
                Container(
                  constraints: BoxConstraints(maxWidth: 300),
                  child: TextField(
                    controller: _passcodeController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    style: TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 16),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      counterText: '',
                      hintText: '••••',
                      hintStyle: TextStyle(color: Colors.white30),
                    ),
                    onSubmitted: (_) => _handlePasscode(),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handlePasscode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_isSetup ? 'Unlock' : 'Set Passcode', style: TextStyle(fontSize: 16)),
                  ),
                ),
                if (!_isSetup) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Remember this passcode. It\'s required to access disguised features.',
                            style: TextStyle(color: Colors.amber, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePasscode() async {
    final passcode = _passcodeController.text;

    if (passcode.length != 4) {
      _showError('Passcode must be 4 digits');
      return;
    }

    if (_isSetup) {
      // Verify passcode
      if (passcode == _savedPasscode) {
        // Navigate to disguise dashboard or unlock features
        Navigator.pushReplacementNamed(context, '/disguise_dashboard');
      } else {
        _showError('Incorrect passcode');
        _passcodeController.clear();
      }
    } else {
      // Save new passcode
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('disguise_passcode', passcode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passcode set successfully'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/disguise_dashboard');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }
}
