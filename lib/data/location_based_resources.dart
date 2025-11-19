import '../models/resource.dart';

class LocationBasedResources {
  static List<Resource> getGhanaResources() {
    return [
      Resource(
        id: 'gh_1',
        name: 'DOVVSU (Domestic Violence Support Unit)',
        description: 'Ghana Police domestic violence and victim support unit',
        type: ResourceType.emergency,
        status: ResourceStatus.available,
        phone: '+233302773906',
        website: 'https://dovvsu.police.gov.gh',
        address: 'Police Headquarters, Accra',
        createdAt: DateTime.now(),
        is24Hours: true,
      ),
      Resource(
        id: 'gh_2',
        name: 'WiLDAF Ghana',
        description: 'Women in Law and Development in Africa - Ghana',
        type: ResourceType.legal,
        status: ResourceStatus.available,
        phone: '+233302761170',
        website: 'https://wildafghana.org',
        address: 'East Legon, Accra',
        createdAt: DateTime.now(),
      ),
      Resource(
        id: 'gh_3',
        name: 'Ark Foundation',
        description: 'Domestic violence shelter and support services',
        type: ResourceType.shelter,
        status: ResourceStatus.available,
        phone: '+233244765988',
        website: 'https://arkfoundationghana.org',
        address: 'Tema, Greater Accra',
        createdAt: DateTime.now(),
        is24Hours: true,
      ),
      Resource(
        id: 'gh_4',
        name: 'Mental Health Authority Ghana',
        description: 'Mental health services and crisis support',
        type: ResourceType.counseling,
        status: ResourceStatus.available,
        phone: '+233302684054',
        website: 'https://moh.gov.gh',
        address: 'Accra, Ghana',
        createdAt: DateTime.now(),
      ),
      Resource(
        id: 'gh_5',
        name: 'Legal Aid Board Ghana',
        description: 'Free legal aid and representation',
        type: ResourceType.legal,
        status: ResourceStatus.available,
        phone: '+233302685995',
        website: 'https://legalaid.gov.gh',
        address: 'Accra, Ghana',
        createdAt: DateTime.now(),
      ),
      Resource(
        id: 'gh_6',
        name: 'Ghana Health Service',
        description: 'Public healthcare services and medical support',
        type: ResourceType.medical,
        status: ResourceStatus.available,
        phone: '+233302681109',
        website: 'https://ghs.gov.gh',
        address: 'Accra, Ghana',
        createdAt: DateTime.now(),
      ),
    ];
  }

  static List<Resource> getUSAResources(String? state) {
    List<Resource> baseResources = [
      Resource(
        id: 'us_1',
        name: 'National Domestic Violence Hotline',
        description: '24/7 confidential domestic violence support',
        type: ResourceType.hotline,
        status: ResourceStatus.available,
        phone: '1-800-799-7233',
        website: 'https://thehotline.org',
        address: 'National Service',
        createdAt: DateTime.now(),
        is24Hours: true,
      ),
      Resource(
        id: 'us_2',
        name: 'National Sexual Assault Hotline',
        description: '24/7 sexual assault crisis support',
        type: ResourceType.hotline,
        status: ResourceStatus.available,
        phone: '1-800-656-4673',
        website: 'https://rainn.org',
        address: 'National Service',
        createdAt: DateTime.now(),
        is24Hours: true,
      ),
      Resource(
        id: 'us_3',
        name: 'Crisis Text Line',
        description: 'Text HOME to 741741 for crisis support',
        type: ResourceType.hotline,
        status: ResourceStatus.available,
        phone: '741741',
        website: 'https://crisistextline.org',
        address: 'National Service',
        createdAt: DateTime.now(),
        is24Hours: true,
      ),
      Resource(
        id: 'us_4',
        name: 'National Suicide Prevention Lifeline',
        description: '24/7 suicide prevention and mental health crisis support',
        type: ResourceType.hotline,
        status: ResourceStatus.available,
        phone: '988',
        website: 'https://suicidepreventionlifeline.org',
        address: 'National Service',
        createdAt: DateTime.now(),
        is24Hours: true,
      ),
    ];

    // Add state-specific resources
    if (state != null) {
      baseResources.addAll(_getStateSpecificResources(state));
    }

    return baseResources;
  }

