import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/listing_model.dart';
import '../models/trade_model.dart';
import '../models/evidence_model.dart';
import '../models/dispute_model.dart';
import '../models/credit_transaction_model.dart';
import '../config/constants.dart';

/// Central application state using ChangeNotifier (Provider pattern).
/// In a production app, this would connect to Firebase/Supabase.
/// For the hackathon, we use in-memory data with seed data.
class AppState extends ChangeNotifier {
  // Auth state
  bool _isAuthenticated = false;
  bool _isLoading = false;
  UserModel? _currentUser;
  String? _verificationId;

  // Data
  List<UserModel> _users = [];
  List<ListingModel> _listings = [];
  List<TradeModel> _trades = [];
  final List<EvidenceModel> _evidence = [];
  final List<DisputeModel> _disputes = [];
  List<CreditTransactionModel> _transactions = [];

  // Navigation
  int _currentTabIndex = 0;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  String? get verificationId => _verificationId;
  int get currentTabIndex => _currentTabIndex;

  List<UserModel> get users => _users;
  List<ListingModel> get listings => _listings;
  List<ListingModel> get activeListings =>
      _listings.where((l) => l.status == 'active').toList();
  List<ListingModel> get myListings =>
      _listings.where((l) => l.farmerId == _currentUser?.id).toList();
  List<TradeModel> get trades => _trades;
  List<TradeModel> get myTrades => _trades
      .where((t) =>
          t.participants.any((p) => p.farmerId == _currentUser?.id))
      .toList();
  List<EvidenceModel> get evidence => _evidence;
  List<DisputeModel> get disputes => _disputes;
  List<DisputeModel> get myDisputes => _disputes
      .where((d) =>
          d.complainantId == _currentUser?.id ||
          d.respondentId == _currentUser?.id)
      .toList();
  List<CreditTransactionModel> get transactions => _transactions;
  List<CreditTransactionModel> get myTransactions =>
      _transactions.where((t) => t.userId == _currentUser?.id).toList();

  final _uuid = const Uuid();
  final _random = Random();

  // ─── AUTHENTICATION ───────────────────────────────────────

  Future<void> sendOtp(String phoneNumber) async {
    _isLoading = true;
    notifyListeners();

    // Simulate OTP sending
    await Future.delayed(const Duration(seconds: 2));
    _verificationId = _uuid.v4();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> verifyOtp(String otp) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // Accept any 6-digit OTP for hackathon demo
    if (otp.length == 6) {
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> setupProfile({
    required String name,
    required String village,
    required String phone,
  }) async {
    final userId = _uuid.v4();
    _currentUser = UserModel(
      id: userId,
      phone: phone,
      name: name,
      village: village,
      latitude: 26.85 + _random.nextDouble() * 0.5,
      longitude: 80.91 + _random.nextDouble() * 0.5,
      reputationScore: 75.0,
      creditBalance: AppConstants.initialCreditBalance,
    );

    // Save login state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('userName', name);

    // Load seed data after setup
    _loadSeedData();
    notifyListeners();
  }

  Future<void> checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      final userName = prefs.getString('userName') ?? 'Farmer';
      _currentUser = UserModel(
        id: userId,
        phone: '+91 9876543210',
        name: userName,
        village: 'Rampur',
        creditBalance: AppConstants.initialCreditBalance,
      );
      _isAuthenticated = true;
      _loadSeedData();
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isAuthenticated = false;
    _currentUser = null;
    _users.clear();
    _listings.clear();
    _trades.clear();
    _evidence.clear();
    _disputes.clear();
    _transactions.clear();
    notifyListeners();
  }

  // ─── NAVIGATION ───────────────────────────────────────────

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // ─── LISTINGS ─────────────────────────────────────────────

  void addListing(ListingModel listing) {
    _listings.insert(0, listing);
    notifyListeners();
    // After adding, check for trade loops
    _checkForTradeLoops();
  }

  void updateListingStatus(String listingId, String status) {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      _listings[index] = _listings[index].copyWith(status: status);
      notifyListeners();
    }
  }

  // ─── TRADE MATCHING ENGINE ────────────────────────────────

