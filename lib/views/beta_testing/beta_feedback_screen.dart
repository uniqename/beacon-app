import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class BetaFeedbackScreen extends StatefulWidget {
  const BetaFeedbackScreen({super.key});

  @override
  State<BetaFeedbackScreen> createState() => _BetaFeedbackScreenState();
}

class _BetaFeedbackScreenState extends State<BetaFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedCategory = 'Bug Report';
  String _selectedPriority = 'Medium';
  int _usabilityRating = 5;
  int _performanceRating = 5;
  int _designRating = 5;
  
  final List<String> _categories = [
    'Bug Report',
    'Feature Request',
    'Usability Issue',
    'Performance Issue',
    'Security Concern',
    'General Feedback'
  ];
  
  final List<String> _priorities = [
    'Low',
    'Medium', 
    'High',
    'Critical'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beta Testing Feedback'),
        backgroundColor: const Color(0xFF00796B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.feedback, size: 48, color: Color(0xFF00796B)),
                      SizedBox(height: 12),
                      Text(
                        'Help Us Improve',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your feedback is crucial in making this app safe and effective for survivors. Thank you for testing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Contact Information
              const Text(
                'Contact Information (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'For follow-up questions only',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 24),
              
              // Feedback Category
              const Text(
                'Feedback Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Priority Level
              const Text(
                'Priority Level',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: _priorities.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(
                          priority == 'Critical' ? Icons.error :
                          priority == 'High' ? Icons.warning :
                          priority == 'Medium' ? Icons.info :
                          Icons.low_priority,
                          color: priority == 'Critical' ? Colors.red :
                                 priority == 'High' ? Colors.orange :
                                 priority == 'Medium' ? Colors.blue :
                                 Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(priority),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Rating Sections
              const Text(
                'App Rating',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              _buildRatingSection('Usability', _usabilityRating, (rating) {
                setState(() {
                  _usabilityRating = rating;
                });
              }),
              
              _buildRatingSection('Performance', _performanceRating, (rating) {
                setState(() {
                  _performanceRating = rating;
                });
              }),
              
              _buildRatingSection('Design', _designRating, (rating) {
                setState(() {
                  _designRating = rating;
                });
              }),
              
              const SizedBox(height: 24),
              
              // Detailed Feedback
              const Text(
                'Detailed Feedback',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feedbackController,
                decoration: const InputDecoration(
                  hintText: 'Please describe your experience, any issues, or suggestions for improvement...',
                  prefixIcon: Icon(Icons.comment),
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide your feedback';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitFeedback,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Feedback'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Emergency Contact
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.emergency, color: Colors.red, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'Emergency Support',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'If you need immediate help during testing, please contact:',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _launchPhone('0800800800'),
                        icon: const Icon(Icons.phone),
                        label: const Text('0800-800-800'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRatingSection(String title, int rating, Function(int) onRatingChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              onPressed: () => onRatingChanged(index + 1),
              icon: Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    try {
      // Save feedback locally
      final prefs = await SharedPreferences.getInstance();
      final feedbackData = {
        'timestamp': DateTime.now().toIso8601String(),
        'email': _emailController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'usability_rating': _usabilityRating,
        'performance_rating': _performanceRating,
        'design_rating': _designRating,
        'feedback': _feedbackController.text.trim(),
      };
      
      final existingFeedback = prefs.getStringList('beta_feedback') ?? [];
      existingFeedback.add(feedbackData.toString());
      await prefs.setStringList('beta_feedback', existingFeedback);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your feedback has been recorded.'),
            backgroundColor: Color(0xFF00796B),
          ),
        );
        
        // Clear form
        _feedbackController.clear();
        _emailController.clear();
        setState(() {
          _selectedCategory = 'Bug Report';
          _selectedPriority = 'Medium';
          _usabilityRating = 5;
          _performanceRating = 5;
          _designRating = 5;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _launchPhone(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
  
  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}