import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/listing_model.dart';
import '../models/trade_model.dart';
import '../models/urgent_request_model.dart';

/// Firestore service for cross-device data sharing.
/// Auth stays local (PIN-based). Only data is synced via Firestore.
class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();

  final _firestore = FirebaseFirestore.instance;

  // ─── COLLECTIONS ───────────────────────────────────────────

  CollectionReference get _usersCol => _firestore.collection('users');
  CollectionReference get _listingsCol => _firestore.collection('listings');
  CollectionReference get _tradesCol => _firestore.collection('trades');
  CollectionReference get _urgentRequestsCol =>
      _firestore.collection('urgent_requests');

  // ─── USERS ─────────────────────────────────────────────────

  /// Save/update user profile to Firestore
  Future<void> saveUser(UserModel user) async {
    await _usersCol.doc(user.id).set({
      'id': user.id,
      'phone': user.phone,
      'name': user.name,
      'village': user.village,
      'latitude': user.latitude,
      'longitude': user.longitude,
      'reputationScore': user.reputationScore,
      'creditBalance': user.creditBalance,
      'totalTrades': user.totalTrades,
      'disputeCount': user.disputeCount,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get all users
  Future<List<UserModel>> getUsers() async {
    final snap = await _usersCol.get();
    return snap.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return UserModel(
        id: d['id'] ?? doc.id,
        phone: d['phone'] ?? '',
        name: d['name'] ?? '',
        village: d['village'] ?? '',
        latitude: (d['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (d['longitude'] as num?)?.toDouble() ?? 0,
        reputationScore: (d['reputationScore'] as num?)?.toDouble() ?? 75,
        creditBalance: (d['creditBalance'] as num?)?.toDouble() ?? 1000,
        totalTrades: (d['totalTrades'] as num?)?.toInt() ?? 0,
        disputeCount: (d['disputeCount'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  /// Update user credit balance
  Future<void> updateUserCredits(String userId, double newBalance) async {
    await _usersCol.doc(userId).update({'creditBalance': newBalance});
  }

  // ─── LISTINGS ──────────────────────────────────────────────

  /// Save a listing to Firestore (visible to all users)
  Future<void> saveListing(ListingModel listing) async {
    await _listingsCol.doc(listing.id).set({
      'id': listing.id,
      'farmerId': listing.farmerId,
      'farmerName': listing.farmerName,
      'farmerVillage': listing.farmerVillage,
      'productType': listing.productType,
      'quantity': listing.quantity,
      'unit': listing.unit,
      'desiredProduct': listing.desiredProduct,
      'qualityExpectation': listing.qualityExpectation,
      'valuationScore': listing.valuationScore,
      'latitude': listing.latitude,
      'longitude': listing.longitude,
      'status': listing.status,
      'createdAt': listing.createdAt.toIso8601String(),
    });
  }

  /// Get all active listings (real-time stream)
  Stream<List<ListingModel>> listingsStream() {
    return _listingsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return ListingModel(
                id: d['id'] ?? doc.id,
                farmerId: d['farmerId'] ?? '',
                farmerName: d['farmerName'] ?? '',
                farmerVillage: d['farmerVillage'] ?? '',
                productType: d['productType'] ?? '',
                quantity: (d['quantity'] as num?)?.toDouble() ?? 0,
                unit: d['unit'] ?? 'kg',
                desiredProduct: d['desiredProduct'] ?? '',
                qualityExpectation: d['qualityExpectation'] ?? 'Good',
                valuationScore: (d['valuationScore'] as num?)?.toDouble() ?? 0,
                latitude: (d['latitude'] as num?)?.toDouble() ?? 0,
                longitude: (d['longitude'] as num?)?.toDouble() ?? 0,
                status: d['status'] ?? 'active',
                createdAt: d['createdAt'] != null
                    ? DateTime.tryParse(d['createdAt']) ?? DateTime.now()
                    : DateTime.now(),
              );
            }).toList());
  }

  /// Get all listings once (non-stream)
  Future<List<ListingModel>> getListings() async {
    final snap =
        await _listingsCol.orderBy('createdAt', descending: true).get();
    return snap.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return ListingModel(
        id: d['id'] ?? doc.id,
        farmerId: d['farmerId'] ?? '',
        farmerName: d['farmerName'] ?? '',
        farmerVillage: d['farmerVillage'] ?? '',
        productType: d['productType'] ?? '',
        quantity: (d['quantity'] as num?)?.toDouble() ?? 0,
        unit: d['unit'] ?? 'kg',
        desiredProduct: d['desiredProduct'] ?? '',
        qualityExpectation: d['qualityExpectation'] ?? 'Good',
        valuationScore: (d['valuationScore'] as num?)?.toDouble() ?? 0,
        latitude: (d['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (d['longitude'] as num?)?.toDouble() ?? 0,
        status: d['status'] ?? 'active',
        createdAt: d['createdAt'] != null
            ? DateTime.tryParse(d['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
    }).toList();
  }

  /// Update listing status
  Future<void> updateListingStatus(String listingId, String status) async {
    await _listingsCol.doc(listingId).update({'status': status});
  }

  // ─── TRADES ────────────────────────────────────────────────

  /// Save a trade to Firestore
  Future<void> saveTrade(TradeModel trade) async {
    await _tradesCol.doc(trade.loopId).set({
      'loopId': trade.loopId,
      'status': trade.status,
      'createdAt': trade.createdAt.toIso8601String(),
      'completedAt': trade.completedAt?.toIso8601String(),
      'participants': trade.participants
          .map((p) => {
                'farmerId': p.farmerId,
                'farmerName': p.farmerName,
                'listingId': p.listingId,
                'offerProduct': p.offerProduct,
                'wantProduct': p.wantProduct,
                'offerQuantity': p.offerQuantity,
                'unit': p.unit,
                'valuationAmount': p.valuationAmount,
                'confirmationStatus': p.confirmationStatus,
              })
          .toList(),
      'creditMovements': trade.creditMovements
          .map((cm) => {
                'fromUserId': cm.fromUserId,
                'toUserId': cm.toUserId,
                'amount': cm.amount,
                'description': cm.description,
              })
          .toList(),
    });
  }

  /// Get all trades (real-time stream)
  Stream<List<TradeModel>> tradesStream() {
    return _tradesCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return _tradeFromMap(d, doc.id);
            }).toList());
  }

  /// Get all trades once
  Future<List<TradeModel>> getTrades() async {
    final snap = await _tradesCol.orderBy('createdAt', descending: true).get();
    return snap.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return _tradeFromMap(d, doc.id);
    }).toList();
  }

  /// Update trade status
  Future<void> updateTrade(TradeModel trade) async {
    await saveTrade(trade); // Overwrite
  }

  TradeModel _tradeFromMap(Map<String, dynamic> d, String docId) {
    final participants = (d['participants'] as List<dynamic>? ?? [])
        .map((p) => TradeParticipant(
              farmerId: p['farmerId'] ?? '',
              farmerName: p['farmerName'] ?? '',
              listingId: p['listingId'] ?? '',
              offerProduct: p['offerProduct'] ?? '',
              wantProduct: p['wantProduct'] ?? '',
              offerQuantity: (p['offerQuantity'] as num?)?.toDouble() ?? 0,
              unit: p['unit'] ?? 'kg',
              valuationAmount: (p['valuationAmount'] as num?)?.toDouble() ?? 0,
              confirmationStatus: p['confirmationStatus'] ?? 'pending',
            ))
        .toList();

    final creditMovements = (d['creditMovements'] as List<dynamic>? ?? [])
        .map((cm) => CreditMovement(
              fromUserId: cm['fromUserId'] ?? '',
              toUserId: cm['toUserId'] ?? '',
              amount: (cm['amount'] as num?)?.toDouble() ?? 0,
              description: cm['description'] ?? '',
            ))
        .toList();

    return TradeModel(
      loopId: d['loopId'] ?? docId,
      status: d['status'] ?? 'pending',
      createdAt: d['createdAt'] != null
          ? DateTime.tryParse(d['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      completedAt:
          d['completedAt'] != null ? DateTime.tryParse(d['completedAt']) : null,
      participants: participants,
      creditMovements: creditMovements,
    );
  }

  // ─── URGENT REQUESTS ──────────────────────────────────────

  /// Save urgent request
  Future<void> saveUrgentRequest(UrgentRequestModel request) async {
    await _urgentRequestsCol.doc(request.id).set({
      'id': request.id,
      'requesterId': request.requesterId,
      'requesterName': request.requesterName,
      'requesterVillage': request.requesterVillage,
      'productNeeded': request.productNeeded,
      'quantity': request.quantity,
      'unit': request.unit,
      'creditCost': request.creditCost,
      'urgencyLevel': request.urgencyLevel,
      'description': request.description,
      'status': request.status,
      'fulfillerId': request.fulfillerId,
      'fulfillerName': request.fulfillerName,
      'createdAt': request.createdAt.toIso8601String(),
      'fulfilledAt': request.fulfilledAt?.toIso8601String(),
    });
  }

  /// Get urgent requests stream
  Stream<List<UrgentRequestModel>> urgentRequestsStream() {
    return _urgentRequestsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return UrgentRequestModel(
                id: d['id'] ?? doc.id,
                requesterId: d['requesterId'] ?? '',
                requesterName: d['requesterName'] ?? '',
                requesterVillage: d['requesterVillage'] ?? '',
                productNeeded: d['productNeeded'] ?? '',
                quantity: (d['quantity'] as num?)?.toDouble() ?? 0,
                unit: d['unit'] ?? 'kg',
                creditCost: (d['creditCost'] as num?)?.toDouble() ?? 0,
                urgencyLevel: d['urgencyLevel'] ?? 'high',
                description: d['description'] ?? '',
                status: d['status'] ?? 'open',
                fulfillerId: d['fulfillerId'],
                fulfillerName: d['fulfillerName'],
                createdAt: d['createdAt'] != null
                    ? DateTime.tryParse(d['createdAt']) ?? DateTime.now()
                    : DateTime.now(),
                fulfilledAt: d['fulfilledAt'] != null
                    ? DateTime.tryParse(d['fulfilledAt'])
                    : null,
              );
            }).toList());
  }

  /// Update urgent request
  Future<void> updateUrgentRequest(UrgentRequestModel request) async {
    await saveUrgentRequest(request);
  }

  // ─── EVIDENCE ──────────────────────────────────────────────

  /// Save evidence to Firestore
  Future<void> saveEvidence(Map<String, dynamic> evidence) async {
    await _firestore.collection('evidence').doc(evidence['id']).set(evidence);
  }

  /// Get all evidence for a trade (real-time stream)
  Stream<List<Map<String, dynamic>>> evidenceStream(String tradeId) {
    return _firestore
        .collection('evidence')
        .where('tradeId', isEqualTo: tradeId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Get all evidence for a trade (one-time)
  Future<List<Map<String, dynamic>>> getEvidenceForTrade(String tradeId) async {
    final snap = await _firestore
        .collection('evidence')
        .where('tradeId', isEqualTo: tradeId)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }
}
