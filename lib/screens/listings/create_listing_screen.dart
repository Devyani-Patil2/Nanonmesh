import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/app_state.dart';
import '../../models/listing_model.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  String? _selectedProduct;
  String? _desiredProduct;
  String _selectedUnit = 'kg';
  String _qualityExpectation = 'Good';
  final _quantityController = TextEditingController();
  double _estimatedValue = 0;
  final _formKey = GlobalKey<FormState>();

  void _updateValuation() async {
    if (_selectedProduct != null && _quantityController.text.isNotEmpty) {
      final qty = double.tryParse(_quantityController.text) ?? 0;
      final appState = context.read<AppState>();
      final value = await appState.getValuationAsync(_selectedProduct!, qty);
      if (mounted) {
        setState(() {
          _estimatedValue = value;
        });
      }
    }
  }

  void _createListing() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null || _desiredProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both products')),
      );
      return;
    }

    final appState = context.read<AppState>();
    final user = appState.currentUser!;
    final listing = ListingModel(
      id: const Uuid().v4(),
      farmerId: user.id,
      farmerName: user.name,
      farmerVillage: user.village,
      productType: _selectedProduct!,
      quantity: double.parse(_quantityController.text),
      unit: _selectedUnit,
      qualityExpectation: _qualityExpectation,
      desiredProduct: _desiredProduct!,
      valuationScore: _estimatedValue,
      latitude: user.latitude,
      longitude: user.longitude,
    );

    appState.addListing(listing);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Listing created! Looking for trade matches... 🔄'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(
          'Create Listing',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // What are you offering?
              FadeInUp(
                child: _sectionTitle('What are you offering?', '🌾'),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: _productGrid(
                  selected: _selectedProduct,
                  onSelect: (product) {
                    setState(() => _selectedProduct = product);
                    _updateValuation();
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Quantity & Unit
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _sectionTitle('Quantity', '📊'),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 250),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Enter quantity',
                          prefixIcon: Icon(Icons.scale, color: Colors.grey.shade500),
                        ),
                        onChanged: (_) => _updateValuation(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(),
                        items: AppConstants.units
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedUnit = v!),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // What do you want?
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: _sectionTitle('What do you want in exchange?', '🎯'),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 350),
                child: _productGrid(
                  selected: _desiredProduct,
                  onSelect: (product) {
                    setState(() => _desiredProduct = product);
                  },
                  exclude: _selectedProduct,
                ),
              ),
              const SizedBox(height: 24),

              // Quality Expectation
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: _sectionTitle('Quality Level', '⭐'),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 450),
                child: Row(
                  children: AppConstants.qualityLevels.map((q) {
                    final isSelected = _qualityExpectation == q;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _qualityExpectation = q),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                q,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Estimated Valuation
              if (_estimatedValue > 0) ...[
                FadeInUp(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.analytics_outlined,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated Value',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                '₹${_estimatedValue.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Based on\nmandi rates',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Create Button
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _createListing,
                    child: Text(
                      'Create Listing 🌱',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _productGrid({
    required String? selected,
    required Function(String) onSelect,
    String? exclude,
  }) {
    final products = AppConstants.productCategories
        .where((p) => p != exclude)
        .toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: products.map((product) {
        final isSelected = selected == product;
        final emoji = AppConstants.productEmojis[product] ?? '📦';
        return GestureDetector(
          onTap: () => onSelect(product),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryGreen : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  product,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
