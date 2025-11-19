import '../models/beacon_division.dart';
import '../models/resource.dart';
import '../models/case.dart';

class SmartAIService {
  // AI-powered resource routing system
  static List<BeaconDivision> smartResourceRouting({
    required String helpType,
    required String urgency,
    required String location,
    String? description,
  }) {
    List<BeaconDivision> allDivisions = _getAllBeaconDivisions();
    List<BeaconDivision> prioritizedDivisions = [];

    // AI Logic: Prioritize Beacon divisions first, then external options
    switch (helpType.toLowerCase()) {
      case 'emergency':
      case 'shelter':
        prioritizedDivisions = _prioritizeForShelter(allDivisions, urgency);
        break;
      case 'legal':
        prioritizedDivisions = _prioritizeForLegal(allDivisions, urgency);
        break;
      case 'counseling':
      case 'therapy':
        prioritizedDivisions = _prioritizeForCounseling(allDivisions, urgency);
        break;
      case 'healthcare':
      case 'medical':
        prioritizedDivisions = _prioritizeForHealthcare(allDivisions, urgency);
        break;
      case 'job-training':
      case 'employment':
        prioritizedDivisions = _prioritizeForJobTraining(allDivisions, urgency);
        break;
      case 'education':
        prioritizedDivisions = _prioritizeForEducation(allDivisions, urgency);
        break;
      case 'financial':
        prioritizedDivisions = _prioritizeForFinancial(allDivisions, urgency);
        break;
      case 'food':
      case 'clothing':
        prioritizedDivisions = _prioritizeForBasicNeeds(allDivisions, urgency);
        break;
      default:
        prioritizedDivisions = _prioritizeGeneral(allDivisions, urgency);
    }

    return prioritizedDivisions;
  }