  static List<Resource> _getStateSpecificResources(String state) {
    switch (state.toLowerCase()) {
      case 'california':
        return [
          Resource(
            id: 'ca_1',
            name: 'California Partnership to End Domestic Violence',
            description: 'California domestic violence resources and advocacy',
            type: ResourceType.legal,
            status: ResourceStatus.available,
            phone: '1-916-444-7163',
            website: 'https://cpedv.org',
            address: 'Sacramento, CA',
            createdAt: DateTime.now(),
          ),
          Resource(
            id: 'ca_2',
            name: 'Los Angeles Domestic Violence Hotline',
            description: 'LA County domestic violence support',
            type: ResourceType.hotline,
            status: ResourceStatus.available,
            phone: '1-877-531-2522',
            website: 'https://lacounty.gov',
            address: 'Los Angeles County, CA',
            createdAt: DateTime.now(),
            is24Hours: true,
          ),
        ];
      case 'new york':
        return [
          Resource(
            id: 'ny_1',
            name: 'New York State Domestic Violence Hotline',
            description: 'NY state domestic violence support',
            type: ResourceType.hotline,
            status: ResourceStatus.available,
            phone: '1-800-942-6906',
            website: 'https://opdv.ny.gov',
            address: 'New York State',
            createdAt: DateTime.now(),
            is24Hours: true,
          ),
          Resource(
            id: 'ny_2',
            name: 'Safe Horizon',
            description: 'NYC domestic violence shelter and services',
            type: ResourceType.shelter,
            status: ResourceStatus.available,
            phone: '1-800-621-4673',
            website: 'https://safehorizon.org',
            address: 'New York City, NY',
            createdAt: DateTime.now(),
            is24Hours: true,
          ),
        ];
      case 'texas':
        return [
          Resource(
            id: 'tx_1',
            name: 'Texas Council on Family Violence',
            description: 'Texas domestic violence resources',
            type: ResourceType.legal,
            status: ResourceStatus.available,
            phone: '1-512-794-1133',
            website: 'https://tcfv.org',
            address: 'Austin, TX',
            createdAt: DateTime.now(),
          ),
          Resource(
            id: 'tx_2',
            name: 'Family Place',
            description: 'Dallas domestic violence shelter',
            type: ResourceType.shelter,
            status: ResourceStatus.available,
            phone: '1-214-941-1991',
            website: 'https://familyplace.org',
            address: 'Dallas, TX',
            createdAt: DateTime.now(),
            is24Hours: true,
          ),
        ];
      case 'florida':
        return [
          Resource(
            id: 'fl_1',
            name: 'Florida Coalition Against Domestic Violence',
            description: 'Florida domestic violence resources',
            type: ResourceType.legal,
            status: ResourceStatus.available,
            phone: '1-850-425-2749',
            website: 'https://fcadv.org',
            address: 'Tallahassee, FL',
            createdAt: DateTime.now(),
          ),
        ];
      default:
        return [
          Resource(
            id: 'state_generic',
            name: '$state Department of Health and Human Services',
            description: 'State health and human services department',
            type: ResourceType.legal,
            status: ResourceStatus.available,
            phone: '211',
            website: 'https://hhs.gov',
            address: state,
            createdAt: DateTime.now(),
          ),
        ];
    }
  }

  static List<Resource> getInternationalResources() {
    return [
      Resource(
        id: 'intl_1',
        name: 'International Direct Dial Emergency',
        description: 'International emergency services',
        type: ResourceType.emergency,
        status: ResourceStatus.available,
        phone: '911',
        website: '',
        address: 'International',
        createdAt: DateTime.now(),
        is24Hours: true,
      ),
      Resource(
        id: 'intl_2',
        name: 'World Health Organization',
        description: 'Global health information and resources',
        type: ResourceType.medical,
        status: ResourceStatus.available,
        phone: '',
        website: 'https://who.int',
        address: 'International',
        createdAt: DateTime.now(),
      ),
    ];
  }
}