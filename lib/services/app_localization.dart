import 'package:flutter/material.dart';

/// Multi-language support service.
/// Provides Hindi + English translations for the app.
class AppLocalization {
  final Locale locale;
  AppLocalization(this.locale);

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization)!;
  }

  static const LocalizationsDelegate<AppLocalization> delegate =
      _AppLocalizationDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', 'IN'),
    Locale('hi', 'IN'),
  ];

  bool get isHindi => locale.languageCode == 'hi';

  // ─── Translations Map ──────────────────────────────────────

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      // Navigation
      'home': 'Home',
      'marketplace': 'Marketplace',
      'trades': 'Trades',
      'wallet': 'Wallet',
      'profile': 'Profile',

      // Home
      'welcome': 'Welcome',
      'credit_balance': 'Credit Balance',
      'reputation_score': 'Reputation Score',
      'quick_actions': 'Quick Actions',
      'create_listing': 'Create Listing',
      'quality_check': 'AI Quality Check',
      'urgent_request': 'Urgent Request',
      'disputes': 'Disputes',
      'active_trades': 'Active Trades',
      'recent_listings': 'Recent Listings',
      'view_all': 'View All',
      'nearby_farmers': 'Nearby Farmers',
      'mandi_prices': 'Mandi Prices',

      // Listings
      'what_offering': 'What are you offering?',
      'quantity': 'Quantity',
      'what_want': 'What do you want in exchange?',
      'quality_level': 'Quality Level',
      'estimated_value': 'Estimated Value',
      'based_on_mandi': 'Based on\nmandi rates',
      'create_listing_btn': 'Create Listing 🌱',
      'no_listings': 'No listings found',

      // Trades
      'confirm': 'Confirm',
      'decline': 'Decline',
      'trade_matched': 'Trade Matched!',
      'pending_confirmation': 'Pending Confirmation',
      'completed': 'Completed',
      'all_confirmed': 'All participants confirmed',

      // Quality
      'ai_quality_check': 'AI Quality Check',
      'tap_capture': 'Tap to Capture & Analyze',
      'take_photo': 'Take a photo of your produce',
      'analyzing': 'AI Analyzing Produce...',
      'freshness': 'Freshness',
      'damage': 'Damage Detection',
      'color_quality': 'Color Quality',
      'size_consistency': 'Size Consistency',
      'save_report': 'Save Report',
      're_analyze': 'Re-analyze',
      'pick_gallery': 'Or pick from gallery',

      // Urgent
      'post_request': 'Post Urgent Request',
      'fulfill_request': 'Fulfill Request',
      'cancel_request': 'Cancel Request',
      'credit_cost': 'Credit Cost',

      // Disputes
      'file_dispute': 'File Dispute',
      'dispute_resolved': 'Dispute Resolved',
      'ai_verdict': 'AI Verdict',

      // Profile
      'sign_out': 'Sign Out',
      'export_data': 'Export Data for FPO',
      'language': 'Language',
      'switch_hindi': 'हिन्दी में बदलें',
      'switch_english': 'Switch to English',

      // Auth
      'set_up_profile': 'Set Up Profile',
      'your_name': 'Your Name',
      'your_village': 'Your Village',
      'auto_detect': 'Auto-detect',
      'start_trading': 'Start Trading 🌾',
      'enter_name': 'Enter your full name',
      'enter_village': 'Enter your village name',
      'mobile_number': 'Mobile Number',

      // Distance
      'km_away': 'km away',
      'transport_cost': 'Transport: ₹',
      'nearby': 'Nearby',
      'far': 'Far',

      // Price Discovery
      'price_discovery': 'Price Discovery',
      'commodity': 'Commodity',
      'min_price': 'Min',
      'max_price': 'Max',
      'modal_price': 'Modal',
      'last_updated': 'Last Updated',
      'refresh_prices': 'Refresh Prices',
      'per_kg': '/kg',
    },
    'hi': {
      // Navigation
      'home': 'होम',
      'marketplace': 'बाज़ार',
      'trades': 'व्यापार',
      'wallet': 'वॉलेट',
      'profile': 'प्रोफ़ाइल',

      // Home
      'welcome': 'स्वागत है',
      'credit_balance': 'क्रेडिट बैलेंस',
      'reputation_score': 'प्रतिष्ठा स्कोर',
      'quick_actions': 'त्वरित कार्य',
      'create_listing': 'लिस्टिंग बनाएं',
      'quality_check': 'AI गुणवत्ता जाँच',
      'urgent_request': 'अत्यावश्यक अनुरोध',
      'disputes': 'विवाद',
      'active_trades': 'सक्रिय व्यापार',
      'recent_listings': 'हाल की लिस्टिंग',
      'view_all': 'सभी देखें',
      'nearby_farmers': 'पास के किसान',
      'mandi_prices': 'मंडी भाव',

      // Listings
      'what_offering': 'आप क्या दे रहे हैं?',
      'quantity': 'मात्रा',
      'what_want': 'बदले में आप क्या चाहते हैं?',
      'quality_level': 'गुणवत्ता स्तर',
      'estimated_value': 'अनुमानित मूल्य',
      'based_on_mandi': 'मंडी भाव\nके अनुसार',
      'create_listing_btn': 'लिस्टिंग बनाएं 🌱',
      'no_listings': 'कोई लिस्टिंग नहीं',

      // Trades
      'confirm': 'पुष्टि करें',
      'decline': 'अस्वीकार',
      'trade_matched': 'व्यापार मिला!',
      'pending_confirmation': 'पुष्टि बाकी',
      'completed': 'पूर्ण',
      'all_confirmed': 'सभी ने पुष्टि की',

      // Quality
      'ai_quality_check': 'AI गुणवत्ता जाँच',
      'tap_capture': 'फ़ोटो लें और जाँच करें',
      'take_photo': 'अपने उत्पाद की फ़ोटो लें',
      'analyzing': 'AI जाँच कर रहा है...',
      'freshness': 'ताज़गी',
      'damage': 'नुकसान पहचान',
      'color_quality': 'रंग गुणवत्ता',
      'size_consistency': 'आकार',
      'save_report': 'रिपोर्ट सेव करें',
      're_analyze': 'फिर से जाँचें',
      'pick_gallery': 'या गैलरी से चुनें',

      // Urgent
      'post_request': 'अत्यावश्यक अनुरोध भेजें',
      'fulfill_request': 'अनुरोध पूरा करें',
      'cancel_request': 'रद्द करें',
      'credit_cost': 'क्रेडिट लागत',

      // Disputes
      'file_dispute': 'विवाद दर्ज करें',
      'dispute_resolved': 'विवाद हल हुआ',
      'ai_verdict': 'AI निर्णय',

      // Profile
      'sign_out': 'लॉग आउट',
      'export_data': 'FPO के लिए डेटा निर्यात',
      'language': 'भाषा',
      'switch_hindi': 'हिन्दी में बदलें',
      'switch_english': 'Switch to English',

      // Auth
      'set_up_profile': 'प्रोफ़ाइल सेट करें',
      'your_name': 'आपका नाम',
      'your_village': 'आपका गाँव',
      'auto_detect': 'स्वतः पता लगाएं',
      'start_trading': 'व्यापार शुरू करें 🌾',
      'enter_name': 'अपना पूरा नाम लिखें',
      'enter_village': 'अपने गाँव का नाम लिखें',
      'mobile_number': 'मोबाइल नंबर',

      // Distance
      'km_away': 'किमी दूर',
      'transport_cost': 'परिवहन: ₹',
      'nearby': 'पास में',
      'far': 'दूर',

      // Price Discovery
      'price_discovery': 'भाव जानकारी',
      'commodity': 'वस्तु',
      'min_price': 'न्यूनतम',
      'max_price': 'अधिकतम',
      'modal_price': 'मॉडल',
      'last_updated': 'अंतिम अपडेट',
      'refresh_prices': 'भाव अपडेट करें',
      'per_kg': '/किग्रा',
    },
  };

  String t(String key) {
    return _translations[locale.languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }
}

class _AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const _AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) async {
    return AppLocalization(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalization> old) =>
      false;
}
