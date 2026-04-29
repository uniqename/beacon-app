import 'dart:math';

class AffirmationService {
  static final List<Map<String, String>> _bibleVerses = [
    {
      'text': 'The Lord is close to the brokenhearted and saves those who are crushed in spirit.',
      'reference': 'Psalm 34:18'
    },
    {
      'text': 'Fear not, for I am with you; be not dismayed, for I am your God; I will strengthen you, I will help you, I will uphold you with my righteous right hand.',
      'reference': 'Isaiah 41:10'
    },
    {
      'text': 'The Lord is my strength and my shield; my heart trusts in him, and he helps me.',
      'reference': 'Psalm 28:7'
    },
    {
      'text': 'Come to me, all you who are weary and burdened, and I will give you rest.',
      'reference': 'Matthew 11:28'
    },
    {
      'text': 'I can do all things through Christ who strengthens me.',
      'reference': 'Philippians 4:13'
    },
    {
      'text': 'God is our refuge and strength, an ever-present help in trouble.',
      'reference': 'Psalm 46:1'
    },
    {
      'text': 'Cast all your anxiety on him because he cares for you.',
      'reference': '1 Peter 5:7'
    },
    {
      'text': 'For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.',
      'reference': 'Jeremiah 29:11'
    },
    {
      'text': 'The Lord is my light and my salvation—whom shall I fear? The Lord is the stronghold of my life—of whom shall I be afraid?',
      'reference': 'Psalm 27:1'
    },
    {
      'text': 'Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.',
      'reference': 'Joshua 1:9'
    },
    {
      'text': 'He heals the brokenhearted and binds up their wounds.',
      'reference': 'Psalm 147:3'
    },
    {
      'text': 'The Lord will fight for you; you need only to be still.',
      'reference': 'Exodus 14:14'
    },
    {
      'text': 'Peace I leave with you; my peace I give you. I do not give to you as the world gives. Do not let your hearts be troubled and do not be afraid.',
      'reference': 'John 14:27'
    },
    {
      'text': 'The Lord your God is with you, the Mighty Warrior who saves. He will take great delight in you; in his love he will no longer rebuke you, but will rejoice over you with singing.',
      'reference': 'Zephaniah 3:17'
    },
    {
      'text': 'Even though I walk through the darkest valley, I will fear no evil, for you are with me; your rod and your staff, they comfort me.',
      'reference': 'Psalm 23:4'
    },
    {
      'text': 'But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint.',
      'reference': 'Isaiah 40:31'
    },
    {
      'text': 'The Lord is gracious and compassionate, slow to anger and rich in love.',
      'reference': 'Psalm 145:8'
    },
    {
      'text': 'And we know that in all things God works for the good of those who love him, who have been called according to his purpose.',
      'reference': 'Romans 8:28'
    },
    {
      'text': 'Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.',
      'reference': 'Proverbs 3:5-6'
    },
    {
      'text': 'The Lord is good, a refuge in times of trouble. He cares for those who trust in him.',
      'reference': 'Nahum 1:7'
    },
    {
      'text': 'Though the mountains be shaken and the hills be removed, yet my unfailing love for you will not be shaken nor my covenant of peace be removed, says the Lord, who has compassion on you.',
      'reference': 'Isaiah 54:10'
    },
    {
      'text': 'When you pass through the waters, I will be with you; and when you pass through the rivers, they will not sweep over you.',
      'reference': 'Isaiah 43:2'
    },
    {
      'text': 'The Lord is my shepherd, I lack nothing. He makes me lie down in green pastures, he leads me beside quiet waters, he refreshes my soul.',
      'reference': 'Psalm 23:1-3'
    },
    {
      'text': 'Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.',
      'reference': 'Joshua 1:9'
    },
    {
      'text': 'He gives strength to the weary and increases the power of the weak.',
      'reference': 'Isaiah 40:29'
    },
    {
      'text': 'My grace is sufficient for you, for my power is made perfect in weakness.',
      'reference': '2 Corinthians 12:9'
    },
    {
      'text': 'The Lord will keep you from all harm—he will watch over your life; the Lord will watch over your coming and going both now and forevermore.',
      'reference': 'Psalm 121:7-8'
    },
    {
      'text': 'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God. And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.',
      'reference': 'Philippians 4:6-7'
    },
    {
      'text': 'You, dear children, are from God and have overcome them, because the one who is in you is greater than the one who is in the world.',
      'reference': '1 John 4:4'
    },
    {
      'text': 'The Lord himself goes before you and will be with you; he will never leave you nor forsake you. Do not be afraid; do not be discouraged.',
      'reference': 'Deuteronomy 31:8'
    },
  ];

  /// Get the daily Bible verse/affirmation
  /// Uses the day of the year to ensure same verse shows all day
  static Map<String, String> getDailyVerse() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _bibleVerses.length;
    return _bibleVerses[index];
  }

  /// Get a random verse (for variety when user wants to see more)
  static Map<String, String> getRandomVerse() {
    final random = Random();
    return _bibleVerses[random.nextInt(_bibleVerses.length)];
  }

  /// Get all verses
  static List<Map<String, String>> getAllVerses() {
    return List.from(_bibleVerses);
  }
}
