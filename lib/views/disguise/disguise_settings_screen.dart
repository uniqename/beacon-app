import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisguiseSettingsScreen extends StatefulWidget {
  const DisguiseSettingsScreen({super.key});

  @override
  State<DisguiseSettingsScreen> createState() => _DisguiseSettingsScreenState();
}

class _DisguiseSettingsScreenState extends State<DisguiseSettingsScreen> {
  bool _requireBiometric = false;
  bool _enableQuickExit = true;
  String _disguiseApp = 'Calculator';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _requireBiometric = prefs.getBool('disguise_biometric') ?? false;
      _enableQuickExit = prefs.getBool('disguise_quick_exit') ?? true;
      _disguiseApp = prefs.getString('disguise_app') ?? 'Calculator';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disguise Settings'),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: Colors.deepPurple[700]),
                    SizedBox(width: 12),
                    Text(
                      'Disguise Mode',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple[900]),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Hide the Beacon app as another app to protect your privacy. The app will look like the selected disguise.',
                  style: TextStyle(color: Colors.deepPurple[800], fontSize: 14),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text('Disguise App Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Card(
            child: RadioGroup<String>(
              groupValue: _disguiseApp,
              onChanged: (value) => _updateDisguiseApp(value!),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'Calculator',
                    title: Text('Calculator'),
                    subtitle: Text('App appears as a working calculator'),
                    secondary: Icon(Icons.calculate, color: Colors.blue),
                  ),
                  RadioListTile<String>(
                    value: 'Gallery',
                    title: Text('Photo Gallery'),
                    subtitle: Text('App appears as a photo gallery'),
                    secondary: Icon(Icons.photo_library, color: Colors.green),
                  ),
                  RadioListTile<String>(
                    value: 'Notes',
                    title: Text('Notes App'),
                    subtitle: Text('App appears as a notes application'),
                    secondary: Icon(Icons.note, color: Colors.orange),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text('Security Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _requireBiometric,
                  onChanged: (value) => _updateSetting('disguise_biometric', value),
                  title: Text('Require Biometric'),
                  subtitle: Text('Use fingerprint or face to unlock'),
                  secondary: Icon(Icons.fingerprint),
                ),
                Divider(height: 1),
                SwitchListTile(
                  value: _enableQuickExit,
                  onChanged: (value) => _updateSetting('disguise_quick_exit', value),
                  title: Text('Quick Exit Gesture'),
                  subtitle: Text('Shake phone to return to disguise'),
                  secondary: Icon(Icons.exit_to_app),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text('Unlock Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Change Passcode'),
              subtitle: Text('Update your 4-digit passcode'),
              trailing: Icon(Icons.chevron_right),
              onTap: _changePasscode,
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[700]),
                    SizedBox(width: 12),
                    Text('How to Access Beacon', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[900])),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Enter your passcode in the disguise app\n• Or use the unlock gesture (shake)',
                  style: TextStyle(color: Colors.amber[900], fontSize: 14),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _testDisguise,
            icon: Icon(Icons.visibility),
            label: Text('Test Disguise Mode'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _activateDisguise,
            icon: Icon(Icons.security),
            label: Text('Activate Disguise Mode Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple[700],
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDisguiseApp(String app) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('disguise_app', app);
    setState(() => _disguiseApp = app);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Disguise changed to $app')),
    );
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    setState(() {
      if (key == 'disguise_biometric') _requireBiometric = value;
      if (key == 'disguise_quick_exit') _enableQuickExit = value;
    });
  }

  void _changePasscode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Passcode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Current Passcode',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'New Passcode',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
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
              // TODO: Implement passcode change
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Passcode updated')),
              );
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _testDisguise() {
    Navigator.pushNamed(context, '/fake_calculator');
  }

  void _activateDisguise() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activate Disguise?'),
        content: Text('The app will switch to $_disguiseApp mode. Use your passcode to return to Beacon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/fake_calculator');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple[700]),
            child: Text('Activate'),
          ),
        ],
      ),
    );
  }
}
