import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:math' as math;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
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

    // Check if database exists and verify tables
    bool needsRecreation = false;
    try {
      final existingDb = await openDatabase(path);
      final tables = await existingDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='mood_entries'"
      );
      if (tables.isEmpty) {
        developer.log('⚠️ [Database] Critical tables missing, forcing recreation...');
        needsRecreation = true;
      }
      await existingDb.close();

      if (needsRecreation) {
        await deleteDatabase(path);
        developer.log('✅ [Database] Old database deleted');
      }
    } catch (e) {
      developer.log('ℹ️ [Database] No existing database found, creating new one');
    }

    return await openDatabase(
      path,
      version: 16,
      onCreate: (db, version) async {
        developer.log('🔨 [Database] Creating database v$version from scratch...');
        // Users table
        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            email TEXT,
            phone TEXT,
            display_name TEXT,
            user_type TEXT DEFAULT 'survivor',
            password_hash TEXT,
            encrypted_data TEXT,
            created_at TEXT,
            last_updated TEXT,
            is_anonymous INTEGER DEFAULT 1,
            emergency_contact TEXT,
            emergency_contact_phone TEXT,
            support_needs TEXT,
            current_location TEXT,
            has_active_cases INTEGER DEFAULT 0,
            specialization TEXT,
            qualifications TEXT,
            is_available INTEGER DEFAULT 1,
            admin_secret_validated INTEGER DEFAULT 0,
            approval_status TEXT DEFAULT 'approved',
            approval_notes TEXT,
            approved_by TEXT,
            approved_at TEXT
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

        // Support groups table (full schema — keep in sync with v8 migration)
        await db.execute('''
          CREATE TABLE support_groups(
            id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            category TEXT,
            meeting_schedule TEXT,
            contact_info TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT,
            type TEXT DEFAULT "general",
            privacy TEXT DEFAULT "public",
            facilitator_id TEXT,
            member_ids TEXT,
            moderator_ids TEXT,
            is_live INTEGER DEFAULT 0,
            guidelines TEXT,
            max_members INTEGER DEFAULT 50,
            tags TEXT,
            host_name TEXT,
            scheduled_time TEXT,
            last_activity_at TEXT,
            agora_channel_name TEXT
          )
        ''');

        // Beacon divisions table
        await db.execute('''
          CREATE TABLE beacon_divisions(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            short_name TEXT NOT NULL,
            description TEXT,
            icon TEXT DEFAULT "🏥",
            color TEXT DEFAULT "#2E8B57",
            contact_email TEXT,
            contact_phone TEXT,
            is_available INTEGER DEFAULT 1,
            capacity INTEGER DEFAULT 50,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        // Support group participants
        await db.execute('''
          CREATE TABLE IF NOT EXISTS support_group_participants(
            id TEXT PRIMARY KEY,
            group_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            role TEXT NOT NULL,
            joined_at TEXT NOT NULL,
            left_at TEXT,
            is_muted INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            FOREIGN KEY (group_id) REFERENCES support_groups (id) ON DELETE CASCADE,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        // Support group invitations
        await db.execute('''
          CREATE TABLE IF NOT EXISTS support_group_invitations(
            id TEXT PRIMARY KEY,
            group_id TEXT NOT NULL,
            inviter_id TEXT NOT NULL,
            invitee_id TEXT NOT NULL,
            status TEXT DEFAULT "pending",
            invited_at TEXT NOT NULL,
            responded_at TEXT,
            FOREIGN KEY (group_id) REFERENCES support_groups (id) ON DELETE CASCADE
          )
        ''');

        // Support group sessions
        await db.execute('''
          CREATE TABLE IF NOT EXISTS support_group_sessions(
            id TEXT PRIMARY KEY,
            group_id TEXT NOT NULL,
            agora_channel_name TEXT NOT NULL,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            facilitator_id TEXT NOT NULL,
            total_participants INTEGER DEFAULT 0,
            max_concurrent_participants INTEGER DEFAULT 0,
            duration_minutes INTEGER,
            FOREIGN KEY (group_id) REFERENCES support_groups (id) ON DELETE CASCADE
          )
        ''');

        // Support group reports
        await db.execute('''
          CREATE TABLE IF NOT EXISTS support_group_reports(
            id TEXT PRIMARY KEY,
            group_id TEXT NOT NULL,
            session_id TEXT,
            reporter_id TEXT NOT NULL,
            reported_user_id TEXT,
            reason TEXT NOT NULL,
            description TEXT,
            status TEXT DEFAULT "pending",
            created_at TEXT NOT NULL,
            reviewed_by TEXT,
            reviewed_at TEXT,
            resolution_notes TEXT,
            FOREIGN KEY (group_id) REFERENCES support_groups (id)
          )
        ''');

        // Safety plans table
        await db.execute('''
          CREATE TABLE safety_plans(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            emergency_contacts TEXT,
            safe_places TEXT,
            escape_plan TEXT,
            essential_items TEXT,
            code_words TEXT,
            children_safety TEXT,
            pet_safety TEXT,
            financial_safety TEXT,
            digital_safety TEXT,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');

        // Evidence logs table
        await db.execute('''
          CREATE TABLE evidence_logs(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            date TEXT,
            incident_type TEXT,
            description TEXT,
            location TEXT,
            witnesses TEXT,
            injuries TEXT,
            police_report_number TEXT,
            hospital_name TEXT,
            photos TEXT,
            audio TEXT,
            created_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');

        // Mood entries table
        await db.execute('''
          CREATE TABLE mood_entries(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            date TEXT,
            mood_rating INTEGER,
            triggers TEXT,
            notes TEXT,
            created_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');

        // Budget transactions table
        await db.execute('''
          CREATE TABLE budget_transactions(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            date TEXT,
            amount REAL,
            category TEXT,
            description TEXT,
            is_income INTEGER DEFAULT 0,
            is_hidden INTEGER DEFAULT 0,
            created_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');

        // Secure documents table
        await db.execute('''
          CREATE TABLE secure_documents(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            title TEXT,
            category TEXT,
            file_path TEXT,
            is_encrypted INTEGER DEFAULT 1,
            uploaded_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');

        // Chat messages table
        await db.execute('''
          CREATE TABLE chat_messages(
            id TEXT PRIMARY KEY,
            conversation_id TEXT,
            sender_id TEXT,
            sender_type TEXT DEFAULT 'user',
            message TEXT,
            timestamp TEXT,
            is_encrypted INTEGER DEFAULT 1,
            is_read INTEGER DEFAULT 0,
            is_ai_response INTEGER DEFAULT 0
          )
        ''');

        // Conversations table for chat management
        await db.execute('''
          CREATE TABLE conversations(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            status TEXT DEFAULT 'active',
            escalated_to_human INTEGER DEFAULT 0,
            escalation_timestamp TEXT,
            last_response_timestamp TEXT,
            created_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');

        // Inquiry tickets table for escalated cases
        await db.execute('''
          CREATE TABLE inquiry_tickets(
            id TEXT PRIMARY KEY,
            conversation_id TEXT,
            user_id TEXT,
            subject TEXT,
            description TEXT,
            priority TEXT DEFAULT 'medium',
            status TEXT DEFAULT 'pending',
            created_at TEXT,
            assigned_to TEXT,
            resolved_at TEXT,
            FOREIGN KEY (conversation_id) REFERENCES conversations (id),
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');

        // Email notifications table
        await db.execute('''
          CREATE TABLE email_notifications(
            id TEXT PRIMARY KEY,
            inquiry_id TEXT,
            recipient_email TEXT,
            subject TEXT,
            body TEXT,
            sent INTEGER DEFAULT 0,
            sent_at TEXT,
            created_at TEXT,
            FOREIGN KEY (inquiry_id) REFERENCES inquiry_tickets (id)
          )
        ''');

        // Disguise settings table
        await db.execute('''
          CREATE TABLE disguise_settings(
            user_id TEXT PRIMARY KEY,
            passcode TEXT,
            disguise_type TEXT DEFAULT 'calculator',
            is_enabled INTEGER DEFAULT 1,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');

        // Helper applications table (for counselor/volunteer approval)
        await db.execute('''
          CREATE TABLE helper_applications(
            id TEXT PRIMARY KEY,
            user_id TEXT UNIQUE,
            experience_description TEXT,
            joining_reason TEXT,
            services_offered TEXT,
            certificate_path TEXT,
            id_document_path TEXT,
            additional_docs_paths TEXT,
            submitted_at TEXT,
            reviewed_at TEXT,
            reviewed_by TEXT,
            review_notes TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id)
          )
        ''');

        // Donations table
        await db.execute('''
          CREATE TABLE donations(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            division_id TEXT,
            amount REAL NOT NULL,
            currency TEXT NOT NULL,
            frequency TEXT NOT NULL,
            payment_method TEXT NOT NULL,
            payment_gateway TEXT,
            transaction_id TEXT UNIQUE,
            status TEXT DEFAULT 'pending',
            donor_name TEXT,
            donor_email TEXT,
            donor_phone TEXT,
            is_anonymous INTEGER DEFAULT 0,
            is_recurring INTEGER DEFAULT 0,
            next_billing_date TEXT,
            created_at TEXT NOT NULL,
            completed_at TEXT,
            receipt_url TEXT,
            metadata TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
          )
        ''');

        await db.execute('CREATE INDEX idx_donations_user ON donations(user_id)');
        await db.execute('CREATE INDEX idx_donations_status ON donations(status)');
        await db.execute('CREATE INDEX idx_donations_transaction ON donations(transaction_id)');
        await db.execute('CREATE INDEX idx_donations_date ON donations(created_at)');

        // Donation receipts table
        await db.execute('''
          CREATE TABLE donation_receipts(
            id TEXT PRIMARY KEY,
            donation_id TEXT NOT NULL,
            receipt_number TEXT UNIQUE NOT NULL,
            generated_at TEXT NOT NULL,
            file_path TEXT,
            email_sent INTEGER DEFAULT 0,
            email_sent_at TEXT,
            FOREIGN KEY (donation_id) REFERENCES donations (id) ON DELETE CASCADE
          )
        ''');

        // Recurring donations table
        await db.execute('''
          CREATE TABLE recurring_donations(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            division_id TEXT,
            amount REAL NOT NULL,
            currency TEXT NOT NULL,
            payment_method TEXT NOT NULL,
            gateway_subscription_id TEXT,
            status TEXT DEFAULT 'active',
            start_date TEXT NOT NULL,
            next_billing_date TEXT,
            last_payment_date TEXT,
            last_payment_id TEXT,
            total_payments_count INTEGER DEFAULT 0,
            donor_name TEXT,
            donor_email TEXT,
            is_anonymous INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL,
            FOREIGN KEY (last_payment_id) REFERENCES donations (id)
          )
        ''');

        // v12: Content management tables
        await db.execute('''
          CREATE TABLE IF NOT EXISTS job_postings(
            id TEXT PRIMARY KEY, title TEXT NOT NULL, type TEXT DEFAULT 'volunteer',
            description TEXT, requirements TEXT, location TEXT, is_remote INTEGER DEFAULT 0,
            application_email TEXT, posted_at TEXT, is_urgent INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS job_applications(
            id TEXT PRIMARY KEY, job_id TEXT, job_title TEXT,
            applicant_name TEXT, applicant_email TEXT, applicant_phone TEXT,
            cover_letter TEXT, resume_path TEXT, ghana_card_path TEXT,
            applied_at TEXT NOT NULL, status TEXT DEFAULT 'pending'
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS events(
            id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT,
            event_date TEXT, location TEXT, is_online INTEGER DEFAULT 0,
            meeting_link TEXT, max_attendees INTEGER DEFAULT 0,
            created_at TEXT, is_active INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS event_rsvps(
            id TEXT PRIMARY KEY, event_id TEXT, user_id TEXT,
            rsvped_at TEXT, status TEXT DEFAULT 'attending'
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS devotionals(
            id TEXT PRIMARY KEY, title TEXT NOT NULL, content TEXT,
            scripture TEXT, author TEXT, published_at TEXT, is_active INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS shelters(
            id TEXT PRIMARY KEY, name TEXT NOT NULL, address TEXT, city TEXT,
            phone TEXT, capacity INTEGER DEFAULT 0, services TEXT,
            is_active INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS bible_verses(
            id TEXT PRIMARY KEY, verse TEXT NOT NULL, reference TEXT,
            category TEXT, display_date TEXT, is_active INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS volunteer_shifts_v2(
            id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT,
            shift_date TEXT, start_time TEXT, end_time TEXT,
            location TEXT, spots_available INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS peer_mentors_v2(
            id TEXT PRIMARY KEY, name TEXT NOT NULL, bio TEXT,
            specialization TEXT, contact_email TEXT, contact_phone TEXT,
            is_available INTEGER DEFAULT 1, created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS service_providers(
            id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT,
            description TEXT, address TEXT, phone TEXT, email TEXT,
            hours TEXT, is_active INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS quizzes(
            id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT,
            category TEXT, questions TEXT, created_at TEXT,
            is_active INTEGER DEFAULT 1
          )
        ''');

        // v13: Daily engagement tables
        await db.execute('''
          CREATE TABLE IF NOT EXISTS daily_streaks(
            user_id TEXT PRIMARY KEY,
            current_streak INTEGER DEFAULT 0,
            longest_streak INTEGER DEFAULT 0,
            last_checkin_date TEXT,
            total_checkins INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS selfcare_entries(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            date TEXT,
            completed_items TEXT,
            score INTEGER DEFAULT 0,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS journal_entries(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            date TEXT,
            title TEXT,
            content TEXT,
            mood_before INTEGER DEFAULT 5,
            mood_after INTEGER DEFAULT 5,
            has_voice_note INTEGER DEFAULT 0,
            voice_note_path TEXT,
            created_at TEXT
          )
        ''');

        // v14: Case management tables
        await db.execute('''
          CREATE TABLE IF NOT EXISTS client_intakes(
            id TEXT PRIMARY KEY,
            client_name TEXT NOT NULL,
            client_phone TEXT,
            client_id TEXT,
            case_manager_id TEXT NOT NULL,
            case_manager_name TEXT NOT NULL,
            intake_date TEXT NOT NULL,
            presenting_situation TEXT,
            needs_identified TEXT,
            emergency_support_desc TEXT,
            emergency_support_amount REAL,
            currency TEXT DEFAULT 'GHC',
            status TEXT DEFAULT 'active',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS case_plans(
            id TEXT PRIMARY KEY,
            intake_id TEXT NOT NULL,
            client_name TEXT NOT NULL,
            client_id TEXT,
            case_manager_id TEXT NOT NULL,
            case_manager_name TEXT NOT NULL,
            plan_status TEXT DEFAULT 'active',
            next_review_date TEXT,
            review_frequency TEXT DEFAULT 'quarterly',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (intake_id) REFERENCES client_intakes (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS case_programs(
            id TEXT PRIMARY KEY,
            case_plan_id TEXT NOT NULL,
            program_number INTEGER DEFAULT 0,
            program_name TEXT NOT NULL,
            goal TEXT,
            current_status_notes TEXT,
            priority TEXT DEFAULT 'medium',
            deadline_label TEXT,
            deadline_date TEXT,
            actions TEXT,
            is_completed INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (case_plan_id) REFERENCES case_plans (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS case_notes(
            id TEXT PRIMARY KEY,
            case_plan_id TEXT NOT NULL,
            case_program_id TEXT,
            note_text TEXT NOT NULL,
            created_by TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (case_plan_id) REFERENCES case_plans (id)
          )
        ''');

        // v15: Pending sync queue — stores records that failed to reach Supabase
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pending_syncs(
            id TEXT PRIMARY KEY,
            table_name TEXT NOT NULL,
            record_id TEXT NOT NULL,
            operation TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0,
            last_error TEXT
          )
        ''');

        // Initialize with Ghana emergency resources
        await _insertInitialResources(db);

        // Create demo accounts for Apple App Review
        await _insertDemoAccounts(db);

        // Seed Abigail's program plan as the first template case
        await _seedAbigailCase(db);

        developer.log('✅ [Database] All tables created successfully for v$version');
      },
      onOpen: (db) async {
        // Always re-seed demo/reviewer accounts so they survive app data clears
        // and are never missing regardless of which migration path ran.
        await _insertDemoAccounts(db);
        // Seed Abigail's case plan on every open (uses IGNORE so live edits are preserved)
        await _seedAbigailCase(db);
        developer.log('✅ [Database] Demo accounts and seed case refreshed on open');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        developer.log('🔄 [Database] Upgrading from v$oldVersion to v$newVersion...');
        // Migrate from version 1 to version 2
        if (oldVersion < 2) {
          // Add new tables for version 2

          // Safety plans table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS safety_plans(
              id TEXT PRIMARY KEY,
              user_id TEXT,
              emergency_contacts TEXT,
              safe_places TEXT,
              escape_plan TEXT,
              essential_items TEXT,
              code_words TEXT,
              children_safety TEXT,
              pet_safety TEXT,
              financial_safety TEXT,
              digital_safety TEXT,
              created_at TEXT,
              updated_at TEXT,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');

          // Evidence logs table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS evidence_logs(
              id TEXT PRIMARY KEY,
              user_id TEXT,
              date TEXT,
              incident_type TEXT,
              description TEXT,
              location TEXT,
              witnesses TEXT,
              injuries TEXT,
              police_report_number TEXT,
              hospital_name TEXT,
              photos TEXT,
              audio TEXT,
              created_at TEXT,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');

          // Mood entries table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS mood_entries(
              id TEXT PRIMARY KEY,
              user_id TEXT,
              date TEXT,
              mood_rating INTEGER,
              triggers TEXT,
              notes TEXT,
              created_at TEXT,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');

          // Budget transactions table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS budget_transactions(
              id TEXT PRIMARY KEY,
              user_id TEXT,
              date TEXT,
              amount REAL,
              category TEXT,
              description TEXT,
              is_income INTEGER DEFAULT 0,
              is_hidden INTEGER DEFAULT 0,
              created_at TEXT,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');

          // Secure documents table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS secure_documents(
              id TEXT PRIMARY KEY,
              user_id TEXT,
              title TEXT,
              category TEXT,
              file_path TEXT,
              is_encrypted INTEGER DEFAULT 1,
              uploaded_at TEXT,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');

          // Chat messages table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS chat_messages(
              id TEXT PRIMARY KEY,
              conversation_id TEXT,
              sender_id TEXT,
              message TEXT,
              timestamp TEXT,
              is_encrypted INTEGER DEFAULT 1,
              is_read INTEGER DEFAULT 0
            )
          ''');

          // Disguise settings table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS disguise_settings(
              user_id TEXT PRIMARY KEY,
              passcode TEXT,
              disguise_type TEXT DEFAULT 'calculator',
              is_enabled INTEGER DEFAULT 1,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');

          // Helper applications table (for counselor/volunteer approval)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS helper_applications(
              id TEXT PRIMARY KEY,
              user_id TEXT UNIQUE,
              experience_description TEXT,
              joining_reason TEXT,
              services_offered TEXT,
              certificate_path TEXT,
              id_document_path TEXT,
              additional_docs_paths TEXT,
              submitted_at TEXT,
              reviewed_at TEXT,
              reviewed_by TEXT,
              review_notes TEXT,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');
        }

        // Migrate from version 2 to version 3
        if (oldVersion < 3) {
          // Add new columns to chat_messages table
          try {
            await db.execute('ALTER TABLE chat_messages ADD COLUMN sender_type TEXT DEFAULT "user"');
          } catch (e) {
            developer.log('⚠️ [Database] sender_type column might already exist: $e');
          }
          try {
            await db.execute('ALTER TABLE chat_messages ADD COLUMN is_ai_response INTEGER DEFAULT 0');
          } catch (e) {
            developer.log('⚠️ [Database] is_ai_response column might already exist: $e');
          }

          // Conversations table for chat management
          await db.execute('''
            CREATE TABLE IF NOT EXISTS conversations(
              id TEXT PRIMARY KEY,
              user_id TEXT,
              status TEXT DEFAULT 'active',
              escalated_to_human INTEGER DEFAULT 0,
              escalation_timestamp TEXT,
              last_response_timestamp TEXT,
              created_at TEXT,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');

          // Inquiry tickets table for escalated cases
          await db.execute('''
            CREATE TABLE IF NOT EXISTS inquiry_tickets(
              id TEXT PRIMARY KEY,
              conversation_id TEXT,
              user_id TEXT,
              subject TEXT,
              description TEXT,
              priority TEXT DEFAULT 'medium',
              status TEXT DEFAULT 'pending',
              created_at TEXT,
              assigned_to TEXT,
              resolved_at TEXT,
              FOREIGN KEY (conversation_id) REFERENCES conversations (id),
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');

          // Email notifications table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS email_notifications(
              id TEXT PRIMARY KEY,
              inquiry_id TEXT,
              recipient_email TEXT,
              subject TEXT,
              body TEXT,
              sent INTEGER DEFAULT 0,
              sent_at TEXT,
              created_at TEXT,
              FOREIGN KEY (inquiry_id) REFERENCES inquiry_tickets (id)
            )
          ''');
        }

        // Migrate from version 3 to version 4
        if (oldVersion < 4) {
          developer.log('🔄 [Database] Migrating to v4 - Ensuring all columns exist...');

          // Ensure chat_messages has all required columns
          try {
            final result = await db.rawQuery('PRAGMA table_info(chat_messages)');
            final columns = result.map((col) => col['name'] as String).toSet();

            if (!columns.contains('sender_type')) {
              await db.execute('ALTER TABLE chat_messages ADD COLUMN sender_type TEXT DEFAULT "user"');
              developer.log('✅ [Database] Added sender_type column');
            }
            if (!columns.contains('is_ai_response')) {
              await db.execute('ALTER TABLE chat_messages ADD COLUMN is_ai_response INTEGER DEFAULT 0');
              developer.log('✅ [Database] Added is_ai_response column');
            }
          } catch (e) {
            developer.log('❌ [Database] Error checking/adding columns: $e');
          }
        }

        // Migrate from version 4 to version 5
        if (oldVersion < 5) {
          developer.log('🔄 [Database] Migrating to v5 - Adding authentication columns...');

          // Add authentication and user management columns to users table
          try {
            final result = await db.rawQuery('PRAGMA table_info(users)');
            final columns = result.map((col) => col['name'] as String).toSet();

            if (!columns.contains('display_name')) {
              await db.execute('ALTER TABLE users ADD COLUMN display_name TEXT');
              developer.log('✅ [Database] Added display_name column');
            }
            if (!columns.contains('user_type')) {
              await db.execute('ALTER TABLE users ADD COLUMN user_type TEXT DEFAULT "survivor"');
              developer.log('✅ [Database] Added user_type column');
            }
            if (!columns.contains('password_hash')) {
              await db.execute('ALTER TABLE users ADD COLUMN password_hash TEXT');
              developer.log('✅ [Database] Added password_hash column');
            }
            if (!columns.contains('emergency_contact')) {
              await db.execute('ALTER TABLE users ADD COLUMN emergency_contact TEXT');
              developer.log('✅ [Database] Added emergency_contact column');
            }
            if (!columns.contains('emergency_contact_phone')) {
              await db.execute('ALTER TABLE users ADD COLUMN emergency_contact_phone TEXT');
              developer.log('✅ [Database] Added emergency_contact_phone column');
            }
            if (!columns.contains('admin_secret_validated')) {
              await db.execute('ALTER TABLE users ADD COLUMN admin_secret_validated INTEGER DEFAULT 0');
              developer.log('✅ [Database] Added admin_secret_validated column');
            }
            developer.log('✅ [Database] v5 migration completed');
          } catch (e) {
            developer.log('❌ [Database] Error migrating to v5: $e');
          }
        }

        // Migrate from version 5 to version 6
        if (oldVersion < 6) {
          developer.log('🔄 [Database] Migrating to v6 - Adding helper approval system...');

          // Add approval status columns to users table
          try {
            final result = await db.rawQuery('PRAGMA table_info(users)');
            final columns = result.map((col) => col['name'] as String).toSet();

            if (!columns.contains('approval_status')) {
              await db.execute('ALTER TABLE users ADD COLUMN approval_status TEXT DEFAULT "approved"');
              developer.log('✅ [Database] Added approval_status column');
            }
            if (!columns.contains('approval_notes')) {
              await db.execute('ALTER TABLE users ADD COLUMN approval_notes TEXT');
              developer.log('✅ [Database] Added approval_notes column');
            }
            if (!columns.contains('approved_by')) {
              await db.execute('ALTER TABLE users ADD COLUMN approved_by TEXT');
              developer.log('✅ [Database] Added approved_by column');
            }
            if (!columns.contains('approved_at')) {
              await db.execute('ALTER TABLE users ADD COLUMN approved_at TEXT');
              developer.log('✅ [Database] Added approved_at column');
            }

            // Create helper_applications table
            await db.execute('''
              CREATE TABLE IF NOT EXISTS helper_applications(
                id TEXT PRIMARY KEY,
                user_id TEXT UNIQUE,
                experience_description TEXT,
                joining_reason TEXT,
                services_offered TEXT,
                certificate_path TEXT,
                id_document_path TEXT,
                additional_docs_paths TEXT,
                submitted_at TEXT,
                reviewed_at TEXT,
                reviewed_by TEXT,
                review_notes TEXT,
                FOREIGN KEY (user_id) REFERENCES users (id)
              )
            ''');
            developer.log('✅ [Database] Created helper_applications table');

            // Update existing counselor/volunteer users to 'pending' status
            await db.execute('''
              UPDATE users
              SET approval_status = 'pending'
              WHERE user_type IN ('counselor', 'volunteer')
              AND approval_status = 'approved'
            ''');
            developer.log('✅ [Database] Set existing helpers to pending approval');

            developer.log('✅ [Database] v6 migration completed');
          } catch (e) {
            developer.log('❌ [Database] Error migrating to v6: $e');
          }
        }

        // Migrate from version 6 to version 7
        if (oldVersion < 7) {
          developer.log('🔄 [Database] Migrating to v7 - Adding user profile columns...');

          // Add missing user profile columns
          try {
            final result = await db.rawQuery('PRAGMA table_info(users)');
            final columns = result.map((col) => col['name'] as String).toSet();

            if (!columns.contains('support_needs')) {
              await db.execute('ALTER TABLE users ADD COLUMN support_needs TEXT');
              developer.log('✅ [Database] Added support_needs column');
            }
            if (!columns.contains('current_location')) {
              await db.execute('ALTER TABLE users ADD COLUMN current_location TEXT');
              developer.log('✅ [Database] Added current_location column');
            }
            if (!columns.contains('has_active_cases')) {
              await db.execute('ALTER TABLE users ADD COLUMN has_active_cases INTEGER DEFAULT 0');
              developer.log('✅ [Database] Added has_active_cases column');
            }
            if (!columns.contains('specialization')) {
              await db.execute('ALTER TABLE users ADD COLUMN specialization TEXT');
              developer.log('✅ [Database] Added specialization column');
            }
            if (!columns.contains('qualifications')) {
              await db.execute('ALTER TABLE users ADD COLUMN qualifications TEXT');
              developer.log('✅ [Database] Added qualifications column');
            }
            if (!columns.contains('is_available')) {
              await db.execute('ALTER TABLE users ADD COLUMN is_available INTEGER DEFAULT 1');
              developer.log('✅ [Database] Added is_available column');
            }

            developer.log('✅ [Database] v7 migration completed');
          } catch (e) {
            developer.log('❌ [Database] Error migrating to v7: $e');
          }
        }

        // Migrate from version 7 to version 8
        if (oldVersion < 8) {
          developer.log('🔄 [Database] Migrating to v8 - Adding support groups real-time features...');

          try {
            // Check existing support_groups columns
            final result = await db.rawQuery('PRAGMA table_info(support_groups)');
            final columns = result.map((col) => col['name'] as String).toSet();

            // Extend support_groups table with missing fields
            if (!columns.contains('type')) {
              await db.execute('ALTER TABLE support_groups ADD COLUMN type TEXT DEFAULT "general"');
              developer.log('✅ [Database] Added type column');
            }
            if (!columns.contains('privacy')) {
              await db.execute('ALTER TABLE support_groups ADD COLUMN privacy TEXT DEFAULT "public"');
              developer.log('✅ [Database] Added privacy column');
            }
            if (!columns.contains('facilitator_id')) {
              await db.execute('ALTER TABLE support_groups ADD COLUMN facilitator_id TEXT');
              developer.log('✅ [Database] Added facilitator_id column');
            }
            if (!columns.contains('member_ids')) {
              await db.execute('ALTER TABLE support_groups ADD COLUMN member_ids TEXT');
              developer.log('✅ [Database] Added member_ids column');
            }
            if (!columns.contains('moderator_ids')) {
              await db.execute('ALTER TABLE support_groups ADD COLUMN moderator_ids TEXT');
              developer.log('✅ [Database] Added moderator_ids column');
            }
            if (!columns.contains('is_live')) {
              await db.execute('ALTER TABLE support_groups ADD COLUMN is_live INTEGER DEFAULT 0');
              developer.log('✅ [Database] Added is_live column');
            }
            if (!columns.contains('guidelines')) {
              await db.execute('ALTER TABLE support_groups ADD COLUMN guidelines TEXT');
              developer.log('✅ [Database] Added guidelines column');
            }
            if (!columns.contains('max_members')) {
              await db.execute('ALTER TABLE support_groups ADD COLUMN max_members INTEGER DEFAULT 50');
              developer.log('✅ [Database] Added max_members column');
            }
            if (!columns.contains('tags')) {
              await db.execute('ALTER TABLE support_groups ADD COLUMN tags TEXT');
              developer.log('✅ [Database] Added tags column');
            }
            if (!columns.contains('host_name')) {
              await db.execute('ALTER TABLE support_groups ADD COLUMN host_name TEXT');
              developer.log('✅ [Database] Added host_name column');
            }
            if (!columns.contains('scheduled_time')) {
              await db.execute('ALTER TABLE support_groups ADD COLUMN scheduled_time TEXT');
              developer.log('✅ [Database] Added scheduled_time column');
            }
            if (!columns.contains('last_activity_at')) {
              await db.execute('ALTER TABLE support_groups ADD COLUMN last_activity_at TEXT');
              developer.log('✅ [Database] Added last_activity_at column');
            }
            if (!columns.contains('agora_channel_name')) {
              await db.execute('ALTER TABLE support_groups ADD COLUMN agora_channel_name TEXT');
              developer.log('✅ [Database] Added agora_channel_name column');
            }

            // Create support_group_participants table
            await db.execute('''
              CREATE TABLE IF NOT EXISTS support_group_participants(
                id TEXT PRIMARY KEY,
                group_id TEXT NOT NULL,
                user_id TEXT NOT NULL,
                role TEXT NOT NULL,
                joined_at TEXT NOT NULL,
                left_at TEXT,
                is_muted INTEGER DEFAULT 0,
                is_active INTEGER DEFAULT 1,
                FOREIGN KEY (group_id) REFERENCES support_groups (id) ON DELETE CASCADE,
                FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
              )
            ''');
            developer.log('✅ [Database] Created support_group_participants table');

            // Create support_group_invitations table
            await db.execute('''
              CREATE TABLE IF NOT EXISTS support_group_invitations(
                id TEXT PRIMARY KEY,
                group_id TEXT NOT NULL,
                inviter_id TEXT NOT NULL,
                invitee_id TEXT NOT NULL,
                status TEXT DEFAULT 'pending',
                invited_at TEXT NOT NULL,
                responded_at TEXT,
                FOREIGN KEY (group_id) REFERENCES support_groups (id) ON DELETE CASCADE
              )
            ''');
            developer.log('✅ [Database] Created support_group_invitations table');

            // Create support_group_sessions table
            await db.execute('''
              CREATE TABLE IF NOT EXISTS support_group_sessions(
                id TEXT PRIMARY KEY,
                group_id TEXT NOT NULL,
                agora_channel_name TEXT NOT NULL,
                started_at TEXT NOT NULL,
                ended_at TEXT,
                facilitator_id TEXT NOT NULL,
                total_participants INTEGER DEFAULT 0,
                max_concurrent_participants INTEGER DEFAULT 0,
                duration_minutes INTEGER,
                FOREIGN KEY (group_id) REFERENCES support_groups (id) ON DELETE CASCADE
              )
            ''');
            developer.log('✅ [Database] Created support_group_sessions table');

            // Create support_group_reports table (for safety)
            await db.execute('''
              CREATE TABLE IF NOT EXISTS support_group_reports(
                id TEXT PRIMARY KEY,
                group_id TEXT NOT NULL,
                session_id TEXT,
                reporter_id TEXT NOT NULL,
                reported_user_id TEXT,
                reason TEXT NOT NULL,
                description TEXT,
                status TEXT DEFAULT 'pending',
                created_at TEXT NOT NULL,
                reviewed_by TEXT,
                reviewed_at TEXT,
                resolution_notes TEXT,
                FOREIGN KEY (group_id) REFERENCES support_groups (id)
              )
            ''');
            developer.log('✅ [Database] Created support_group_reports table');

            // Create indexes for better performance
            await db.execute('''
              CREATE INDEX IF NOT EXISTS idx_support_groups_is_live
              ON support_groups(is_live)
            ''');
            await db.execute('''
              CREATE INDEX IF NOT EXISTS idx_support_groups_facilitator
              ON support_groups(facilitator_id)
            ''');
            await db.execute('''
              CREATE INDEX IF NOT EXISTS idx_participants_group
              ON support_group_participants(group_id, is_active)
            ''');
            await db.execute('''
              CREATE INDEX IF NOT EXISTS idx_invitations_invitee
              ON support_group_invitations(invitee_id, status)
            ''');
            await db.execute('''
              CREATE INDEX IF NOT EXISTS idx_sessions_group
              ON support_group_sessions(group_id)
            ''');
            await db.execute('''
              CREATE INDEX IF NOT EXISTS idx_reports_status
              ON support_group_reports(status)
            ''');
            developer.log('✅ [Database] Created indexes for support groups');

            developer.log('✅ [Database] v8 migration completed');
          } catch (e) {
            developer.log('❌ [Database] Error migrating to v8: $e');
          }
        }

        // Migrate from version 8 to version 9
        if (oldVersion < 9) {
          developer.log('🔄 [Database] Migrating to v9 - Adding donations and payment features...');

          try {
            // Create donations table
            await db.execute('''
              CREATE TABLE IF NOT EXISTS donations(
                id TEXT PRIMARY KEY,
                user_id TEXT,
                division_id TEXT,
                amount REAL NOT NULL,
                currency TEXT NOT NULL,
                frequency TEXT NOT NULL,
                payment_method TEXT NOT NULL,
                payment_gateway TEXT,
                transaction_id TEXT UNIQUE,
                status TEXT DEFAULT 'pending',
                donor_name TEXT,
                donor_email TEXT,
                donor_phone TEXT,
                is_anonymous INTEGER DEFAULT 0,
                is_recurring INTEGER DEFAULT 0,
                next_billing_date TEXT,
                created_at TEXT NOT NULL,
                completed_at TEXT,
                receipt_url TEXT,
                metadata TEXT,
                FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
              )
            ''');

            // Create indexes for donations table
            await db.execute('CREATE INDEX IF NOT EXISTS idx_donations_user ON donations(user_id)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_donations_status ON donations(status)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_donations_transaction ON donations(transaction_id)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_donations_date ON donations(created_at)');

            // Create donation_receipts table
            await db.execute('''
              CREATE TABLE IF NOT EXISTS donation_receipts(
                id TEXT PRIMARY KEY,
                donation_id TEXT NOT NULL,
                receipt_number TEXT UNIQUE NOT NULL,
                generated_at TEXT NOT NULL,
                file_path TEXT,
                email_sent INTEGER DEFAULT 0,
                email_sent_at TEXT,
                FOREIGN KEY (donation_id) REFERENCES donations (id) ON DELETE CASCADE
              )
            ''');

            // Create recurring_donations table
            await db.execute('''
              CREATE TABLE IF NOT EXISTS recurring_donations(
                id TEXT PRIMARY KEY,
                user_id TEXT,
                division_id TEXT,
                amount REAL NOT NULL,
                currency TEXT NOT NULL,
                payment_method TEXT NOT NULL,
                gateway_subscription_id TEXT,
                status TEXT DEFAULT 'active',
                start_date TEXT NOT NULL,
                next_billing_date TEXT,
                last_payment_date TEXT,
                last_payment_id TEXT,
                total_payments_count INTEGER DEFAULT 0,
                donor_name TEXT,
                donor_email TEXT,
                is_anonymous INTEGER DEFAULT 0,
                created_at TEXT NOT NULL,
                FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL,
                FOREIGN KEY (last_payment_id) REFERENCES donations (id)
              )
            ''');

            developer.log('✅ [Database] v9 migration completed - Donation tables added');
          } catch (e) {
            developer.log('❌ [Database] Error migrating to v9: $e');
          }
        }

        // Migrate to version 10 - Add demo accounts for Apple App Review
        if (oldVersion < 10) {
          try {
            await _insertDemoAccounts(db);
            developer.log('✅ [Database] v10 migration completed - Demo accounts added');
          } catch (e) {
            developer.log('❌ [Database] Error migrating to v10: $e');
          }
        }

        // Migrate to version 11 - Add demo admin account + divisions table
        if (oldVersion < 11) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS beacon_divisions(
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                short_name TEXT NOT NULL,
                description TEXT,
                icon TEXT DEFAULT "🏥",
                color TEXT DEFAULT "#2E8B57",
                contact_email TEXT,
                contact_phone TEXT,
                is_available INTEGER DEFAULT 1,
                capacity INTEGER DEFAULT 50,
                created_at TEXT,
                updated_at TEXT
              )
            ''');
            developer.log('✅ [Database] v11 divisions table created');
          } catch (e) {
            developer.log('❌ [Database] Error creating divisions table: $e');
          }
        }

        // Migrate to version 11 - Add demo admin account
        if (oldVersion < 11) {
          try {
            String hashPassword(String password) {
              final bytes = utf8.encode('${password}ngo_support_salt');
              return sha256.convert(bytes).toString();
            }
            final now = DateTime.now().toIso8601String();
            await db.insert('users', {
              'id': 'demo_admin_enam',
              'email': 'admin@beaconnewbeginnings.org',
              'display_name': 'Beacon Admin',
              'password_hash': hashPassword('BeaconAdmin2025!'),
              'user_type': 'admin',
              'is_anonymous': 0,
              'approval_status': 'approved',
              'is_available': 1,
              'admin_secret_validated': 1,
              'created_at': now,
              'last_updated': now,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
            developer.log('✅ [Database] v11 migration completed - Demo admin added');
          } catch (e) {
            developer.log('❌ [Database] Error migrating to v11: $e');
          }
        }

        // Migrate to version 12 - Add content management tables
        if (oldVersion < 12) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS job_postings(
                id TEXT PRIMARY KEY, title TEXT NOT NULL, type TEXT DEFAULT 'volunteer',
                description TEXT, requirements TEXT, location TEXT, is_remote INTEGER DEFAULT 0,
                application_email TEXT, posted_at TEXT, is_urgent INTEGER DEFAULT 0,
                is_active INTEGER DEFAULT 1
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS job_applications(
                id TEXT PRIMARY KEY, job_id TEXT, job_title TEXT,
                applicant_name TEXT, applicant_email TEXT, applicant_phone TEXT,
                cover_letter TEXT, resume_path TEXT, ghana_card_path TEXT,
                applied_at TEXT NOT NULL, status TEXT DEFAULT 'pending'
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS events(
                id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT,
                event_date TEXT, location TEXT, is_online INTEGER DEFAULT 0,
                meeting_link TEXT, max_attendees INTEGER DEFAULT 0,
                created_at TEXT, is_active INTEGER DEFAULT 1
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS event_rsvps(
                id TEXT PRIMARY KEY, event_id TEXT, user_id TEXT,
                rsvped_at TEXT, status TEXT DEFAULT 'attending'
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS devotionals(
                id TEXT PRIMARY KEY, title TEXT NOT NULL, content TEXT,
                scripture TEXT, author TEXT, published_at TEXT, is_active INTEGER DEFAULT 1
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS shelters(
                id TEXT PRIMARY KEY, name TEXT NOT NULL, address TEXT, city TEXT,
                phone TEXT, capacity INTEGER DEFAULT 0, services TEXT,
                is_active INTEGER DEFAULT 1
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS bible_verses(
                id TEXT PRIMARY KEY, verse TEXT NOT NULL, reference TEXT,
                category TEXT, display_date TEXT, is_active INTEGER DEFAULT 1
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS volunteer_shifts_v2(
                id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT,
                shift_date TEXT, start_time TEXT, end_time TEXT,
                location TEXT, spots_available INTEGER DEFAULT 0,
                is_active INTEGER DEFAULT 1
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS peer_mentors_v2(
                id TEXT PRIMARY KEY, name TEXT NOT NULL, bio TEXT,
                specialization TEXT, contact_email TEXT, contact_phone TEXT,
                is_available INTEGER DEFAULT 1, created_at TEXT
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS service_providers(
                id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT,
                description TEXT, address TEXT, phone TEXT, email TEXT,
                hours TEXT, is_active INTEGER DEFAULT 1
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS quizzes(
                id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT,
                category TEXT, questions TEXT, created_at TEXT,
                is_active INTEGER DEFAULT 1
              )
            ''');

            developer.log('✅ [Database] v12 migration completed - Content management tables added');
          } catch (e) {
            developer.log('❌ [Database] Error migrating to v12: $e');
          }
        }

        // Migrate to version 13 - Daily engagement tables
        if (oldVersion < 13) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS daily_streaks(
                user_id TEXT PRIMARY KEY,
                current_streak INTEGER DEFAULT 0,
                longest_streak INTEGER DEFAULT 0,
                last_checkin_date TEXT,
                total_checkins INTEGER DEFAULT 0
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS selfcare_entries(
                id TEXT PRIMARY KEY,
                user_id TEXT,
                date TEXT,
                completed_items TEXT,
                score INTEGER DEFAULT 0,
                created_at TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS journal_entries(
                id TEXT PRIMARY KEY,
                user_id TEXT,
                date TEXT,
                title TEXT,
                content TEXT,
                mood_before INTEGER DEFAULT 5,
                mood_after INTEGER DEFAULT 5,
                has_voice_note INTEGER DEFAULT 0,
                voice_note_path TEXT,
                created_at TEXT
              )
            ''');
            developer.log('✅ [Database] v13 migration completed - Daily engagement tables added');
          } catch (e) {
            developer.log('❌ [Database] Error migrating to v13: $e');
          }
        }

        // Migrate to version 14 - Case management tables
        if (oldVersion < 14) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS client_intakes(
                id TEXT PRIMARY KEY,
                client_name TEXT NOT NULL,
                client_phone TEXT,
                client_id TEXT,
                case_manager_id TEXT NOT NULL,
                case_manager_name TEXT NOT NULL,
                intake_date TEXT NOT NULL,
                presenting_situation TEXT,
                needs_identified TEXT,
                emergency_support_desc TEXT,
                emergency_support_amount REAL,
                currency TEXT DEFAULT 'GHC',
                status TEXT DEFAULT 'active',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS case_plans(
                id TEXT PRIMARY KEY,
                intake_id TEXT NOT NULL,
                client_name TEXT NOT NULL,
                client_id TEXT,
                case_manager_id TEXT NOT NULL,
                case_manager_name TEXT NOT NULL,
                plan_status TEXT DEFAULT 'active',
                next_review_date TEXT,
                review_frequency TEXT DEFAULT 'quarterly',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (intake_id) REFERENCES client_intakes (id)
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS case_programs(
                id TEXT PRIMARY KEY,
                case_plan_id TEXT NOT NULL,
                program_number INTEGER DEFAULT 0,
                program_name TEXT NOT NULL,
                goal TEXT,
                current_status_notes TEXT,
                priority TEXT DEFAULT 'medium',
                deadline_label TEXT,
                deadline_date TEXT,
                actions TEXT,
                is_completed INTEGER DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (case_plan_id) REFERENCES case_plans (id)
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS case_notes(
                id TEXT PRIMARY KEY,
                case_plan_id TEXT NOT NULL,
                case_program_id TEXT,
                note_text TEXT NOT NULL,
                created_by TEXT NOT NULL,
                created_at TEXT NOT NULL,
                FOREIGN KEY (case_plan_id) REFERENCES case_plans (id)
              )
            ''');
            developer.log('✅ [Database] v14 migration completed - Case management tables added');
          } catch (e) {
            developer.log('❌ [Database] Error migrating to v14: $e');
          }
        }

        // Migrate to version 15 - Supabase pending sync queue
        if (oldVersion < 15) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS pending_syncs(
                id TEXT PRIMARY KEY,
                table_name TEXT NOT NULL,
                record_id TEXT NOT NULL,
                operation TEXT NOT NULL,
                data TEXT NOT NULL,
                created_at TEXT NOT NULL,
                retry_count INTEGER DEFAULT 0,
                last_error TEXT
              )
            ''');
            developer.log('✅ [Database] v15 migration completed - Pending sync queue added');
          } catch (e) {
            developer.log('❌ [Database] Error migrating to v15: $e');
          }
        }

        if (oldVersion < 16) {
          try {
            // Add country_code to client_intakes and case_plans so plans can
            // be filtered by the active org (Ghana vs US).
            await db.execute(
                'ALTER TABLE client_intakes ADD COLUMN country_code TEXT DEFAULT "GH"');
            await db.execute(
                'ALTER TABLE case_plans ADD COLUMN country_code TEXT DEFAULT "GH"');
            developer.log('✅ [Database] v16 migration completed — country_code added');
          } catch (e) {
            developer.log('❌ [Database] Error migrating to v16: $e');
          }
        }

        developer.log('✅ [Database] Successfully upgraded to v$newVersion');
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

  // Create demo accounts for Apple App Review
  static Future<void> _insertDemoAccounts(Database db) async {
    // Password hashing (same as auth_service.dart)
    String hashPassword(String password) {
      final bytes = utf8.encode('${password}ngo_support_salt');
      final digest = sha256.convert(bytes);
      return digest.toString();
    }

    final demoAccounts = [
      {
        'id': 'demo_reviewer_1',
        'email': 'reviewer@beaconnewbeginnings.org',
        'display_name': 'Apple Reviewer',
        'password_hash': hashPassword('SafeReview2025!'),
        'user_type': 'survivor',
        'is_anonymous': 0,
        'approval_status': 'approved',
        'is_available': 1,
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      },
      {
        'id': 'demo_reviewer_2',
        'email': 'appstore.reviewer@beaconnewbeginnings.org',
        'display_name': 'App Store Reviewer',
        'password_hash': hashPassword('AppleReview2025!'),
        'user_type': 'survivor',
        'is_anonymous': 0,
        'approval_status': 'approved',
        'is_available': 1,
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      },
      {
        'id': 'demo_reviewer_3',
        'email': 'test.reviewer@beaconnewbeginnings.org',
        'display_name': 'Test Reviewer',
        'password_hash': hashPassword('TestAccess2025!'),
        'user_type': 'survivor',
        'is_anonymous': 0,
        'approval_status': 'approved',
        'is_available': 1,
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      },
      // Demo admin account
      {
        'id': 'demo_admin_enam',
        'email': 'admin@beaconnewbeginnings.org',
        'display_name': 'Beacon Admin',
        'password_hash': hashPassword('BeaconAdmin2025!'),
        'user_type': 'admin',
        'is_anonymous': 0,
        'approval_status': 'approved',
        'is_available': 1,
        'admin_secret_validated': 1,
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      },
      // Enam — Executive Director admin account
      {
        'id': 'admin_enam_egyir',
        'email': 'enam.egyir@gmail.com',
        'display_name': 'Enam Egyir',
        'password_hash': hashPassword('BeaconAdmin2025!'),
        'user_type': 'admin',
        'is_anonymous': 0,
        'approval_status': 'approved',
        'is_available': 1,
        'admin_secret_validated': 1,
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      },
    ];

    for (var account in demoAccounts) {
      try {
        await db.insert('users', account, conflictAlgorithm: ConflictAlgorithm.replace);
        developer.log('✅ [Database] Upserted demo account: ${account['email']}');
      } catch (e) {
        developer.log('⚠️ [Database] Failed to upsert demo account ${account['email']}: $e');
      }
    }
  }

  // Seed Abigail Bubune Abubakar's program plan as the first demo case
  static Future<void> _seedAbigailCase(Database db) async {
    const intakeId = 'intake_abigail_2026';
    const planId   = 'plan_abigail_2026';
    const now      = '2026-04-17T09:00:00.000';

    // ── 1. Client Intake ──────────────────────────────────────────────────────
    await db.insert('client_intakes', {
      'id': intakeId,
      'client_name': 'Abigail Bubune Abubakar',
      'client_phone': null,
      'client_id': null,
      'case_manager_id': 'admin_enam_egyir',
      'case_manager_name': 'Enam Egyir',
      'intake_date': '2026-04-01T00:00:00.000',
      'presenting_situation':
          'Abigail lost both parents at a young age and recently converted from Islam to Christianity. '
          'Following her conversion, extended family members withdrew all financial and emotional support '
          'and issued ultimatums demanding she renounce her faith or relocate north to live under '
          'strict family supervision. She is currently living in university hostel accommodation '
          'and pursuing her undergraduate degree. She has no immediate family safety net and faces '
          'social isolation, financial vulnerability, and ongoing pressure from her extended family. '
          'Emergency support of GHC 3,100 (tuition + hostel) was provided by BNB in January 2026.',
      'needs_identified': '["Education","Housing","Psychosocial","Community","Economic","Legal","Safety"]',
      'emergency_support_desc': 'Tuition GHC 1,900 + Hostel accommodation GHC 1,200 — paid January 2026',
      'emergency_support_amount': 3100.0,
      'currency': 'GHC',
      'status': 'active',
      'created_at': '2026-01-15T10:00:00.000',
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // ── 2. Case Plan ──────────────────────────────────────────────────────────
    await db.insert('case_plans', {
      'id': planId,
      'intake_id': intakeId,
      'client_name': 'Abigail Bubune Abubakar',
      'client_id': null,
      'case_manager_id': 'admin_enam_egyir',
      'case_manager_name': 'Enam Egyir',
      'plan_status': 'active',
      'next_review_date': '2026-07-01T00:00:00.000',
      'review_frequency': 'quarterly',
      'created_at': '2026-04-01T00:00:00.000',
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // ── 3. Programs ───────────────────────────────────────────────────────────
    final programs = [
      {
        'id': 'prog_abigail_1',
        'case_plan_id': planId,
        'program_number': 1,
        'program_name': 'Case Management',
        'goal': 'Maintain a complete, coordinated case file and serve as primary BNB point of contact for Abigail throughout her support journey.',
        'current_status_notes': 'Active — regular check-ins established. Weekly touchpoints scheduled with client.',
        'priority': 'ongoing',
        'deadline_label': 'Ongoing',
        'deadline_date': null,
        'actions': jsonEncode([
          {'text': 'Create and maintain complete case file with all supporting documents', 'completed': true, 'completedAt': '2026-04-01T10:00:00.000'},
          {'text': 'Schedule monthly check-in meetings with Abigail', 'completed': true, 'completedAt': '2026-04-17T09:00:00.000'},
          {'text': 'Coordinate communication between all program leads', 'completed': false, 'completedAt': null},
          {'text': 'Document all interventions and outcomes in case management system', 'completed': false, 'completedAt': null},
          {'text': 'Conduct first quarterly review — July 2026', 'completed': false, 'completedAt': null},
        ]),
        'is_completed': 0,
        'created_at': '2026-04-01T00:00:00.000',
        'updated_at': now,
      },
      {
        'id': 'prog_abigail_2',
        'case_plan_id': planId,
        'program_number': 2,
        'program_name': 'Education Support & Continuity',
        'goal': 'Ensure Abigail completes her academic programme without financial interruption, with pastoral and chaplaincy support available on campus.',
        'current_status_notes': 'Emergency tuition (GHC 1,900) and hostel (GHC 1,200) paid January 2026. Next semester payment due May 2026.',
        'priority': 'high',
        'deadline_label': 'May 2026',
        'deadline_date': '2026-05-01T00:00:00.000',
        'actions': jsonEncode([
          {'text': 'Emergency tuition payment: GHC 1,900 (Jan 2026)', 'completed': true, 'completedAt': '2026-01-15T00:00:00.000'},
          {'text': 'Emergency hostel payment: GHC 1,200 (Jan 2026)', 'completed': true, 'completedAt': '2026-01-15T00:00:00.000'},
          {'text': 'Confirm next semester tuition cost and payment due date', 'completed': false, 'completedAt': null},
          {'text': 'Arrange semester 2 tuition payment by May 2026', 'completed': false, 'completedAt': null},
          {'text': 'Connect Abigail with campus chaplain or pastoral support team', 'completed': false, 'completedAt': null},
          {'text': 'Explore merit scholarships or bursary applications', 'completed': false, 'completedAt': null},
          {'text': 'Verify academic performance and attendance record', 'completed': false, 'completedAt': null},
        ]),
        'is_completed': 0,
        'created_at': '2026-04-01T00:00:00.000',
        'updated_at': now,
      },
      {
        'id': 'prog_abigail_3',
        'case_plan_id': planId,
        'program_number': 3,
        'program_name': 'Housing Stability & Safety Planning',
        'goal': 'Ensure safe, stable housing during and after the BNB support period; prevent any forced return to an unsafe family environment.',
        'current_status_notes': 'Currently in university hostel funded by BNB. Hostel contract assessed — secure through current academic year. Risk: family may escalate pressure if conversion becomes widely known.',
        'priority': 'high',
        'deadline_label': 'January 2027',
        'deadline_date': '2027-01-01T00:00:00.000',
        'actions': jsonEncode([
          {'text': 'Hostel accommodation secured and funded through current semester', 'completed': true, 'completedAt': '2026-01-15T00:00:00.000'},
          {'text': 'Assess hostel contract renewal timeline for next academic year', 'completed': false, 'completedAt': null},
          {'text': 'Identify backup housing options (BNB safe house, partner shelter) if family escalates', 'completed': false, 'completedAt': null},
          {'text': 'Create personal safety plan with Abigail for family contact scenarios', 'completed': false, 'completedAt': null},
          {'text': 'Review housing plan at each quarterly review', 'completed': false, 'completedAt': null},
          {'text': 'Explore long-term housing options post-graduation', 'completed': false, 'completedAt': null},
        ]),
        'is_completed': 0,
        'created_at': '2026-04-01T00:00:00.000',
        'updated_at': now,
      },
      {
        'id': 'prog_abigail_4',
        'case_plan_id': planId,
        'program_number': 4,
        'program_name': 'Psychosocial Support & Counselling',
        'goal': 'Address grief, religious trauma, rejection, and social isolation through professional counselling and peer support.',
        'current_status_notes': 'URGENT — formal counselling referral not yet completed. Abigail has experienced loss of both parents, religious persecution within family, and social isolation. Must act within 30 days of plan date (by 17 May 2026).',
        'priority': 'urgent',
        'deadline_label': 'Within 30 days',
        'deadline_date': '2026-05-17T00:00:00.000',
        'actions': jsonEncode([
          {'text': 'Refer to trained counsellor specialising in grief and religious trauma', 'completed': false, 'completedAt': null},
          {'text': 'Initial counselling session booked and attended', 'completed': false, 'completedAt': null},
          {'text': 'Assess for depression, anxiety, or PTSD indicators', 'completed': false, 'completedAt': null},
          {'text': 'Connect with Christian support community or church group on campus', 'completed': false, 'completedAt': null},
          {'text': 'Establish bi-weekly emotional wellbeing check-ins', 'completed': false, 'completedAt': null},
          {'text': 'Review counselling progress at quarterly review (July 2026)', 'completed': false, 'completedAt': null},
        ]),
        'is_completed': 0,
        'created_at': '2026-04-01T00:00:00.000',
        'updated_at': now,
      },
      {
        'id': 'prog_abigail_5',
        'case_plan_id': planId,
        'program_number': 5,
        'program_name': 'Community & Social Reintegration',
        'goal': 'Rebuild a sense of community and belonging; establish a safe, supportive social network to replace the family network she has lost.',
        'current_status_notes': 'Abigail is socially isolated following family estrangement. Priority is connecting her with a safe Christian community and campus social network.',
        'priority': 'medium',
        'deadline_label': 'April–July 2026',
        'deadline_date': '2026-07-31T00:00:00.000',
        'actions': jsonEncode([
          {'text': 'Connect Abigail with a church or campus Christian fellowship she feels safe in', 'completed': false, 'completedAt': null},
          {'text': 'Facilitate introduction to campus student support services', 'completed': false, 'completedAt': null},
          {'text': 'Identify at least one peer mentor or trusted friend on campus', 'completed': false, 'completedAt': null},
          {'text': 'Explore campus clubs or community service opportunities', 'completed': false, 'completedAt': null},
          {'text': 'Review social support network at July quarterly review', 'completed': false, 'completedAt': null},
        ]),
        'is_completed': 0,
        'created_at': '2026-04-01T00:00:00.000',
        'updated_at': now,
      },
      {
        'id': 'prog_abigail_6',
        'case_plan_id': planId,
        'program_number': 6,
        'program_name': 'Skills Training & Economic Empowerment',
        'goal': 'Equip Abigail with practical skills and begin laying the foundation for financial independence post-graduation.',
        'current_status_notes': 'Currently focused on academic continuity. Skills and economic planning to begin Q2 2026 once Abigail is settled and emotionally stable.',
        'priority': 'medium',
        'deadline_label': 'April–September 2026',
        'deadline_date': '2026-09-30T00:00:00.000',
        'actions': jsonEncode([
          {'text': 'Assess Abigail\'s interests, strengths, and career aspirations', 'completed': false, 'completedAt': null},
          {'text': 'Identify relevant skills training programmes (digital, entrepreneurship, vocational)', 'completed': false, 'completedAt': null},
          {'text': 'Enroll in at least one skills course by July 2026', 'completed': false, 'completedAt': null},
          {'text': 'Connect with BNB economic empowerment partners', 'completed': false, 'completedAt': null},
          {'text': 'Develop basic personal budget and financial literacy plan', 'completed': false, 'completedAt': null},
          {'text': 'Review progress at September follow-up', 'completed': false, 'completedAt': null},
        ]),
        'is_completed': 0,
        'created_at': '2026-04-01T00:00:00.000',
        'updated_at': now,
      },
      {
        'id': 'prog_abigail_7',
        'case_plan_id': planId,
        'program_number': 7,
        'program_name': 'Legal Resource Navigation',
        'goal': 'Ensure Abigail understands her legal rights and that a referral pathway is ready if family coercion or threats escalate.',
        'current_status_notes': 'Currently monitoring. No immediate legal threat, but family has issued ultimatums that may constitute coercion. Legal aid referral pathway established as a precaution.',
        'priority': 'monitor',
        'deadline_label': 'Ongoing — monitor',
        'deadline_date': null,
        'actions': jsonEncode([
          {'text': 'Brief Abigail on her right to religious freedom and freedom from coercion under Ghana law', 'completed': false, 'completedAt': null},
          {'text': 'Identify legal aid partner (LAWA or equivalent) for referral if needed', 'completed': false, 'completedAt': null},
          {'text': 'Document any threats or ultimatums from family in case file', 'completed': false, 'completedAt': null},
          {'text': 'Establish clear escalation trigger — what actions by family would prompt legal referral', 'completed': false, 'completedAt': null},
          {'text': 'Review legal situation at each quarterly check-in', 'completed': false, 'completedAt': null},
        ]),
        'is_completed': 0,
        'created_at': '2026-04-01T00:00:00.000',
        'updated_at': now,
      },
    ];

    for (final prog in programs) {
      await db.insert('case_programs', prog, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // ── 4. Case Notes ─────────────────────────────────────────────────────────
    final notes = [
      {
        'id': 'note_abigail_1',
        'case_plan_id': planId,
        'case_program_id': null,
        'note_text':
            'Intake completed April 2026. Abigail was referred to BNB by campus chaplain. '
            'Emergency support of GHC 3,100 (tuition + hostel) was provided in January 2026 prior to formal intake. '
            'Client is resilient and highly motivated — pursuing studies despite significant family and social challenges. '
            'Confidentiality concerns raised: client does not want extended family to know she is receiving BNB support. '
            'Protocols explained and agreed.',
        'created_by': 'Enam Egyir',
        'created_at': '2026-04-01T10:00:00.000',
      },
      {
        'id': 'note_abigail_2',
        'case_plan_id': planId,
        'case_program_id': null,
        'note_text':
            'Case plan presented to Abigail on 17 April 2026. She is aware of all 7 programme areas and has consented to support. '
            'Immediate priority flagged: psychosocial counselling referral must be completed within 30 days. '
            'Client expressed both gratitude and anxiety — particularly around family finding out about BNB involvement. '
            'Next steps confirmed: education payment (May), counselling referral (immediate), housing review (quarterly).',
        'created_by': 'Enam Egyir',
        'created_at': now,
      },
      {
        'id': 'note_abigail_3',
        'case_plan_id': planId,
        'case_program_id': 'prog_abigail_4',
        'note_text':
            'URGENT: Psychosocial counselling referral is the most time-sensitive action in this plan. '
            'Abigail has experienced compound losses — both parents, her entire family support network, and her former religious community. '
            'She is displaying signs of grief and social anxiety. Referral to specialist counsellor must happen within 30 days of this plan date.',
        'created_by': 'Enam Egyir',
        'created_at': now,
      },
    ];

    for (final note in notes) {
      await db.insert('case_notes', note, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    developer.log('✅ [Database] Abigail case seed completed (or already present)');
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

  // Safety Plan methods
  static Future<void> saveSafetyPlan(String userId, Map<String, dynamic> planData) async {
    final db = await database;
    await db.insert(
      'safety_plans',
      {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'user_id': userId,
        'emergency_contacts': jsonEncode(planData['emergency_contacts'] ?? []),
        'safe_places': jsonEncode(planData['safe_places'] ?? []),
        'escape_plan': jsonEncode(planData['escape_plan'] ?? {}),
        'essential_items': jsonEncode(planData['essential_items'] ?? {}),
        'code_words': jsonEncode(planData['code_words'] ?? {}),
        'children_safety': jsonEncode(planData['children_safety'] ?? []),
        'pet_safety': jsonEncode(planData['pet_safety'] ?? []),
        'financial_safety': jsonEncode(planData['financial_safety'] ?? []),
        'digital_safety': jsonEncode(planData['digital_safety'] ?? {}),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getSafetyPlan(String userId) async {
    final db = await database;
    final maps = await db.query(
      'safety_plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return {
      'id': map['id'],
      'user_id': map['user_id'],
      'emergency_contacts': jsonDecode(map['emergency_contacts'] as String? ?? '[]'),
      'safe_places': jsonDecode(map['safe_places'] as String? ?? '[]'),
      'escape_plan': jsonDecode(map['escape_plan'] as String? ?? '{}'),
      'essential_items': jsonDecode(map['essential_items'] as String? ?? '{}'),
      'code_words': jsonDecode(map['code_words'] as String? ?? '{}'),
      'children_safety': jsonDecode(map['children_safety'] as String? ?? '[]'),
      'pet_safety': jsonDecode(map['pet_safety'] as String? ?? '[]'),
      'financial_safety': jsonDecode(map['financial_safety'] as String? ?? '[]'),
      'digital_safety': jsonDecode(map['digital_safety'] as String? ?? '{}'),
      'created_at': map['created_at'],
      'updated_at': map['updated_at'],
    };
  }

  // Evidence Log methods
  static Future<String> saveEvidenceLog(String userId, Map<String, dynamic> evidenceData) async {
    final db = await database;
    final evidenceId = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('evidence_logs', {
      'id': evidenceId,
      'user_id': userId,
      'date': evidenceData['date'] ?? DateTime.now().toIso8601String(),
      'incident_type': evidenceData['incident_type'] ?? '',
      'description': _encryptData(evidenceData['description'] ?? ''),
      'location': evidenceData['location'] ?? '',
      'witnesses': evidenceData['witnesses'] ?? '',
      'injuries': evidenceData['injuries'] ?? '',
      'police_report_number': evidenceData['police_report_number'] ?? '',
      'hospital_name': evidenceData['hospital_name'] ?? '',
      'photos': jsonEncode(evidenceData['photos'] ?? []),
      'audio': jsonEncode(evidenceData['audio'] ?? []),
      'created_at': DateTime.now().toIso8601String(),
    });

    return evidenceId;
  }

  static Future<List<Map<String, dynamic>>> getEvidenceLogs(String userId) async {
    final db = await database;
    final maps = await db.query(
      'evidence_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return maps.map((map) {
      return {
        'id': map['id'],
        'user_id': map['user_id'],
        'date': map['date'],
        'incident_type': map['incident_type'],
        'description': _decryptData(map['description'] as String? ?? ''),
        'location': map['location'],
        'witnesses': map['witnesses'],
        'injuries': map['injuries'],
        'police_report_number': map['police_report_number'],
        'hospital_name': map['hospital_name'],
        'photos': jsonDecode(map['photos'] as String? ?? '[]'),
        'audio': jsonDecode(map['audio'] as String? ?? '[]'),
        'created_at': map['created_at'],
      };
    }).toList();
  }

  static Future<void> deleteEvidenceLog(String evidenceId) async {
    final db = await database;
    await db.delete('evidence_logs', where: 'id = ?', whereArgs: [evidenceId]);
  }

  // Mood Entry methods
  static Future<void> saveMoodEntry(String userId, int moodRating, List<String> triggers, String notes) async {
    final db = await database;
    await db.insert('mood_entries', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user_id': userId,
      'date': DateTime.now().toIso8601String(),
      'mood_rating': moodRating,
      'triggers': jsonEncode(triggers),
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getMoodEntries(String userId, {int? days}) async {
    final db = await database;
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (days != null) {
      final startDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate);
    }

    final maps = await db.query(
      'mood_entries',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map((map) {
      return {
        'id': map['id'],
        'user_id': map['user_id'],
        'date': map['date'],
        'mood_rating': map['mood_rating'],
        'triggers': jsonDecode(map['triggers'] as String? ?? '[]'),
        'notes': map['notes'],
        'created_at': map['created_at'],
      };
    }).toList();
  }

  // Budget Transaction methods
  static Future<String> saveBudgetTransaction(String userId, Map<String, dynamic> transactionData) async {
    final db = await database;
    final transactionId = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('budget_transactions', {
      'id': transactionId,
      'user_id': userId,
      'date': transactionData['date'] ?? DateTime.now().toIso8601String(),
      'amount': transactionData['amount'],
      'category': transactionData['category'],
      'description': transactionData['description'],
      'is_income': transactionData['is_income'] == true ? 1 : 0,
      'is_hidden': transactionData['is_hidden'] == true ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    return transactionId;
  }

  static Future<List<Map<String, dynamic>>> getBudgetTransactions(String userId, {bool includeHidden = false}) async {
    final db = await database;
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (!includeHidden) {
      whereClause += ' AND is_hidden = 0';
    }

    final maps = await db.query(
      'budget_transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map((map) {
      return {
        'id': map['id'],
        'user_id': map['user_id'],
        'date': map['date'],
        'amount': map['amount'],
        'category': map['category'],
        'description': map['description'],
        'is_income': map['is_income'] == 1,
        'is_hidden': map['is_hidden'] == 1,
        'created_at': map['created_at'],
      };
    }).toList();
  }

  static Future<Map<String, double>> getBudgetSummary(String userId) async {
    final db = await database;

    final income = await db.rawQuery(
      'SELECT SUM(amount) as total FROM budget_transactions WHERE user_id = ? AND is_income = 1',
      [userId]
    );

    final expenses = await db.rawQuery(
      'SELECT SUM(amount) as total FROM budget_transactions WHERE user_id = ? AND is_income = 0',
      [userId]
    );

    return {
      'income': (income.first['total'] as num?)?.toDouble() ?? 0.0,
      'expenses': (expenses.first['total'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // Secure Document methods
  static Future<String> saveSecureDocument(String userId, Map<String, dynamic> documentData) async {
    final db = await database;
    final documentId = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('secure_documents', {
      'id': documentId,
      'user_id': userId,
      'title': documentData['title'],
      'category': documentData['category'],
      'file_path': documentData['file_path'],
      'is_encrypted': 1,
      'uploaded_at': DateTime.now().toIso8601String(),
    });

    return documentId;
  }

  static Future<List<Map<String, dynamic>>> getSecureDocuments(String userId) async {
    final db = await database;
    final maps = await db.query(
      'secure_documents',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'uploaded_at DESC',
    );

    return maps.map((map) {
      return {
        'id': map['id'],
        'user_id': map['user_id'],
        'title': map['title'],
        'category': map['category'],
        'file_path': map['file_path'],
        'is_encrypted': map['is_encrypted'] == 1,
        'uploaded_at': map['uploaded_at'],
      };
    }).toList();
  }

  static Future<void> deleteSecureDocument(String documentId) async {
    final db = await database;
    await db.delete('secure_documents', where: 'id = ?', whereArgs: [documentId]);
  }

  // Chat Message methods
  static Future<void> saveChatMessage(String conversationId, String senderId, String message) async {
    final db = await database;
    await db.insert('chat_messages', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message': _encryptData(message),
      'timestamp': DateTime.now().toIso8601String(),
      'is_encrypted': 1,
      'is_read': 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getChatMessages(String conversationId) async {
    final db = await database;
    final maps = await db.query(
      'chat_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) {
      return {
        'id': map['id'],
        'conversation_id': map['conversation_id'],
        'sender_id': map['sender_id'],
        'message': _decryptData(map['message'] as String? ?? ''),
        'timestamp': map['timestamp'],
        'is_encrypted': map['is_encrypted'] == 1,
        'is_read': map['is_read'] == 1,
      };
    }).toList();
  }

  // Disguise Settings methods
  static Future<void> saveDisguiseSettings(String userId, String passcode, String disguiseType) async {
    final db = await database;
    await db.insert(
      'disguise_settings',
      {
        'user_id': userId,
        'passcode': _encryptData(passcode),
        'disguise_type': disguiseType,
        'is_enabled': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getDisguiseSettings(String userId) async {
    final db = await database;
    final maps = await db.query(
      'disguise_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return {
      'user_id': map['user_id'],
      'passcode': _decryptData(map['passcode'] as String? ?? ''),
      'disguise_type': map['disguise_type'],
      'is_enabled': map['is_enabled'] == 1,
    };
  }

  // Conversation management methods
  static Future<String> createConversation(String userId) async {
    final db = await database;
    final conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}';

    await db.insert('conversations', {
      'id': conversationId,
      'user_id': userId,
      'status': 'active',
      'escalated_to_human': 0,
      'last_response_timestamp': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });

    return conversationId;
  }

  static Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    final db = await database;
    final maps = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  static Future<List<Map<String, dynamic>>> getUserConversations(String userId) async {
    final db = await database;
    return await db.query(
      'conversations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<void> escalateConversation(String conversationId) async {
    final db = await database;
    await db.update(
      'conversations',
      {
        'escalated_to_human': 1,
        'escalation_timestamp': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  static Future<void> updateConversationResponseTime(String conversationId) async {
    final db = await database;
    await db.update(
      'conversations',
      {'last_response_timestamp': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  static Future<void> closeConversation(String conversationId) async {
    final db = await database;
    await db.update(
      'conversations',
      {'status': 'closed'},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  // Inquiry ticket methods
  static Future<String> createInquiryTicket({
    required String conversationId,
    required String userId,
    required String subject,
    required String description,
    String priority = 'medium',
  }) async {
    final db = await database;
    final ticketId = 'ticket_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}';

    await db.insert('inquiry_tickets', {
      'id': ticketId,
      'conversation_id': conversationId,
      'user_id': userId,
      'subject': subject,
      'description': _encryptData(description),
      'priority': priority,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });

    return ticketId;
  }

  static Future<List<Map<String, dynamic>>> getAllInquiryTickets({String? status}) async {
    final db = await database;
    final maps = status != null
        ? await db.query(
            'inquiry_tickets',
            where: 'status = ?',
            whereArgs: [status],
            orderBy: 'created_at DESC',
          )
        : await db.query('inquiry_tickets', orderBy: 'created_at DESC');

    return maps.map((map) {
      return {
        'id': map['id'],
        'conversation_id': map['conversation_id'],
        'user_id': map['user_id'],
        'subject': map['subject'],
        'description': _decryptData(map['description'] as String? ?? ''),
        'priority': map['priority'],
        'status': map['status'],
        'created_at': map['created_at'],
        'assigned_to': map['assigned_to'],
        'resolved_at': map['resolved_at'],
      };
    }).toList();
  }

  static Future<Map<String, dynamic>?> getInquiryTicket(String ticketId) async {
    final db = await database;
    final maps = await db.query(
      'inquiry_tickets',
      where: 'id = ?',
      whereArgs: [ticketId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return {
      'id': map['id'],
      'conversation_id': map['conversation_id'],
      'user_id': map['user_id'],
      'subject': map['subject'],
      'description': _decryptData(map['description'] as String? ?? ''),
      'priority': map['priority'],
      'status': map['status'],
      'created_at': map['created_at'],
      'assigned_to': map['assigned_to'],
      'resolved_at': map['resolved_at'],
    };
  }

  static Future<void> assignInquiryTicket(String ticketId, String assigneeId) async {
    final db = await database;
    await db.update(
      'inquiry_tickets',
      {'assigned_to': assigneeId, 'status': 'in_progress'},
      where: 'id = ?',
      whereArgs: [ticketId],
    );
  }

  static Future<void> resolveInquiryTicket(String ticketId) async {
    final db = await database;
    await db.update(
      'inquiry_tickets',
      {
        'status': 'resolved',
        'resolved_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [ticketId],
    );
  }

  static Future<void> updateInquiryTicketStatus(String ticketId, String status) async {
    final db = await database;
    final updates = <String, dynamic>{'status': status};

    if (status == 'resolved') {
      updates['resolved_at'] = DateTime.now().toIso8601String();
    }

    await db.update(
      'inquiry_tickets',
      updates,
      where: 'id = ?',
      whereArgs: [ticketId],
    );
  }

  // Email notification methods
  static Future<String> createEmailNotification({
    required String inquiryId,
    required String recipientEmail,
    required String subject,
    required String body,
  }) async {
    final db = await database;
    final notificationId = 'email_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}';

    await db.insert('email_notifications', {
      'id': notificationId,
      'inquiry_id': inquiryId,
      'recipient_email': recipientEmail,
      'subject': subject,
      'body': body,
      'sent': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    return notificationId;
  }

  static Future<List<Map<String, dynamic>>> getPendingEmailNotifications() async {
    final db = await database;
    return await db.query(
      'email_notifications',
      where: 'sent = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
  }

  static Future<void> markEmailAsSent(String notificationId) async {
    final db = await database;
    await db.update(
      'email_notifications',
      {
        'sent': 1,
        'sent_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  // Admin Dashboard Statistics
  static Future<int> getTotalUsersCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE is_anonymous = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<int> getActiveUsersCount() async {
    final db = await database;
    // Users who have logged in within the last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30)).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE is_anonymous = 0 AND last_updated >= ?',
      [thirtyDaysAgo],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<int> getTotalInquiriesCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM inquiry_tickets',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<int> getPendingInquiriesCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM inquiry_tickets WHERE status = ?',
      ['pending'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<int> getTotalCasesCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cases',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<Map<String, int>> getAdminDashboardStats() async {
    final totalUsers = await getTotalUsersCount();
    final activeUsers = await getActiveUsersCount();
    final totalInquiries = await getTotalInquiriesCount();
    final pendingInquiries = await getPendingInquiriesCount();
    final totalCases = await getTotalCasesCount();

    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'totalInquiries': totalInquiries,
      'pendingInquiries': pendingInquiries,
      'totalCases': totalCases,
    };
  }

  // Helper Application Management
  static Future<String> saveHelperApplication({
    required String userId,
    required String experienceDescription,
    required String joiningReason,
    required String servicesOffered,
    String? certificatePath,
    String? idDocumentPath,
    List<String>? additionalDocsPaths,
  }) async {
    final db = await database;
    final applicationId = 'app_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}';

    await db.insert('helper_applications', {
      'id': applicationId,
      'user_id': userId,
      'experience_description': experienceDescription,
      'joining_reason': joiningReason,
      'services_offered': servicesOffered,
      'certificate_path': certificatePath,
      'id_document_path': idDocumentPath,
      'additional_docs_paths': additionalDocsPaths?.join(','),
      'submitted_at': DateTime.now().toIso8601String(),
    });

    // Update user status to pending
    await db.update(
      'users',
      {'approval_status': 'pending'},
      where: 'id = ?',
      whereArgs: [userId],
    );

    return applicationId;
  }

  static Future<Map<String, dynamic>?> getHelperApplication(String userId) async {
    final db = await database;
    final results = await db.query(
      'helper_applications',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final app = results.first;
    return {
      'id': app['id'],
      'user_id': app['user_id'],
      'experience_description': app['experience_description'],
      'joining_reason': app['joining_reason'],
      'services_offered': app['services_offered'],
      'certificate_path': app['certificate_path'],
      'id_document_path': app['id_document_path'],
      'additional_docs_paths': (app['additional_docs_paths'] as String?)?.split(',') ?? [],
      'submitted_at': app['submitted_at'],
      'reviewed_at': app['reviewed_at'],
      'reviewed_by': app['reviewed_by'],
      'review_notes': app['review_notes'],
    };
  }

  static Future<List<Map<String, dynamic>>> getPendingHelperApplications() async {
    final db = await database;

    // Join with users table to get user info
    final results = await db.rawQuery('''
      SELECT
        ha.*,
        u.display_name,
        u.email,
        u.phone,
        u.user_type,
        u.created_at as user_created_at
      FROM helper_applications ha
      INNER JOIN users u ON ha.user_id = u.id
      WHERE u.approval_status = 'pending'
      ORDER BY ha.submitted_at DESC
    ''');

    return results.map((row) {
      return {
        'id': row['id'],
        'user_id': row['user_id'],
        'display_name': row['display_name'],
        'email': row['email'],
        'phone': row['phone'],
        'user_type': row['user_type'],
        'experience_description': row['experience_description'],
        'joining_reason': row['joining_reason'],
        'services_offered': row['services_offered'],
        'certificate_path': row['certificate_path'],
        'id_document_path': row['id_document_path'],
        'additional_docs_paths': (row['additional_docs_paths'] as String?)?.split(',') ?? [],
        'submitted_at': row['submitted_at'],
        'user_created_at': row['user_created_at'],
      };
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getAllHelperApplications() async {
    final db = await database;

    // Join with users table to get user info
    final results = await db.rawQuery('''
      SELECT
        ha.*,
        u.display_name,
        u.email,
        u.phone,
        u.user_type,
        u.approval_status,
        u.approved_at,
        u.created_at as user_created_at
      FROM helper_applications ha
      INNER JOIN users u ON ha.user_id = u.id
      ORDER BY ha.submitted_at DESC
    ''');

    return results.map((row) {
      return {
        'id': row['id'],
        'user_id': row['user_id'],
        'display_name': row['display_name'],
        'email': row['email'],
        'phone': row['phone'],
        'user_type': row['user_type'],
        'approval_status': row['approval_status'],
        'experience_description': row['experience_description'],
        'joining_reason': row['joining_reason'],
        'services_offered': row['services_offered'],
        'certificate_path': row['certificate_path'],
        'id_document_path': row['id_document_path'],
        'additional_docs_paths': (row['additional_docs_paths'] as String?)?.split(',') ?? [],
        'submitted_at': row['submitted_at'],
        'reviewed_at': row['reviewed_at'],
        'reviewed_by': row['reviewed_by'],
        'review_notes': row['review_notes'],
        'approved_at': row['approved_at'],
        'user_created_at': row['user_created_at'],
      };
    }).toList();
  }

  static Future<void> approveHelperApplication({
    required String userId,
    required String reviewerId,
    String? notes,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Update user approval status
    await db.update(
      'users',
      {
        'approval_status': 'approved',
        'approved_by': reviewerId,
        'approved_at': now,
        'approval_notes': notes,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    // Update application review info
    await db.update(
      'helper_applications',
      {
        'reviewed_at': now,
        'reviewed_by': reviewerId,
        'review_notes': notes,
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  static Future<void> rejectHelperApplication({
    required String userId,
    required String reviewerId,
    required String reason,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Update user approval status
    await db.update(
      'users',
      {
        'approval_status': 'rejected',
        'approved_by': reviewerId,
        'approved_at': now,
        'approval_notes': reason,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    // Update application review info
    await db.update(
      'helper_applications',
      {
        'reviewed_at': now,
        'reviewed_by': reviewerId,
        'review_notes': reason,
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  static Future<int> getPendingApplicationsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE approval_status = ? AND user_type IN (?, ?)',
      ['pending', 'counselor', 'volunteer'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─── Daily Streaks ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStreak(String userId) async {
    final db = await database;
    final rows = await db.query('daily_streaks', where: 'user_id = ?', whereArgs: [userId]);
    if (rows.isEmpty) {
      return {'current_streak': 0, 'longest_streak': 0, 'last_checkin_date': null, 'total_checkins': 0};
    }
    return Map<String, dynamic>.from(rows.first);
  }

  static Future<void> updateStreak(String userId) async {
    final db = await database;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    final streak = await getStreak(userId);
    final lastDate = streak['last_checkin_date'] as String?;

    int currentStreak = streak['current_streak'] as int;
    int longestStreak = streak['longest_streak'] as int;
    int totalCheckins = streak['total_checkins'] as int;

    if (lastDate == todayStr) return; // already checked in today

    if (lastDate != null) {
      final last = DateTime.parse(lastDate);
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        currentStreak += 1;
      } else if (diff > 1) {
        currentStreak = 1; // streak broken
      }
    } else {
      currentStreak = 1;
    }

    totalCheckins += 1;
    if (currentStreak > longestStreak) longestStreak = currentStreak;

    await db.insert('daily_streaks', {
      'user_id': userId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_checkin_date': todayStr,
      'total_checkins': totalCheckins,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ─── Self-Care Entries ────────────────────────────────────────────────────

  static Future<void> saveSelfcareEntry(String userId, List<String> completedItems) async {
    final db = await database;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    final id = 'sc_${userId}_$todayStr';
    await db.insert('selfcare_entries', {
      'id': id,
      'user_id': userId,
      'date': todayStr,
      'completed_items': jsonEncode(completedItems),
      'score': completedItems.length,
      'created_at': today.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getTodaySelfcareEntry(String userId) async {
    final db = await database;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    final rows = await db.query('selfcare_entries',
        where: 'user_id = ? AND date = ?', whereArgs: [userId, todayStr]);
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  static Future<List<Map<String, dynamic>>> getSelfcareHistory(String userId, {int days = 30}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffStr = '${cutoff.year}-${cutoff.month.toString().padLeft(2,'0')}-${cutoff.day.toString().padLeft(2,'0')}';
    return await db.query('selfcare_entries',
        where: 'user_id = ? AND date >= ?',
        whereArgs: [userId, cutoffStr],
        orderBy: 'date DESC');
  }

  // ─── Journal Entries ──────────────────────────────────────────────────────

  static Future<void> saveJournalEntry({
    required String userId,
    required String title,
    required String content,
    required int moodBefore,
    required int moodAfter,
    String? voiceNotePath,
  }) async {
    final db = await database;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    final id = 'j_${userId}_${now.millisecondsSinceEpoch}';
    await db.insert('journal_entries', {
      'id': id,
      'user_id': userId,
      'date': todayStr,
      'title': title,
      'content': content,
      'mood_before': moodBefore,
      'mood_after': moodAfter,
      'has_voice_note': voiceNotePath != null ? 1 : 0,
      'voice_note_path': voiceNotePath,
      'created_at': now.toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getJournalEntries(String userId, {int days = 30}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffStr = '${cutoff.year}-${cutoff.month.toString().padLeft(2,'0')}-${cutoff.day.toString().padLeft(2,'0')}';
    return await db.query('journal_entries',
        where: 'user_id = ? AND date >= ?',
        whereArgs: [userId, cutoffStr],
        orderBy: 'date DESC');
  }

  static Future<void> deleteJournalEntry(String entryId) async {
    final db = await database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [entryId]);
  }
}

