class AppLocalizations {
  static const String fallbackLanguage = 'en';

  static const Map<String, Map<String, String>> _localized = {
    'en': {
      'app_name': 'Smart Billing',
      'select_language': 'Select Language',
      'continue': 'Continue',
      'login': 'Login',
      'register': 'Register',
      'email_or_phone': 'Email / Phone',
      'password': 'Password',
      'logout': 'Logout',
      'billing': 'Billing',
      'products': 'Products',
      'dashboard': 'Dashboard',
      'more': 'More',
      'quick_add_bill': 'Quick Add Bill',
      'b2b_marketplace': 'B2B Marketplace',
      'notifications': 'Notifications',
      'feedback': 'Feedback',
      'demo_mode': 'Demo Mode',
      'settings': 'Settings',
      'business_ai': 'Business AI Insights',
      'stock_reorder': 'AI Stock Reorder',
    },
    'ta': {
      'app_name': 'ஸ்மார்ட் பில்லிங்',
      'select_language': 'மொழியை தேர்ந்தெடுக்கவும்',
      'continue': 'தொடரவும்',
      'login': 'உள்நுழை',
      'register': 'பதிவு செய்',
      'email_or_phone': 'மின்னஞ்சல் / தொலைபேசி',
      'password': 'கடவுச்சொல்',
      'logout': 'வெளியேறு',
      'billing': 'பில்லிங்',
      'products': 'பொருட்கள்',
      'dashboard': 'டாஷ்போர்டு',
      'more': 'மேலும்',
      'quick_add_bill': 'விரைவு பில்',
      'b2b_marketplace': 'B2B சந்தை',
      'notifications': 'அறிவிப்புகள்',
      'feedback': 'கருத்து',
      'demo_mode': 'டெமோ முறை',
      'settings': 'அமைப்புகள்',
      'business_ai': 'வணிக AI பார்வைகள்',
      'stock_reorder': 'AI மறுவரிசை',
    },
    'hi': {
      'app_name': 'स्मार्ट बिलिंग',
      'select_language': 'भाषा चुनें',
      'continue': 'जारी रखें',
      'login': 'लॉगिन',
      'register': 'रजिस्टर',
      'email_or_phone': 'ईमेल / फोन',
      'password': 'पासवर्ड',
      'logout': 'लॉगआउट',
      'billing': 'बिलिंग',
      'products': 'प्रोडक्ट्स',
      'dashboard': 'डैशबोर्ड',
      'more': 'और',
    },
    'te': {
      'select_language': 'భాషను ఎంచుకోండి',
      'login': 'లాగిన్',
      'register': 'నమోదు',
    },
    'ml': {
      'select_language': 'ഭാഷ തിരഞ്ഞെടുക്കുക',
      'login': 'ലോഗിൻ',
      'register': 'രജിസ്റ്റർ',
    },
    'kn': {
      'select_language': 'ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ',
      'login': 'ಲಾಗಿನ್',
      'register': 'ನೋಂದಣಿ',
    },
  };

  static String tr(String languageCode, String key) {
    final lang = _localized[languageCode];
    final fallback = _localized[fallbackLanguage]!;
    return lang?[key] ?? fallback[key] ?? key;
  }
}