  static List<BeaconDivision> _getAllBeaconDivisions() {
    return [
      BeaconDivision(
        id: 'beacon_shelter',
        name: 'BeaconGH Shelter Services',
        shortName: 'BeaconGH Shelter',
        description: 'Planning comprehensive emergency and transitional housing programs',
        icon: '🏠',
        color: '#2E8B57',
        services: [
          'Emergency shelter placement (Available 24/7)',
          'Transitional housing (In Development)',
          'Safety planning (Available)',
          'Children accommodation (Planning)',
          '24/7 security (Future)'
        ],
        resources: [
          'Crisis intervention (Available)',
          'Case management (Available)',
          'Support groups (Planning)',
          'Community partnerships (Building)'
        ],
        isAvailable: false,
        capacity: 0,
        contactEmail: 'shelter@beaconnewbeginnings.org',
        contactPhone: '+233501234567',
        donationUrl: 'https://beaconnewbeginnings.org/donate/shelter',
        jobOpenings: [],
      ),
      BeaconDivision(
        id: 'beacon_legal',
        name: 'BeaconGH Legal Assistance',
        shortName: 'BeaconGH Legal',
        description: 'Building legal advocacy network and partnerships for survivors',
        icon: '⚖️',
        color: '#1B5E42',
        services: [
          'Legal representation (Building Network)',
          'Court accompaniment (Future)',
          'Protective orders (Planning)',
          'Family law assistance (Available)',
          'Immigration support (Future)'
        ],
        resources: [
          'Pro bono lawyers (Recruiting)',
          'Legal aid application (Available)',
          'Court documentation (Future)',
          'Rights education (Planning)'
        ],
        isAvailable: false,
        capacity: 0,
        contactEmail: 'legal@beaconnewbeginnings.org',
        contactPhone: '+233501234568',
        donationUrl: 'https://beaconnewbeginnings.org/donate/legal',
        jobOpenings: [],
      ),
      BeaconDivision(
        id: 'beacon_counseling',
        name: 'BeaconGH Counseling Services',
        shortName: 'BeaconGH Counseling',
        description: 'Developing trauma-informed therapy and mental health programs',
        icon: '💬',
        color: '#4CAF50',
        services: [
          'Individual therapy (Available)',
          'Group counseling (Planning)',
          'Family therapy (Future)',
          'Trauma counseling (In Development)',
          'Crisis intervention (Available)'
        ],
        resources: [
          'Licensed therapists (Recruiting)',
          'Support groups (Planning)',
          'Mental health workshops (Future)',
          'Peer counseling (Available)'
        ],
        isAvailable: false,
        capacity: 0,
        contactEmail: 'counseling@beaconnewbeginnings.org',
        contactPhone: '+233501234569',
        donationUrl: 'https://beaconnewbeginnings.org/donate/counseling',
        jobOpenings: [],
      ),
      BeaconDivision(
        id: 'beacon_groups',
        name: 'BeaconGH Support Groups',
        shortName: 'BeaconGH Groups',
        description: 'Creating peer support networks and community healing initiatives',
        icon: '👥',
        color: '#FFA726',
        services: [
          'Survivor support circles (Planning)',
          'Peer mentoring (Available)',
          'Skills workshops (Future)',
          'Community events (Planning)',
          'Healing retreats (Future)'
        ],
        resources: [
          'Weekly group meetings (Planning)',
          'Peer support network (Building)',
          'Online forums (Future)',
          'Resource sharing (Available)'
        ],
        isAvailable: false,
        capacity: 0,
        contactEmail: 'groups@beaconnewbeginnings.org',
        contactPhone: '+233501234570',
        donationUrl: 'https://beaconnewbeginnings.org/donate/groups',
        jobOpenings: [],
      ),
      BeaconDivision(
        id: 'beacon_healthcare',
        name: 'BeaconGH Healthcare Support',
        shortName: 'BeaconGH Healthcare',
        description: 'Establishing medical care coordination and health advocacy programs',
        icon: '🏥',
        color: '#64B5F6',
        services: [
          'Medical referrals (Building Network)',
          'Health insurance assistance (Available)',
          'Mental health medication (Future)',
          'Emergency medical care (Planning)',
          'Health education (Available)'
        ],
        resources: [
          'Partner clinics (Developing)',
          'Mobile health units (Future)',
          'Prescription assistance (Planning)',
          'Health screenings (Available)'
        ],
        isAvailable: false,
        capacity: 0,
        contactEmail: 'healthcare@beaconnewbeginnings.org',
        contactPhone: '+233501234571',
        donationUrl: 'https://beaconnewbeginnings.org/donate/healthcare',
        jobOpenings: [],
      ),
      BeaconDivision(
        id: 'beacon_job_training',
        name: 'BeaconGH Job Training',
        shortName: 'BeaconGH Training',
        description: 'Launching vocational skills and employment preparation programs',
        icon: '💼',
        color: '#9C27B0',
        services: [
          'Vocational training (Planning)',
          'Computer literacy (Available)',
          'Job placement (Future)',
          'Resume building (Planning)',
          'Interview preparation (Available)'
        ],
        resources: [
          'Training workshops (Developing)',
          'Employer partnerships (Building)',
          'Equipment lending (Future)',
          'Certification programs (Planning)'
        ],
        isAvailable: false,
        capacity: 0,
        contactEmail: 'training@beaconnewbeginnings.org',
        contactPhone: '+233501234572',
        donationUrl: 'https://beaconnewbeginnings.org/donate/training',
        jobOpenings: [],
      ),
      BeaconDivision(
        id: 'beacon_education',
        name: 'BeaconGH Education Assistance',
        shortName: 'BeaconGH Education',
        description: 'Developing educational support and literacy programs for survivors and families',
        icon: '🎓',
        color: '#FF6B35',
        services: [
          'Adult literacy (Planning)',
          'GED preparation (Available)',
          'Scholarship assistance (Future)',
          'Children\'s tutoring (Planning)',
          'Educational counseling (Available)'
        ],
        resources: [
          'Literacy classes (Developing)',
          'Educational materials (Planning)',
          'Tutoring services (Future)',
          'Scholarship fund (Building)'
        ],
        isAvailable: false,
        capacity: 0,
        contactEmail: 'education@beaconnewbeginnings.org',
        contactPhone: '+233501234573',
        donationUrl: 'https://beaconnewbeginnings.org/donate/education',
        jobOpenings: [],
      ),
      BeaconDivision(
        id: 'beacon_financial',
        name: 'BeaconGH Financial Options',
        shortName: 'BeaconGH Financial',
        description: 'Creating financial literacy programs and emergency assistance funds',
        icon: '💰',
        color: '#388E3C',
        services: [
          'Emergency financial aid (Planning)',
          'Financial literacy training (Available)',
          'Micro-loans (Future)',
          'Savings programs (Planning)',
          'Budget counseling (Available)'
        ],
        resources: [
          'Emergency fund (Building)',
          'Financial workshops (Planning)',
          'Banking partnerships (Developing)',
          'Credit building (Future)'
        ],
        isAvailable: false,
        capacity: 0,
        contactEmail: 'financial@beaconnewbeginnings.org',
        contactPhone: '+233501234574',
        donationUrl: 'https://beaconnewbeginnings.org/donate/financial',
        jobOpenings: [],
      ),
      BeaconDivision(
        id: 'beacon_basic_needs',
        name: 'BeaconGH Food & Clothing Assistance',
        shortName: 'BeaconGH Basic Needs',
        description: 'Establishing emergency food, clothing, and essential supplies distribution',
        icon: '🍽️',
        color: '#D32F2F',
        services: [
          'Food pantry (Planning)',
          'Clothing bank (Available)',
          'Emergency supplies (Planning)',
          'Meal programs (Future)',
          'Hygiene kits (Available)'
        ],
        resources: [
          'Food distribution (Planning)',
          'Clothing donations (Building)',
          'Emergency supplies (Available)',
          'Mobile food truck (Future)'
        ],
        isAvailable: false,
        capacity: 0,
        contactEmail: 'basicneeds@beaconnewbeginnings.org',
        contactPhone: '+233501234575',
        donationUrl: 'https://beaconnewbeginnings.org/donate/basicneeds',
        jobOpenings: [],
      ),
    ];
  }

