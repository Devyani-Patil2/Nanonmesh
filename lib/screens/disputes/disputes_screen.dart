import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/app_state.dart';

class DisputesScreen extends StatelessWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final disputes = appState.disputes;

    return Scaffold(
      
      appBar: AppBar(
        title: Text('Dispute Center', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showFileDisputeDialog(context),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text('File', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: disputes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No disputes',
                    style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All trades are clean! 🎉',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: disputes.length,
              itemBuilder: (context, index) {
                final dispute = disputes[index];
                return FadeInUp(
                  delay: Duration(milliseconds: index * 100),
                  child: _disputeCard(context, dispute),
                );
              },
            ),
    );
  }

  Widget _disputeCard(BuildContext context, dispute) {
    Color verdictColor;
    IconData verdictIcon;
    switch (dispute.aiVerdict) {
      case 'valid_complaint':
        verdictColor = AppTheme.successGreen;
        verdictIcon = Icons.check_circle;
        break;
      case 'partial_refund':
        verdictColor = AppTheme.warningOrange;
        verdictIcon = Icons.info;
        break;
      case 'false_complaint':
        verdictColor = AppTheme.errorRed;
        verdictIcon = Icons.cancel;
        break;
      default:
        verdictColor = Colors.grey;
        verdictIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: verdictColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(verdictIcon, color: verdictColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dispute #${dispute.id.substring(0, 8)}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Against ${dispute.respondentName}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.statusColor(dispute.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dispute.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.statusColor(dispute.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dispute.description.isNotEmpty)
            Text(
              dispute.description,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 12),
          // AI Analysis
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_outlined, size: 18, color: AppTheme.skyBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Verdict: ${dispute.aiVerdict.replaceAll('_', ' ').toUpperCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: verdictColor,
                        ),
                      ),
                      Text(
                        'Similarity: ${dispute.aiSimilarityScore.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (dispute.refundAmount > 0)
                  Text(
                    'Refund ₹${dispute.refundAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successGreen,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFileDisputeDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final completedTrades = appState.trades.where((t) => t.status == 'completed').toList();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
              const SizedBox(height: 20),
              Text(
                'File a Dispute',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (completedTrades.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No completed trades to dispute',
                    style: GoogleFonts.inter(color: Colors.grey.shade500),
                  ),
                )
              else ...[
                Text(
                  'Select a completed trade:',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                ...completedTrades.take(5).map((trade) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sync, color: AppTheme.primaryGreen),
                    ),
                    title: Text(
                      '${trade.participants.length}-Party Loop',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      trade.participants.map((p) => p.farmerName.split(' ').first).join(' → '),
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      _showDisputeForm(context, trade, descriptionController);
                    },
                  );
                }),
              ],
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
            ],
          ),
        );
      },
    );
  }

  void _showDisputeForm(BuildContext context, trade, TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Describe the Issue',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe what went wrong with the trade...',
                    hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final appState = context.read<AppState>();
                      final respondent = trade.participants.firstWhere(
                        (p) => p.farmerId != appState.currentUser?.id,
                        orElse: () => trade.participants.first,
                      );
                      appState.fileDispute(
                        tradeId: trade.loopId,
                        respondentId: respondent.farmerId,
                        respondentName: respondent.farmerName,
                        description: controller.text.isEmpty
                            ? 'Quality mismatch'
                            : controller.text,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dispute filed! AI is analyzing... 🤖'),
                          backgroundColor: AppTheme.skyBlue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.gavel_rounded, size: 20),
                    label: Text(
                      'Submit Dispute',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
