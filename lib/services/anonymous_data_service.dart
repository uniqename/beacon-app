import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/anonymous_submission.dart';

class AnonymousDataService {
  static const String _submissionsKey = 'anonymous_submissions';
  static const Uuid _uuid = Uuid();

  // Submit anonymous information for follow-up
  Future<String> submitAnonymousInformation({
    required String type, // 'help_request', 'resource_need', 'emergency_info'
    required String description,
    String? location,
    String? contactMethod, // 'phone', 'email', 'in_person'
    String? contactInfo,
    String? urgencyLevel, // 'low', 'medium', 'high', 'critical'
    Map<String, dynamic>? additionalData,
  }) async {
    final submission = AnonymousSubmission(
      id: _uuid.v4(),
      type: type,
      description: description,
      location: location,
      contactMethod: contactMethod,
      contactInfo: contactInfo,
      urgencyLevel: urgencyLevel ?? 'medium',
      additionalData: additionalData ?? {},
      submittedAt: DateTime.now(),
      status: 'pending',
    );

    await _saveSubmission(submission);
    return submission.id;
  }

  // Save submission locally
  Future<void> _saveSubmission(AnonymousSubmission submission) async {
    final prefs = await SharedPreferences.getInstance();
    final submissions = await getAllSubmissions();
    submissions.add(submission);
    
    final submissionsJson = submissions.map((s) => s.toMap()).toList();
    await prefs.setString(_submissionsKey, jsonEncode(submissionsJson));
  }

  // Get all submissions
  Future<List<AnonymousSubmission>> getAllSubmissions() async {
    final prefs = await SharedPreferences.getInstance();
    final submissionsData = prefs.getString(_submissionsKey);
    
    if (submissionsData == null) return [];
    
    final List<dynamic> submissionsList = jsonDecode(submissionsData);
    return submissionsList
        .map((data) => AnonymousSubmission.fromMap(data))
        .toList();
  }

  // Get submissions by type
  Future<List<AnonymousSubmission>> getSubmissionsByType(String type) async {
    final allSubmissions = await getAllSubmissions();
    return allSubmissions.where((s) => s.type == type).toList();
  }

  // Quick emergency submission
  Future<String> submitEmergencyInfo({
    required String situation,
    String? location,
    String? safeContactMethod,
    bool isImmediate = false,
  }) async {
    return await submitAnonymousInformation(
      type: 'emergency_info',
      description: situation,
      location: location,
      contactMethod: safeContactMethod,
      urgencyLevel: isImmediate ? 'critical' : 'high',
      additionalData: {
        'is_immediate': isImmediate,
        'needs_immediate_response': isImmediate,
      },
    );
  }

  // Submit resource request
  Future<String> submitResourceRequest({
    required String resourceType,
    required String description,
    String? location,
    String? preferredContact,
    String? contactInfo,
  }) async {
    return await submitAnonymousInformation(
      type: 'resource_need',
      description: description,
      location: location,
      contactMethod: preferredContact,
      contactInfo: contactInfo,
      urgencyLevel: 'medium',
      additionalData: {
        'resource_type': resourceType,
      },
    );
  }

  // Submit general help request
  Future<String> submitHelpRequest({
    required String helpDescription,
    String? location,
    String? contactPreference,
    String? contactInfo,
    String? timeframe,
  }) async {
    return await submitAnonymousInformation(
      type: 'help_request',
      description: helpDescription,
      location: location,
      contactMethod: contactPreference,
      contactInfo: contactInfo,
      additionalData: {
        'timeframe': timeframe,
      },
    );
  }

  // Clear all submissions (for testing/reset)
  Future<void> clearAllSubmissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_submissionsKey);
  }

  // Get submission count
  Future<int> getSubmissionCount() async {
    final submissions = await getAllSubmissions();
    return submissions.length;
  }

  // Check if user has any pending submissions
  Future<bool> hasPendingSubmissions() async {
    final submissions = await getAllSubmissions();
    return submissions.any((s) => s.status == 'pending');
  }
}