  static List<BeaconDivision> _prioritizeForShelter(List<BeaconDivision> divisions, String urgency) {
    List<BeaconDivision> prioritized = [];
    
    // Only show shelter-specific services
    prioritized.add(divisions.firstWhere((d) => d.id == 'beacon_shelter'));
    
    return prioritized;
  }

  static List<BeaconDivision> _prioritizeForLegal(List<BeaconDivision> divisions, String urgency) {
    List<BeaconDivision> prioritized = [];
    
    // Only show legal-specific services
    prioritized.add(divisions.firstWhere((d) => d.id == 'beacon_legal'));
    
    return prioritized;
  }

  static List<BeaconDivision> _prioritizeForCounseling(List<BeaconDivision> divisions, String urgency) {
    List<BeaconDivision> prioritized = [];
    
    // Only show counseling-specific services
    prioritized.add(divisions.firstWhere((d) => d.id == 'beacon_counseling'));
    
    return prioritized;
  }

  static List<BeaconDivision> _prioritizeForHealthcare(List<BeaconDivision> divisions, String urgency) {
    List<BeaconDivision> prioritized = [];
    
    // Only show healthcare-specific services
    prioritized.add(divisions.firstWhere((d) => d.id == 'beacon_healthcare'));
    
    return prioritized;
  }

  static List<BeaconDivision> _prioritizeForJobTraining(List<BeaconDivision> divisions, String urgency) {
    List<BeaconDivision> prioritized = [];
    
    // Only show job training-specific services
    prioritized.add(divisions.firstWhere((d) => d.id == 'beacon_job_training'));
    
    return prioritized;
  }

  static List<BeaconDivision> _prioritizeForEducation(List<BeaconDivision> divisions, String urgency) {
    List<BeaconDivision> prioritized = [];
    
    // Only show education-specific services
    prioritized.add(divisions.firstWhere((d) => d.id == 'beacon_education'));
    
    return prioritized;
  }

  static List<BeaconDivision> _prioritizeForFinancial(List<BeaconDivision> divisions, String urgency) {
    List<BeaconDivision> prioritized = [];
    
    // Only show financial-specific services
    prioritized.add(divisions.firstWhere((d) => d.id == 'beacon_financial'));
    
    return prioritized;
  }

  static List<BeaconDivision> _prioritizeForBasicNeeds(List<BeaconDivision> divisions, String urgency) {
    List<BeaconDivision> prioritized = [];
    
    // Only show basic needs-specific services
    prioritized.add(divisions.firstWhere((d) => d.id == 'beacon_basic_needs'));
    
    return prioritized;
  }

  static List<BeaconDivision> _prioritizeGeneral(List<BeaconDivision> divisions, String urgency) {
    // Return all divisions for general help
    return divisions;
  }

