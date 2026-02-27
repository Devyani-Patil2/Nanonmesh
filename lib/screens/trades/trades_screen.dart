import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/app_state.dart';
import '../../models/trade_model.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TradeModel> _filterTrades(List<TradeModel> trades, String filter) {
    switch (filter) {
      case 'active':
        return trades
            .where(
              (t) =>
                  t.status == 'confirmed' ||
                  t.status == 'executing' ||
                  t.status == 'active',
            )
            .toList();
      case 'pending':
        return trades.where((t) => t.status == 'pending').toList();
      case 'history':
        return trades
            .where(
              (t) =>
                  t.status == 'completed' ||
                  t.status == 'failed' ||
                  t.status == 'cancelled',
            )
            .toList();
      default:
        return trades;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final trades = appState.trades;
    final activeTrades = _filterTrades(trades, 'active');
    final pendingTrades = _filterTrades(trades, 'pending');
    final historyTrades = _filterTrades(trades, 'history');
    final isDark = appState.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(
          'Trade Hub',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {},
            tooltip: 'Refresh trades',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Active (${activeTrades.length})'),
                Tab(text: 'Pending (${pendingTrades.length})'),
                Tab(text: 'History (${historyTrades.length})'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTradeList(
                  context,
                  activeTrades,
                  'No active trades',
                  'Confirm pending trades to activate loops',
                  isDark,
                ),
                _buildTradeList(
                  context,
                  pendingTrades,
                  'No pending trades',
                  'New loop matches will appear here',
                  isDark,
                ),
                _buildTradeList(
                  context,
                  historyTrades,
                  'No trade history',
                  'Completed trades will show here',
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeList(
    BuildContext context,
    List<TradeModel> trades,
    String emptyTitle,
    String emptySubtitle,
    bool isDark,
  ) {
    if (trades.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_calls_rounded,
              size: 64,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: trades.length,
      itemBuilder: (context, index) {
        final trade = trades[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 100),
          child: _tradeCard(context, trade, isDark),
        );
      },
    );
  }

  Widget _tradeCard(BuildContext context, TradeModel trade, bool isDark) {
    final statusColor = AppTheme.statusColor(trade.status);
    final totalValue = trade.participants.fold<double>(
      0,
      (sum, p) => sum + p.valuationAmount,
    );
    final confirmedCount = trade.participants
        .where((p) => p.confirmationStatus == 'confirmed')
        .length;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/trade-detail', arguments: trade),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.sync_rounded, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trade.participants.length}-Party Trade Loop',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trade.participants
                            .map((p) => p.farmerName.split(' ').first)
                            .join(' → '),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trade.status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Status FSM mini stepper
            _buildMiniStepper(trade.status, isDark),
            const SizedBox(height: 14),

            // Product chips row
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: trade.participants.map<Widget>((p) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${AppConstants.productEmojis[p.offerProduct] ?? "📦"} ${p.offerProduct}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade300 : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Bottom info row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 14,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$confirmedCount/${trade.participants.length} confirmed',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                if (totalValue > 0)
                  Text(
                    '₹${totalValue.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStepper(String status, bool isDark) {
    final steps = ['pending', 'confirmed', 'executing', 'completed'];
    final currentIdx = steps.indexOf(status);

    return Row(
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final isActive = idx <= currentIdx && currentIdx >= 0;
        final isCurrent = idx == currentIdx;

        return Expanded(
          child: Row(
            children: [
              if (idx > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isActive
                        ? AppTheme.primaryGreen
                        : (isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300),
                  ),
                ),
              Container(
                width: isCurrent ? 14 : 10,
                height: isCurrent ? 14 : 10,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryGreen
                      : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              if (idx < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: idx < currentIdx
                        ? AppTheme.primaryGreen
                        : (isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
