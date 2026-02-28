// Constants for the Nanonmesh Agricultural Barter Exchange Platform

class AppConstants {
  // App Info
  static const String appName = 'AgroSwap';
  static const String appTagline = 'Smart Barter for Smart Farmers';
  static const String appVersion = '1.0.0';

  // Product Categories
  static const List<String> productCategories = [
    'Wheat',
    'Rice',
    'Corn',
    'Millet',
    'Sugarcane',
    'Cotton',
    'Soybean',
    'Pulses',
    'Vegetables',
    'Fruits',
    'Seeds',
    'Fertilizer',
    'Tractor Service',
    'Labor Service',
    'Irrigation Service',
    'Transport Service',
    'Equipment',
    'Fodder',
    'Dairy',
    'Poultry',
  ];

  // Product Icons Mapping
  static const Map<String, String> productEmojis = {
    'Wheat': '🌾',
    'Rice': '🍚',
    'Corn': '🌽',
    'Millet': '🌿',
    'Sugarcane': '🎋',
    'Cotton': '☁️',
    'Soybean': '🫘',
    'Pulses': '🫛',
    'Vegetables': '🥬',
    'Fruits': '🍎',
    'Seeds': '🌱',
    'Fertilizer': '🧪',
    'Tractor Service': '🚜',
    'Labor Service': '👷',
    'Irrigation Service': '💧',
    'Transport Service': '🚛',
    'Equipment': '⚙️',
    'Fodder': '🌿',
    'Dairy': '🥛',
    'Poultry': '🐔',
  };

  // Units
  static const List<String> units = [
    'kg',
    'quintal',
    'ton',
    'litre',
    'piece',
    'bag',
    'crate',
    'hour',
    'day',
    'trip',
  ];

  // Quality Levels
  static const List<String> qualityLevels = [
    'Excellent',
    'Good',
    'Average',
    'Poor',
  ];

  // Trade Loop Limits
  static const int minLoopSize = 2;
  static const int maxLoopSize = 6;

  // Credit System
  static const double initialCreditBalance = 1000.0;
  static const double maxCreditLimit = 50000.0;

  // Mandi Reference Prices (INR per kg) - Hackathon sample data
  static const Map<String, double> mandiPrices = {
    'Wheat': 25.0,
    'Rice': 35.0,
    'Corn': 20.0,
    'Millet': 28.0,
    'Sugarcane': 3.5,
    'Cotton': 65.0,
    'Soybean': 45.0,
    'Pulses': 80.0,
    'Vegetables': 30.0,
    'Fruits': 50.0,
    'Seeds': 100.0,
    'Fertilizer': 15.0,
    'Tractor Service': 500.0,
    'Labor Service': 300.0,
    'Irrigation Service': 200.0,
    'Transport Service': 400.0,
    'Equipment': 1000.0,
    'Fodder': 12.0,
    'Dairy': 55.0,
    'Poultry': 180.0,
  };

  // Reputation Weights
  static const double weightTradeCompletion = 0.40;
  static const double weightDisputeFrequency = 0.20;
  static const double weightQualityConsistency = 0.25;
  static const double weightCommunityRating = 0.15;

  // Villages (sample data for hackathon)
  static const List<String> sampleVillages = [
    'Rampur',
    'Sundarpur',
    'Govindnagar',
    'Krishnapur',
    'Laxminagar',
    'Chandpur',
    'Sitapur',
    'Devgarh',
    'Mohanpur',
    'Shivnagar',
  ];
}
