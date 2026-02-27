import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/app_state.dart';
import '../../services/mandi_price_service.dart';

/// Real-time price discovery screen.
/// Shows current mandi prices from the government API cached in SQLite.
class PriceDiscoveryScreen extends StatefulWidget {
  const PriceDiscoveryScreen({super.key});

  @override
  State<PriceDiscoveryScreen> createState() => _PriceDiscoveryScreenState();
}

class _PriceDiscoveryScreenState extends State<PriceDiscoveryScreen> {
  Map<String, double> _prices = {};
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    final prices = await MandiPriceService.instance.getAllPrices();
    if (mounted) {
      setState(() {
        _prices = prices;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFromAPI() async {
    setState(() => _isRefreshing = true);
    final success = await MandiPriceService.instance.fetchLatestPrices();
    if (success) {
      await _loadPrices();
    }
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Prices updated from government mandi data ✅'
              : 'Could not reach API. Using cached prices.'),
          backgroundColor: success ? AppTheme.successGreen : AppTheme.accentAmber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort by price descending
    final sortedEntries = _prices.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      
      appBar: AppBar(
        title: Text('Mandi Price Discovery',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _refreshFromAPI,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header info
                  FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.analytics_outlined,
                              color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live Mandi Prices',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Data from Government of India (data.gov.in)',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price table
                  FadeInUp(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Table header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text('Commodity',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryGreen)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Price/kg',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryGreen),
                                      textAlign: TextAlign.right),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: Text('Demand',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryGreen),
                                      textAlign: TextAlign.center),
                                ),
                              ],
                            ),
                          ),
                          // Price rows
                          ...sortedEntries.map((entry) {
                            final emoji = AppConstants.productEmojis[entry.key] ?? '📦';
                            final appState = context.read<AppState>();
                            final demandCount = appState.activeListings
                                .where((l) =>
                                    l.desiredProduct.toLowerCase() ==
                                    entry.key.toLowerCase())
                                .length;
                            final supplyCount = appState.activeListings
                                .where((l) =>
                                    l.productType.toLowerCase() ==
                                    entry.key.toLowerCase())
                                .length;

                            String demandLabel;
                            Color demandColor;
                            if (demandCount > supplyCount) {
                              demandLabel = '🔥 High';
                              demandColor = AppTheme.errorRed;
                            } else if (demandCount == supplyCount) {
                              demandLabel = '⚖️ Normal';
                              demandColor = AppTheme.accentAmber;
                            } else {
                              demandLabel = '📉 Low';
                              demandColor = Colors.grey;
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      color: Colors.grey.shade100, width: 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        Text(emoji,
                                            style:
                                                const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            entry.key,
                                            style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '₹${entry.value.toStringAsFixed(1)}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryGreen,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      demandLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: demandColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info card
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.skyBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppTheme.skyBlue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Prices are fetched from government mandi data and cached for offline use. Tap refresh to get latest rates.',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
