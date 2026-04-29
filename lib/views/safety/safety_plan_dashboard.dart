import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/safety_plan.dart';
import '../../services/safety_plan_service.dart';
import 'emergency_contacts_screen.dart';
import 'safe_places_screen.dart';
import 'escape_plan_screen.dart';
import 'essential_items_screen.dart';
import 'code_words_screen.dart';
import 'crisis_coping_screen.dart';

class SafetyPlanDashboard extends StatefulWidget {
  final String userId;

  const SafetyPlanDashboard({super.key, required this.userId});

  @override
  State<SafetyPlanDashboard> createState() => _SafetyPlanDashboardState();
}

class _SafetyPlanDashboardState extends State<SafetyPlanDashboard> {
  final SafetyPlanService _service = SafetyPlanService();
  SafetyPlan? _plan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() => _loading = true);
    try {
      developer.log('🔍 [SafetyPlan] Loading plan for user: ${widget.userId}');
      var plan = await _service.getSafetyPlan(widget.userId);
      developer.log('🔍 [SafetyPlan] Got plan: ${plan != null ? "exists" : "null"}');
      if (plan == null) {
        developer.log('🔍 [SafetyPlan] Creating new plan...');
        plan = await _service.createSafetyPlan(widget.userId);
        developer.log('✅ [SafetyPlan] New plan created');
      }
      setState(() {
        _plan = plan;
        _loading = false;
      });
      developer.log('✅ [SafetyPlan] Plan loaded successfully');
    } catch (e, stack) {
      developer.log('❌ [SafetyPlan] ERROR loading plan: $e');
      developer.log('   Stack: $stack');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading safety plan: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Safety Plan')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Safety Plan'),
        backgroundColor: Colors.orange[600],
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildProgressCard(),
          SizedBox(height: 16),
          _buildSectionCard(
            'Emergency Contacts',
            Icons.contacts,
            Colors.red,
            _plan!.emergencyContacts.length,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => EmergencyContactsScreen(userId: widget.userId),
            )),
          ),
          _buildSectionCard(
            'Safe Places',
            Icons.place,
            Colors.blue,
            _plan!.safePlaces.length,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => SafePlacesScreen(userId: widget.userId),
            )),
          ),
          _buildSectionCard(
            'Escape Plan',
            Icons.directions_run,
            Colors.orange,
            _plan!.escapePlan != null ? 1 : 0,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => EscapePlanScreen(userId: widget.userId),
            )),
          ),
          _buildSectionCard(
            'Essential Items',
            Icons.backpack,
            Colors.green,
            _plan!.checkedItems.length,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => EssentialItemsScreen(userId: widget.userId),
            )),
          ),
          _buildSectionCard(
            'Code Words',
            Icons.lock,
            Colors.purple,
            _plan!.dangerCodeWord != null ? 1 : 0,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => CodeWordsScreen(userId: widget.userId),
            )),
          ),
          _buildSectionCard(
            'Crisis Coping Plan',
            Icons.favorite,
            Colors.red[700]!,
            1,
            () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => const CrisisCoopingScreen(),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Plan Completion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            SizedBox(
              height: 120,
              width: 120,
              child: CircularProgressIndicator(
                value: _plan!.completionPercentage / 100,
                strokeWidth: 10,
                backgroundColor: Colors.grey[300],
              ),
            ),
            SizedBox(height: 8),
            Text('${_plan!.completionPercentage.toStringAsFixed(0)}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, int count, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(title),
        subtitle: Text('$count items'),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
