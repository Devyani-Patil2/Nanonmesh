import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/theme.dart';
import '../../providers/app_state.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String _currentPin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;

  void _handleSubmit() async {
    final appState = context.read<AppState>();

    if (appState.isNewUser) {
      // New user: Create PIN flow
      if (!_isConfirmStep) {
        // First entry — ask to confirm
        if (_currentPin.length != 4) return;
        setState(() {
          _isConfirmStep = true;
          _confirmPinController.clear();
          _confirmPin = '';
        });
      } else {
        // Confirm step — check match
        if (_confirmPin != _currentPin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PINs do not match. Try again.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
          setState(() {
            _isConfirmStep = false;
            _pinController.clear();
            _confirmPinController.clear();
            _currentPin = '';
            _confirmPin = '';
          });
          return;
        }

        final success = await appState.registerPin(_currentPin);
        if (!mounted) return;
        if (success) {
          Navigator.pushReplacementNamed(
            context,
            '/profile-setup',
            arguments: widget.phoneNumber,
          );
        }
      }
    } else {
      // Existing user: Verify PIN
      if (_currentPin.length != 4) return;
      final success = await appState.verifyPin(_currentPin);
      if (!mounted) return;
      if (success) {
        Navigator.pushReplacementNamed(
          context,
          '/profile-setup',
          arguments: widget.phoneNumber,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appState.authError ?? 'Incorrect PIN'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        _pinController.clear();
        setState(() => _currentPin = '');
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isLoading = appState.isLoading;
    final isNew = appState.isNewUser;

    String title;
    String subtitle;
    if (isNew && !_isConfirmStep) {
      title = 'Create PIN';
      subtitle = 'Create a 4-digit security PIN\nfor ${widget.phoneNumber}';
    } else if (isNew && _isConfirmStep) {
      title = 'Confirm PIN';
      subtitle = 'Re-enter your 4-digit PIN\nto confirm';
    } else {
      title = 'Enter PIN';
      subtitle = 'Enter your 4-digit PIN\nfor ${widget.phoneNumber}';
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                IconButton(
                  onPressed: () {
                    if (_isConfirmStep) {
                      setState(() {
                        _isConfirmStep = false;
                        _pinController.clear();
                        _confirmPinController.clear();
                        _currentPin = '';
                        _confirmPin = '';
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                const SizedBox(height: 40),
                FadeInDown(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isNew ? Icons.lock_outline : Icons.lock_open,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeInLeft(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    title,
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
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // PIN Input
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
                      children: [
                        if (isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isConfirmStep
                                        ? 'Confirm your PIN to complete signup'
                                        : 'New number! Create a secure 4-digit PIN',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        PinCodeTextField(
                          appContext: context,
                          length: 4,
                          controller: _isConfirmStep
                              ? _confirmPinController
                              : _pinController,
                          obscureText: true,
                          obscuringCharacter: '●',
                          animationType: AnimationType.scale,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12),
                            fieldHeight: 60,
                            fieldWidth: 56,
                            activeFillColor: Colors.grey.shade50,
                            inactiveFillColor: Colors.grey.shade100,
                            selectedFillColor:
                                AppTheme.primaryGreen.withValues(alpha: 0.05),
                            activeColor: AppTheme.primaryGreen,
                            inactiveColor: Colors.grey.shade300,
                            selectedColor: AppTheme.primaryGreen,
                          ),
                          enableActiveFill: true,
                          textStyle: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              if (_isConfirmStep) {
                                _confirmPin = value;
                              } else {
                                _currentPin = value;
                              }
                            });
                          },
                          onCompleted: (value) {
                            if (_isConfirmStep) {
                              _confirmPin = value;
                            } else {
                              _currentPin = value;
                            }
                            _handleSubmit();
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    final pin = _isConfirmStep
                                        ? _confirmPin
                                        : _currentPin;
                                    if (pin.length == 4) _handleSubmit();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _isConfirmStep
                                        ? 'Confirm & Continue'
                                        : isNew
                                            ? 'Create PIN'
                                            : 'Verify & Continue',
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
                const SizedBox(height: 24),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Center(
                    child: Text(
                      isNew
                          ? 'This PIN will be used to log in next time'
                          : 'Forgot PIN? Contact support',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
