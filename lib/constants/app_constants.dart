class AppConstants {
  // Website and Contact Information
  static const String websiteUrl = 'https://beaconnewbeginnings.org'; // Update this to your actual domain
  static const String organizationName = 'Beacon of New Beginnings';
  static const String organizationEmail = 'info@beaconnewbeginnings.org';
  static const String emergencyContactGhana = '191'; // Ghana Police Emergency
  static const String supportEmail = 'support@beaconnewbeginnings.org';
  
  // App Information
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Providing safety, healing, and empowerment to survivors of abuse and homelessness';
  
  // Emergency Contacts (Ghana)
  static const Map<String, String> emergencyContacts = {
    'Police': '191',
    'Fire Service': '192',
    'Ambulance': '193',
    'Domestic Violence Hotline': '055 123 4567', // Replace with actual hotline
    'Crisis Support': '024 567 8901', // Replace with actual crisis line
  };
  
  // Default Resource Categories
  static const List<String> resourceCategories = [
    'Shelter',
    'Legal Aid',
    'Counseling',
    'Healthcare',
    'Job Training',
    'Education',
    'Food & Clothing',
    'Financial Support',
  ];
  
  // Privacy and Security
  static const String privacyPolicyUrl = 'https://beaconnewbeginnings.org/privacy';
  static const String termsOfServiceUrl = 'https://beaconnewbeginnings.org/terms';
  
  // Beacon Brand Colors (from Brand Guideline)
  static const int primaryColorValue = 0xFFF0562D; // Vibrant Orange - courage, transformation
  static const int accentColorValue = 0xFFC6DEAD; // Soft Sage Green - growth, healing
  static const int emergencyColorValue = 0xFFE53935; // Keep red for emergencies
  static const int darkCharcoalValue = 0xFF221E1F; // Deep Charcoal - strength, stability
  static const int warmOffWhiteValue = 0xFFEAEADA; // Warm Off-White - clarity, calm
}