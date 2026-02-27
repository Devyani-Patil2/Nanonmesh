import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../config/theme.dart';
import '../../providers/app_state.dart';
import '../../services/supply_chain_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.heroGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'F',
                              style: GoogleFonts.outfit(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.name ?? 'Farmer',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${user?.village ?? ''} • ${user?.phone ?? ''}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Phone Verified',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reputation Card
                  FadeInUp(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                              const Icon(
                                Icons.star_rounded,
                                color: AppTheme.accentAmber,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reputation Score',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CircularPercentIndicator(
                                radius: 42,
                                lineWidth: 6,
                                percent: (user?.reputationScore ?? 0) / 100,
                                center: Text(
                                  '${(user?.reputationScore ?? 0).toInt()}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                progressColor: AppTheme.primaryGreen,
                                backgroundColor: Colors.grey.shade200,
                                circularStrokeCap: CircularStrokeCap.round,
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  children: [
                                    _reputationBar(
                                      'Trade Completion',
                                      0.85,
                                      AppTheme.successGreen,
                                    ),
                                    const SizedBox(height: 8),
                                    _reputationBar(
                                      'Quality Score',
                                      0.78,
                                      AppTheme.accentAmber,
                                    ),
                                    const SizedBox(height: 8),
                                    _reputationBar(
                                      'Dispute Record',
                                      0.92,
                                      AppTheme.skyBlue,
                                    ),
                                    const SizedBox(height: 8),
                                    _reputationBar(
                                      'Community Rating',
                                      0.70,
                                      AppTheme.warmBrown,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: Row(
                      children: [
                        Expanded(
                          child: _statBox(
                            context,
                            '${user?.totalTrades ?? 0}',
                            'Total Trades',
                            Icons.sync_rounded,
                            AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statBox(
                            context,
                            '${user?.disputeCount ?? 0}',
                            'Disputes',
                            Icons.gavel_rounded,
                            AppTheme.warningOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statBox(
                            context,
                            '₹${user?.creditBalance.toStringAsFixed(0) ?? '0'}',
                            'Credits',
                            Icons.account_balance_wallet,
                            AppTheme.skyBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Language Toggle
                  FadeInUp(
                    delay: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.skyBlue.withValues(alpha: 0.1),
                            AppTheme.primaryGreen.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.translate,
                              color: AppTheme.skyBlue, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Language / भाषा',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  appState.locale.languageCode == 'en'
                                      ? 'English'
                                      : 'हिन्दी',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => appState.toggleLocale(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              appState.locale.languageCode == 'en'
                                  ? 'हिन्दी में बदलें'
                                  : 'Switch to English',
                              style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menu Items
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _menuItem(
                            context,
                            Icons.list_alt_rounded,
                            'My Listings',
                            () {
                              Navigator.pushNamed(context, '/listings');
                            },
                          ),
                          _divider(context),
                          _menuItem(
                            context,
                            Icons.swap_calls_rounded,
                            'Trade History',
                            () {
                              Navigator.pushNamed(context, '/trades');
                            },
                          ),
                          _divider(context),
                          _menuItem(
                            context,
                            Icons.account_balance_wallet_outlined,
                            'Wallet',
                            () {
                              Navigator.pushNamed(context, '/wallet');
                            },
                          ),
                          _divider(context),
                          _menuItem(
                            context,
                            Icons.history_rounded,
                            'Credit History',
                            () {
                              Navigator.pushNamed(context, '/credit-history');
                            },
                          ),
                          _divider(context),
                          _menuItem(
                            context,
                            Icons.shield_outlined,
                            'Disputes',
                            () {
                              Navigator.pushNamed(context, '/disputes');
                            },
                          ),
                          _menuItem(
                            context,
                            Icons.camera_alt_outlined,
                            'Quality Check',
                            () {
                              Navigator.pushNamed(context, '/quality-check');
                            },
                          ),
                          _divider(context),
                          _menuItem(
                            context,
                            Icons.bar_chart_rounded,
                            'Mandi Prices',
                            () {
                              Navigator.pushNamed(context, '/price-discovery');
                            },
                          ),
                          _divider(context),
                          _menuItem(
                            context,
                            Icons.upload_file_rounded,
                            'Export Data for FPO',
                            () async {
                              if (user == null) return;
                              final data = await SupplyChainService.instance
                                  .generateFPODataPackage(
                                user: user,
                                trades: appState.trades,
                                listings: appState.listings,
                                transactions: appState.transactions,
                              );
                              await SupplyChainService.instance.shareReport(
                                'Nanonmesh FPO Report - ${user.name}',
                                data,
                              );
                            },
                          ),
                          _divider(context),
                          // Dark Mode Toggle
                          ListTile(
                            leading: Icon(
                              appState.isDarkMode
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: AppTheme.primaryGreen,
                              size: 22,
                            ),
                            title: Text(
                              'Dark Mode',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Switch(
                              value: appState.isDarkMode,
                              onChanged: (_) => appState.toggleTheme(),
                              activeTrackColor:
                                  AppTheme.primaryGreen.withValues(alpha: 0.5),
                              thumbColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppTheme.primaryGreen;
                                }
                                return Colors.grey;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign Out
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await appState.signOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: Text(
                          'Sign Out',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                          side: const BorderSide(color: AppTheme.errorRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
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

  Widget _reputationBar(String label, double value, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          flex: 4,
          child: LinearPercentIndicator(
            lineHeight: 6,
            percent: value,
            progressColor: color,
            backgroundColor: Colors.grey.shade200,
            padding: EdgeInsets.zero,
            barRadius: const Radius.circular(3),
          ),
        ),
      ],
    );
  }

  Widget _statBox(BuildContext context, String value, String label,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.primaryGreen, size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.3) ??
            Colors.grey.shade400,
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
    );
  }
}
