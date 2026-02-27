import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notification service for trade events.
/// Triggers notifications when trades are matched, requests fulfilled, etc.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification system.
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Show a notification with the given title and body.
  Future<void> show({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'agroswap_channel',
      'AgroSwap Alerts',
      channelDescription: 'Trade and exchange notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }

  // ─── Convenience methods for specific events ────────────────

  /// Notify when a new trade loop is matched.
  Future<void> notifyTradeMatched(String productInfo) async {
    await show(
      title: '🔄 New Trade Match Found!',
      body: 'A trade loop involving $productInfo has been created. Confirm now!',
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Notify when all participants confirm a trade.
  Future<void> notifyTradeCompleted(String tradeInfo) async {
    await show(
      title: '✅ Trade Completed!',
      body: 'Your trade for $tradeInfo has been executed successfully.',
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Notify when someone fulfills an urgent request.
  Future<void> notifyRequestFulfilled(String product) async {
    await show(
      title: '🎉 Urgent Request Fulfilled!',
      body: 'Your urgent request for $product has been fulfilled. Credits transferred.',
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Notify when a new urgent request matches what you have.
  Future<void> notifyNewUrgentRequest(String product, String farmer) async {
    await show(
      title: '🚨 Nearby Farmer Needs Help!',
      body: '$farmer urgently needs $product. Fulfill to earn credits!',
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Notify when a dispute is resolved.
  Future<void> notifyDisputeResolved(String verdict) async {
    await show(
      title: '⚖️ Dispute Resolved',
      body: 'Your dispute has been resolved: $verdict',
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Notify about mandi price updates.
  Future<void> notifyPriceUpdate(String commodity, double newPrice) async {
    await show(
      title: '📊 Mandi Price Update',
      body: '$commodity price updated to ₹${newPrice.toStringAsFixed(1)}/kg',
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}
