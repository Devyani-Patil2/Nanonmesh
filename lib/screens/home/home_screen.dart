import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppTheme.heroGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Image.asset(
                                    'assets/images/app_logo.png',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppConstants.appName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Namaste ${user?.name.split(' ').first ?? 'Farmer'}! 🙏',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Notification bell
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                children: [
                                  const Center(
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  if (appState.myTrades
                                      .where((t) => t.status == 'pending')
                                      .isNotEmpty)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.accentAmber,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Credit Balance
                        FadeInUp(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.glassCardDark,
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentAmber
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: AppTheme.accentAmberLight,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Credit Balance',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      Text(
                                        '₹${user?.creditBalance.toStringAsFixed(0) ?? '0'}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CircularPercentIndicator(
                                  radius: 28,
                                  lineWidth: 4,
                                  percent: (user?.reputationScore ?? 0) / 100,
                                  center: Text(
                                    '${(user?.reputationScore ?? 0).toInt()}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  progressColor: AppTheme.accentAmberLight,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  FadeInUp(
                    child: _buildQuickActions(context),
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: _buildStatsRow(context, appState),
                  ),
                  const SizedBox(height: 24),

                  // Active Trade Loops
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: _buildSectionHeader(context, 'Active Trade Loops',
                        Icons.swap_horiz_rounded),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: _buildTradeLoops(context, appState),
                  ),
                  const SizedBox(height: 24),

                  // Recent Listings
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: _buildSectionHeader(context, 'Matching Marketplace',
                        Icons.handshake_rounded),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: _buildRecentListings(context, appState),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.add_circle_outline,
                label: 'New\nListing',
                color: AppTheme.primaryGreen,
                onTap: () => Navigator.pushNamed(context, '/create-listing'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.swap_calls_rounded,
                label: 'My\nTrades',
                color: AppTheme.accentAmber,
                onTap: () => Navigator.pushNamed(context, '/trades'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Credit\nWallet',
                color: AppTheme.skyBlue,
                onTap: () => Navigator.pushNamed(context, '/wallet'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.notification_important_rounded,
                label: 'Urgent\nNeed',
                color: AppTheme.errorRed,
                onTap: () => Navigator.pushNamed(context, '/urgent-requests'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.camera_alt_rounded,
                label: 'AI\nQuality',
                color: AppTheme.primaryGreen,
                onTap: () => Navigator.pushNamed(context, '/quality-check'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.shield_outlined,
                label: 'Dispute\nCenter',
                color: AppTheme.warningOrange,
                onTap: () => Navigator.pushNamed(context, '/disputes'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, AppState appState) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            '${appState.activeListings.length}',
            'Active Listings',
            Icons.list_alt,
            AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            context,
            '${appState.myTrades.where((t) => t.status == 'pending').length}',
            'Pending Trades',
            Icons.pending_actions,
            AppTheme.accentAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            context,
            '${appState.myTrades.where((t) => t.status == 'completed').length}',
            'Completed',
            Icons.check_circle_outline,
            AppTheme.successGreen,
          ),
        ),
      ],
    );
  }

  Widget _statCard(BuildContext context, String value, String label,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildTradeLoops(BuildContext context, AppState appState) {
    final pendingTrades =
        appState.trades.where((t) => t.status == 'pending').toList();

    if (pendingTrades.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(Icons.sync_rounded, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'No active trade loops',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a listing to find matches',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: pendingTrades.take(3).map((trade) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _tradeLoopCard(context, trade, appState),
        );
      }).toList(),
    );
  }

  Widget _tradeLoopCard(BuildContext context, trade, AppState appState) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/trade-detail', arguments: trade),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentAmber.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentAmber.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${trade.participants.length}-Party Loop',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trade.status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Loop visualization
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (int i = 0; i < trade.participants.length; i++) ...[
                  Chip(
                    avatar: Text(AppConstants.productEmojis[
                            trade.participants[i].offerProduct] ??
                        '📦'),
                    label: Text(
                      trade.participants[i].farmerName.split(' ').first,
                      style: GoogleFonts.inter(fontSize: 11),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  if (i < trade.participants.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.arrow_forward,
                          size: 16, color: AppTheme.primaryGreen),
                    ),
                ],
                const Icon(Icons.replay,
                    size: 16, color: AppTheme.primaryGreen),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.touch_app,
                    size: 14, color: AppTheme.primaryGreen),
                const SizedBox(width: 4),
                Text(
                  'Tap to view details & confirm',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentListings(BuildContext context, AppState appState) {
    final listings = appState.matchingListings.take(4).toList();

    if (listings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.handshake_rounded,
                size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              appState.myListings.isEmpty
                  ? 'Create a listing to find matches'
                  : 'No matching listings yet',
              style:
                  GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              appState.myListings.isEmpty
                  ? 'Post what you offer & want to see matches here'
                  : 'Other farmers will appear when they match your needs',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return Column(
      children: listings.map((listing) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/listing-detail',
                arguments: listing),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        AppConstants.productEmojis[listing.productType] ?? '📦',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.productType,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${listing.quantity} ${listing.unit} • ${listing.farmerName}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '✓ Match',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Wants ${listing.desiredProduct}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
