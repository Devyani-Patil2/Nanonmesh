import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/app_state.dart';
import '../../services/location_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phoneNumber;
  const ProfileSetupScreen({super.key, required this.phoneNumber});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _villageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isDetectingLocation = false;
  String _locationStatus = '';
  bool _locationError = false;
  bool _permissionDenied = false;

  double? _detectedLat;
  double? _detectedLng;

  @override
  void initState() {
    super.initState();
    // Auto-detect village from GPS on screen load
    _detectLocation();
  }

  /// Use real GPS to auto-fill village name with proper error feedback.
  Future<void> _detectLocation() async {
    setState(() {
      _isDetectingLocation = true;
      _locationStatus = '📡 Detecting your location...';
      _locationError = false;
      _permissionDenied = false;
    });

    final appState = context.read<AppState>();
    final localeIdentifier = '${appState.locale.languageCode}_${appState.locale.countryCode}';

    final result = await LocationService.instance.detectLocation(
      localeIdentifier: localeIdentifier,
    );

    if (!mounted) return;

    if (result.success) {
      final lat = result.position!.latitude;
      final lng = result.position!.longitude;
      setState(() {
        _villageController.text = result.villageName ?? 'Unknown';
        _detectedLat = lat;
        _detectedLng = lng;
        _isDetectingLocation = false;
        _locationError = false;
        _locationStatus =
            '📍 Location detected: ${result.villageName}\n'
            '🌐 Coordinates: ${_detectedLat!.toStringAsFixed(4)}, '
            '${_detectedLng!.toStringAsFixed(4)}';
      });
    } else {
      setState(() {
        _isDetectingLocation = false;
        _locationError = true;
        _permissionDenied = result.permissionDenied;
        _locationStatus = '⚠️ ${result.error}';
      });
    }
  }

  void _setupProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    await appState.setupProfile(
      name: _nameController.text.trim(),
      village: _villageController.text.trim(),
      phone: widget.phoneNumber,
    );

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: SafeArea(
            child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  FadeInDown(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInLeft(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Set Up Profile',
                      style: GoogleFonts.outfit(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInLeft(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'Tell us about yourself to get started',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name Input
                          Text(
                            'Your Name',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Colors.grey.shade500,
                              ),
                              hintText: 'Enter your full name',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Village Input (real GPS + manual entry)
                          Row(
                            children: [
                              Text(
                                'Your Village',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const Spacer(),
                              if (_isDetectingLocation)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Detecting...',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                GestureDetector(
                                  onTap: _detectLocation,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.my_location,
                                          size: 14,
                                          color: AppTheme.primaryGreen,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Auto-detect',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppTheme.primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _villageController,
                            textCapitalization: TextCapitalization.words,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey.shade500,
                              ),
                              hintText: 'Enter your village name',
                              suffixIcon: _detectedLat != null
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.successGreen,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your village';
                              }
                              return null;
                            },
                          ),

                          // Location status message
                          if (_locationStatus.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _locationError
                                    ? Colors.red.shade50
                                    : AppTheme.successGreen
                                        .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _locationError
                                      ? Colors.red.shade200
                                      : AppTheme.successGreen
                                          .withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _locationStatus,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      height: 1.4,
                                      color: _locationError
                                          ? Colors.red.shade700
                                          : AppTheme.successGreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  // Show "Open Settings" button for permission errors
                                  if (_permissionDenied) ...[
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () async {
                                        await LocationService.instance
                                            .openAppSettings();
                                      },
                                      child: Text(
                                        '→ Open Settings',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryGreen,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Phone display
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen
                                  .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.phone_android,
                                  color: AppTheme.primaryGreen,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mobile Number',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    Text(
                                      '+91 ${widget.phoneNumber}',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.successGreen,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Continue Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _setupProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Start Trading 🌾',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
          ),
          ),
        ),
      ),
    );
  }
}
