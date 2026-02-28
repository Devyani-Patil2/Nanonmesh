import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math' as math;
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/app_state.dart';
import '../../models/trade_model.dart';
import '../../widgets/translated_text.dart';
import '../../models/evidence_model.dart';

class TradeDetailScreen extends StatelessWidget {
  final TradeModel trade;
  const TradeDetailScreen({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUserId = appState.currentUser?.id;
    final isDark = appState.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      appBar: AppBar(
        title: TranslatedText(
          'Trade Loop',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (trade.status == 'confirmed' || trade.status == 'executing')
            IconButton(
              icon: const Icon(Icons.report_problem_outlined),
              tooltip: 'File Dispute',
              onPressed: () => Navigator.pushNamed(context, '/disputes'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loop visualization header
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    TranslatedText(
                      '${trade.participants.length}-Party Trade Loop',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.statusColor(
                          trade.status,
                        ).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TranslatedText(
                        trade.status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Enhanced loop diagram
                    SizedBox(
                      height: 220,
                      width: 220,
                      child: CustomPaint(
                        size: const Size(220, 220),
                        painter: _EnhancedLoopPainter(trade.participants),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status FSM Stepper
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    'Trade Progress',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFullStepper(trade.status, isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Participants
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: TranslatedText(
                'Participants',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : null,
                ),
              ),
            ),
            const SizedBox(height: 12),

            ...trade.participants.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final isCurrentUser = p.farmerId == currentUserId;

              return FadeInUp(
                delay: Duration(milliseconds: 250 + i * 100),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? AppTheme.primaryGreen.withValues(
                            alpha: isDark ? 0.15 : 0.05,
                          )
                        : (isDark ? AppTheme.cardDark : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: isCurrentUser
                        ? Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                            width: 2,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.04,
                        ),
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: TranslatedText(
                                p.farmerName[0],
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    TranslatedText(
                                      p.farmerName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : null,
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: TranslatedText(
                                          'YOU',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                TranslatedText(
                                  '₹${p.valuationAmount.toStringAsFixed(0)} value',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Confirmation status badge
                          _statusBadge(p.confirmationStatus),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Product exchange info
                      Row(
                        children: [
                          _chipInfo(
                            AppConstants.productEmojis[p.offerProduct] ?? '📦',
                            '${p.offerProduct} (${p.offerQuantity.toStringAsFixed(0)} ${p.unit})',
                            isDark,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          _chipInfo(
                            AppConstants.productEmojis[p.wantProduct] ?? '🎯',
                            p.wantProduct,
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Credit Movements section
            if (trade.creditMovements.isNotEmpty) ...[
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      'Credit Settlements',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...trade.creditMovements.map(
                      (cm) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.swap_horiz_rounded,
                                color: AppTheme.primaryGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TranslatedText(
                                cm.description,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            TranslatedText(
                              '₹${cm.amount.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            if (trade.status == 'pending') ...[
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          appState.confirmTrade(
                            trade.loopId,
                            currentUserId ?? '',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: TranslatedText('Trade confirmed! ✅'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: TranslatedText(
                          'Confirm Trade',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          appState.declineTrade(
                            trade.loopId,
                            currentUserId ?? '',
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: TranslatedText(
                          'Decline',
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
                  ],
                ),
              ),
            ],

            if (trade.status == 'confirmed' ||
                trade.status == 'executing' ||
                trade.status == 'disputed') ...[
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Builder(
                  builder: (ctx) {
                    // Load evidence from Firestore (other phone's uploads)
                    appState.loadEvidenceFromFirestore(trade.loopId);

                    // Find what current user is SENDING and RECEIVING
                    final myParticipant = trade.participants.firstWhere(
                      (p) => p.farmerId == currentUserId,
                      orElse: () => trade.participants.first,
                    );
                    final otherParticipant = trade.participants.firstWhere(
                      (p) => p.farmerId != currentUserId,
                      orElse: () => trade.participants.last,
                    );

                    final mySendingProduct = myParticipant.offerProduct;
                    final myReceivingProduct = otherParticipant.offerProduct;

                    // My evidence
                    final sendEvidence = appState.getMyEvidence(
                      trade.loopId,
                      currentUserId ?? '',
                      'sending',
                    );
                    final recvEvidence = appState.getMyEvidence(
                      trade.loopId,
                      currentUserId ?? '',
                      'receiving',
                    );

                    // All evidence
                    final allEvidence =
                        appState.getEvidenceForTrade(trade.loopId);
                    final allSending =
                        allEvidence.where((e) => e.role == 'sending').toList();
                    final bothSentUploaded =
                        allSending.length >= trade.participants.length;
                    final allDone =
                        allEvidence.length >= trade.participants.length * 2;

                    return Column(
                      children: [
                        // ══════ PHASE 1: SENDING PHOTO ══════
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppTheme.skyBlue.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: AppTheme.skyBlue
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text('STEP 1',
                                      style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.skyBlue)),
                                ),
                                const SizedBox(width: 8),
                                Text('Upload Sending Photo',
                                    style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                              ]),
                              const SizedBox(height: 6),
                              Text(
                                  'Take a photo of $mySendingProduct before you hand it over',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                              const SizedBox(height: 10),
                              _evidenceSection(
                                ctx: ctx,
                                title: '📤 Sending: $mySendingProduct',
                                subtitle: 'Your product before delivery',
                                evidence: sendEvidence,
                                buttonColor: AppTheme.skyBlue,
                                onUpload: () => _uploadPhoto(
                                  ctx,
                                  trade.loopId,
                                  currentUserId ?? '',
                                  'sending',
                                  mySendingProduct,
                                  appState,
                                ),
                              ),
                              if (!bothSentUploaded &&
                                  sendEvidence != null) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Icon(Icons.hourglass_top_rounded,
                                      color: AppTheme.accentAmber, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                      'Waiting for other farmer to upload their sending photo...',
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppTheme.accentAmber,
                                          fontWeight: FontWeight.w500)),
                                ]),
                              ],
                              if (bothSentUploaded) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppTheme.successGreen, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Both sending photos uploaded ✅',
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppTheme.successGreen,
                                          fontWeight: FontWeight.w500)),
                                ]),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ══════ PHASE 2: RECEIVING PHOTO (unlocked after both send) ══════
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bothSentUploaded
                                ? Colors.white
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: bothSentUploaded
                                    ? AppTheme.accentAmber
                                        .withValues(alpha: 0.3)
                                    : Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: bothSentUploaded
                                          ? AppTheme.accentAmber
                                              .withValues(alpha: 0.15)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: TranslatedText('STEP 2',
                                      style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: bothSentUploaded
                                              ? AppTheme.accentAmber
                                              : Colors.grey)),
                                ),
                                const SizedBox(width: 8),
                                Text('Upload Receiving Photo',
                                    style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: bothSentUploaded
                                            ? null
                                            : Colors.grey)),
                              ]),
                              const SizedBox(height: 6),
                              if (!bothSentUploaded)
                                Text(
                                    '🔒 Unlocks after both farmers upload their sending photos',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: Colors.grey))
                              else ...[
                                TranslatedText(
                                    'Take a photo of $myReceivingProduct that you received',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey.shade600)),
                                const SizedBox(height: 10),
                                _evidenceSection(
                                  ctx: ctx,
                                  title: '📥 Receiving: $myReceivingProduct',
                                  subtitle:
                                      'Product you received from other farmer',
                                  evidence: recvEvidence,
                                  buttonColor: AppTheme.accentAmber,
                                  onUpload: () => _uploadPhoto(
                                    ctx,
                                    trade.loopId,
                                    currentUserId ?? '',
                                    'receiving',
                                    myReceivingProduct,
                                    appState,
                                  ),
                                ),
                                if (!allDone && recvEvidence != null) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    const Icon(Icons.hourglass_top_rounded,
                                        color: AppTheme.accentAmber, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                        'Waiting for other farmer to upload receiving photo...',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppTheme.accentAmber,
                                            fontWeight: FontWeight.w500)),
                                  ]),
                                ],
                              ],
                            ],
                          ),
                        ),

                        // ══════ RESULT: Compare & Complete or Dispute ══════
                        if (allDone) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: trade.status == 'disputed'
                                  ? AppTheme.errorRed.withValues(alpha: 0.08)
                                  : AppTheme.successGreen
                                      .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: trade.status == 'disputed'
                                      ? AppTheme.errorRed.withValues(alpha: 0.3)
                                      : AppTheme.successGreen
                                          .withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                        trade.status == 'disputed'
                                            ? Icons.warning_rounded
                                            : Icons.verified_rounded,
                                        color: trade.status == 'disputed'
                                            ? AppTheme.errorRed
                                            : AppTheme.successGreen,
                                        size: 24),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TranslatedText(
                                        trade.status == 'disputed'
                                            ? 'Mismatch detected! Dispute filed automatically.'
                                            : 'AI verification passed! Photos match.',
                                        style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: trade.status == 'disputed'
                                                ? AppTheme.errorRed
                                                : AppTheme.successGreen),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _conditionColor(
                                                sendEvidence!.conditionTag)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: TranslatedText(
                                        sendEvidence.conditionTag,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _conditionColor(
                                              sendEvidence.conditionTag),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Overall Score
                                Row(
                                  children: [
                                    TranslatedText('Overall Score: ',
                                        style: GoogleFonts.inter(fontSize: 13)),
                                    TranslatedText(
                                      '${sendEvidence.aiQualityScore.toStringAsFixed(0)}%',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Score bars
                                _scoreBar(
                                    'Freshness', sendEvidence.freshnessScore),
                                const SizedBox(height: 6),
                                _scoreBar(
                                    'Damage Check', sendEvidence.damageScore),
                                const SizedBox(height: 6),
                                _scoreBar(
                                    'Color Quality', sendEvidence.colorScore),
                                const SizedBox(height: 6),
                                _scoreBar(
                                    'Size Consistency', sendEvidence.sizeScore),
                                if (trade.status != 'disputed' &&
                                    trade.status != 'completed') ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        appState.completeTrade(trade.loopId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: const TranslatedText(
                                                    'Trade completed! 🎉',
                                                    style: TextStyle()),
                                                backgroundColor:
                                                    AppTheme.successGreen),
                                          );
                                          Navigator.pop(context);
                                        }
                                      },
                                      icon: const Icon(
                                          Icons.check_circle_rounded),
                                      label: TranslatedText('Complete Trade',
                                          style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700)),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.successGreen,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14))),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // Upload status
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (sendEvidence != null && bothSentUploaded)
                                ? AppTheme.successGreen.withValues(alpha: 0.08)
                                : AppTheme.accentAmber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                (sendEvidence != null && bothSentUploaded)
                                    ? Icons.check_circle_rounded
                                    : Icons.hourglass_top_rounded,
                                color:
                                    (sendEvidence != null && bothSentUploaded)
                                        ? AppTheme.successGreen
                                        : AppTheme.accentAmber,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TranslatedText(
                                  sendEvidence == null
                                      ? 'Upload your evidence to proceed'
                                      : bothSentUploaded
                                          ? 'Both parties uploaded. AI comparison complete!'
                                          : 'Waiting for other party to upload evidence...',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: (sendEvidence != null &&
                                            bothSentUploaded)
                                        ? AppTheme.successGreen
                                        : AppTheme.accentAmber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (trade.status == 'disputed') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/disputes'),
                              icon: const Icon(Icons.gavel_rounded),
                              label: TranslatedText('View Disputes',
                                  style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.errorRed,
                                side:
                                    const BorderSide(color: AppTheme.errorRed),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],

            if (trade.status == 'completed') ...[
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.successGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.successGreen,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TranslatedText(
                              'Trade Completed!',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.successGreen,
                              ),
                            ),
                            TranslatedText(
                              'Credits have been settled for all participants',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.successGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Handle camera upload for a specific role (sending/receiving)
  Future<void> _uploadPhoto(
    BuildContext ctx,
    String tradeId,
    String farmerId,
    String role,
    String productName,
    AppState appState,
  ) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo != null && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Analyzing $productName with AI... 📸',
              style: GoogleFonts.inter()),
          backgroundColor: AppTheme.skyBlue,
        ),
      );

      final bytes = await photo.readAsBytes();
      await appState.uploadEvidence(
        tradeId: tradeId,
        farmerId: farmerId,
        role: role,
        productName: productName,
        imageBytes: bytes,
        photoUrl: photo.path,
      );

      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('$productName evidence ($role) uploaded & saved! ✅',
                style: GoogleFonts.inter()),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  /// Reusable evidence section: upload button + AI report card
  Widget _evidenceSection({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required EvidenceModel? evidence,
    required Color buttonColor,
    required VoidCallback onUpload,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle,
            style:
                GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        if (evidence == null)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: Text('Upload Photo',
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.smart_toy_rounded,
                        color: AppTheme.primaryGreen, size: 18),
                    const SizedBox(width: 6),
                    Text('AI Report',
                        style: GoogleFonts.outfit(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: _conditionColor(evidence.conditionTag)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(evidence.conditionTag,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _conditionColor(evidence.conditionTag))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Text('Score: ', style: GoogleFonts.inter(fontSize: 12)),
                  Text('${evidence.aiQualityScore.toStringAsFixed(0)}%',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen)),
                ]),
                const SizedBox(height: 8),
                _scoreBar('Freshness', evidence.freshnessScore),
                const SizedBox(height: 4),
                _scoreBar('Damage', evidence.damageScore),
                const SizedBox(height: 4),
                _scoreBar('Color', evidence.colorScore),
                const SizedBox(height: 4),
                _scoreBar('Size', evidence.sizeScore),
              ],
            ),
          ),
      ],
    );
  }

  Widget _scoreBar(String label, double score) {
    final color = score >= 70
        ? AppTheme.successGreen
        : score >= 45
            ? AppTheme.accentAmber
            : AppTheme.errorRed;
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: TranslatedText(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TranslatedText(
          '${score.toStringAsFixed(0)}%',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _conditionColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'excellent':
        return AppTheme.successGreen;
      case 'good':
        return const Color(0xFF4CAF50);
      case 'average':
        return AppTheme.accentAmber;
      case 'poor':
        return AppTheme.errorRed;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFullStepper(String status, bool isDark) {
    final steps = [
      ('Pending', 'pending', Icons.hourglass_top_rounded),
      ('Confirmed', 'confirmed', Icons.check_circle_outline),
      ('Executing', 'executing', Icons.sync_rounded),
      ('Completed', 'completed', Icons.verified_rounded),
    ];

    final currentIdx = steps.indexWhere((s) => s.$2 == status);

    return Container(
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
        children: steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final step = entry.value;
          final isActive = idx <= currentIdx && currentIdx >= 0;
          final isCurrent = idx == currentIdx;
          final statusColor = isActive
              ? AppTheme.primaryGreen
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300);

          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                          : (isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100),
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: AppTheme.primaryGreen, width: 2)
                          : null,
                    ),
                    child: Icon(step.$3, color: statusColor, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TranslatedText(
                      step.$1,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400),
                      ),
                    ),
                  ),
                  if (isActive && !isCurrent)
                    const Icon(
                      Icons.check_rounded,
                      color: AppTheme.primaryGreen,
                      size: 18,
                    )
                  else if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TranslatedText(
                        'CURRENT',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              if (idx < steps.length - 1)
                Container(
                  margin: const EdgeInsets.only(left: 17),
                  width: 2,
                  height: 20,
                  color: idx < currentIdx
                      ? AppTheme.primaryGreen
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = AppTheme.statusColor(status);
    final icon = status == 'confirmed'
        ? Icons.check_circle_rounded
        : status == 'declined'
            ? Icons.cancel_rounded
            : Icons.pending_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        TranslatedText(
          status.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _chipInfo(String emoji, String label, bool isDark) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TranslatedText(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Flexible(
              child: TranslatedText(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade300 : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced loop diagram with participant names, product labels, and arrows
class _EnhancedLoopPainter extends CustomPainter {
  final List<TradeParticipant> participants;
  _EnhancedLoopPainter(this.participants);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;
    final n = participants.length;

    // Calculate node positions
    final positions = <Offset>[];
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / n);
      positions.add(
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
      );
    }

    // Draw edges with arrows
    for (int i = 0; i < n; i++) {
      final from = positions[i];
      final to = positions[(i + 1) % n];

      // Connection line
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(from, to, linePaint);

      // Arrow head
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      final unitX = dx / len;
      final unitY = dy / len;

      final arrowTip = Offset(
        from.dx + unitX * (len - 24),
        from.dy + unitY * (len - 24),
      );
      final arrowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(arrowTip.dx, arrowTip.dy)
        ..lineTo(
          arrowTip.dx - 7 * unitX + 5 * unitY,
          arrowTip.dy - 7 * unitY - 5 * unitX,
        )
        ..moveTo(arrowTip.dx, arrowTip.dy)
        ..lineTo(
          arrowTip.dx - 7 * unitX - 5 * unitY,
          arrowTip.dy - 7 * unitY + 5 * unitX,
        );
      canvas.drawPath(path, arrowPaint);

      // Product label on edge
      final midX = (from.dx + to.dx) / 2;
      final midY = (from.dy + to.dy) / 2;
      final labelOffset = Offset(midX + 10 * unitY, midY - 10 * unitX);

      final productEmoji =
          AppConstants.productEmojis[participants[i].offerProduct] ?? '📦';
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$productEmoji ${participants[i].offerProduct}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          labelOffset.dx - textPainter.width / 2,
          labelOffset.dy - textPainter.height / 2,
        ),
      );
    }

    // Draw nodes
    for (int i = 0; i < n; i++) {
      final pos = positions[i];
      final p = participants[i];
      final isConfirmed = p.confirmationStatus == 'confirmed';

      // Outer glow
      final glowPaint = Paint()
        ..color = (isConfirmed ? Colors.greenAccent : Colors.orangeAccent)
            .withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(pos, 22, glowPaint);

      // Node circle
      final nodePaint = Paint()
        ..color =
            isConfirmed ? Colors.white : Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 18, nodePaint);

      // Inner dark circle
      final innerPaint = Paint()
        ..color = const Color(0xFF1B5E20)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 14, innerPaint);

      // Initial letter
      final textPainter = TextPainter(
        text: TextSpan(
          text: p.farmerName[0],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );

      // Name below node
      final namePainter = TextPainter(
        text: TextSpan(
          text: p.farmerName.split(' ')[0],
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      namePainter.layout();
      namePainter.paint(
        canvas,
        Offset(pos.dx - namePainter.width / 2, pos.dy + 22),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