  // AI-powered job matching with real opportunities
  static List<JobOpportunity> getRelevantJobs({
    required String userSkills,
    required String location,
    String? availability,
  }) {
    List<JobOpportunity> allJobs = _getAllJobOpportunities();
    
    // Filter and score jobs based on user preferences
    List<JobOpportunity> relevantJobs = allJobs.where((job) {
      // Location matching
      if (location.isNotEmpty && !job.location.toLowerCase().contains(location.toLowerCase())) {
        if (!job.isRemote) return false;
      }
      
      // Availability matching
      if (availability != null && availability.isNotEmpty) {
        if (availability.toLowerCase() == 'part-time' && job.type != 'part-time') {
          return false;
        }
        if (availability.toLowerCase() == 'full-time' && job.type != 'full-time') {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Sort by posting date (newest first) and urgent status
    relevantJobs.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return b.postedDate.compareTo(a.postedDate);
    });
    
    return relevantJobs;
  }

  static List<JobOpportunity> _getAllJobOpportunities() {
    return [
      JobOpportunity(
        id: 'job_001',
        title: 'Administrative Assistant',
        type: 'full-time',
        description: 'Support office operations and provide administrative assistance to the BeaconGH team. Ideal for those seeking stable employment with growth opportunities.',
        requirements: [
          'Basic computer skills (Microsoft Office)',
          'Good communication skills',
          'High school diploma or equivalent',
          'Ability to work independently',
        ],
        location: 'Accra',
        isRemote: false,
        applicationEmail: 'jobs@beaconnewbeginnings.org',
        postedDate: DateTime.now().subtract(const Duration(days: 3)),
        isUrgent: false,
      ),
      JobOpportunity(
        id: 'job_002',
        title: 'Peer Support Counselor',
        type: 'part-time',
        description: 'Provide peer support and mentoring to other survivors. This position is specifically designed for survivors who want to help others in their healing journey.',
        requirements: [
          'Personal experience with recovery/healing',
          'Strong listening and communication skills',
          'Ability to maintain confidentiality',
          'Willingness to undergo training',
          'Emotional stability and self-awareness',
        ],
        location: 'Accra',
        isRemote: true,
        applicationEmail: 'counseling@beaconnewbeginnings.org',
        postedDate: DateTime.now().subtract(const Duration(days: 1)),
        isUrgent: true,
      ),
      JobOpportunity(
        id: 'job_003',
        title: 'Skills Training Instructor',
        type: 'part-time',
        description: 'Teach vocational skills to program participants. Areas needed: sewing, cooking, computer basics, and small business management.',
        requirements: [
          'Expertise in at least one vocational skill',
          'Experience teaching or training others',
          'Patience and understanding with trauma survivors',
          'Relevant certifications preferred',
        ],
        location: 'Accra',
        isRemote: false,
        applicationEmail: 'training@beaconnewbeginnings.org',
        postedDate: DateTime.now().subtract(const Duration(days: 5)),
        isUrgent: false,
      ),
      JobOpportunity(
        id: 'job_004',
        title: 'Community Outreach Volunteer',
        type: 'volunteer',
        description: 'Help raise awareness about domestic violence and connect with community members. Flexible schedule with training provided.',
        requirements: [
          'Passion for helping others',
          'Good communication skills',
          'Ability to work with diverse communities',
          'Weekend availability preferred',
        ],
        location: 'Greater Accra',
        isRemote: false,
        applicationEmail: 'volunteer@beaconnewbeginnings.org',
        postedDate: DateTime.now().subtract(const Duration(days: 2)),
        isUrgent: true,
      ),
      JobOpportunity(
        id: 'job_005',
        title: 'Data Entry Clerk',
        type: 'part-time',
        description: 'Remote data entry position perfect for those who need flexible work arrangements. Training provided.',
        requirements: [
          'Basic computer skills',
          'Attention to detail',
          'Reliable internet connection',
          'Ability to maintain confidentiality',
        ],
        location: 'Remote',
        isRemote: true,
        applicationEmail: 'admin@beaconnewbeginnings.org',
        postedDate: DateTime.now().subtract(const Duration(days: 7)),
        isUrgent: false,
      ),
      JobOpportunity(
        id: 'job_006',
        title: 'Childcare Assistant',
        type: 'part-time',
        description: 'Provide childcare services for children of program participants during counseling sessions and training programs.',
        requirements: [
          'Experience working with children',
          'Background check required',
          'First aid certification preferred',
          'Understanding of trauma-informed care',
        ],
        location: 'Accra',
        isRemote: false,
        applicationEmail: 'childcare@beaconnewbeginnings.org',
        postedDate: DateTime.now().subtract(const Duration(days: 4)),
        isUrgent: true,
      ),
      JobOpportunity(
        id: 'job_007',
        title: 'Website Content Creator',
        type: 'freelance',
        description: 'Create engaging content for our website and social media to help spread awareness and share success stories.',
        requirements: [
          'Writing and communication skills',
          'Basic understanding of social media',
          'Experience with content creation',
          'Sensitivity to trauma-related topics',
        ],
        location: 'Remote',
        isRemote: true,
        applicationEmail: 'marketing@beaconnewbeginnings.org',
        postedDate: DateTime.now().subtract(const Duration(days: 6)),
        isUrgent: false,
      ),
    ];
  }
}