import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/app_state.dart';

class UrgentRequestsScreen extends StatefulWidget {
  const UrgentRequestsScreen({super.key});

  @override
  State<UrgentRequestsScreen> createState() => _UrgentRequestsScreenState();
}

class _UrgentRequestsScreenState extends State<UrgentRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      
      appBar: AppBar(
        title: Text('Urgent Requests',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: '🆘 Open Requests'),
            Tab(text: '📋 My Requests'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostRequestSheet(context),
        icon: const Icon(Icons.add_alert_rounded),
        label: Text('Post Request',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: All open requests (from other farmers)
          _buildOpenRequestsList(appState),
          // Tab 2: My requests
          _buildMyRequestsList(appState),
        ],
      ),
    );
  }

  Widget _buildOpenRequestsList(AppState appState) {
    final requests = appState.openUrgentRequests
        .where((r) => r.requesterId != appState.currentUser?.id)
        .toList();

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No urgent requests right now',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 6),
            Text(
              'Help a fellow farmer when requests appear!',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 100),
          child: _requestCard(context, req, appState, canFulfill: true),
        );
      },
    );
  }

  Widget _buildMyRequestsList(AppState appState) {
    final requests = appState.myUrgentRequests;

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No requests posted yet',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 6),
            Text(
              'Post a request when you urgently need something',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 100),
          child: _requestCard(context, req, appState, canFulfill: false),
        );
      },
    );
  }

  Widget _requestCard(
    BuildContext context,
    req,
    AppState appState, {
    required bool canFulfill,
  }) {
    final emoji = AppConstants.productEmojis[req.productNeeded] ?? '📦';
    final isOpen = req.status == 'open';
    final urgencyColor = req.urgencyLevel == 'high'
        ? AppTheme.errorRed
        : req.urgencyLevel == 'medium'
            ? AppTheme.warningOrange
            : AppTheme.accentAmber;

    final timeDiff = DateTime.now().difference(req.createdAt);
    String timeAgo;
    if (timeDiff.inDays > 0) {
      timeAgo = '${timeDiff.inDays}d ago';
    } else if (timeDiff.inHours > 0) {
      timeAgo = '${timeDiff.inHours}h ago';
    } else {
      timeAgo = '${timeDiff.inMinutes}m ago';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isOpen
            ? Border.all(color: urgencyColor.withValues(alpha: 0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isOpen
                ? urgencyColor.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.productNeeded,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${req.quantity.toStringAsFixed(0)} ${req.unit} • ${req.requesterName}',
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (req.urgencyLevel == 'high')
                          Icon(Icons.warning_amber_rounded,
                              size: 12, color: urgencyColor),
                        if (req.urgencyLevel == 'high') const SizedBox(width: 3),
                        Text(
                          req.urgencyLevel.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: urgencyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Description
          if (req.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              req.description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 12),

          // Credit cost + action
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '₹${req.creditCost.toStringAsFixed(0)} credits',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      req.requesterVillage,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isOpen && canFulfill)
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmFulfill(context, req, appState),
                    icon: const Icon(Icons.handshake_rounded, size: 16),
                    label: Text('Fulfill',
                        style: GoogleFonts.outfit(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              if (isOpen && !canFulfill)
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () {
                      appState.cancelUrgentRequest(req.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request cancelled'),
                          backgroundColor: AppTheme.warningOrange,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: const BorderSide(color: AppTheme.errorRed),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              if (!isOpen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.statusColor(req.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    req.status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.statusColor(req.status),
                    ),
                  ),
                ),
            ],
          ),

          // Show fulfiller info if completed
          if (req.status == 'completed' && req.fulfillerName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.successGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 16, color: AppTheme.successGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Fulfilled by ${req.fulfillerName}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmFulfill(BuildContext context, req, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.handshake_rounded, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text('Fulfill Request?',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${req.requesterName} needs:',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    AppConstants.productEmojis[req.productNeeded] ?? '📦',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${req.productNeeded}',
                        style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${req.quantity.toStringAsFixed(0)} ${req.unit}',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.successGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_upward_rounded,
                      color: AppTheme.successGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will earn ₹${req.creditCost.toStringAsFixed(0)} credits',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              appState.fulfillUrgentRequest(req.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Request fulfilled! You earned ₹${req.creditCost.toStringAsFixed(0)} credits 🎉'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm & Earn',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showPostRequestSheet(BuildContext context) {
    String? selectedProduct;
    final qtyController = TextEditingController();
    final descController = TextEditingController();
    String selectedUnit = 'kg';
    String urgency = 'high';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Calculate credit cost based on mandi price
            double creditCost = 0;
            if (selectedProduct != null && qtyController.text.isNotEmpty) {
              final qty = double.tryParse(qtyController.text) ?? 0;
              final basePrice =
                  AppConstants.mandiPrices[selectedProduct] ?? 50.0;
              // Urgent requests cost 10% of valuation as credit fee
              creditCost = basePrice * qty * 0.10;
              if (creditCost < 50) creditCost = 50; // Minimum 50 credits
            }

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '🆘 Post Urgent Request',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Another farmer will provide what you need and earn credits',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 20),

                      // Product selection
                      Text('What do you need?',
                          style: GoogleFonts.outfit(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            AppConstants.productCategories.map((product) {
                          final isSelected = selectedProduct == product;
                          return GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedProduct = product),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.errorRed
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.errorRed
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                '${AppConstants.productEmojis[product] ?? "📦"} $product',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Quantity + unit
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: qtyController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Quantity',
                                prefixIcon: Icon(Icons.scale,
                                    color: Colors.grey.shade400, size: 20),
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedUnit,
                              decoration: const InputDecoration(),
                              items: AppConstants.units
                                  .map((u) => DropdownMenuItem(
                                      value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) =>
                                  setModalState(() => selectedUnit = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Why do you need this urgently?',
                          hintStyle:
                              GoogleFonts.inter(color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Urgency level
                      Row(
                        children: ['high', 'medium', 'low'].map((level) {
                          final isSelected = urgency == level;
                          final color = level == 'high'
                              ? AppTheme.errorRed
                              : level == 'medium'
                                  ? AppTheme.warningOrange
                                  : AppTheme.accentAmber;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () =>
                                    setModalState(() => urgency = level),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? color : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: isSelected
                                            ? color
                                            : Colors.grey.shade300),
                                  ),
                                  child: Center(
                                    child: Text(
                                      level.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Credit cost display
                      if (creditCost > 0)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                    AppTheme.errorRed.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: AppTheme.errorRed, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'This will cost you',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      '₹${creditCost.toStringAsFixed(0)} credits',
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.errorRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'The farmer who\nfulfills will earn\nthese credits',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                    height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: selectedProduct != null &&
                                  qtyController.text.isNotEmpty &&
                                  creditCost > 0
                              ? () {
                                  final appState = context.read<AppState>();
                                  if ((appState.currentUser?.creditBalance ??
                                          0) <
                                      creditCost) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Not enough credits! ❌'),
                                        backgroundColor: AppTheme.errorRed,
                                      ),
                                    );
                                    return;
                                  }
                                  appState.postUrgentRequest(
                                    productNeeded: selectedProduct!,
                                    quantity: double.parse(qtyController.text),
                                    unit: selectedUnit,
                                    creditCost: creditCost,
                                    urgencyLevel: urgency,
                                    description: descController.text,
                                  );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Request posted! Waiting for a farmer to fulfill 🙏'),
                                      backgroundColor: AppTheme.primaryGreen,
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Post Urgent Request 🆘',
                            style: GoogleFonts.outfit(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
