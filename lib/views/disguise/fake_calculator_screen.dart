import 'package:flutter/material.dart';

class FakeCalculatorScreen extends StatefulWidget {
  const FakeCalculatorScreen({super.key});

  @override
  State<FakeCalculatorScreen> createState() => _FakeCalculatorScreenState();
}

class _FakeCalculatorScreenState extends State<FakeCalculatorScreen> {
  String _display = '0';
  String _secretCode = '';
  final String _unlockCode = '1234';

  final List<List<String>> _buttons = [
    ['7', '8', '9', '÷'],
    ['4', '5', '6', '×'],
    ['1', '2', '3', '-'],
    ['C', '0', '=', '+'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('Calculator', style: TextStyle(color: Colors.white70)),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.all(32),
              child: Text(
                _display,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _buttons.length * 4,
              itemBuilder: (context, index) {
                final row = index ~/ 4;
                final col = index % 4;
                final button = _buttons[row][col];
                return _buildButton(button);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text) {
    final isOperator = ['÷', '×', '-', '+', '='].contains(text);
    final isSpecial = ['C'].contains(text);

    return Material(
      color: isOperator
          ? Colors.orange[700]
          : isSpecial
              ? Colors.grey[800]
              : Colors.grey[900],
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _handleButtonPress(text),
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _handleButtonPress(String button) {
    setState(() {
      if (button == 'C') {
        _display = '0';
        _secretCode = '';
      } else if (button == '=') {
        // Check if secret code was entered
        if (_secretCode == _unlockCode) {
          _unlockApp();
        } else {
          // Perform fake calculation
          _display = '42'; // Always show 42 as a joke
        }
      } else {
        // Track button presses for secret code
        if ('0123456789'.contains(button)) {
          _secretCode += button;
          if (_secretCode.length > _unlockCode.length) {
            _secretCode = _secretCode.substring(_secretCode.length - _unlockCode.length);
          }
        }

        // Update display
        if (_display == '0' && button != '.') {
          _display = button;
        } else if (!'÷×-+'.contains(button)) {
          _display += button;
        }
      }
    });
  }

  void _unlockApp() {
    Navigator.pushReplacementNamed(context, '/home');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Welcome back to Beacon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
