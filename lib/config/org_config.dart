/// All values that differ between the US (Beacon of New Beginnings) and
/// Ghana (BeaconPath Ghana) deployments of the same app binary.
class OrgConfig {
  final String orgKey; // 'us' | 'gh'
  final String orgName;
  final String orgTagline;
  final String website;
  final String supportEmail;
  final String infoEmail;

  // Localisation
  final String countryCode; // ISO 3166-1 alpha-2
  final String countryName;
  final String currencyCode; // ISO 4217
  final String currencySymbol;

  // Emergency contacts shown in the app and injected into AI prompts
  final Map<String, String> emergencyNumbers;
  final String dvHotline; // primary DV hotline number/text
  final String dvHotlineLabel;

  // AI prompt context — injected into Gemini system instructions
  final String dvAuthorityName; // e.g. 'DOVVSU' or 'local law enforcement'
  final String domesticViolenceLaw; // e.g. 'DV Act 2007 (Act 732)' or 'VAWA'
  final String legalAidName; // e.g. 'Legal Aid Commission' or 'Legal Aid'
  final String culturalContext; // freeform sentence(s) appended to AI prompts

  // Payments
  final String primaryGateway; // 'flutterwave' | 'stripe'
  final String merchantCountryCode; // for Apple/Google Pay

  const OrgConfig({
    required this.orgKey,
    required this.orgName,
    required this.orgTagline,
    required this.website,
    required this.supportEmail,
    required this.infoEmail,
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.emergencyNumbers,
    required this.dvHotline,
    required this.dvHotlineLabel,
    required this.dvAuthorityName,
    required this.domesticViolenceLaw,
    required this.legalAidName,
    required this.culturalContext,
    required this.primaryGateway,
    required this.merchantCountryCode,
  });
}

// ─── Ghana — BeaconPath Ghana ──────────────────────────────────────────────

const ghanaConfig = OrgConfig(
  orgKey: 'gh',
  orgName: 'BeaconPath Ghana',
  orgTagline: 'Walking the path from pain to power — hand in hand',
  website: 'https://beaconnewbeginnings.org',
  supportEmail: 'support@beaconnewbeginnings.org',
  infoEmail: 'info@beaconnewbeginnings.org',
  countryCode: 'GH',
  countryName: 'Ghana',
  currencyCode: 'GHS',
  currencySymbol: 'GH₵',
  emergencyNumbers: {
    'Police': '191',
    'Fire Service': '192',
    'Ambulance': '193',
    'DV Hotline (DOVVSU)': '0800800800',
    'Crisis Support': '080000000',
  },
  dvHotline: '0800800800',
  dvHotlineLabel: 'DOVVSU DV Hotline',
  dvAuthorityName: 'DOVVSU (Domestic Violence and Victim Support Unit)',
  domesticViolenceLaw: 'Ghana Domestic Violence Act 2007 (Act 732)',
  legalAidName: 'Legal Aid Commission Ghana',
  culturalContext:
      'Users are in Ghana. Reference Ghanaian services, DOVVSU units, '
      'local shelters such as the Ark Foundation and Oasis Ghana, and use '
      'culturally sensitive language appropriate for a Ghanaian context.',
  primaryGateway: 'flutterwave',
  merchantCountryCode: 'GH',
);

// ─── United States — Beacon of New Beginnings ─────────────────────────────

const usConfig = OrgConfig(
  orgKey: 'us',
  orgName: 'Beacon of New Beginnings',
  orgTagline: 'From pain to power — you are not alone',
  website: 'https://beaconnewbeginnings.org',
  supportEmail: 'support@beaconnewbeginnings.org',
  infoEmail: 'info@beaconnewbeginnings.org',
  countryCode: 'US',
  countryName: 'United States',
  currencyCode: 'USD',
  currencySymbol: '\$',
  emergencyNumbers: {
    'Emergency (Police / Fire / Ambulance)': '911',
    'National DV Hotline': '1-800-799-7233',
    'Crisis Text Line': 'Text HOME to 741741',
    'RAINN (Sexual Assault)': '1-800-656-4673',
    'Suicide & Crisis Lifeline': '988',
  },
  dvHotline: '1-800-799-7233',
  dvHotlineLabel: 'National Domestic Violence Hotline',
  dvAuthorityName: 'local law enforcement and DV shelter',
  domesticViolenceLaw:
      'Violence Against Women Act (VAWA) and applicable state DV statutes',
  legalAidName: 'local Legal Aid society',
  culturalContext:
      'Users are in the United States. Reference US services such as the '
      'National Domestic Violence Hotline (1-800-799-7233), local DV shelters, '
      'RAINN, and state-specific legal aid. Use language appropriate for a '
      'US survivor support context.',
  primaryGateway: 'stripe',
  merchantCountryCode: 'US',
);

/// All available configs, keyed by orgKey.
const Map<String, OrgConfig> allConfigs = {
  'gh': ghanaConfig,
  'us': usConfig,
};
