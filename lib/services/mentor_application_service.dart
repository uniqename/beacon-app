import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// One SheBelongs mentor application, as stored in public.mentor_applications.
class MentorApplication {
  final String id;
  final DateTime createdAt;
  final String source; // website | app | paper
  final String status; // submitted | in_review | interview | approved | declined | withdrawn
  final String fullName;
  final String email;
  final String? phone;
  final String? city;
  final String? county;
  final bool age21Plus;
  final String? availability;
  final bool canCommitOneYear;
  final String? experience;
  final String? motivation;
  final String? referenceName;
  final String? referenceContact;
  final bool agreedBackgroundCheck;
  final bool agreedCodeOfConduct;
  final String? paperImagePath;
  final String? adminNotes;

  const MentorApplication({
    required this.id,
    required this.createdAt,
    required this.source,
    required this.status,
    required this.fullName,
    required this.email,
    this.phone,
    this.city,
    this.county,
    required this.age21Plus,
    this.availability,
    required this.canCommitOneYear,
    this.experience,
    this.motivation,
    this.referenceName,
    this.referenceContact,
    required this.agreedBackgroundCheck,
    required this.agreedCodeOfConduct,
    this.paperImagePath,
    this.adminNotes,
  });

  factory MentorApplication.fromMap(Map<String, dynamic> m) => MentorApplication(
        id: m['id'] as String,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        source: (m['source'] as String?) ?? 'website',
        status: (m['status'] as String?) ?? 'submitted',
        fullName: (m['full_name'] as String?) ?? '',
        email: (m['email'] as String?) ?? '',
        phone: m['phone'] as String?,
        city: m['city'] as String?,
        county: m['county'] as String?,
        age21Plus: (m['age_21_plus'] as bool?) ?? false,
        availability: m['availability'] as String?,
        canCommitOneYear: (m['can_commit_one_year'] as bool?) ?? false,
        experience: m['experience'] as String?,
        motivation: m['motivation'] as String?,
        referenceName: m['reference_name'] as String?,
        referenceContact: m['reference_contact'] as String?,
        agreedBackgroundCheck: (m['agreed_background_check'] as bool?) ?? false,
        agreedCodeOfConduct: (m['agreed_code_of_conduct'] as bool?) ?? false,
        paperImagePath: m['paper_image_path'] as String?,
        adminNotes: m['admin_notes'] as String?,
      );
}

/// Reads and writes mentor applications through Supabase.
/// Only signed-in admins (listed in admin_emails) can read or change rows;
/// the database enforces this, so this service only has to make the calls.
class MentorApplicationService {
  static const String table = 'mentor_applications';
  static const String paperBucket = 'mentor-paper-forms';

  static const statuses = [
    'submitted',
    'in_review',
    'interview',
    'approved',
    'declined',
    'withdrawn',
  ];

  /// Returns the Supabase client, initializing it from .env if needed.
  static Future<sb.SupabaseClient> _client() async {
    try {
      return sb.Supabase.instance.client;
    } catch (_) {
      final url = dotenv.env['SUPABASE_URL'] ?? '';
      final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      if (url.isEmpty || key.isEmpty) {
        throw StateError('Supabase is not configured in .env');
      }
      await sb.Supabase.initialize(url: url, anonKey: key);
      return sb.Supabase.instance.client;
    }
  }

  static bool get isSignedIn {
    try {
      return sb.Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  static String? get signedInEmail {
    try {
      return sb.Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  /// Signs an admin in with their Supabase account. Throws on failure.
  static Future<void> signIn(String email, String password) async {
    final client = await _client();
    await client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  static Future<void> signOut() async {
    final client = await _client();
    await client.auth.signOut();
  }

  static Future<List<MentorApplication>> list({String? status}) async {
    final client = await _client();
    dynamic query = client.from(table).select();
    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((r) => MentorApplication.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<void> updateStatus(String id, String status, {String? adminNotes}) async {
    final email = signedInEmail;
    final client = await _client();
    await client.from(table).update({
      'status': status,
      if (adminNotes != null) 'admin_notes': adminNotes,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'reviewed_by': email,
    }).eq('id', id);
  }

  /// Adds an application typed in from a paper form.
  static Future<void> addPaperApplication(Map<String, dynamic> fields) async {
    final client = await _client();
    await client.from(table).insert({
      ...fields,
      'source': 'paper',
      'status': 'submitted',
      'reviewed_by': signedInEmail,
    });
  }

  /// Uploads a photo of a paper form to the private bucket. Returns the storage path.
  static Future<String> uploadPaperPhoto(Uint8List bytes, {String extension = 'jpg'}) async {
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final path = 'paper/$stamp.$extension';
    final client = await _client();
    await client.storage.from(paperBucket).uploadBinary(
          path,
          bytes,
          fileOptions: sb.FileOptions(contentType: 'image/$extension', upsert: false),
        );
    return path;
  }

  /// Short-lived link to view a stored paper photo (one hour).
  static Future<String> paperPhotoUrl(String path) async {
    final client = await _client();
    final url = await client.storage.from(paperBucket).createSignedUrl(path, 3600);
    developer.log('Created signed URL for paper photo');
    return url;
  }
}
