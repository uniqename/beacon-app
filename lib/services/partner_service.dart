import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/partner.dart';

class PartnerService {
  static final PartnerService _instance = PartnerService._internal();
  factory PartnerService() => _instance;
  PartnerService._internal();

  final _uuid = const Uuid();
  static const _customKey = 'custom_partners';

  // ── Seed partners (Ghana-focused) ─────────────────────────────────────────
  static const List<Partner> _seedPartners = [
    // ── Police / DOVVSU ──────────────────────────────────────────────────────
    Partner(
      id: 'seed-dovvsu-national',
      name: 'DOVVSU – National Headquarters',
      type: 'police',
      description:
          'The Domestic Violence and Victim Support Unit of the Ghana Police Service. '
          'Dedicated to investigating domestic violence cases and protecting victims.',
      address: 'Police Headquarters, Ring Road Central, Accra',
      region: 'Greater Accra',
      phone: '0800-800-800',
      phone2: '0302772900',
      services: [
        'DV Case Investigation',
        'Protective Orders',
        'Emergency Shelter Referral',
        'Victim Support',
        'Child Protection',
      ],
      hours: 'Open 24/7',
      isVerified: true,
      isBeaconPartner: true,
    ),
    Partner(
      id: 'seed-dovvsu-kumasi',
      name: 'DOVVSU – Kumasi',
      type: 'police',
      description: 'DOVVSU office serving Kumasi and the Ashanti Region. '
          'Provides victim support and DV case investigation services.',
      address: 'Kumasi Central Police Station, Kumasi',
      region: 'Ashanti',
      phone: '0322024141',
      services: [
        'DV Case Investigation',
        'Protective Orders',
        'Emergency Referral',
        'Victim Support',
      ],
      hours: 'Open 24/7',
      isVerified: true,
      isBeaconPartner: true,
    ),
    Partner(
      id: 'seed-gps-emergency',
      name: 'Ghana Police Service – Emergency',
      type: 'police',
      description: 'National emergency police line for immediate danger situations.',
      address: 'Nationwide',
      region: 'National',
      phone: '999',
      phone2: '18555',
      services: ['Emergency Response', 'Crime Reporting', 'Protection'],
      hours: 'Open 24/7',
      isVerified: true,
      isBeaconPartner: false,
    ),

    // ── Legal Aid ──────────────────────────────────────────────────────────
    Partner(
      id: 'seed-fida-ghana',
      name: 'FIDA Ghana',
      type: 'legal',
      description:
          'International Federation of Women Lawyers – Ghana Chapter. '
          'Provides free legal aid and advocacy for women and children, especially DV survivors.',
      address: '4 Sir Arku Korsah Road, Airport Residential Area, Accra',
      region: 'Greater Accra',
      phone: '0302762901',
      email: 'fidaghana@gmail.com',
      website: 'https://fidaghana.org',
      services: [
        'Free Legal Aid',
        'Court Representation',
        'Legal Counseling',
        'Advocacy',
        'Protective Orders',
      ],
      hours: 'Mon–Fri: 8am–5pm',
      isVerified: true,
      isBeaconPartner: true,
    ),
    Partner(
      id: 'seed-legal-aid-ghana',
      name: 'Legal Aid Commission Ghana',
      type: 'legal',
      description:
          'Government commission providing free legal services to citizens who cannot afford legal representation.',
      address: 'Freetown Road, Adabraka, Accra',
      region: 'Greater Accra',
      phone: '0302221991',
      website: 'https://legalaidgh.org',
      services: [
        'Free Legal Aid',
        'Court Representation',
        'Legal Advice',
        'Mediation',
      ],
      hours: 'Mon–Fri: 8am–4:30pm',
      isVerified: true,
      isBeaconPartner: false,
    ),

    // ── NGOs / Shelters ───────────────────────────────────────────────────
    Partner(
      id: 'seed-ark-foundation',
      name: 'Ark Foundation Ghana',
      type: 'ngo',
      description:
          'NGO focused on eliminating all forms of violence against women and girls in Ghana. '
          'Provides emergency shelter, counseling, and advocacy.',
      address: 'House No. B 3/3, East Legon, Accra',
      region: 'Greater Accra',
      phone: '0302511189',
      email: 'arkfoundationghana@yahoo.com',
      services: [
        'Emergency Shelter',
        'Counseling',
        'Legal Referral',
        'Economic Empowerment',
        'Child Support',
      ],
      hours: 'Mon–Fri: 8am–5pm | Emergency: 24/7',
      isVerified: true,
      isBeaconPartner: true,
    ),
    Partner(
      id: 'seed-oasis-ghana',
      name: 'Oasis Ghana',
      type: 'shelter',
      description:
          'Provides safe housing and holistic support for survivors of domestic violence and trafficking.',
      address: 'Accra, Ghana',
      region: 'Greater Accra',
      phone: '0302780915',
      services: [
        'Safe Housing',
        'Counseling',
        'Skills Training',
        'Reintegration Support',
      ],
      hours: 'Mon–Fri: 8am–5pm',
      isVerified: true,
      isBeaconPartner: false,
    ),
    Partner(
      id: 'seed-lawa-ghana',
      name: 'LAWA Ghana',
      type: 'ngo',
      description:
          'Ladies Against Women Abuse – provides counseling, legal support, and outreach programs for abuse survivors.',
      address: 'Accra, Ghana',
      region: 'Greater Accra',
      phone: '0302776998',
      services: [
        'Counseling',
        'Legal Referral',
        'Support Groups',
        'Awareness Outreach',
      ],
      hours: 'Mon–Fri: 9am–5pm',
      isVerified: false,
      isBeaconPartner: false,
    ),
    Partner(
      id: 'seed-waju-ghana',
      name: 'WAJU – Women and Juvenile Unit',
      type: 'police',
      description:
          'Ghana Police unit dedicated to cases involving women and children, including domestic violence.',
      address: 'Various Police Stations, Nationwide',
      region: 'National',
      phone: '0302773906',
      services: [
        'DV Investigation',
        'Child Protection',
        'Victim Support',
        'Prosecution Support',
      ],
      hours: 'Open 24/7',
      isVerified: true,
      isBeaconPartner: false,
    ),

    // ── Hospitals / Medical ────────────────────────────────────────────────
    Partner(
      id: 'seed-korle-bu',
      name: 'Korle Bu Teaching Hospital',
      type: 'hospital',
      description:
          'Ghana\'s largest teaching hospital. Provides medical care, forensic examination, '
          'and documentation services for DV survivors.',
      address: 'Korle Bu, Accra',
      region: 'Greater Accra',
      phone: '0302674500',
      website: 'https://kbth.gov.gh',
      services: [
        'Emergency Medical Care',
        'Forensic Examination',
        'DV Documentation',
        'Mental Health Referral',
        'Social Work Services',
      ],
      hours: 'Emergency: 24/7 | Outpatient: Mon–Fri 7am–5pm',
      isVerified: true,
      isBeaconPartner: false,
    ),
    Partner(
      id: 'seed-37-military',
      name: '37 Military Hospital',
      type: 'hospital',
      description: 'Provides emergency and specialist medical care including services for abuse survivors.',
      address: '37 Liberation Road, Accra',
      region: 'Greater Accra',
      phone: '0302776111',
      services: [
        'Emergency Medical Care',
        'General Outpatient',
        'Mental Health',
        'Forensic Services',
      ],
      hours: 'Emergency: 24/7',
      isVerified: true,
      isBeaconPartner: false,
    ),
    Partner(
      id: 'seed-komfo-anokye',
      name: 'Komfo Anokye Teaching Hospital',
      type: 'hospital',
      description:
          'Major referral hospital for the Ashanti Region. Offers comprehensive medical services.',
      address: 'Hospital Road, Kumasi',
      region: 'Ashanti',
      phone: '0322022301',
      services: [
        'Emergency Medical Care',
        'Specialist Services',
        'Mental Health',
        'Social Work',
      ],
      hours: 'Emergency: 24/7',
      isVerified: true,
      isBeaconPartner: false,
    ),

    // ── Counseling / Mental Health ─────────────────────────────────────────
    Partner(
      id: 'seed-mhf-ghana',
      name: 'Mental Health Foundation Ghana',
      type: 'counselor',
      description:
          'Provides mental health advocacy, counseling, and community-based psychosocial support for trauma survivors.',
      address: 'Accra, Ghana',
      region: 'Greater Accra',
      phone: '0302233889',
      services: [
        'Trauma Counseling',
        'Group Therapy',
        'Community Mental Health',
        'Crisis Intervention',
      ],
      hours: 'Mon–Fri: 9am–5pm',
      isVerified: false,
      isBeaconPartner: true,
    ),
    Partner(
      id: 'seed-ghana-psychology',
      name: 'Ghana Psychology Council',
      type: 'counselor',
      description:
          'Regulatory body for psychologists in Ghana. Can refer survivors to certified professional counselors.',
      address: 'Accra, Ghana',
      region: 'Greater Accra',
      phone: '0302770669',
      services: ['Counselor Referral', 'Psychological Assessment', 'Therapy'],
      hours: 'Mon–Fri: 8am–4:30pm',
      isVerified: true,
      isBeaconPartner: false,
    ),

    // ── Churches ──────────────────────────────────────────────────────────
    Partner(
      id: 'seed-scripture-union',
      name: 'Scripture Union Ghana',
      type: 'church',
      description:
          'Christian organization providing counseling, support groups, and community care across Ghana.',
      address: 'Accra, Ghana',
      region: 'National',
      phone: '0302226477',
      website: 'https://sughana.org',
      services: [
        'Counseling',
        'Support Groups',
        'Crisis Prayer',
        'Community Outreach',
      ],
      hours: 'Mon–Fri: 9am–5pm',
      isVerified: true,
      isBeaconPartner: false,
    ),
    Partner(
      id: 'seed-catholic-secretariat',
      name: 'Catholic Secretariat of Ghana',
      type: 'church',
      description:
          'The Catholic Church\'s social services arm — provides counseling, shelter referrals, and community support programs.',
      address: 'P.O. Box 9712, Airport Accra',
      region: 'National',
      phone: '0302777434',
      website: 'https://ghanacatholic.org',
      services: [
        'Counseling',
        'Shelter Referral',
        'Community Support',
        'Children Support',
      ],
      hours: 'Mon–Fri: 8am–5pm',
      isVerified: true,
      isBeaconPartner: false,
    ),
    Partner(
      id: 'seed-presbyterian-development',
      name: 'Presbyterian Development & Relief Agency',
      type: 'church',
      description:
          'Church-based development agency providing crisis intervention, counseling, and livelihood support.',
      address: 'Accra, Ghana',
      region: 'National',
      phone: '0302224567',
      services: [
        'Crisis Support',
        'Counseling',
        'Livelihood Skills',
        'Community Programs',
      ],
      hours: 'Mon–Fri: 8am–5pm',
      isVerified: false,
      isBeaconPartner: false,
    ),
  ];