  /// Build directed graph and detect cycles for multilateral trades.
  /// Nodes = Listings, Edge exists if listing A's desiredProduct == listing B's productType
  void _checkForTradeLoops() {
    final active = activeListings;
    if (active.length < 2) return;

    // Build adjacency: listing index -> list of listing indices it can trade with
    final adj = <int, List<int>>{};
    for (int i = 0; i < active.length; i++) {
      adj[i] = [];
      for (int j = 0; j < active.length; j++) {
        if (i != j &&
            active[i].desiredProduct.toLowerCase() ==
                active[j].productType.toLowerCase() &&
            active[i].farmerId != active[j].farmerId) {
          adj[i]!.add(j);
        }
      }
    }

    // DFS-based cycle detection
    final visited = <int>{};
    final recStack = <int>[];

    bool dfs(int node) {
      visited.add(node);
      recStack.add(node);

      for (final neighbor in adj[node] ?? []) {
        if (recStack.contains(neighbor)) {
          // Found a cycle
          final cycleStart = recStack.indexOf(neighbor);
          final cyclePath = recStack.sublist(cycleStart);

          if (cyclePath.length >= AppConstants.minLoopSize &&
              cyclePath.length <= AppConstants.maxLoopSize) {
            // Verify the cycle closes (last node's desiredProduct matches first node's productType)
            final lastListing = active[cyclePath.last];
            final firstListing = active[cyclePath.first];
            if (lastListing.desiredProduct.toLowerCase() ==
                firstListing.productType.toLowerCase()) {
              _createTradeFromCycle(cyclePath, active);
              return true;
            }
          }
        }
        if (!visited.contains(neighbor)) {
          if (dfs(neighbor)) return true;
        }
      }

      recStack.remove(node);
      return false;
    }

    for (int i = 0; i < active.length; i++) {
      if (!visited.contains(i)) {
        if (dfs(i)) break; // Stop after finding one loop for simplicity
      }
    }
  }

  void _createTradeFromCycle(List<int> cyclePath, List<ListingModel> active) {
    final participants = cyclePath.map((idx) {
      final listing = active[idx];
      final valuation = _calculateValuation(
        listing.productType,
        listing.quantity,
        85.0, // default quality score
      );
      return TradeParticipant(
        farmerId: listing.farmerId,
        farmerName: listing.farmerName,
        listingId: listing.id,
        offerProduct: listing.productType,
        wantProduct: listing.desiredProduct,
        offerQuantity: listing.quantity,
        unit: listing.unit,
        valuationAmount: valuation,
      );
    }).toList();

    // Check if a similar trade already exists
    final existingLoop = _trades.any((t) =>
        t.status == 'pending' &&
        t.participants.length == participants.length &&
        t.participants.every(
            (p) => participants.any((np) => np.listingId == p.listingId)));
    if (existingLoop) return;

    final trade = TradeModel(
      loopId: _uuid.v4(),
      participants: participants,
      status: 'pending',
    );

    _trades.insert(0, trade);
    notifyListeners();
  }

  // ─── TRADE ACTIONS ────────────────────────────────────────

  void confirmTrade(String loopId, String farmerId) {
    final tradeIndex = _trades.indexWhere((t) => t.loopId == loopId);
    if (tradeIndex == -1) return;

    final trade = _trades[tradeIndex];
    final updatedParticipants = trade.participants.map((p) {
      if (p.farmerId == farmerId) {
        return TradeParticipant(
          farmerId: p.farmerId,
          farmerName: p.farmerName,
          listingId: p.listingId,
          offerProduct: p.offerProduct,
          wantProduct: p.wantProduct,
          offerQuantity: p.offerQuantity,
          unit: p.unit,
          valuationAmount: p.valuationAmount,
          confirmationStatus: 'confirmed',
        );
      }
      return p;
    }).toList();

    // Check if all confirmed
    final allConfirmed =
        updatedParticipants.every((p) => p.confirmationStatus == 'confirmed');

    _trades[tradeIndex] = trade.copyWith(
      participants: updatedParticipants,
      status: allConfirmed ? 'executing' : 'pending',
    );

    if (allConfirmed) {
      _executeTrade(loopId);
    }

    notifyListeners();
  }

  void declineTrade(String loopId, String farmerId) {
    final tradeIndex = _trades.indexWhere((t) => t.loopId == loopId);
    if (tradeIndex == -1) return;

    _trades[tradeIndex] = _trades[tradeIndex].copyWith(status: 'cancelled');

    // Unlock listings
    for (final p in _trades[tradeIndex].participants) {
      updateListingStatus(p.listingId, 'active');
    }

    notifyListeners();
  }

