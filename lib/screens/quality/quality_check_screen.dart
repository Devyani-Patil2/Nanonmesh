import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../providers/app_state.dart';
import '../../models/evidence_model.dart';
import '../../services/quality_analysis_service.dart';

class QualityCheckScreen extends StatefulWidget {
  const QualityCheckScreen({super.key});

  @override
  State<QualityCheckScreen> createState() => _QualityCheckScreenState();
}

class _QualityCheckScreenState extends State<QualityCheckScreen> {
  EvidenceModel? _report;
  bool _isAnalyzing = false;
  File? _capturedImage;
  final _picker = ImagePicker();

  // Dynamic labels from AI category detection
  String _analyzeText = 'Analyzing item...';
  String _score1Label = '⭐ Quality';
  String _score2Label = '🔍 Damage';
  String _score3Label = '🎨 Color';
  String _score4Label = '📏 Size';
  String _categoryLabel = '';
  String _categoryEmoji = '';
  String _howItWorks = '1. Take a photo of your item\n'
      '2. AI analyzes quality & condition\n'
      '3. Get an instant quality score (0–100)\n'
      '4. Use this score in trade negotiations';

  /// Capture a REAL photo using the device camera and analyze it.
  void _captureAndAnalyze() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (photo == null || !mounted) return;
    await _analyzePhoto(photo);
  }

  /// Pick from gallery for testing.
  void _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (photo == null || !mounted) return;
    await _analyzePhoto(photo);
  }

  /// Shared analysis logic: read image, detect category, generate report.
  Future<void> _analyzePhoto(XFile photo) async {
    setState(() {
      _isAnalyzing = true;
      _capturedImage = File(photo.path);
    });

    // Read real image bytes
    final imageBytes = await File(photo.path).readAsBytes();
    if (!mounted) return;

    // First, get raw analysis with category detection
    final rawResult =
        QualityAnalysisService.instance.analyzeImageBytes(imageBytes);

    // Update dynamic labels from detected category
    setState(() {
      _score1Label = rawResult['score1Label'] ?? '⭐ Quality';
      _score2Label = rawResult['score2Label'] ?? '🔍 Damage';
      _score3Label = rawResult['score3Label'] ?? '🎨 Color';
      _score4Label = rawResult['score4Label'] ?? '📏 Size';
      _categoryLabel = rawResult['categoryLabel'] ?? 'General Item';
      _categoryEmoji = rawResult['categoryEmoji'] ?? '📦';
      _analyzeText = rawResult['analyzeText'] ?? 'Analyzing...';
      _howItWorks = rawResult['howItWorks'] ?? _howItWorks;
    });

    // Now generate the evidence report via AppState
    final appState = context.read<AppState>();
    final report = await appState.generateQualityScoreFromImage(
      tradeId: 'quality_${DateTime.now().millisecondsSinceEpoch}',
      farmerId: appState.currentUser?.id ?? '',
      imageBytes: imageBytes,
      photoUrl: photo.path,
    );

    if (!mounted) return;
    setState(() {
      _report = report;
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text(
          'AI Quality Check',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
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
            // Camera/Capture Section
            FadeInDown(
              child: GestureDetector(
                onTap: _isAnalyzing ? null : _captureAndAnalyze,
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                    image: _capturedImage != null
                        ? DecorationImage(
                            image: FileImage(_capturedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _isAnalyzing
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: AppTheme.primaryGreen,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '🤖 AI Detecting Item Type...',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _analyzeText,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : _capturedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 32,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to Capture & Analyze',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                Text(
                                  'Take a photo of crop, equipment, grain, etc.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            )
                          : null,
                ),
              ),
            ),

            // Gallery option
            if (!_isAnalyzing)
              FadeInUp(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: _pickFromGallery,
                      icon:
                          const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(
                        'Or pick from gallery',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // AI Report
            if (_report != null) ...[
              // Detected Category Badge
              FadeInUp(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _categoryEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Detected Category',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Text(
                            _categoryLabel,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.accentAmber,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Overall Score Card
              FadeInUp(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.smart_toy_rounded,
                              color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$_categoryEmoji AI Quality Report',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CircularPercentIndicator(
                        radius: 52,
                        lineWidth: 8,
                        percent: _report!.aiQualityScore / 100,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _report!.aiQualityScore.toStringAsFixed(0),
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'out of 100',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        progressColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _report!.conditionTag,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic Score Breakdown (labels change with category!)
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score Breakdown — $_categoryLabel',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _scoreRow(_score1Label, _report!.freshnessScore),
                      _scoreRow(_score2Label, _report!.damageScore),
                      _scoreRow(_score3Label, _report!.colorScore),
                      _scoreRow(_score4Label, _report!.sizeScore),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Metadata
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _metaRow(Icons.category_outlined, 'Detected As',
                          '$_categoryEmoji $_categoryLabel'),
                      _metaRow(Icons.location_on_outlined, 'Geo-tag',
                          '${_report!.latitude.toStringAsFixed(4)}, ${_report!.longitude.toStringAsFixed(4)}'),
                      _metaRow(Icons.access_time, 'Timestamp',
                          _report!.timestamp.toString().substring(0, 19)),
                      _metaRow(Icons.tag, 'Report ID',
                          _report!.id.substring(0, 8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _captureAndAnalyze,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(
                          'Re-analyze',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Report saved! ✅'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: Text(
                          'Save Report',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_report == null && !_isAnalyzing) ...[
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: AppTheme.accentAmber, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'Smart AI Detection',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Category cards
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _categoryChip('🌿', 'Crops', 'Freshness & ripeness'),
                          _categoryChip('🌾', 'Grains', 'Purity & uniformity'),
                          _categoryChip('🔧', 'Equipment', 'Condition & rust'),
                          _categoryChip('🐄', 'Livestock', 'Health & coat'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AI automatically detects what you\'re photographing and generates a report with metrics specific to that item type.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _categoryChip(String emoji, String label, String desc) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 32,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, double score) {
    Color barColor;
    if (score >= 80) {
      barColor = AppTheme.successGreen;
    } else if (score >= 60) {
      barColor = AppTheme.accentAmber;
    } else {
      barColor = AppTheme.errorRed;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: Colors.grey.shade200,
                color: barColor,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              score.toStringAsFixed(0),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