  String generateId() => _uuid.v4();

  Future<List<Partner>> getAllPartners() async {
    final custom = await _getCustomPartners();
    return [..._seedPartners, ...custom];
  }

  Future<List<Partner>> getPartnersByType(String type) async {
    final all = await getAllPartners();
    return all.where((p) => p.type == type).toList();
  }

  Future<List<Partner>> getBeaconPartners() async {
    final all = await getAllPartners();
    return all.where((p) => p.isBeaconPartner).toList();
  }

  Future<List<Partner>> searchPartners(String query) async {
    final all = await getAllPartners();
    final q = query.toLowerCase();
    return all
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.services.any((s) => s.toLowerCase().contains(q)) ||
            p.region.toLowerCase().contains(q))
        .toList();
  }

  Future<void> addPartner(Partner partner) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    List<Map<String, dynamic>> list = [];
    if (raw != null) {
      list = List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
    }
    list.removeWhere((p) => p['id'] == partner.id);
    list.add(partner.toMap());
    await prefs.setString(_customKey, jsonEncode(list));
  }

  Future<void> deletePartner(String partnerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    if (raw == null) return;
    List<Map<String, dynamic>> list =
        List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
    list.removeWhere((p) => p['id'] == partnerId);
    await prefs.setString(_customKey, jsonEncode(list));
  }

  Future<List<Partner>> _getCustomPartners() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Partner.fromMap(e as Map<String, dynamic>)).toList();
  }

  static const List<String> partnerTypes = [
    'church',
    'police',
    'hospital',
    'counselor',
    'shelter',
    'legal',
    'ngo',
    'other',
  ];
}