  void _executeTrade(String loopId) {
    final tradeIndex = _trades.indexWhere((t) => t.loopId == loopId);
    if (tradeIndex == -1) return;

    final trade = _trades[tradeIndex];
    final creditMovements = <CreditMovement>[];

    // Execute credit movements
    for (int i = 0; i < trade.participants.length; i++) {
      final giver = trade.participants[i];
      final receiver =
          trade.participants[(i + 1) % trade.participants.length];

      creditMovements.add(CreditMovement(
        fromUserId: giver.farmerId,
        toUserId: receiver.farmerId,
        amount: giver.valuationAmount,
        description:
            '${giver.offerProduct} → ${receiver.farmerName}',
      ));

      // Record transactions
      _transactions.add(CreditTransactionModel(
        id: _uuid.v4(),
        userId: giver.farmerId,
        fromUserId: giver.farmerId,
        toUserId: receiver.farmerId,
        amount: giver.valuationAmount,
        type: 'debit',
        tradeId: loopId,
        description: 'Sent ${giver.offerProduct} to ${receiver.farmerName}',
        balanceAfter: _currentUser?.creditBalance ?? 0,
      ));
    }

    // Mark listings as completed
    for (final p in trade.participants) {
      updateListingStatus(p.listingId, 'completed');
    }

    // Update trade status
    _trades[tradeIndex] = trade.copyWith(
      status: 'completed',
      completedAt: DateTime.now(),
      creditMovements: creditMovements,
    );

    // Update reputation for current user
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        totalTrades: _currentUser!.totalTrades + 1,
        reputationScore:
            min(100, _currentUser!.reputationScore + 2.0),
      );
    }

    notifyListeners();
  }

  // ─── VALUATION ENGINE ─────────────────────────────────────

  double _calculateValuation(
      String productType, double quantity, double qualityScore) {
    final basePrice =
        AppConstants.mandiPrices[productType] ?? 50.0;
    final qualityFactor = qualityScore / 100.0;
    final demandFactor = 0.8 + _random.nextDouble() * 0.4; // 0.8–1.2
    return basePrice * quantity * qualityFactor * demandFactor;
  }

  double getValuation(String productType, double quantity,
      {double qualityScore = 85.0}) {
    return _calculateValuation(productType, quantity, qualityScore);
  }

  // ─── AI QUALITY SCORING ───────────────────────────────────

  EvidenceModel generateQualityScore({
    required String tradeId,
    required String farmerId,
    String? photoUrl,
  }) {
    // Simulated AI quality scoring for hackathon
    final freshness = 60.0 + _random.nextDouble() * 40;
    final damage = 70.0 + _random.nextDouble() * 30;
    final color = 65.0 + _random.nextDouble() * 35;
    final size = 55.0 + _random.nextDouble() * 45;
    final overall = (freshness + damage + color + size) / 4;

    String conditionTag;
    if (overall >= 85) {
      conditionTag = 'Excellent';
    } else if (overall >= 70) {
      conditionTag = 'Good';
    } else if (overall >= 50) {
      conditionTag = 'Average';
    } else {
      conditionTag = 'Poor';
    }

    final evidence = EvidenceModel(
      id: _uuid.v4(),
      tradeId: tradeId,
      farmerId: farmerId,
      photoUrl: photoUrl,
      aiQualityScore: overall,
      conditionTag: conditionTag,
      freshnessScore: freshness,
      damageScore: damage,
      colorScore: color,
      sizeScore: size,
      latitude: _currentUser?.latitude ?? 0,
      longitude: _currentUser?.longitude ?? 0,
    );

    _evidence.add(evidence);
    notifyListeners();
    return evidence;
  }

  // ─── DISPUTE SYSTEM ───────────────────────────────────────

  DisputeModel fileDispute({
    required String tradeId,
    required String respondentId,
    required String respondentName,
    required String description,
    String? complaintPhotoUrl,
    String? deliveryPhotoUrl,
  }) {
    // AI comparison simulation
    final similarity = 40.0 + _random.nextDouble() * 60;
    String verdict;
    double refund = 0;

    if (similarity < 50) {
      verdict = 'valid_complaint';
      refund = 500;
    } else if (similarity < 70) {
      verdict = 'partial_refund';
      refund = 250;
    } else if (similarity < 85) {
      verdict = 'false_complaint';
      refund = 0;
    } else {
      verdict = 'full_penalty';
      refund = 0;
    }

    final dispute = DisputeModel(
      id: _uuid.v4(),
      tradeId: tradeId,
      complainantId: _currentUser?.id ?? '',
      complainantName: _currentUser?.name ?? '',
      respondentId: respondentId,
      respondentName: respondentName,
      complaintPhotoUrl: complaintPhotoUrl,
      deliveryPhotoUrl: deliveryPhotoUrl,
      description: description,
      aiSimilarityScore: similarity,
      aiVerdict: verdict,
      refundAmount: refund,
      status: 'under_review',
    );

    _disputes.add(dispute);

    // Update reputation
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        disputeCount: _currentUser!.disputeCount + 1,
      );
    }

    notifyListeners();
    return dispute;
  }

  void resolveDispute(String disputeId, String resolution) {
    final index = _disputes.indexWhere((d) => d.id == disputeId);
    if (index != -1) {
      _disputes[index] = DisputeModel(
        id: _disputes[index].id,
        tradeId: _disputes[index].tradeId,
        complainantId: _disputes[index].complainantId,
        complainantName: _disputes[index].complainantName,
        respondentId: _disputes[index].respondentId,
        respondentName: _disputes[index].respondentName,
        complaintPhotoUrl: _disputes[index].complaintPhotoUrl,
        deliveryPhotoUrl: _disputes[index].deliveryPhotoUrl,
        description: _disputes[index].description,
        aiSimilarityScore: _disputes[index].aiSimilarityScore,
        aiVerdict: _disputes[index].aiVerdict,
        resolution: resolution,
        status: 'resolved',
        refundAmount: _disputes[index].refundAmount,
        resolvedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // ─── REPUTATION ───────────────────────────────────────────

  double calculateReputation(UserModel user) {
    final completionRate = user.totalTrades > 0
        ? min(1.0, user.totalTrades / (user.totalTrades + 2))
        : 0.5;
    final disputeRate = user.totalTrades > 0
        ? max(0.0, 1.0 - (user.disputeCount / user.totalTrades))
        : 0.8;
    final qualityConsistency = 0.75 + _random.nextDouble() * 0.25;
    final communityRating = 0.7 + _random.nextDouble() * 0.3;

    return (completionRate * AppConstants.weightTradeCompletion +
            disputeRate * AppConstants.weightDisputeFrequency +
            qualityConsistency * AppConstants.weightQualityConsistency +
            communityRating * AppConstants.weightCommunityRating) *
        100;
  }

  // ─── SEED DATA ────────────────────────────────────────────

  void _loadSeedData() {
    // Create sample farmers
    _users = [
      ?_currentUser,
      UserModel(
        id: 'farmer_001',
        phone: '+91 9876543001',
        name: 'Rajesh Kumar',
        village: 'Sundarpur',
        latitude: 26.92,
        longitude: 81.05,
        reputationScore: 88,
        creditBalance: 2500,
        totalTrades: 12,
      ),
      UserModel(
        id: 'farmer_002',
        phone: '+91 9876543002',
        name: 'Priya Devi',
        village: 'Govindnagar',
        latitude: 26.87,
        longitude: 80.98,
        reputationScore: 92,
        creditBalance: 3200,
        totalTrades: 18,
      ),
      UserModel(
        id: 'farmer_003',
        phone: '+91 9876543003',
        name: 'Suresh Yadav',
        village: 'Krishnapur',
        latitude: 26.95,
        longitude: 81.12,
        reputationScore: 76,
        creditBalance: 1800,
        totalTrades: 8,
        disputeCount: 2,
      ),
      UserModel(
        id: 'farmer_004',
        phone: '+91 9876543004',
        name: 'Meena Sharma',
        village: 'Laxminagar',
        latitude: 26.88,
        longitude: 81.03,
        reputationScore: 95,
        creditBalance: 4100,
        totalTrades: 24,
      ),
      UserModel(
        id: 'farmer_005',
        phone: '+91 9876543005',
        name: 'Vikram Singh',
        village: 'Chandpur',
        latitude: 26.90,
        longitude: 80.96,
        reputationScore: 82,
        creditBalance: 2100,
        totalTrades: 10,
        disputeCount: 1,
      ),
    ];

    // Create sample listings (some form perfect loops)
    _listings = [
      // Loop 1: Wheat → Seeds → Tractor Service → Wheat
      ListingModel(
        id: 'listing_001',
        farmerId: 'farmer_001',
        farmerName: 'Rajesh Kumar',
        farmerVillage: 'Sundarpur',
        productType: 'Wheat',
        quantity: 100,
        unit: 'kg',
        desiredProduct: 'Seeds',
        valuationScore: 2500,
        status: 'active',
      ),
      ListingModel(
        id: 'listing_002',
        farmerId: 'farmer_002',
        farmerName: 'Priya Devi',
        farmerVillage: 'Govindnagar',
        productType: 'Seeds',
        quantity: 20,
        unit: 'kg',
        desiredProduct: 'Tractor Service',
        valuationScore: 2000,
        status: 'active',
      ),
      ListingModel(
        id: 'listing_003',
        farmerId: 'farmer_003',
        farmerName: 'Suresh Yadav',
        farmerVillage: 'Krishnapur',
        productType: 'Tractor Service',
        quantity: 5,
        unit: 'hour',
        desiredProduct: 'Wheat',
        valuationScore: 2500,
        status: 'active',
      ),
      // Additional listings
      ListingModel(
        id: 'listing_004',
        farmerId: 'farmer_004',
        farmerName: 'Meena Sharma',
        farmerVillage: 'Laxminagar',
        productType: 'Rice',
        quantity: 200,
        unit: 'kg',
        desiredProduct: 'Vegetables',
        valuationScore: 7000,
        status: 'active',
      ),
      ListingModel(
        id: 'listing_005',
        farmerId: 'farmer_005',
        farmerName: 'Vikram Singh',
        farmerVillage: 'Chandpur',
        productType: 'Vegetables',
        quantity: 50,
        unit: 'kg',
        desiredProduct: 'Fertilizer',
        valuationScore: 1500,
        status: 'active',
      ),
      ListingModel(
        id: 'listing_006',
        farmerId: 'farmer_001',
        farmerName: 'Rajesh Kumar',
        farmerVillage: 'Sundarpur',
        productType: 'Fertilizer',
        quantity: 30,
        unit: 'bag',
        desiredProduct: 'Rice',
        valuationScore: 4500,
        status: 'active',
      ),
      ListingModel(
        id: 'listing_007',
        farmerId: 'farmer_004',
        farmerName: 'Meena Sharma',
        farmerVillage: 'Laxminagar',
        productType: 'Dairy',
        quantity: 50,
        unit: 'litre',
        desiredProduct: 'Fodder',
        valuationScore: 2750,
        status: 'active',
      ),
    ];

    // Create a sample completed trade
    _trades = [
      TradeModel(
        loopId: 'trade_001',
        participants: [
          TradeParticipant(
            farmerId: 'farmer_001',
            farmerName: 'Rajesh Kumar',
            listingId: 'old_listing_1',
            offerProduct: 'Corn',
            wantProduct: 'Labor Service',
            offerQuantity: 50,
            unit: 'kg',
            valuationAmount: 1000,
            confirmationStatus: 'confirmed',
          ),
          TradeParticipant(
            farmerId: 'farmer_005',
            farmerName: 'Vikram Singh',
            listingId: 'old_listing_2',
            offerProduct: 'Labor Service',
            wantProduct: 'Corn',
            offerQuantity: 3,
            unit: 'day',
            valuationAmount: 900,
            confirmationStatus: 'confirmed',
          ),
        ],
        status: 'completed',
        completedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    // Sample transactions
    _transactions = [
      CreditTransactionModel(
        id: 'txn_001',
        userId: _currentUser?.id ?? '',
        amount: 1000.0,
        type: 'credit',
        description: 'Welcome bonus credits',
        balanceAfter: 1000.0,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
      ),
      CreditTransactionModel(
        id: 'txn_002',
        userId: _currentUser?.id ?? '',
        fromUserId: _currentUser?.id,
        toUserId: 'farmer_001',
        amount: 250.0,
        type: 'debit',
        tradeId: 'trade_001',
        description: 'Trade settlement - Sent Wheat',
        balanceAfter: 750.0,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
      CreditTransactionModel(
        id: 'txn_003',
        userId: _currentUser?.id ?? '',
        fromUserId: 'farmer_002',
        toUserId: _currentUser?.id,
        amount: 300.0,
        type: 'credit',
        tradeId: 'trade_001',
        description: 'Trade settlement - Received Seeds',
        balanceAfter: 1050.0,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    // Run matching engine on seed data
    _checkForTradeLoops();
    notifyListeners();
  }
}
