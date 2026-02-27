import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Real-time mandi price service.
/// Fetches commodity prices from government APIs and caches in SQLite.
/// Falls back to cached prices when offline.
class MandiPriceService {
  static final MandiPriceService instance = MandiPriceService._();
  MandiPriceService._();

  // data.gov.in API for daily commodity prices
  // Users can register for free at https://data.gov.in to get an API key
  static const String _apiBaseUrl =
      'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070';
  static const String _apiKey = '579b464db66ec23bdd000001cdd3946e44ce4aad7209ff7b23ac571b';

  /// Initialize the mandi prices table in SQLite
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mandi_prices (
        commodity TEXT PRIMARY KEY,
        minPrice REAL NOT NULL DEFAULT 0,
        maxPrice REAL NOT NULL DEFAULT 0,
        modalPrice REAL NOT NULL DEFAULT 0,
        market TEXT NOT NULL DEFAULT '',
        state TEXT NOT NULL DEFAULT '',
        lastUpdated TEXT NOT NULL
      )
    ''');
  }

  /// Fetch latest prices from government API and cache in SQLite.
  /// Returns true if successful, false if API failed (cached data still available).
  Future<bool> fetchLatestPrices() async {
    try {
      final url = Uri.parse(
        '$_apiBaseUrl?api-key=$_apiKey&format=json&limit=100&offset=0',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final records = data['records'] as List? ?? [];

        final db = await DatabaseHelper.instance.database;

        for (final record in records) {
          final commodity = _normalizeCommodity(
            record['commodity'] as String? ?? '',
          );
          if (commodity.isEmpty) {
            continue;
          }

          final minPrice =
              double.tryParse(record['min_price']?.toString() ?? '0') ?? 0;
          final maxPrice =
              double.tryParse(record['max_price']?.toString() ?? '0') ?? 0;
          final modalPrice =
              double.tryParse(record['modal_price']?.toString() ?? '0') ?? 0;

          // Store price per kg (API gives per quintal, 1 quintal = 100 kg)
          await db.insert('mandi_prices', {
            'commodity': commodity,
            'minPrice': minPrice / 100,
            'maxPrice': maxPrice / 100,
            'modalPrice': modalPrice / 100,
            'market': record['market'] as String? ?? '',
            'state': record['state'] as String? ?? '',
            'lastUpdated': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get price for a specific commodity.
  /// First tries SQLite cache, then falls back to seed defaults.
  Future<double> getPrice(String commodity) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'mandi_prices',
        where: 'commodity = ?',
        whereArgs: [commodity],
      );

      if (rows.isNotEmpty) {
        return (rows.first['modalPrice'] as num?)?.toDouble() ?? _getFallback(commodity);
      }
    } catch (_) {}

    return _getFallback(commodity);
  }

  /// Get all cached prices from SQLite.
  Future<Map<String, double>> getAllPrices() async {
    final prices = <String, double>{};
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('mandi_prices');
      for (final r in rows) {
        final commodity = r['commodity'] as String;
        final price = (r['modalPrice'] as num?)?.toDouble() ?? 0;
        prices[commodity] = price;
      }
    } catch (_) {}

    // Fill missing with fallbacks
    for (final entry in _fallbackPrices.entries) {
      prices.putIfAbsent(entry.key, () => entry.value);
    }
    return prices;
  }

  /// Seed initial prices into SQLite (only if table is empty).
  Future<void> seedDefaultPrices() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM mandi_prices'));
      if ((count ?? 0) > 0) {
        return;
      }

      for (final entry in _fallbackPrices.entries) {
        await db.insert('mandi_prices', {
          'commodity': entry.key,
          'minPrice': entry.value * 0.9,
          'maxPrice': entry.value * 1.1,
          'modalPrice': entry.value,
          'market': 'Default',
          'state': 'India',
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  /// Normalize API commodity names to match app categories.
  String _normalizeCommodity(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('wheat')) { return 'Wheat'; }
    if (lower.contains('rice') || lower.contains('paddy')) { return 'Rice'; }
    if (lower.contains('maize') || lower.contains('corn')) { return 'Corn'; }
    if (lower.contains('bajra') || lower.contains('millet')) { return 'Millet'; }
    if (lower.contains('sugarcane') || lower.contains('gur')) { return 'Sugarcane'; }
    if (lower.contains('cotton')) { return 'Cotton'; }
    if (lower.contains('soyabean') || lower.contains('soybean')) { return 'Soybean'; }
    if (lower.contains('toor') || lower.contains('moong') ||
        lower.contains('urad') || lower.contains('chana') ||
        lower.contains('dal') || lower.contains('pulse')) {
      return 'Pulses';
    }
    if (lower.contains('tomato') || lower.contains('onion') ||
        lower.contains('potato') || lower.contains('cabbage') ||
        lower.contains('cauliflower') || lower.contains('brinjal')) {
      return 'Vegetables';
    }
    if (lower.contains('apple') || lower.contains('banana') ||
        lower.contains('mango') || lower.contains('orange') ||
        lower.contains('grape')) {
      return 'Fruits';
    }
    if (lower.contains('seed')) { return 'Seeds'; }
    if (lower.contains('fodder')) { return 'Fodder'; }
    if (lower.contains('milk') || lower.contains('dairy')) { return 'Dairy'; }
    if (lower.contains('poultry') || lower.contains('chicken') ||
        lower.contains('egg')) {
      return 'Poultry';
    }
    return ''; // Unknown → skip
  }

  /// Fallback prices (used only when SQLite is also empty AND API failed).
  static const Map<String, double> _fallbackPrices = {
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

  double _getFallback(String commodity) {
    return _fallbackPrices[commodity] ?? 50.0;
  }
}
