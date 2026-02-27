import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/listing_model.dart';
import '../models/trade_model.dart';
import '../models/evidence_model.dart';
import '../models/dispute_model.dart';
import '../models/credit_transaction_model.dart';
import '../models/urgent_request_model.dart';

/// SQLite database helper for offline data persistence.
/// Auth/login remains on SharedPreferences.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nanonmesh.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // ─── TABLE CREATION ───────────────────────────────────────

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        phone TEXT NOT NULL,
        name TEXT NOT NULL,
        village TEXT NOT NULL DEFAULT '',
        latitude REAL NOT NULL DEFAULT 0,
        longitude REAL NOT NULL DEFAULT 0,
        reputationScore REAL NOT NULL DEFAULT 75,
        creditBalance REAL NOT NULL DEFAULT 1000,
        totalTrades INTEGER NOT NULL DEFAULT 0,
        disputeCount INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // Listings table
    await db.execute('''
      CREATE TABLE listings (
        id TEXT PRIMARY KEY,
        farmerId TEXT NOT NULL,
        farmerName TEXT NOT NULL,
        farmerVillage TEXT NOT NULL DEFAULT '',
        productType TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'kg',
        desiredProduct TEXT NOT NULL,
        qualityExpectation TEXT NOT NULL DEFAULT 'Good',
        valuationScore REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        createdAt TEXT NOT NULL,
        FOREIGN KEY (farmerId) REFERENCES users(id)
      )
    ''');

    // Trades table
    await db.execute('''
      CREATE TABLE trades (
        loopId TEXT PRIMARY KEY,
        status TEXT NOT NULL DEFAULT 'pending',
        createdAt TEXT NOT NULL,
        completedAt TEXT
      )
    ''');

    // Trade participants (child of trades)
    await db.execute('''
      CREATE TABLE trade_participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loopId TEXT NOT NULL,
        farmerId TEXT NOT NULL,
        farmerName TEXT NOT NULL,
        listingId TEXT NOT NULL,
        offerProduct TEXT NOT NULL,
        wantProduct TEXT NOT NULL,
        offerQuantity REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'kg',
        valuationAmount REAL NOT NULL DEFAULT 0,
        confirmationStatus TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (loopId) REFERENCES trades(loopId)
      )
    ''');

    // Credit movements (child of trades)
    await db.execute('''
      CREATE TABLE credit_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loopId TEXT NOT NULL,
        fromUserId TEXT NOT NULL,
        toUserId TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (loopId) REFERENCES trades(loopId)
      )
    ''');

    // Evidence / AI quality reports
    await db.execute('''
      CREATE TABLE evidence (
        id TEXT PRIMARY KEY,
        tradeId TEXT NOT NULL,
        farmerId TEXT NOT NULL,
        photoUrl TEXT,
        aiQualityScore REAL NOT NULL DEFAULT 0,
        conditionTag TEXT NOT NULL DEFAULT '',
        freshnessScore REAL NOT NULL DEFAULT 0,
        damageScore REAL NOT NULL DEFAULT 0,
        colorScore REAL NOT NULL DEFAULT 0,
        sizeScore REAL NOT NULL DEFAULT 0,
        latitude REAL NOT NULL DEFAULT 0,
        longitude REAL NOT NULL DEFAULT 0,
        timestamp TEXT NOT NULL
      )
    ''');

    // Disputes
    await db.execute('''
      CREATE TABLE disputes (
        id TEXT PRIMARY KEY,
        tradeId TEXT NOT NULL,
        complainantId TEXT NOT NULL,
        complainantName TEXT NOT NULL,
        respondentId TEXT NOT NULL,
        respondentName TEXT NOT NULL,
        complaintPhotoUrl TEXT,
        deliveryPhotoUrl TEXT,
        description TEXT NOT NULL DEFAULT '',
        aiSimilarityScore REAL NOT NULL DEFAULT 0,
        aiVerdict TEXT NOT NULL DEFAULT '',
        resolution TEXT,
        status TEXT NOT NULL DEFAULT 'under_review',
        refundAmount REAL NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        resolvedAt TEXT
      )
    ''');

    // Credit transactions
    await db.execute('''
      CREATE TABLE credit_transactions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        fromUserId TEXT,
        toUserId TEXT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        tradeId TEXT,
        description TEXT NOT NULL DEFAULT '',
        balanceAfter REAL NOT NULL DEFAULT 0,
        timestamp TEXT NOT NULL
      )
    ''');

    // Urgent requests
    await db.execute('''
      CREATE TABLE urgent_requests (
        id TEXT PRIMARY KEY,
        requesterId TEXT NOT NULL,
        requesterName TEXT NOT NULL,
        requesterVillage TEXT NOT NULL DEFAULT '',
        productNeeded TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'kg',
        creditCost REAL NOT NULL DEFAULT 0,
        urgencyLevel TEXT NOT NULL DEFAULT 'high',
        description TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'open',
        fulfillerId TEXT,
        fulfillerName TEXT,
        createdAt TEXT NOT NULL,
        fulfilledAt TEXT
      )
    ''');
    // Mandi prices (cached from API)
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

  // ─── USERS ───────────────────────────────────────────────

  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert('users', {
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
      'createdAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUser(UserModel user) async {
    final db = await database;
    await db.update('users', {
      'name': user.name,
      'village': user.village,
      'latitude': user.latitude,
      'longitude': user.longitude,
      'reputationScore': user.reputationScore,
      'creditBalance': user.creditBalance,
      'totalTrades': user.totalTrades,
      'disputeCount': user.disputeCount,
    }, where: 'id = ?', whereArgs: [user.id]);
  }

  Future<List<UserModel>> getUsers() async {
    final db = await database;
    final rows = await db.query('users');
    return rows.map((r) => UserModel(
      id: r['id'] as String,
      phone: r['phone'] as String,
      name: r['name'] as String,
      village: r['village'] as String? ?? '',
      latitude: (r['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (r['longitude'] as num?)?.toDouble() ?? 0,
      reputationScore: (r['reputationScore'] as num?)?.toDouble() ?? 75,
      creditBalance: (r['creditBalance'] as num?)?.toDouble() ?? 1000,
      totalTrades: (r['totalTrades'] as int?) ?? 0,
      disputeCount: (r['disputeCount'] as int?) ?? 0,
    )).toList();
  }

  Future<UserModel?> getUser(String id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return UserModel(
      id: r['id'] as String,
      phone: r['phone'] as String,
      name: r['name'] as String,
      village: r['village'] as String? ?? '',
      latitude: (r['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (r['longitude'] as num?)?.toDouble() ?? 0,
      reputationScore: (r['reputationScore'] as num?)?.toDouble() ?? 75,
      creditBalance: (r['creditBalance'] as num?)?.toDouble() ?? 1000,
      totalTrades: (r['totalTrades'] as int?) ?? 0,
      disputeCount: (r['disputeCount'] as int?) ?? 0,
    );
  }

  // ─── LISTINGS ───────────────────────────────────────────

  Future<void> insertListing(ListingModel listing) async {
    final db = await database;
    await db.insert('listings', {
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
      'status': listing.status,
      'createdAt': listing.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateListingStatus(String id, String status) async {
    final db = await database;
    await db.update('listings', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ListingModel>> getListings() async {
    final db = await database;
    final rows = await db.query('listings', orderBy: 'createdAt DESC');
    return rows.map((r) => ListingModel(
      id: r['id'] as String,
      farmerId: r['farmerId'] as String,
      farmerName: r['farmerName'] as String,
      farmerVillage: r['farmerVillage'] as String? ?? '',
      productType: r['productType'] as String,
      quantity: (r['quantity'] as num).toDouble(),
      unit: r['unit'] as String? ?? 'kg',
      desiredProduct: r['desiredProduct'] as String,
      qualityExpectation: r['qualityExpectation'] as String? ?? 'Good',
      valuationScore: (r['valuationScore'] as num?)?.toDouble() ?? 0,
      status: r['status'] as String? ?? 'active',
      createdAt: DateTime.parse(r['createdAt'] as String),
    )).toList();
  }

  // ─── TRADES ─────────────────────────────────────────────

  Future<void> insertTrade(TradeModel trade) async {
    final db = await database;
    await db.insert('trades', {
      'loopId': trade.loopId,
      'status': trade.status,
      'createdAt': trade.createdAt.toIso8601String(),
      'completedAt': trade.completedAt?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Insert participants
    for (final p in trade.participants) {
      await db.insert('trade_participants', {
        'loopId': trade.loopId,
        'farmerId': p.farmerId,
        'farmerName': p.farmerName,
        'listingId': p.listingId,
        'offerProduct': p.offerProduct,
        'wantProduct': p.wantProduct,
        'offerQuantity': p.offerQuantity,
        'unit': p.unit,
        'valuationAmount': p.valuationAmount,
        'confirmationStatus': p.confirmationStatus,
      });
    }

    // Insert credit movements
    for (final cm in trade.creditMovements) {
      await db.insert('credit_movements', {
        'loopId': trade.loopId,
        'fromUserId': cm.fromUserId,
        'toUserId': cm.toUserId,
        'amount': cm.amount,
        'description': cm.description,
      });
    }
  }

  Future<void> updateTrade(TradeModel trade) async {
    final db = await database;
    await db.update('trades', {
      'status': trade.status,
      'completedAt': trade.completedAt?.toIso8601String(),
    }, where: 'loopId = ?', whereArgs: [trade.loopId]);

    // Update participants
    await db.delete('trade_participants',
        where: 'loopId = ?', whereArgs: [trade.loopId]);
    for (final p in trade.participants) {
      await db.insert('trade_participants', {
        'loopId': trade.loopId,
        'farmerId': p.farmerId,
        'farmerName': p.farmerName,
        'listingId': p.listingId,
        'offerProduct': p.offerProduct,
        'wantProduct': p.wantProduct,
        'offerQuantity': p.offerQuantity,
        'unit': p.unit,
        'valuationAmount': p.valuationAmount,
        'confirmationStatus': p.confirmationStatus,
      });
    }

    // Update credit movements
    await db.delete('credit_movements',
        where: 'loopId = ?', whereArgs: [trade.loopId]);
    for (final cm in trade.creditMovements) {
      await db.insert('credit_movements', {
        'loopId': trade.loopId,
        'fromUserId': cm.fromUserId,
        'toUserId': cm.toUserId,
        'amount': cm.amount,
        'description': cm.description,
      });
    }
  }

  Future<List<TradeModel>> getTrades() async {
    final db = await database;
    final tradeRows = await db.query('trades', orderBy: 'createdAt DESC');
    final trades = <TradeModel>[];

    for (final t in tradeRows) {
      final loopId = t['loopId'] as String;
      final participants = await db.query('trade_participants',
          where: 'loopId = ?', whereArgs: [loopId]);
      final movements = await db.query('credit_movements',
          where: 'loopId = ?', whereArgs: [loopId]);

      trades.add(TradeModel(
        loopId: loopId,
        status: t['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(t['createdAt'] as String),
        completedAt: t['completedAt'] != null
            ? DateTime.parse(t['completedAt'] as String)
            : null,
        participants: participants.map((p) => TradeParticipant(
          farmerId: p['farmerId'] as String,
          farmerName: p['farmerName'] as String,
          listingId: p['listingId'] as String,
          offerProduct: p['offerProduct'] as String,
          wantProduct: p['wantProduct'] as String,
          offerQuantity: (p['offerQuantity'] as num).toDouble(),
          unit: p['unit'] as String? ?? 'kg',
          valuationAmount: (p['valuationAmount'] as num?)?.toDouble() ?? 0,
          confirmationStatus: p['confirmationStatus'] as String? ?? 'pending',
        )).toList(),
        creditMovements: movements.map((m) => CreditMovement(
          fromUserId: m['fromUserId'] as String,
          toUserId: m['toUserId'] as String,
          amount: (m['amount'] as num).toDouble(),
          description: m['description'] as String? ?? '',
        )).toList(),
      ));
    }
    return trades;
  }

  // ─── EVIDENCE ───────────────────────────────────────────

  Future<void> insertEvidence(EvidenceModel evidence) async {
    final db = await database;
    await db.insert('evidence', {
      'id': evidence.id,
      'tradeId': evidence.tradeId,
      'farmerId': evidence.farmerId,
      'photoUrl': evidence.photoUrl,
      'aiQualityScore': evidence.aiQualityScore,
      'conditionTag': evidence.conditionTag,
      'freshnessScore': evidence.freshnessScore,
      'damageScore': evidence.damageScore,
      'colorScore': evidence.colorScore,
      'sizeScore': evidence.sizeScore,
      'latitude': evidence.latitude,
      'longitude': evidence.longitude,
      'timestamp': evidence.timestamp.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<EvidenceModel>> getEvidence() async {
    final db = await database;
    final rows = await db.query('evidence', orderBy: 'timestamp DESC');
    return rows.map((r) => EvidenceModel(
      id: r['id'] as String,
      tradeId: r['tradeId'] as String,
      farmerId: r['farmerId'] as String,
      photoUrl: r['photoUrl'] as String?,
      aiQualityScore: (r['aiQualityScore'] as num).toDouble(),
      conditionTag: r['conditionTag'] as String? ?? '',
      freshnessScore: (r['freshnessScore'] as num?)?.toDouble() ?? 0,
      damageScore: (r['damageScore'] as num?)?.toDouble() ?? 0,
      colorScore: (r['colorScore'] as num?)?.toDouble() ?? 0,
      sizeScore: (r['sizeScore'] as num?)?.toDouble() ?? 0,
      latitude: (r['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (r['longitude'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.parse(r['timestamp'] as String),
    )).toList();
  }

  // ─── DISPUTES ───────────────────────────────────────────

  Future<void> insertDispute(DisputeModel dispute) async {
    final db = await database;
    await db.insert('disputes', {
      'id': dispute.id,
      'tradeId': dispute.tradeId,
      'complainantId': dispute.complainantId,
      'complainantName': dispute.complainantName,
      'respondentId': dispute.respondentId,
      'respondentName': dispute.respondentName,
      'complaintPhotoUrl': dispute.complaintPhotoUrl,
      'deliveryPhotoUrl': dispute.deliveryPhotoUrl,
      'description': dispute.description,
      'aiSimilarityScore': dispute.aiSimilarityScore,
      'aiVerdict': dispute.aiVerdict,
      'resolution': dispute.resolution,
      'status': dispute.status,
      'refundAmount': dispute.refundAmount,
      'createdAt': dispute.createdAt.toIso8601String(),
      'resolvedAt': dispute.resolvedAt?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateDispute(DisputeModel dispute) async {
    final db = await database;
    await db.update('disputes', {
      'resolution': dispute.resolution,
      'status': dispute.status,
      'resolvedAt': dispute.resolvedAt?.toIso8601String(),
    }, where: 'id = ?', whereArgs: [dispute.id]);
  }

  Future<List<DisputeModel>> getDisputes() async {
    final db = await database;
    final rows = await db.query('disputes', orderBy: 'createdAt DESC');
    return rows.map((r) => DisputeModel(
      id: r['id'] as String,
      tradeId: r['tradeId'] as String,
      complainantId: r['complainantId'] as String,
      complainantName: r['complainantName'] as String,
      respondentId: r['respondentId'] as String,
      respondentName: r['respondentName'] as String,
      complaintPhotoUrl: r['complaintPhotoUrl'] as String?,
      deliveryPhotoUrl: r['deliveryPhotoUrl'] as String?,
      description: r['description'] as String? ?? '',
      aiSimilarityScore: (r['aiSimilarityScore'] as num).toDouble(),
      aiVerdict: r['aiVerdict'] as String? ?? '',
      resolution: r['resolution'] as String? ?? 'pending',
      status: r['status'] as String? ?? 'under_review',
      refundAmount: (r['refundAmount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(r['createdAt'] as String),
      resolvedAt: r['resolvedAt'] != null
          ? DateTime.parse(r['resolvedAt'] as String)
          : null,
    )).toList();
  }

  // ─── CREDIT TRANSACTIONS ────────────────────────────────

  Future<void> insertTransaction(CreditTransactionModel txn) async {
    final db = await database;
    await db.insert('credit_transactions', {
      'id': txn.id,
      'userId': txn.userId,
      'fromUserId': txn.fromUserId,
      'toUserId': txn.toUserId,
      'amount': txn.amount,
      'type': txn.type,
      'tradeId': txn.tradeId,
      'description': txn.description,
      'balanceAfter': txn.balanceAfter,
      'timestamp': txn.timestamp.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CreditTransactionModel>> getTransactions() async {
    final db = await database;
    final rows =
        await db.query('credit_transactions', orderBy: 'timestamp DESC');
    return rows.map((r) => CreditTransactionModel(
      id: r['id'] as String,
      userId: r['userId'] as String,
      fromUserId: r['fromUserId'] as String?,
      toUserId: r['toUserId'] as String?,
      amount: (r['amount'] as num).toDouble(),
      type: r['type'] as String,
      tradeId: r['tradeId'] as String?,
      description: r['description'] as String? ?? '',
      balanceAfter: (r['balanceAfter'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.parse(r['timestamp'] as String),
    )).toList();
  }

  // ─── URGENT REQUESTS ────────────────────────────────────

  Future<void> insertUrgentRequest(UrgentRequestModel request) async {
    final db = await database;
    await db.insert('urgent_requests', {
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
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUrgentRequest(UrgentRequestModel request) async {
    final db = await database;
    await db.update('urgent_requests', {
      'status': request.status,
      'fulfillerId': request.fulfillerId,
      'fulfillerName': request.fulfillerName,
      'fulfilledAt': request.fulfilledAt?.toIso8601String(),
    }, where: 'id = ?', whereArgs: [request.id]);
  }

  Future<List<UrgentRequestModel>> getUrgentRequests() async {
    final db = await database;
    final rows =
        await db.query('urgent_requests', orderBy: 'createdAt DESC');
    return rows.map((r) => UrgentRequestModel(
      id: r['id'] as String,
      requesterId: r['requesterId'] as String,
      requesterName: r['requesterName'] as String,
      requesterVillage: r['requesterVillage'] as String? ?? '',
      productNeeded: r['productNeeded'] as String,
      quantity: (r['quantity'] as num).toDouble(),
      unit: r['unit'] as String? ?? 'kg',
      creditCost: (r['creditCost'] as num?)?.toDouble() ?? 0,
      urgencyLevel: r['urgencyLevel'] as String? ?? 'high',
      description: r['description'] as String? ?? '',
      status: r['status'] as String? ?? 'open',
      fulfillerId: r['fulfillerId'] as String?,
      fulfillerName: r['fulfillerName'] as String?,
      createdAt: DateTime.parse(r['createdAt'] as String),
      fulfilledAt: r['fulfilledAt'] != null
          ? DateTime.parse(r['fulfilledAt'] as String)
          : null,
    )).toList();
  }

  // ─── UTILITIES ──────────────────────────────────────────

  /// Check if seed data already exists
  Future<bool> hasSeedData() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM users'));
    return (count ?? 0) > 0;
  }

  /// Clear all tables (for sign-out)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('trade_participants');
    await db.delete('credit_movements');
    await db.delete('trades');
    await db.delete('listings');
    await db.delete('evidence');
    await db.delete('disputes');
    await db.delete('credit_transactions');
    await db.delete('urgent_requests');
    await db.delete('users');
  }

  /// Close the database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
