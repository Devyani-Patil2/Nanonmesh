import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/listing_model.dart';
import '../models/trade_model.dart';
import '../models/evidence_model.dart';
import '../models/dispute_model.dart';
import '../models/credit_transaction_model.dart';
import '../models/urgent_request_model.dart';

/// Local database helper using SharedPreferences for persistence.
/// Stores data as JSON strings so it survives app restarts.
/// For hackathon prototype — production would use SQLite or Firestore.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  // In-memory caches (loaded from SharedPreferences on init)
  final List<UserModel> _users = [];
  final List<ListingModel> _listings = [];
  final List<TradeModel> _trades = [];
  final List<EvidenceModel> _evidence = [];
  final List<DisputeModel> _disputes = [];
  final List<CreditTransactionModel> _transactions = [];
  final List<UrgentRequestModel> _urgentRequests = [];

  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load users
      final usersJson = prefs.getStringList('db_users') ?? [];
      for (final json in usersJson) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          _users.add(UserModel(
            id: map['id'] ?? '',
            phone: map['phone'] ?? '',
            name: map['name'] ?? '',
            village: map['village'] ?? '',
            latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
            longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
            reputationScore: (map['reputationScore'] as num?)?.toDouble() ?? 75,
            creditBalance: (map['creditBalance'] as num?)?.toDouble() ?? 1000,
            totalTrades: (map['totalTrades'] as num?)?.toInt() ?? 0,
            disputeCount: (map['disputeCount'] as num?)?.toInt() ?? 0,
          ));
        } catch (_) {}
      }

      // Load listings
      final listingsJson = prefs.getStringList('db_listings') ?? [];
      for (final json in listingsJson) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          _listings.add(ListingModel(
            id: map['id'] ?? '',
            farmerId: map['farmerId'] ?? '',
            farmerName: map['farmerName'] ?? '',
            farmerVillage: map['farmerVillage'] ?? '',
            productType: map['productType'] ?? '',
            quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
            unit: map['unit'] ?? 'kg',
            desiredProduct: map['desiredProduct'] ?? '',
            qualityExpectation: map['qualityExpectation'] ?? 'Good',
            valuationScore: (map['valuationScore'] as num?)?.toDouble() ?? 0,
            latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
            longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
            status: map['status'] ?? 'active',
          ));
        } catch (_) {}
      }
    } catch (_) {}
  }

  // ─── SAVE HELPERS ─────────────────────────────────────────

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _users.map((u) => jsonEncode({
      'id': u.id, 'phone': u.phone, 'name': u.name,
      'village': u.village, 'latitude': u.latitude,
      'longitude': u.longitude, 'reputationScore': u.reputationScore,
      'creditBalance': u.creditBalance, 'totalTrades': u.totalTrades,
      'disputeCount': u.disputeCount,
    })).toList();
    await prefs.setStringList('db_users', list);
  }

  Future<void> _saveListings() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _listings.map((l) => jsonEncode({
      'id': l.id, 'farmerId': l.farmerId, 'farmerName': l.farmerName,
      'farmerVillage': l.farmerVillage, 'productType': l.productType,
      'quantity': l.quantity, 'unit': l.unit,
      'desiredProduct': l.desiredProduct,
      'qualityExpectation': l.qualityExpectation,
      'valuationScore': l.valuationScore, 'latitude': l.latitude,
      'longitude': l.longitude, 'status': l.status,
    })).toList();
    await prefs.setStringList('db_listings', list);
  }

  // ─── USERS ────────────────────────────────────────────────

  Future<void> insertUser(UserModel user) async {
    await _ensureInit();
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
    } else {
      _users.add(user);
    }
    await _saveUsers();
  }

  Future<UserModel?> getUser(String id) async {
    await _ensureInit();
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<UserModel>> getUsers() async {
    await _ensureInit();
    return List.from(_users);
  }

  Future<void> updateUser(UserModel user) async {
    await insertUser(user); // upsert
  }

  // ─── LISTINGS ─────────────────────────────────────────────

  Future<void> insertListing(ListingModel listing) async {
    await _ensureInit();
    final index = _listings.indexWhere((l) => l.id == listing.id);
    if (index != -1) {
      _listings[index] = listing;
    } else {
      _listings.add(listing);
    }
    await _saveListings();
  }

  Future<List<ListingModel>> getListings() async {
    await _ensureInit();
    return List.from(_listings);
  }

  Future<void> updateListingStatus(String listingId, String status) async {
    await _ensureInit();
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      _listings[index] = _listings[index].copyWith(status: status);
      await _saveListings();
    }
  }

  // ─── TRADES ───────────────────────────────────────────────

  Future<void> insertTrade(TradeModel trade) async {
    await _ensureInit();
    final index = _trades.indexWhere((t) => t.loopId == trade.loopId);
    if (index != -1) {
      _trades[index] = trade;
    } else {
      _trades.add(trade);
    }
  }

  Future<List<TradeModel>> getTrades() async {
    await _ensureInit();
    return List.from(_trades);
  }

  Future<void> updateTrade(TradeModel trade) async {
    await insertTrade(trade); // upsert
  }

  // ─── EVIDENCE ─────────────────────────────────────────────

  Future<void> insertEvidence(EvidenceModel evidence) async {
    await _ensureInit();
    _evidence.add(evidence);
  }

  Future<List<EvidenceModel>> getEvidence() async {
    await _ensureInit();
    return List.from(_evidence);
  }

  // ─── DISPUTES ─────────────────────────────────────────────

  Future<void> insertDispute(DisputeModel dispute) async {
    await _ensureInit();
    _disputes.add(dispute);
  }

  Future<List<DisputeModel>> getDisputes() async {
    await _ensureInit();
    return List.from(_disputes);
  }

  Future<void> updateDispute(DisputeModel dispute) async {
    await _ensureInit();
    final index = _disputes.indexWhere((d) => d.id == dispute.id);
    if (index != -1) {
      _disputes[index] = dispute;
    }
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────

  Future<void> insertTransaction(CreditTransactionModel txn) async {
    await _ensureInit();
    _transactions.add(txn);
  }

  Future<List<CreditTransactionModel>> getTransactions() async {
    await _ensureInit();
    return List.from(_transactions);
  }

  // ─── URGENT REQUESTS ──────────────────────────────────────

  Future<void> insertUrgentRequest(UrgentRequestModel request) async {
    await _ensureInit();
    _urgentRequests.add(request);
  }

  Future<List<UrgentRequestModel>> getUrgentRequests() async {
    await _ensureInit();
    return List.from(_urgentRequests);
  }

  Future<void> updateUrgentRequest(UrgentRequestModel request) async {
    await _ensureInit();
    final index = _urgentRequests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      _urgentRequests[index] = request;
    }
  }

  // ─── SEED DATA ────────────────────────────────────────────

  Future<bool> hasSeedData() async {
    await _ensureInit();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seed_data') ?? false;
  }

  Future<void> markSeedDataLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seed_data', true);
  }

  // ─── CLEAR ────────────────────────────────────────────────

  Future<void> clearAll() async {
    _users.clear();
    _listings.clear();
    _trades.clear();
    _evidence.clear();
    _disputes.clear();
    _transactions.clear();
    _urgentRequests.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('db_users');
    await prefs.remove('db_listings');
    await prefs.remove('has_seed_data');
  }
}
