import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Notification preferences
  bool _emergencyAlerts = true;
  bool _serviceUpdates = true;
  bool _communityUpdates = false;
  bool _successStories = true;
  bool _appointmentReminders = true;
  bool _safetyTips = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;

  // Quiet hours
  TimeOfDay _quietStart = TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = TimeOfDay(hour: 8, minute: 0);
  bool _enableQuietHours = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal[600],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroSection(),
            SizedBox(height: 24),
            _buildNotificationTypesSection(),
            SizedBox(height: 24),
            _buildDeliveryMethodsSection(),
            SizedBox(height: 24),
            _buildQuietHoursSection(),
            SizedBox(height: 24),
            _buildEmergencyNoticeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[100]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications, color: Colors.teal[600], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Stay Informed, Stay Safe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Customize your notifications to stay updated on important information while maintaining your privacy and peace of mind.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.teal[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypesSection() {
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
            'Notification Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
          SizedBox(height: 16),
          
          _buildNotificationToggle(
            title: 'Emergency Alerts',
            subtitle: 'Critical safety information and emergency updates',
            icon: Icons.emergency,
            iconColor: Colors.red[600]!,
            value: _emergencyAlerts,
            onChanged: (value) => setState(() => _emergencyAlerts = value),
            important: true,
          ),
          
          _buildNotificationToggle(
            title: 'Service Updates',
            subtitle: 'Changes to available services and resources',
            icon: Icons.medical_services,
            iconColor: Colors.blue[600]!,
            value: _serviceUpdates,
            onChanged: (value) => setState(() => _serviceUpdates = value),
          ),
          
          _buildNotificationToggle(
            title: 'Community Updates',
            subtitle: 'New support groups and community events',
            icon: Icons.people,
            iconColor: Colors.purple[600]!,
            value: _communityUpdates,
            onChanged: (value) => setState(() => _communityUpdates = value),
          ),
          
          _buildNotificationToggle(
            title: 'Success Stories',
            subtitle: 'Inspiring stories from the community',
            icon: Icons.auto_awesome,
            iconColor: Colors.orange[600]!,
            value: _successStories,
            onChanged: (value) => setState(() => _successStories = value),
          ),
          
          _buildNotificationToggle(
            title: 'Appointment Reminders',
            subtitle: 'Upcoming counseling sessions and meetings',
            icon: Icons.event,
            iconColor: Colors.green[600]!,
            value: _appointmentReminders,
            onChanged: (value) => setState(() => _appointmentReminders = value),
          ),
          
          _buildNotificationToggle(
            title: 'Safety Tips',
            subtitle: 'Helpful safety and wellness information',
            icon: Icons.lightbulb,
            iconColor: Colors.amber[600]!,
            value: _safetyTips,
            onChanged: (value) => setState(() => _safetyTips = value),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryMethodsSection() {
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
            'Delivery Methods',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
          SizedBox(height: 16),
          
          _buildNotificationToggle(
            title: 'Push Notifications',
            subtitle: 'Instant notifications on your device',
            icon: Icons.phone_android,
            iconColor: Colors.teal[600]!,
            value: _pushNotifications,
            onChanged: (value) => setState(() => _pushNotifications = value),
          ),
          
          _buildNotificationToggle(
            title: 'Email Notifications',
            subtitle: 'Receive updates via email',
            icon: Icons.email,
            iconColor: Colors.blue[600]!,
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
          ),
          
          _buildNotificationToggle(
            title: 'SMS Notifications',
            subtitle: 'Text message alerts (emergency only)',
            icon: Icons.sms,
            iconColor: Colors.green[600]!,
            value: _smsNotifications,
            onChanged: (value) => setState(() => _smsNotifications = value),
          ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursSection() {
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quiet Hours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
              ),
              Switch(
                value: _enableQuietHours,
                onChanged: (value) => setState(() => _enableQuietHours = value),
                activeColor: Colors.teal[600],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Pause non-emergency notifications during specified hours',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          if (_enableQuietHours) ...[
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    'Start Time',
                    _quietStart,
                    (time) => setState(() => _quietStart = time),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildTimeSelector(
                    'End Time',
                    _quietEnd,
                    (time) => setState(() => _quietEnd = time),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Emergency alerts will still come through during quiet hours.',
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
        ],
      ),
    );
  }

  Widget _buildEmergencyNoticeSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red[600], size: 20),
              SizedBox(width: 8),
              Text(
                'Important Safety Notice',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Emergency alerts cannot be disabled and will always come through to ensure your safety. These include severe weather warnings, safety threats, and critical service interruptions.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.red[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool important = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (important) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Required',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: important ? null : onChanged,
            activeColor: Colors.teal[600],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final newTime = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (newTime != null) {
              onChanged(newTime);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time.format(context),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _saveSettings() {
    // Here you would typically save to local storage or send to server
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification settings saved!'),
        backgroundColor: Colors.teal[600],
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
    
    Navigator.pop(context);
  }
}