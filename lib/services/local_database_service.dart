import 'dart:convert';
import 'dart:math' as math;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart';
import '../models/user.dart';
import '../models/case.dart';
import '../models/resource.dart';

class LocalDatabaseService {
  static Database? _database;
  static final _encrypter = Encrypter(AES(Key.fromSecureRandom(32)));
  static final _iv = IV.fromSecureRandom(16);

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'ngo_support.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Users table
        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            email TEXT,
            phone TEXT,
            encrypted_data TEXT,
            created_at TEXT,
            last_updated TEXT,
            is_anonymous INTEGER DEFAULT 1
          )
        ''');

        // Cases table for emergency submissions
        await db.execute('''
          CREATE TABLE cases(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            type TEXT,
            priority TEXT,
            status TEXT,
            encrypted_description TEXT,
            location_lat REAL,
            location_lng REAL,
            created_at TEXT,
            updated_at TEXT,
            is_anonymous INTEGER DEFAULT 1,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');

        // Resources table (local cache)
        await db.execute('''
          CREATE TABLE resources(
            id TEXT PRIMARY KEY,
            name TEXT,
            category TEXT,
            description TEXT,
            address TEXT,
            phone TEXT,
            email TEXT,
            website TEXT,
            latitude REAL,
            longitude REAL,
            availability_status TEXT,
            operating_hours TEXT,
            verified INTEGER DEFAULT 0,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        // Feedback table
        await db.execute('''
          CREATE TABLE feedback(
            id TEXT PRIMARY KEY,
            category TEXT,
            priority TEXT,
            usability_rating INTEGER,
            performance_rating INTEGER,
            design_rating INTEGER,
            encrypted_content TEXT,
            email TEXT,
            created_at TEXT,
            submitted INTEGER DEFAULT 0
          )
        ''');

        // Support groups table
        await db.execute('''
          CREATE TABLE support_groups(
            id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            category TEXT,
            meeting_schedule TEXT,
            contact_info TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT
          )
        ''');

        // Initialize with Ghana emergency resources
        await _insertInitialResources(db);
      },
    );
  }

  static Future<void> _insertInitialResources(Database db) async {
    final resources = [
      {
        'id': 'gh_emergency_999',
        'name': 'Ghana Emergency Services',
        'category': 'Emergency',
        'description': 'Police, Fire, and Medical Emergency Services',
        'phone': '999',
        'availability_status': 'available_24_7',
        'verified': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'gh_dv_hotline',
        'name': 'Domestic Violence Hotline',
        'category': 'Crisis Support',
        'description': '24/7 Support for domestic violence survivors',
        'phone': '0800800800',
        'availability_status': 'available_24_7',
        'verified': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'beacon_support',
        'name': 'Beacon of New Beginnings',
        'category': 'NGO Support',
        'description': 'Supporting survivors with hope and care',
        'phone': '+233123456789',
        'email': 'support@beaconnewbeginnings.org',
        'website': 'https://beaconnewbeginnings.org',
        'availability_status': 'available_business_hours',
        'operating_hours': 'Monday-Friday 8AM-6PM, Saturday 9AM-3PM',
        'verified': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      // Add more Ghana-specific resources
      {
        'id': 'ark_foundation',
        'name': 'ARK Foundation Ghana',
        'category': 'Shelter',
        'description': 'Safe shelter and support for women and children',
        'address': 'Accra, Ghana',
        'phone': '+233302123456',
        'email': 'info@arkfoundation.org.gh',
        'availability_status': 'available',
        'verified': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }
    ];

    for (var resource in resources) {
      await db.insert('resources', resource);
    }
  }

  // User management
  static Future<String> createAnonymousUser() async {
    final db = await database;
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    
    await db.insert('users', {
      'id': userId,
      'is_anonymous': 1,
      'created_at': DateTime.now().toIso8601String(),
      'last_updated': DateTime.now().toIso8601String(),
    });
    
    return userId;
  }

  static Future<void> saveUserData(String userId, Map<String, dynamic> userData) async {
    final db = await database;
    final encryptedData = _encryptData(jsonEncode(userData));
    
    await db.update(
      'users',
      {
        'encrypted_data': encryptedData,
        'last_updated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Case management
  static Future<String> createCase({
    required String userId,
    required String type,
    required String priority,
    required String description,
    double? latitude,
    double? longitude,
    bool isAnonymous = true,
  }) async {
    final db = await database;
    final caseId = DateTime.now().millisecondsSinceEpoch.toString();
    final encryptedDescription = _encryptData(description);
    
    await db.insert('cases', {
      'id': caseId,
      'user_id': userId,
      'type': type,
      'priority': priority,
      'status': 'submitted',
      'encrypted_description': encryptedDescription,
      'location_lat': latitude,
      'location_lng': longitude,
      'is_anonymous': isAnonymous ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    
    return caseId;
  }

  // Resource management
  static Future<List<Resource>> getResources({String? category}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    
    if (category != null) {
      maps = await db.query(
        'resources',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'verified DESC, name ASC',
      );
    } else {
      maps = await db.query(
        'resources',
        orderBy: 'verified DESC, category ASC, name ASC',
      );
    }
    
    return List.generate(maps.length, (i) {
      return Resource.fromMap(maps[i]);
    });
  }

  static Future<List<Resource>> getNearbyResources(
    double latitude,
    double longitude,
    {double radiusKm = 10.0, String? category}
  ) async {
    final db = await database;
    String whereClause = '(latitude IS NOT NULL AND longitude IS NOT NULL)';
    List<dynamic> whereArgs = [];
    
    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }
    
    final maps = await db.query(
      'resources',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'verified DESC',
    );
    
    List<Resource> resources = List.generate(maps.length, (i) {
      return Resource.fromMap(maps[i]);
    });
    
    // Filter by distance
    return resources.where((resource) {
      if (resource.latitude == null || resource.longitude == null) return false;
      final distance = _calculateDistance(
        latitude, longitude,
        resource.latitude!, resource.longitude!
      );
      return distance <= radiusKm;
    }).toList();
  }

  // Feedback management
  static Future<void> saveFeedback({
    required String category,
    required String priority,
    required int usabilityRating,
    required int performanceRating,
    required int designRating,
    required String content,
    String? email,
  }) async {
    final db = await database;
    final feedbackId = DateTime.now().millisecondsSinceEpoch.toString();
    final encryptedContent = _encryptData(content);
    
    await db.insert('feedback', {
      'id': feedbackId,
      'category': category,
      'priority': priority,
      'usability_rating': usabilityRating,
      'performance_rating': performanceRating,
      'design_rating': designRating,
      'encrypted_content': encryptedContent,
      'email': email,
      'created_at': DateTime.now().toIso8601String(),
      'submitted': 0,
    });
  }

  // Support groups
  static Future<List<Map<String, dynamic>>> getSupportGroups() async {
    final db = await database;
    return await db.query(
      'support_groups',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
  }

  // Utility methods
  static String _encryptData(String data) {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      // If encryption fails, store as base64 encoded
      return base64Encode(utf8.encode(data));
    }
  }

  static String _decryptData(String encryptedData) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      // If decryption fails, try base64 decode
      try {
        return utf8.decode(base64Decode(encryptedData));
      } catch (e) {
        return encryptedData; // Return as-is if all fails
      }
    }
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radiusEarth = 6371.0; // Earth's radius in km
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return radiusEarth * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Clean up sensitive data
  static Future<void> clearUserData(String userId) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
    await db.delete('cases', where: 'user_id = ?', whereArgs: [userId]);
  }

  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('cases');
    await db.delete('feedback');
  }
}

