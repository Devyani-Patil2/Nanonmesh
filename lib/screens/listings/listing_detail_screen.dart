import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/listing_model.dart';
import '../../providers/app_state.dart';

class ListingDetailScreen extends StatelessWidget {
  final ListingModel listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final basePrice = AppConstants.mandiPrices[listing.productType] ?? 50.0;
    final emoji = AppConstants.productEmojis[listing.productType] ?? '📦';
    final isOwnListing = listing.farmerId == appState.currentUser?.id;

    // Find the farmer's reputation
    final farmer =
        appState.users.where((u) => u.id == listing.farmerId).toList();
    final reputation = farmer.isNotEmpty ? farmer.first.reputationScore : 75.0;

    // Find user's listing to trade with
    double? fairnessPercent;
    ListingModel? myMatchingListing;
    ListingModel? myBestListing; // fallback: any active listing
    if (!isOwnListing && appState.currentUser != null) {
      final myListings =
          appState.myListings.where((l) => l.status == 'active').toList();
      // First try: exact product match
      for (final ml in myListings) {
        if (ml.desiredProduct == listing.productType ||
            ml.productType == listing.desiredProduct) {
          myMatchingListing = ml;
          fairnessPercent = appState.getFairnessPercent(
            ml.valuationScore,
            listing.valuationScore,
          );
          break;
        }
      }
      // Fallback: use first active listing for trading
      if (myMatchingListing == null && myListings.isNotEmpty) {
        myBestListing = myListings.first;
        fairnessPercent = appState.getFairnessPercent(
          myBestListing.valuationScore,
          listing.valuationScore,
        );
      }
    }
    // The listing to use for trading (match preferred, fallback otherwise)
    final myTradeListing = myMatchingListing ?? myBestListing;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(listing.productType,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Hero Card
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 12),
                    Text(
                      listing.productType,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${listing.quantity} ${listing.unit}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '₹${listing.valuationScore.toStringAsFixed(0)} estimated value',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Farmer Info + Reputation
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: _infoCard(
                title: 'Farmer',
                children: [
                  _infoRow(Icons.person_outline, 'Name', listing.farmerName),
                  _infoRow(Icons.location_on_outlined, 'Village',
                      listing.farmerVillage),
                  _infoRow(Icons.verified_outlined, 'Quality',
                      listing.qualityExpectation),
                  _infoRow(Icons.star_rounded, 'Reputation',
                      '${reputation.toStringAsFixed(0)}/100'),
                  // Reputation bar
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: reputation / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        reputation >= 70
                            ? AppTheme.successGreen
                            : reputation >= 40
                                ? AppTheme.accentAmber
                                : AppTheme.errorRed,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Wants
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.accentAmber.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          AppConstants.productEmojis[listing.desiredProduct] ??
                              '🎯',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wants in Exchange',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            listing.desiredProduct,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Fairness Pricing Card (only for others' listings)
            if (!isOwnListing &&
                fairnessPercent != null &&
                myMatchingListing != null)
              FadeInUp(
                delay: const Duration(milliseconds: 250),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color:
                        _fairnessColor(fairnessPercent).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _fairnessColor(fairnessPercent)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.balance_rounded,
                              color: _fairnessColor(fairnessPercent), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Fairness Score',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _fairnessColor(fairnessPercent)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${fairnessPercent.toStringAsFixed(0)}%',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _fairnessColor(fairnessPercent),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Value comparison
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text('Your Offer',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.grey.shade600)),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${myMatchingListing.valuationScore.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(myMatchingListing.productType,
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          Icon(Icons.swap_horiz_rounded,
                              color: _fairnessColor(fairnessPercent)),
                          Expanded(
                            child: Column(
                              children: [
                                Text('Their Offer',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.grey.shade600)),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${listing.valuationScore.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(listing.productType,
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Fairness bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fairnessPercent / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _fairnessColor(fairnessPercent)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _fairnessLabel(fairnessPercent),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _fairnessColor(fairnessPercent),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!isOwnListing && fairnessPercent != null)
              const SizedBox(height: 14),

            // Valuation Breakdown
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: _infoCard(
                title: 'Valuation Breakdown',
                children: [
                  _infoRow(Icons.store_outlined, 'Mandi Price',
                      '₹${basePrice.toStringAsFixed(0)} per ${listing.unit}'),
                  _infoRow(Icons.scale_outlined, 'Quantity',
                      '${listing.quantity} ${listing.unit}'),
                  _infoRow(Icons.star_outline, 'Quality Factor',
                      listing.qualityExpectation),
                  const Divider(),
                  _infoRow(Icons.calculate_outlined, 'Total Value',
                      '₹${listing.valuationScore.toStringAsFixed(0)}'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CONFIRM TRADE BUTTON (for ALL other farmers' listings)
            if (!isOwnListing && myTradeListing != null)
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _showConfirmDialog(
                      context,
                      appState,
                      myTradeListing,
                      listing,
                      fairnessPercent ?? 0,
                    ),
                    icon: const Icon(Icons.handshake_rounded,
                        color: Colors.white),
                    label: Text(
                      'Accept & Barter',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            // Show message if user has no listings to trade
            if (!isOwnListing && myTradeListing == null)
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.accentAmber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.accentAmber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Create your own listing first to trade with this farmer!',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  /// Show fairness confirmation dialog before accepting trade
  void _showConfirmDialog(
    BuildContext context,
    AppState appState,
    ListingModel myListing,
    ListingModel theirListing,
    double fairness,
  ) {
    final valueDiff =
        (myListing.valuationScore - theirListing.valuationScore).abs();
    final isInMyFavor = myListing.valuationScore > theirListing.valuationScore;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.balance_rounded, color: _fairnessColor(fairness)),
            const SizedBox(width: 8),
            Text('Confirm Trade',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trade summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('You give:',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const Spacer(),
                      Text(
                        '${myListing.productType} (₹${myListing.valuationScore.toStringAsFixed(0)})',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.swap_vert_rounded,
                      color: AppTheme.primaryGreen),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('You get:',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const Spacer(),
                      Text(
                        '${theirListing.productType} (₹${theirListing.valuationScore.toStringAsFixed(0)})',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Fairness indicator
            Row(
              children: [
                Text('Fairness: ', style: GoogleFonts.inter(fontSize: 13)),
                Text(
                  '${fairness.toStringAsFixed(0)}%',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _fairnessColor(fairness),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (valueDiff > 0)
              Text(
                isInMyFavor
                    ? 'Your offer is ₹${valueDiff.toStringAsFixed(0)} more valuable'
                    : 'Their offer is ₹${valueDiff.toStringAsFixed(0)} more valuable',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            const SizedBox(height: 12),

            Text(
              'Are you OK with this trade?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              // Create actual trade via AppState
              appState.acceptDirectTrade(myListing, theirListing);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '🤝 Trade created with ${theirListing.farmerName}! Check Active Trades',
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: AppTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.handshake_rounded,
                size: 18, color: Colors.white),
            label: Text(
              'Confirm Trade',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Color _fairnessColor(double percent) {
    if (percent >= 80) return AppTheme.successGreen;
    if (percent >= 50) return AppTheme.accentAmber;
    return AppTheme.errorRed;
  }

  String _fairnessLabel(double percent) {
    if (percent >= 90) return '✅ Excellent — Very fair exchange';
    if (percent >= 70) return '👍 Good — Reasonable trade';
    if (percent >= 50) return '⚠️ Moderate — Some value difference';
    return '🔴 Low fairness — Large value gap';
  }

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
