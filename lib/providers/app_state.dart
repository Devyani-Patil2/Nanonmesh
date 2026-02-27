import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/listing_model.dart';
import '../models/trade_model.dart';
import '../models/evidence_model.dart';
import '../models/dispute_model.dart';
import '../models/credit_transaction_model.dart';
import '../models/urgent_request_model.dart';
import '../config/constants.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/mandi_price_service.dart';
import '../services/quality_analysis_service.dart';
import '../services/image_comparison_service.dart';
import '../services/notification_service.dart';
import 'package:geolocator/geolocator.dart';

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
  List<EvidenceModel> _evidence = [];
  List<DisputeModel> _disputes = [];
  List<CreditTransactionModel> _transactions = [];
  final List<UrgentRequestModel> _urgentRequests = [];

  // Navigation
  int _currentTabIndex = 0;

  // Locale for multi-language
  Locale _locale = const Locale('en', 'IN');

  // Theme
  bool _isDarkMode = false;

  // Real-time Firestore listeners
  StreamSubscription? _listingsSubscription;
  StreamSubscription? _tradesSubscription;
  StreamSubscription? _urgentRequestsSubscription;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  String? get verificationId => _verificationId;
  int get currentTabIndex => _currentTabIndex;
  Locale get locale => _locale;
  final _notifications = NotificationService.instance;
  bool get isDarkMode => _isDarkMode;
  String? get authError => _authError;
  bool get isNewUser => _isNewUser;

  List<UserModel> get users => _users;
  List<ListingModel> get listings => _listings;
  List<ListingModel> get activeListings =>
      _listings.where((l) => l.status == 'active').toList();
  List<ListingModel> get myListings =>
      _listings.where((l) => l.farmerId == _currentUser?.id).toList();

  /// Listings from OTHER users that match what the current user wants or offers.
  /// Sorted by: (1) fairness of value exchange, (2) farmer reputation.
  List<ListingModel> get matchingListings {
    if (_currentUser == null) return [];
    final myOwnListings = _listings
        .where((l) => l.farmerId == _currentUser!.id && l.status == 'active')
        .toList();
    if (myOwnListings.isEmpty) return [];

    // Collect what I offer and what I want
    final myOffers = myOwnListings.map((l) => l.productType).toSet();
    final myWants = myOwnListings.map((l) => l.desiredProduct).toSet();

    // Best valuation from my own listings (for fairness comparison)
    final myBestValuation = myOwnListings
        .map((l) => l.valuationScore)
        .reduce((a, b) => a > b ? a : b);

    // Find OTHER users' active listings that match
    final matches = _listings.where((l) {
      if (l.farmerId == _currentUser!.id) return false;
      if (l.status != 'active') return false;
      return myWants.contains(l.productType) ||
          myOffers.contains(l.desiredProduct);
    }).toList();

    // Sort: best fairness + highest reputation first
    matches.sort((a, b) {
      // Fairness = how close their valuation is to mine (lower diff = better)
      final fairnessA = (a.valuationScore - myBestValuation).abs();
      final fairnessB = (b.valuationScore - myBestValuation).abs();

      // Get reputation of the farmer
      final repA = _users
              .where((u) => u.id == a.farmerId)
              .firstOrNull
              ?.reputationScore ??
          50.0;
      final repB = _users
              .where((u) => u.id == b.farmerId)
              .firstOrNull
              ?.reputationScore ??
          50.0;

      // Combined score: lower fairness gap is better, higher rep is better
      // Normalize: fairness 0-10000 â†’ 0-100, rep already 0-100
      final scoreA = (100 - (fairnessA / 100).clamp(0, 100)) * 0.5 + repA * 0.5;
      final scoreB = (100 - (fairnessB / 100).clamp(0, 100)) * 0.5 + repB * 0.5;

      return scoreB.compareTo(scoreA); // Higher score first
    });

    return matches;
  }

  /// Calculate fairness percentage between two valuations.
  double getFairnessPercent(double myValue, double theirValue) {
    if (myValue == 0 && theirValue == 0) return 100;
    final maxVal = myValue > theirValue ? myValue : theirValue;
    if (maxVal == 0) return 100;
    final diff = (myValue - theirValue).abs();
    return ((1 - diff / maxVal) * 100).clamp(0, 100);
  }

  List<TradeModel> get trades => _trades;
  List<TradeModel> get myTrades => _trades
      .where((t) => t.participants.any((p) => p.farmerId == _currentUser?.id))
      .toList();
  List<EvidenceModel> get evidence => _evidence;
  List<DisputeModel> get disputes => _disputes;
  List<DisputeModel> get myDisputes => _disputes
      .where(
        (d) =>
            d.complainantId == _currentUser?.id ||
            d.respondentId == _currentUser?.id,
      )
      .toList();
  List<CreditTransactionModel> get transactions => _transactions;
  List<CreditTransactionModel> get myTransactions =>
      _transactions.where((t) => t.userId == _currentUser?.id).toList();
  List<UrgentRequestModel> get urgentRequests => _urgentRequests;
  List<UrgentRequestModel> get openUrgentRequests =>
      _urgentRequests.where((r) => r.status == 'open').toList();
  List<UrgentRequestModel> get myUrgentRequests =>
      _urgentRequests.where((r) => r.requesterId == _currentUser?.id).toList();

  final _uuid = const Uuid();
  final _random = Random();
  final _firestore = FirestoreService.instance;
  final _location = LocationService.instance;
  final _mandiPrices = MandiPriceService.instance;
  final _qualityAnalysis = QualityAnalysisService.instance;
  final _imageComparison = ImageComparisonService.instance;

  // â”€â”€â”€ PHONE + PIN AUTHENTICATION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  String? _authError;
  bool _isNewUser = false;
  String _pendingPhone = '';

  /// Check if phone number has a registered PIN
  Future<void> checkPhone(String phoneNumber) async {
    _isLoading = true;
    _authError = null;
    _pendingPhone = phoneNumber;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('pin_$phoneNumber');

    _isNewUser = (storedPin == null);
    _verificationId = phoneNumber;
    _isLoading = false;
    notifyListeners();
  }

  /// Register a new 4-digit PIN for the phone number
  Future<bool> registerPin(String pin) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    if (pin.length != 4) {
      _authError = 'PIN must be 4 digits';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pin_$_pendingPhone', pin);

    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Verify PIN for existing user
  Future<bool> verifyPin(String pin) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('pin_$_pendingPhone');

    if (storedPin == null) {
      _authError = 'No account found. Please sign up first.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (storedPin != pin) {
      _authError = 'Incorrect PIN. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  // Compatibility wrappers
  Future<void> sendOtp(String phoneNumber) async => checkPhone(phoneNumber);
  Future<bool> verifyOtp(String pin) async => verifyPin(pin);

  Future<void> setupProfile({
    required String name,
    required String village,
    required String phone,
  }) async {
    // Check Firestore for existing user with same phone
    final existingUsers = await _firestore.getUsers();
    final existingUser = existingUsers.where((u) => u.phone == phone).toList();

    // Use REAL GPS location
    double latitude = 0;
    double longitude = 0;
    String resolvedVillage = village;

    final position = await _location.getCurrentPosition();
    if (position != null) {
      latitude = position.latitude;
      longitude = position.longitude;
      if (village.isEmpty || village == 'Unknown') {
        resolvedVillage =
            await _location.getVillageFromCoordinates(latitude, longitude);
      }
    }

    if (existingUser.isNotEmpty) {
      // Re-use existing user — restore their data!
      _currentUser = existingUser.first.copyWith(
        name: name,
        village: resolvedVillage,
        latitude: latitude,
        longitude: longitude,
      );
    } else {
      // Truly new user
      final userId = _uuid.v4();
      _currentUser = UserModel(
        id: userId,
        phone: phone,
        name: name,
        village: resolvedVillage,
        latitude: latitude,
        longitude: longitude,
        reputationScore: 75.0,
        creditBalance: AppConstants.initialCreditBalance,
      );
    }

    // Save login state (auth stays on SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _currentUser!.id);
    await prefs.setString('userName', name);

    // Sync to Firestore for cross-device visibility
    await _firestore.saveUser(_currentUser!);

    // Seed mandi prices and try to fetch latest from API
    await _mandiPrices.seedDefaultPrices();
    _mandiPrices.fetchLatestPrices();

    // Load existing data from Firestore
    await _loadDataFromFirestore();

    // Start real-time listeners for cross-device sync
    _startListeningToFirestore();
    notifyListeners();
  }

  Future<void> checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    final userId = prefs.getString('userId');
    if (userId != null) {
      // Try to load user from Firestore
      final firestoreUsers = await _firestore.getUsers();
      final matchedUser = firestoreUsers.where((u) => u.id == userId).toList();
      if (matchedUser.isNotEmpty) {
        _currentUser = matchedUser.first;
      } else {
        final userName = prefs.getString('userName') ?? 'Farmer';
        _currentUser = UserModel(
          id: userId,
          phone: '+91 9876543210',
          name: userName,
          village: 'Rampur',
          creditBalance: AppConstants.initialCreditBalance,
        );
        await _firestore.saveUser(_currentUser!);
      }
      _isAuthenticated = true;

      // Load data from Firestore (one-time initial load)
      await _loadDataFromFirestore();

      // Start real-time listeners for cross-device sync
      _startListeningToFirestore();

      notifyListeners();
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    // Only remove session keys, keep PIN data
    await prefs.remove('userId');
    await prefs.remove('userName');
    _isAuthenticated = false;
    _currentUser = null;
    _users.clear();
    _listings.clear();
    _trades.clear();
    _evidence.clear();
    _disputes.clear();
    _transactions.clear();
    _urgentRequests.clear();
    notifyListeners();
  }

  // â”€â”€â”€ NAVIGATION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  /// Toggle between English and Hindi.
  void toggleLocale() {
    _locale = _locale.languageCode == 'en'
        ? const Locale('hi', 'IN')
        : const Locale('en', 'IN');
    notifyListeners();
  }

  /// Calculate distance in km between current user and a listing.
  double getDistanceToListing(ListingModel listing) {
    if (_currentUser == null) return 0;
    return Geolocator.distanceBetween(
          _currentUser!.latitude,
          _currentUser!.longitude,
          listing.latitude,
          listing.longitude,
        ) /
        1000; // meters â†’ km
  }

  /// Estimate transport cost based on distance (â‚¹5/km baseline).
  double estimateTransportCost(double distanceKm) {
    if (distanceKm <= 5) return 0; // Free within 5 km
    return (distanceKm - 5) * 5; // â‚¹5 per km above 5 km
  }

  /// Get listings sorted by proximity to the current user.
  List<ListingModel> get activeListingsByDistance {
    final list = activeListings;
    list.sort((a, b) {
      final distA = getDistanceToListing(a);
      final distB = getDistanceToListing(b);
      return distA.compareTo(distB);
    });
    return list;
  }

  // â”€â”€â”€ THEME â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
  // â”€â”€â”€ URGENT REQUESTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€â”€ DATABASE LOADING â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Load all data from Firestore (cross-device shared data)
  Future<void> _loadDataFromFirestore() async {
    try {
      _users = await _firestore.getUsers();
      _listings = await _firestore.getListings();
      _trades = await _firestore.getTrades();
      _urgentRequests.clear();
      final urgentFromFirestore = await _firestore.urgentRequestsStream().first;
      _urgentRequests.addAll(urgentFromFirestore);
    } catch (e) {
      debugPrint('Firestore load failed: $e');
    }
  }

  /// Start listening to Firestore streams for real-time updates.
  /// When another user creates a listing, it appears automatically.
  void _startListeningToFirestore() {
    // Cancel any existing subscriptions
    _listingsSubscription?.cancel();
    _tradesSubscription?.cancel();
    _urgentRequestsSubscription?.cancel();

    // Listen to listings changes (cross-device)
    _listingsSubscription = _firestore.listingsStream().listen((listings) {
      _listings = listings;
      notifyListeners();
    });

    // Listen to trades changes
    _tradesSubscription = _firestore.tradesStream().listen((trades) {
      _trades = trades;
      notifyListeners();
    });

    // Listen to urgent requests changes
    _urgentRequestsSubscription =
        _firestore.urgentRequestsStream().listen((requests) {
      _urgentRequests.clear();
      _urgentRequests.addAll(requests);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _listingsSubscription?.cancel();
    _tradesSubscription?.cancel();
    _urgentRequestsSubscription?.cancel();
    super.dispose();
  }

  // â”€â”€â”€ URGENT REQUEST ACTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Post an urgent request. The requester is willing to spend credits
  /// to get something they need right now.
  void postUrgentRequest({
    required String productNeeded,
    required double quantity,
    required String unit,
    required double creditCost,
    String urgencyLevel = 'high',
    String description = '',
  }) {
    if (_currentUser == null) return;

    // Check if requester has enough credits
    if (_currentUser!.creditBalance < creditCost) return;

    final request = UrgentRequestModel(
      id: _uuid.v4(),
      requesterId: _currentUser!.id,
      requesterName: _currentUser!.name,
      requesterVillage: _currentUser!.village,
      productNeeded: productNeeded,
      quantity: quantity,
      unit: unit,
      creditCost: creditCost,
      urgencyLevel: urgencyLevel,
      description: description,
    );

    _urgentRequests.insert(0, request);
    _firestore.saveUrgentRequest(request);
    notifyListeners();
  }

  /// Fulfill an urgent request. The fulfiller provides the product
  /// and earns the credits. The requester pays the credits.
  void fulfillUrgentRequest(String requestId) {
    if (_currentUser == null) return;

    final index = _urgentRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final request = _urgentRequests[index];

    // Can't fulfill your own request
    if (request.requesterId == _currentUser!.id) return;
    // Must be open
    if (request.status != 'open') return;

    // Find the requester user
    final requesterIndex = _users.indexWhere(
      (u) => u.id == request.requesterId,
    );

    // Update request status
    _urgentRequests[index] = request.copyWith(
      status: 'completed',
      fulfillerId: _currentUser!.id,
      fulfillerName: _currentUser!.name,
      fulfilledAt: DateTime.now(),
    );

    // Transfer credits: requester pays â†’ fulfiller earns
    // Debit requester
    if (requesterIndex != -1) {
      _users[requesterIndex] = _users[requesterIndex].copyWith(
        creditBalance:
            _users[requesterIndex].creditBalance - request.creditCost,
      );
    }
    // If the requester is the current user (viewing someone else's perspective)
    if (request.requesterId == _currentUser!.id) {
      _currentUser = _currentUser!.copyWith(
        creditBalance: _currentUser!.creditBalance - request.creditCost,
      );
    }

    // Credit the fulfiller (current user)
    _currentUser = _currentUser!.copyWith(
      creditBalance: _currentUser!.creditBalance + request.creditCost,
      totalTrades: _currentUser!.totalTrades + 1,
      reputationScore: min(100, _currentUser!.reputationScore + 3.0),
    );

    // Record transactions
    _transactions.insert(
      0,
      CreditTransactionModel(
        id: _uuid.v4(),
        userId: request.requesterId,
        fromUserId: request.requesterId,
        toUserId: _currentUser!.id,
        amount: request.creditCost,
        type: 'debit',
        description:
            'Urgent: Paid for ${request.productNeeded} to ${_currentUser!.name}',
        balanceAfter:
            requesterIndex != -1 ? _users[requesterIndex].creditBalance : 0,
        timestamp: DateTime.now(),
      ),
    );
    _transactions.insert(
      0,
      CreditTransactionModel(
        id: _uuid.v4(),
        userId: _currentUser!.id,
        fromUserId: request.requesterId,
        toUserId: _currentUser!.id,
        amount: request.creditCost,
        type: 'credit',
        description:
            'Urgent: Earned for providing ${request.productNeeded} to ${request.requesterName}',
        balanceAfter: _currentUser!.creditBalance,
        timestamp: DateTime.now(),
      ),
    );
    // Persist all changes to SQLite
    _firestore.updateUrgentRequest(_urgentRequests[index]);
    _firestore.saveUser(_currentUser!);
    if (requesterIndex != -1) {
      _firestore.saveUser(_users[requesterIndex]);
    }
    // Transactions stay in-memory

    // ðŸ”” Notify about urgent request fulfillment
    _notifications.notifyRequestFulfilled(request.productNeeded);

    notifyListeners();
  }

  /// Cancel an urgent request (only the requester can cancel)
  void cancelUrgentRequest(String requestId) {
    final index = _urgentRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    if (_urgentRequests[index].requesterId != _currentUser?.id) return;
    if (_urgentRequests[index].status != 'open') return;

    _urgentRequests[index] = _urgentRequests[index].copyWith(
      status: 'cancelled',
    );
    _firestore.updateUrgentRequest(_urgentRequests[index]);
    notifyListeners();
  }

  // â”€â”€â”€ DIRECT TRADE (from Matching Marketplace) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Accept a direct barter trade between current user's listing and another farmer's listing.
  /// Automatically transfers credits to cover the value gap.
  void acceptDirectTrade(ListingModel myListing, ListingModel theirListing) {
    // Calculate value gap for credit transfer
    final valueGap =
        (myListing.valuationScore - theirListing.valuationScore).abs();
    final iPayCredits = myListing.valuationScore < theirListing.valuationScore;
    final tradeId = _uuid.v4();

    // Credit movements for the trade
    List<CreditMovement> creditMovements = [];
    if (valueGap > 0) {
      creditMovements.add(CreditMovement(
        fromUserId: iPayCredits ? myListing.farmerId : theirListing.farmerId,
        toUserId: iPayCredits ? theirListing.farmerId : myListing.farmerId,
        amount: valueGap,
        description:
            'Value gap compensation: ${iPayCredits ? myListing.farmerName : theirListing.farmerName} → ${iPayCredits ? theirListing.farmerName : myListing.farmerName}',
      ));
    }

    // Create trade with both participants
    final trade = TradeModel(
      loopId: tradeId,
      participants: [
        TradeParticipant(
          farmerId: myListing.farmerId,
          farmerName: myListing.farmerName,
          listingId: myListing.id,
          offerProduct: myListing.productType,
          wantProduct: myListing.desiredProduct,
          offerQuantity: myListing.quantity,
          unit: myListing.unit,
          valuationAmount: myListing.valuationScore,
          confirmationStatus: 'confirmed',
        ),
        TradeParticipant(
          farmerId: theirListing.farmerId,
          farmerName: theirListing.farmerName,
          listingId: theirListing.id,
          offerProduct: theirListing.productType,
          wantProduct: theirListing.desiredProduct,
          offerQuantity: theirListing.quantity,
          unit: theirListing.unit,
          valuationAmount: theirListing.valuationScore,
          confirmationStatus: 'pending',
        ),
      ],
      status: 'pending',
      creditMovements: creditMovements,
    );

    _trades.insert(0, trade);
    _firestore.saveTrade(trade);

    // Transfer credits if there's a value gap
    if (valueGap > 0) {
      final payerId = iPayCredits ? myListing.farmerId : theirListing.farmerId;
      final receiverId =
          iPayCredits ? theirListing.farmerId : myListing.farmerId;
      final payerName =
          iPayCredits ? myListing.farmerName : theirListing.farmerName;
      final receiverName =
          iPayCredits ? theirListing.farmerName : myListing.farmerName;

      // Deduct from payer
      final payerIdx = _users.indexWhere((u) => u.id == payerId);
      if (payerIdx != -1) {
        _users[payerIdx] = _users[payerIdx].copyWith(
          creditBalance: _users[payerIdx].creditBalance - valueGap,
        );
        _firestore.saveUser(_users[payerIdx]);
      }
      // Update current user if they are the payer
      if (_currentUser?.id == payerId) {
        _currentUser = _currentUser!.copyWith(
          creditBalance: _currentUser!.creditBalance - valueGap,
        );
        _firestore.saveUser(_currentUser!);
      }

      // Add to receiver
      final receiverIdx = _users.indexWhere((u) => u.id == receiverId);
      if (receiverIdx != -1) {
        _users[receiverIdx] = _users[receiverIdx].copyWith(
          creditBalance: _users[receiverIdx].creditBalance + valueGap,
        );
        _firestore.saveUser(_users[receiverIdx]);
      }
      if (_currentUser?.id == receiverId) {
        _currentUser = _currentUser!.copyWith(
          creditBalance: _currentUser!.creditBalance + valueGap,
        );
        _firestore.saveUser(_currentUser!);
      }

      // Record transactions
      _transactions.insert(
          0,
          CreditTransactionModel(
            id: _uuid.v4(),
            userId: payerId,
            fromUserId: payerId,
            toUserId: receiverId,
            amount: valueGap,
            type: 'debit',
            tradeId: tradeId,
            description:
                'Trade gap: Paid ₹${valueGap.toStringAsFixed(0)} to $receiverName for ${theirListing.productType}',
            balanceAfter: payerIdx != -1 ? _users[payerIdx].creditBalance : 0,
          ));
      _transactions.insert(
          0,
          CreditTransactionModel(
            id: _uuid.v4(),
            userId: receiverId,
            fromUserId: payerId,
            toUserId: receiverId,
            amount: valueGap,
            type: 'credit',
            tradeId: tradeId,
            description:
                'Trade gap: Received ₹${valueGap.toStringAsFixed(0)} from $payerName for ${myListing.productType}',
            balanceAfter:
                receiverIdx != -1 ? _users[receiverIdx].creditBalance : 0,
          ));
    }

    // Update reputation for both (+2 for trading)
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        reputationScore: (_currentUser!.reputationScore + 2).clamp(0, 100),
        totalTrades: _currentUser!.totalTrades + 1,
      );
      _firestore.saveUser(_currentUser!);
    }
    final otherIdx = _users.indexWhere((u) => u.id == theirListing.farmerId);
    if (otherIdx != -1) {
      _users[otherIdx] = _users[otherIdx].copyWith(
        reputationScore:
            (_users[otherIdx].reputationScore + 2).clamp(0.0, 100.0),
        totalTrades: _users[otherIdx].totalTrades + 1,
      );
      _firestore.saveUser(_users[otherIdx]);
    }

    // Update listing statuses
    updateListingStatus(myListing.id, 'in_trade');
    updateListingStatus(theirListing.id, 'in_trade');

    // Notify
    _notifications.notifyTradeMatched(
      '${myListing.productType} ↔ ${theirListing.productType}',
    );

    notifyListeners();
  }

  // â”€â”€â”€ LISTINGS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void addListing(ListingModel listing) {
    _listings.insert(0, listing);
    // Already synced via _firestore.saveListing above
    // Sync to Firestore so other users can see it
    _firestore.saveListing(listing);
    notifyListeners();
    // After adding, check for trade loops
    _checkForTradeLoops();
  }

  void updateListingStatus(String listingId, String status) {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index != -1) {
      _listings[index] = _listings[index].copyWith(status: status);
      // Already synced via _firestore.updateListingStatus above
      _firestore.updateListingStatus(listingId, status);
      notifyListeners();
    }
  }

  // â”€â”€â”€ TRADE MATCHING ENGINE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    final existingLoop = _trades.any(
      (t) =>
          t.status == 'pending' &&
          t.participants.length == participants.length &&
          t.participants.every(
            (p) => participants.any((np) => np.listingId == p.listingId),
          ),
    );
    if (existingLoop) return;

    final trade = TradeModel(
      loopId: _uuid.v4(),
      participants: participants,
      status: 'pending',
    );

    _trades.insert(0, trade);
    // Already synced via _firestore.saveTrade above
    _firestore.saveTrade(trade);

    // ðŸ”” Notify about new trade match
    final productFlow = participants.map((p) => p.offerProduct).join(' â†’ ');
    _notifications.notifyTradeMatched(productFlow);

    notifyListeners();
  }

  // â”€â”€â”€ TRADE ACTIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void confirmTrade(String loopId, String farmerId) {
    final tradeIndex = _trades.indexWhere((t) => t.loopId == loopId);
    if (tradeIndex == -1) return;

    final trade = _trades[tradeIndex];

    // Only confirm the calling farmer
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

    // Check if ALL participants confirmed
    final allConfirmed = updatedParticipants.every(
      (p) => p.confirmationStatus == 'confirmed',
    );

    _trades[tradeIndex] = trade.copyWith(
      participants: updatedParticipants,
      status: allConfirmed ? 'executing' : 'pending',
    );

    // Trade stays at 'executing' — both parties must upload evidence before completion

    _firestore.updateTrade(_trades[tradeIndex]);
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

    _firestore.updateTrade(_trades[tradeIndex]);
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
      final receiver = trade.participants[(i + 1) % trade.participants.length];

      creditMovements.add(
        CreditMovement(
          fromUserId: giver.farmerId,
          toUserId: receiver.farmerId,
          amount: giver.valuationAmount,
          description: '${giver.offerProduct} â†’ ${receiver.farmerName}',
        ),
      );

      // Record transactions
      _transactions.add(
        CreditTransactionModel(
          id: _uuid.v4(),
          userId: giver.farmerId,
          fromUserId: giver.farmerId,
          toUserId: receiver.farmerId,
          amount: giver.valuationAmount,
          type: 'debit',
          tradeId: loopId,
          description: 'Sent ${giver.offerProduct} to ${receiver.farmerName}',
          balanceAfter: _currentUser?.creditBalance ?? 0,
        ),
      );
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
        reputationScore: min(100, _currentUser!.reputationScore + 2.0),
      );
      _firestore.saveUser(_currentUser!);
    }

    _firestore.updateTrade(_trades[tradeIndex]);

    // ðŸ”” Notify about trade completion
    final tradeProducts =
        trade.participants.map((p) => p.offerProduct).join(', ');
    _notifications.notifyTradeCompleted(tradeProducts);

    notifyListeners();
  }

  // â”€â”€â”€ VALUATION ENGINE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Calculate valuation using REAL mandi prices from API/SQLite
  /// and REAL demand factor from actual listing supply/demand.
  Future<double> _calculateValuationAsync(
      String productType, double quantity, double qualityScore) async {
    // Get real mandi price (from API cache in SQLite)
    final basePrice = await _mandiPrices.getPrice(productType);
    final qualityFactor = qualityScore / 100.0;

    // Real demand factor: based on actual supply/demand in listings
    final demandFactor = _calculateRealDemandFactor(productType);

    return basePrice * quantity * qualityFactor * demandFactor;
  }

  /// Synchronous fallback (used where async isn't practical)
  double _calculateValuation(
    String productType,
    double quantity,
    double qualityScore,
  ) {
    final basePrice = AppConstants.mandiPrices[productType] ?? 50.0;
    final qualityFactor = qualityScore / 100.0;
    final demandFactor = _calculateRealDemandFactor(productType);
    return basePrice * quantity * qualityFactor * demandFactor;
  }

  /// Calculate REAL demand factor based on actual listing data.
  /// demand = (number wanting this product) / (number offering this product)
  double _calculateRealDemandFactor(String productType) {
    final active = activeListings;
    if (active.isEmpty) return 1.0;

    // Count how many people WANT this product
    final demandCount = active
        .where(
            (l) => l.desiredProduct.toLowerCase() == productType.toLowerCase())
        .length;

    // Count how many people OFFER this product
    final supplyCount = active
        .where((l) => l.productType.toLowerCase() == productType.toLowerCase())
        .length;

    if (supplyCount == 0 && demandCount == 0) return 1.0;
    if (supplyCount == 0) return 1.5; // High demand, no supply â†’ premium
    if (demandCount == 0) return 0.7; // No demand â†’ discount

    // Demand/supply ratio, clamped to reasonable range [0.5, 2.0]
    final ratio = demandCount / supplyCount;
    return ratio.clamp(0.5, 2.0);
  }

  Future<double> getValuationAsync(String productType, double quantity,
      {double qualityScore = 85.0}) async {
    return _calculateValuationAsync(productType, quantity, qualityScore);
  }

  double getValuation(
    String productType,
    double quantity, {
    double qualityScore = 85.0,
  }) {
    return _calculateValuation(productType, quantity, qualityScore);
  }

  // â”€â”€â”€ AI QUALITY SCORING (REAL IMAGE ANALYSIS) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Analyze a real crop photo for quality scoring.
  /// Uses pixel-level analysis: brightness, saturation, green ratio,
  /// brown ratio, uniformity — NOT random numbers.
  Future<EvidenceModel> generateQualityScoreFromImage({
    required String tradeId,
    required String farmerId,
    required Uint8List imageBytes,
    String? photoUrl,
    String role = 'sending',
    String productName = '',
  }) async {
    // Real image analysis
    final analysis = _qualityAnalysis.analyzeImageBytes(imageBytes);

    final evidence = EvidenceModel(
      id: _uuid.v4(),
      tradeId: tradeId,
      farmerId: farmerId,
      role: role,
      productName: productName,
      photoUrl: photoUrl,
      aiQualityScore: analysis['overall'] as double,
      conditionTag: analysis['conditionTag'] as String,
      freshnessScore: analysis['freshness'] as double,
      damageScore: analysis['damage'] as double,
      colorScore: analysis['color'] as double,
      sizeScore: analysis['size'] as double,
      latitude: _currentUser?.latitude ?? 0,
      longitude: _currentUser?.longitude ?? 0,
    );

    _evidence.add(evidence);
    notifyListeners();
    return evidence;
  }

  // ─── EVIDENCE UPLOAD (BOTH PARTIES × 2 ROLES) ─────────────────

  /// Get all evidence for a specific trade (from local cache).
  List<EvidenceModel> getEvidenceForTrade(String tradeId) {
    return _evidence.where((e) => e.tradeId == tradeId).toList();
  }

  /// Get evidence uploaded by a specific farmer for a specific role.
  EvidenceModel? getMyEvidence(String tradeId, String farmerId, String role) {
    try {
      return _evidence.firstWhere(
        (e) => e.tradeId == tradeId && e.farmerId == farmerId && e.role == role,
      );
    } catch (_) {
      return null;
    }
  }

  /// Load evidence from Firestore into local cache for a trade.
  Future<void> loadEvidenceFromFirestore(String tradeId) async {
    try {
      final maps = await _firestore.getEvidenceForTrade(tradeId);
      for (final map in maps) {
        final e = EvidenceModel.fromMap(map);
        // Only add if not already in local cache
        if (!_evidence.any((existing) => existing.id == e.id)) {
          _evidence.add(e);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading evidence from Firestore: $e');
    }
  }

  /// Upload delivery evidence for a trade.
  /// Each farmer calls this TWICE: once for 'sending', once for 'receiving'.
  /// When all 4 photos are uploaded, auto-compare per product.
  Future<EvidenceModel> uploadEvidence({
    required String tradeId,
    required String farmerId,
    required String role, // 'sending' or 'receiving'
    required String productName,
    required Uint8List imageBytes,
    String? photoUrl,
  }) async {
    // Generate AI quality report
    final evidence = await generateQualityScoreFromImage(
      tradeId: tradeId,
      farmerId: farmerId,
      imageBytes: imageBytes,
      photoUrl: photoUrl,
      role: role,
      productName: productName,
    );

    // Save evidence to Firestore (cross-device sync)
    await _firestore.saveEvidence(evidence.toMap());

    // Refresh evidence from Firestore to get all uploads (both phones)
    await loadEvidenceFromFirestore(tradeId);

    // Check if all photos are uploaded
    final tradeEvidence = getEvidenceForTrade(tradeId);
    final tradeIndex = _trades.indexWhere((t) => t.loopId == tradeId);
    if (tradeIndex == -1) return evidence;

    final trade = _trades[tradeIndex];

    // For a 2-party trade: we need 4 photos total
    // Farmer A: sending + receiving = 2
    // Farmer B: sending + receiving = 2
    final expectedCount = trade.participants.length * 2;
    if (tradeEvidence.length >= expectedCount) {
      _autoCompareEvidence(tradeId, tradeEvidence, trade);
    }

    return evidence;
  }

  /// Compare evidence per product: sender's photo vs receiver's photo.
  /// If all products match → complete trade. If any mismatch → dispute.
  void _autoCompareEvidence(
    String tradeId,
    List<EvidenceModel> evidenceList,
    TradeModel trade,
  ) {
    bool anyMismatch = false;
    String mismatchDetails = '';

    // For each participant, compare their SENDING photo with 
    // the other party's RECEIVING photo (same product)
    for (final participant in trade.participants) {
      final senderEvidence = evidenceList.where(
        (e) => e.farmerId == participant.farmerId && e.role == 'sending',
      ).toList();

      if (senderEvidence.isEmpty) continue;
      final senderReport = senderEvidence.first;
      final product = senderReport.productName;

      // Find the receiver's photo of this same product
      final receiverEvidence = evidenceList.where(
        (e) => e.farmerId != participant.farmerId && e.role == 'receiving' && e.productName == product,
      ).toList();

      if (receiverEvidence.isEmpty) continue;
      final receiverReport = receiverEvidence.first;

      // Compare sender vs receiver scores for this product
      final freshDiff = (senderReport.freshnessScore - receiverReport.freshnessScore).abs();
      final damageDiff = (senderReport.damageScore - receiverReport.damageScore).abs();
      final colorDiff = (senderReport.colorScore - receiverReport.colorScore).abs();
      final sizeDiff = (senderReport.sizeScore - receiverReport.sizeScore).abs();
      final avgDiff = (freshDiff + damageDiff + colorDiff + sizeDiff) / 4;

      if (avgDiff > 25) {
        anyMismatch = true;
        mismatchDetails +=
            '$product: Sender (${participant.farmerName}) reported '
            '${senderReport.conditionTag} (${senderReport.aiQualityScore.toStringAsFixed(0)}%), '
            'Receiver reported '
            '${receiverReport.conditionTag} (${receiverReport.aiQualityScore.toStringAsFixed(0)}%). '
            'Diff: ${avgDiff.toStringAsFixed(1)}pts. ';
      }
    }

    if (!anyMismatch) {
      // All products match → trade is legit, complete it
      _executeTrade(tradeId);
    } else {
      // Mismatch found → auto-create dispute
      final respondent = trade.participants.first.farmerId;
      final respondentName = trade.participants.first.farmerName;

      fileDispute(
        tradeId: tradeId,
        respondentId: respondent,
        respondentName: respondentName,
        description: 'Auto-detected quality mismatch. $mismatchDetails',
      );

      // Move trade to disputed status
      final idx = _trades.indexWhere((t) => t.loopId == tradeId);
      if (idx != -1) {
        _trades[idx] = _trades[idx].copyWith(status: 'disputed');
        _firestore.updateTrade(_trades[idx]);
      }

      _notifications.notifyDisputeResolved('Quality mismatch detected — dispute filed automatically');
      notifyListeners();
    }
  }

  /// Fallback: generate quality score without an image (uses defaults).
  EvidenceModel generateQualityScore({
    required String tradeId,
    required String farmerId,
    String? photoUrl,
  }) {
    // Without image, use conservative defaults
    final evidence = EvidenceModel(
      id: _uuid.v4(),
      tradeId: tradeId,
      farmerId: farmerId,
      photoUrl: photoUrl,
      aiQualityScore: 70.0,
      conditionTag: 'Good',
      freshnessScore: 70.0,
      damageScore: 75.0,
      colorScore: 65.0,
      sizeScore: 70.0,
      latitude: _currentUser?.latitude ?? 0,
      longitude: _currentUser?.longitude ?? 0,
    );

    _evidence.add(evidence);
    // Evidence stays in-memory
    notifyListeners();
    return evidence;
  }

  // â”€â”€â”€ DISPUTE SYSTEM (REAL IMAGE COMPARISON) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// File a dispute with REAL image comparison when photos are provided.
  Future<DisputeModel> fileDisputeWithImages({
    required String tradeId,
    required String respondentId,
    required String respondentName,
    required String description,
    Uint8List? complaintImageBytes,
    Uint8List? deliveryImageBytes,
    String? complaintPhotoUrl,
    String? deliveryPhotoUrl,
  }) async {
    double similarity = 50.0;
    String verdict = 'manual_review';
    double refund = 0;

    // Real image comparison if both photos provided
    if (complaintImageBytes != null && deliveryImageBytes != null) {
      final result = _imageComparison.compareImageBytes(
        complaintImageBytes,
        deliveryImageBytes,
      );
      similarity = result['similarity'] as double;
      verdict = result['verdict'] as String;
      refund = (result['refundAmount'] as num?)?.toDouble() ?? 0;
    } else {
      // Without both images, base on description severity
      if (description.toLowerCase().contains('damaged') ||
          description.toLowerCase().contains('rotten') ||
          description.toLowerCase().contains('wrong')) {
        similarity = 30.0;
        verdict = 'valid_complaint';
        refund = 500;
      } else {
        similarity = 60.0;
        verdict = 'partial_refund';
        refund = 250;
      }
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

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        disputeCount: _currentUser!.disputeCount + 1,
      );
      _firestore.saveUser(_currentUser!);
    }

    // Dispute stays in-memory
    notifyListeners();
    return dispute;
  }

  /// Legacy fallback without image bytes
  DisputeModel fileDispute({
    required String tradeId,
    required String respondentId,
    required String respondentName,
    required String description,
    String? complaintPhotoUrl,
    String? deliveryPhotoUrl,
  }) {
    // Text-based analysis when no image bytes available
    double similarity = 60.0;
    String verdict;
    double refund = 0;

    // Analyze description text for severity keywords
    final descLower = description.toLowerCase();
    final severityKeywords = [
      'damaged',
      'rotten',
      'broken',
      'wrong',
      'bad',
      'spoiled',
      'fake'
    ];
    final moderateKeywords = ['different', 'less', 'quality', 'size', 'color'];

    final severeCount =
        severityKeywords.where((k) => descLower.contains(k)).length;
    final moderateCount =
        moderateKeywords.where((k) => descLower.contains(k)).length;

    if (severeCount >= 2) {
      similarity = 25.0;
      verdict = 'valid_complaint';
      refund = 500;
    } else if (severeCount >= 1) {
      similarity = 40.0;
      verdict = 'valid_complaint';
      refund = 500;
    } else if (moderateCount >= 2) {
      similarity = 55.0;
      verdict = 'partial_refund';
      refund = 250;
    } else if (moderateCount >= 1) {
      similarity = 65.0;
      verdict = 'partial_refund';
      refund = 250;
    } else {
      similarity = 75.0;
      verdict = 'false_complaint';
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

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        disputeCount: _currentUser!.disputeCount + 1,
      );
      _firestore.saveUser(_currentUser!);
    }

    // Dispute stays in-memory
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
      // Dispute update stays in-memory
      notifyListeners();
    }
  }

  // â”€â”€â”€ REPUTATION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
}
