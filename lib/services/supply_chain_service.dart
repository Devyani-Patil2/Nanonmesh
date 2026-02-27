import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import '../models/trade_model.dart';
import '../models/listing_model.dart';
import '../models/credit_transaction_model.dart';
import '../models/user_model.dart';

/// Supply chain integration service.
/// Exports trade/listing data as CSV for FPO/mandi integration.
class SupplyChainService {
  static final SupplyChainService instance = SupplyChainService._();
  SupplyChainService._();

  /// Generate a CSV report of all completed trades for FPO/mandi integration.
  String generateTradeReport(List<TradeModel> trades) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Trade ID,Status,Created At,Product Flow,Participants,Total Value');

    for (final trade in trades) {
      final flow = trade.participants
          .map((p) => '${p.farmerName}(${p.offerProduct})')
          .join(' → ');
      final totalValue = trade.creditMovements
          .fold<double>(0, (sum, m) => sum + m.amount);
      buffer.writeln(
          '${trade.loopId},${trade.status},${trade.createdAt.toIso8601String()},"$flow",${trade.participants.length},${totalValue.toStringAsFixed(0)}');
    }
    return buffer.toString();
  }

  /// Generate a CSV of all listings for agricultural supply chain data.
  String generateListingReport(List<ListingModel> listings) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Listing ID,Farmer,Village,Product,Quantity,Unit,Quality,Desired Product,Value (INR),Status,Latitude,Longitude');

    for (final l in listings) {
      buffer.writeln(
          '${l.id},${l.farmerName},${l.farmerVillage},${l.productType},${l.quantity},${l.unit},${l.qualityExpectation},${l.desiredProduct},${l.valuationScore.toStringAsFixed(0)},${l.status},${l.latitude},${l.longitude}');
    }
    return buffer.toString();
  }

  /// Generate transaction ledger CSV.
  String generateTransactionReport(List<CreditTransactionModel> txns) {
    final buffer = StringBuffer();
    buffer.writeln('Transaction ID,Type,Amount,Description,Date');

    for (final t in txns) {
      buffer.writeln(
          '${t.id},${t.type},${t.amount.toStringAsFixed(0)},${t.description},${t.timestamp.toIso8601String()}');
    }
    return buffer.toString();
  }

  /// Generate comprehensive JSON data package for FPO/supply chain systems.
  Future<String> generateFPODataPackage({
    required UserModel user,
    required List<TradeModel> trades,
    required List<ListingModel> listings,
    required List<CreditTransactionModel> transactions,
  }) async {
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'farmer': {
        'id': user.id,
        'name': user.name,
        'village': user.village,
        'phone': user.phone,
        'reputationScore': user.reputationScore,
        'creditBalance': user.creditBalance,
        'totalTrades': user.totalTrades,
        'coordinates': {
          'latitude': user.latitude,
          'longitude': user.longitude,
        },
      },
      'summary': {
        'totalTrades': trades.length,
        'completedTrades':
            trades.where((t) => t.status == 'completed').length,
        'activeListings':
            listings.where((l) => l.status == 'active').length,
        'totalTransactions': transactions.length,
      },
      'trades': trades
          .map((t) => {
                'loopId': t.loopId,
                'status': t.status,
                'createdAt': t.createdAt.toIso8601String(),
                'participants': t.participants.map((p) => p.toMap()).toList(),
                'creditMovements': t.creditMovements.map((c) => c.toMap()).toList(),
              })
          .toList(),
      'listings': listings
          .map((l) => {
                'id': l.id,
                'product': l.productType,
                'quantity': l.quantity,
                'unit': l.unit,
                'desiredProduct': l.desiredProduct,
                'value': l.valuationScore,
                'status': l.status,
              })
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Share data via system share dialog (WhatsApp, email, etc.)
  Future<void> shareReport(String title, String data) async {
    await Share.share(data, subject: title);
  }
}
