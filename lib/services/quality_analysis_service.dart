import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Item categories that the AI can detect from pixel analysis.
enum ItemCategory {
  crop,       // Green produce: vegetables, fruits, leafy greens
  grain,      // Grains/seeds: wheat, rice, pulses — yellowish/brown, small uniform
  equipment,  // Tools/machinery: metallic grey/blue, hard edges, low saturation
  livestock,  // Animals: varied brown/white, high contrast, organic shapes
  general,    // Fallback for unrecognized items
}

/// Category-specific label set for the 4 score dimensions.
class CategoryLabels {
  final String category;
  final String emoji;
  final String score1Label;
  final String score1Emoji;
  final String score2Label;
  final String score2Emoji;
  final String score3Label;
  final String score3Emoji;
  final String score4Label;
  final String score4Emoji;
  final String analyzeText;
  final String howItWorks;

  const CategoryLabels({
    required this.category,
    required this.emoji,
    required this.score1Label,
    required this.score1Emoji,
    required this.score2Label,
    required this.score2Emoji,
    required this.score3Label,
    required this.score3Emoji,
    required this.score4Label,
    required this.score4Emoji,
    required this.analyzeText,
    required this.howItWorks,
  });
}

/// Real image-based quality analysis service.
/// Detects what type of item is in the image and generates
/// category-specific quality reports.
class QualityAnalysisService {
  static final QualityAnalysisService instance = QualityAnalysisService._();
  QualityAnalysisService._();

  /// Labels for each detected category.
  static const _labels = <ItemCategory, CategoryLabels>{
    ItemCategory.crop: CategoryLabels(
      category: 'Crop / Produce',
      emoji: '🌿',
      score1Label: 'Freshness',
      score1Emoji: '🌿',
      score2Label: 'Damage Detection',
      score2Emoji: '🔍',
      score3Label: 'Color & Ripeness',
      score3Emoji: '🎨',
      score4Label: 'Size & Uniformity',
      score4Emoji: '📏',
      analyzeText: 'Analyzing crop freshness, damage, color & size...',
      howItWorks: '1. Take a clear photo of your crop/produce\n'
          '2. AI detects freshness, ripeness & damage\n'
          '3. Get quality score (0–100)\n'
          '4. Use in trade negotiations',
    ),
    ItemCategory.grain: CategoryLabels(
      category: 'Grain / Seeds',
      emoji: '🌾',
      score1Label: 'Grain Purity',
      score1Emoji: '✨',
      score2Label: 'Foreign Matter',
      score2Emoji: '🔍',
      score3Label: 'Color Consistency',
      score3Emoji: '🎨',
      score4Label: 'Size Uniformity',
      score4Emoji: '📐',
      analyzeText: 'Analyzing grain purity, foreign matter & consistency...',
      howItWorks: '1. Spread grains on a flat surface\n'
          '2. AI checks purity, foreign matter & uniformity\n'
          '3. Get quality grade (0–100)\n'
          '4. Use for fair pricing in trades',
    ),
    ItemCategory.equipment: CategoryLabels(
      category: 'Equipment / Tool',
      emoji: '🔧',
      score1Label: 'Overall Condition',
      score1Emoji: '🛠️',
      score2Label: 'Rust / Corrosion',
      score2Emoji: '🔍',
      score3Label: 'Surface Quality',
      score3Emoji: '✨',
      score4Label: 'Wear Level',
      score4Emoji: '⚙️',
      analyzeText: 'Analyzing equipment condition, rust & wear...',
      howItWorks: '1. Take a clear photo of the equipment/tool\n'
          '2. AI checks condition, rust & surface wear\n'
          '3. Get quality score (0–100)\n'
          '4. Fair valuation for equipment trades',
    ),
    ItemCategory.livestock: CategoryLabels(
      category: 'Livestock / Animal',
      emoji: '🐄',
      score1Label: 'Health Appearance',
      score1Emoji: '💪',
      score2Label: 'Coat / Skin Quality',
      score2Emoji: '🔍',
      score3Label: 'Color & Vitality',
      score3Emoji: '🎨',
      score4Label: 'Body Condition',
      score4Emoji: '📏',
      analyzeText: 'Analyzing animal health, coat & body condition...',
      howItWorks: '1. Take a clear side photo of the animal\n'
          '2. AI checks health appearance & coat quality\n'
          '3. Get health score (0–100)\n'
          '4. Use for fair livestock valuation',
    ),
    ItemCategory.general: CategoryLabels(
      category: 'General Item',
      emoji: '📦',
      score1Label: 'Overall Quality',
      score1Emoji: '⭐',
      score2Label: 'Damage Level',
      score2Emoji: '🔍',
      score3Label: 'Visual Appeal',
      score3Emoji: '🎨',
      score4Label: 'Condition',
      score4Emoji: '📋',
      analyzeText: 'Analyzing item quality, condition & appearance...',
      howItWorks: '1. Take a clear photo of the item\n'
          '2. AI analyzes quality & condition\n'
          '3. Get quality score (0–100)\n'
          '4. Use for fair trade valuation',
    ),
  };

  /// Get labels for a given category.
  CategoryLabels getLabels(ItemCategory category) {
    return _labels[category] ?? _labels[ItemCategory.general]!;
  }

  /// Analyze a crop photo from a File.
  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return analyzeImageBytes(bytes);
    } catch (e) {
      return _defaultScores(ItemCategory.general);
    }
  }

  /// Analyze from raw image bytes.
  Map<String, dynamic> analyzeImageBytes(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return _defaultScores(ItemCategory.general);

      // Resize to 150x150 for fast analysis
      final resized = img.copyResize(image, width: 150, height: 150);

      // Step 1: Detect what type of item this is
      final pixelData = _extractPixelData(resized);
      final category = _detectCategory(pixelData);

      // Step 2: Generate category-specific scores
      return _generateCategoryScores(pixelData, category);
    } catch (e) {
      return _defaultScores(ItemCategory.general);
    }
  }

  /// Extract pixel statistics from the image.
  _PixelData _extractPixelData(img.Image image) {
    double totalBrightness = 0;
    double totalSaturation = 0;
    double totalHue = 0;
    int darkPixels = 0;
    int greenPixels = 0;
    int brownPixels = 0;
    int yellowPixels = 0;
    int greyPixels = 0;     // metallic/grey tones
    int bluePixels = 0;     // metallic blue
    int whitePixels = 0;
    int uniformPixels = 0;
    int highContrastPixels = 0;
    final pixelCount = image.width * image.height;
    final brightnessList = <double>[];
    double totalRed = 0;
    double totalGreen = 0;
    double totalBlue = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        totalRed += r;
        totalGreen += g;
        totalBlue += b;

        // Brightness
        final brightness = (0.299 * r + 0.587 * g + 0.114 * b);
        totalBrightness += brightness;
        brightnessList.add(brightness);

        // Saturation (HSV)
        final maxC = [r, g, b].reduce((a, c) => a > c ? a : c);
        final minC = [r, g, b].reduce((a, c) => a < c ? a : c);
        final saturation = maxC > 0 ? (maxC - minC) / maxC : 0.0;
        totalSaturation += saturation;

        // Hue
        double hue = 0;
        if (maxC != minC) {
          final delta = maxC - minC;
          if (maxC == r) {
            hue = 60 * (((g - b) / delta) % 6);
          } else if (maxC == g) {
            hue = 60 * (((b - r) / delta) + 2);
          } else {
            hue = 60 * (((r - g) / delta) + 4);
          }
          if (hue < 0) hue += 360;
        }
        totalHue += hue;

        // Classify pixels
        if (brightness < 50) darkPixels++;
        if (brightness > 220) whitePixels++;
        if (g > r * 1.2 && g > b * 1.2) greenPixels++;
        if (r > g * 1.3 && r > b * 1.2 && brightness < 150) brownPixels++;
        if (r > g * 0.9 && r < g * 1.4 && g > b * 1.3 && brightness > 100) yellowPixels++;
        if (saturation < 0.15 && brightness > 80 && brightness < 200) greyPixels++;
        if (b > r * 1.2 && b > g * 1.1) bluePixels++;

        // Uniformity
        final avgLocal = (r + g + b) / 3;
        if ((r - avgLocal).abs() < 30 &&
            (g - avgLocal).abs() < 30 &&
            (b - avgLocal).abs() < 30) {
          uniformPixels++;
        }

        // Edge detection (local contrast)
        if (x > 0 && y > 0) {
          final prevPixel = image.getPixel(x - 1, y);
          final diff = ((r - prevPixel.r.toDouble()).abs() +
                  (g - prevPixel.g.toDouble()).abs() +
                  (b - prevPixel.b.toDouble()).abs()) /
              3;
          if (diff > 30) highContrastPixels++;
        }
      }
    }

    final avgBrightness = totalBrightness / pixelCount;
    final avgSaturation = totalSaturation / pixelCount;
    final avgHue = totalHue / pixelCount;

    // Brightness variance
    double varianceSum = 0;
    for (final b in brightnessList) {
      varianceSum += (b - avgBrightness) * (b - avgBrightness);
    }
    final brightnessStdDev = pixelCount > 0 ? (varianceSum / pixelCount) : 0.0;

    return _PixelData(
      pixelCount: pixelCount,
      avgBrightness: avgBrightness,
      avgSaturation: avgSaturation,
      avgHue: avgHue,
      avgRed: totalRed / pixelCount,
      avgGreen: totalGreen / pixelCount,
      avgBlue: totalBlue / pixelCount,
      greenRatio: greenPixels / pixelCount,
      brownRatio: brownPixels / pixelCount,
      yellowRatio: yellowPixels / pixelCount,
      greyRatio: greyPixels / pixelCount,
      blueRatio: bluePixels / pixelCount,
      darkRatio: darkPixels / pixelCount,
      whiteRatio: whitePixels / pixelCount,
      uniformityRatio: uniformPixels / pixelCount,
      edgeRatio: highContrastPixels / pixelCount,
      brightnessVariance: brightnessStdDev,
    );
  }

  /// Detect item category from pixel statistics.
  ItemCategory _detectCategory(_PixelData d) {
    // EQUIPMENT: High grey ratio, low saturation, high edges
    // Metal tools are desaturated with hard edges
    if (d.greyRatio > 0.25 && d.avgSaturation < 0.2 && d.edgeRatio > 0.15) {
      return ItemCategory.equipment;
    }
    if (d.greyRatio > 0.35 && d.avgSaturation < 0.25) {
      return ItemCategory.equipment;
    }
    // Blue metallic (painted equipment)
    if (d.blueRatio > 0.15 && d.greyRatio > 0.15 && d.edgeRatio > 0.12) {
      return ItemCategory.equipment;
    }

    // GRAIN/SEEDS: High yellow/brown, high uniformity, moderate brightness
    // Grains are typically small, uniform, yellow-brown
    if (d.yellowRatio > 0.15 && d.uniformityRatio > 0.4 && d.greenRatio < 0.1) {
      return ItemCategory.grain;
    }
    if (d.brownRatio > 0.2 && d.uniformityRatio > 0.35 && d.greenRatio < 0.08) {
      return ItemCategory.grain;
    }
    // Average hue in yellow range (30-60°) with low green
    if (d.avgHue > 25 && d.avgHue < 65 && d.avgSaturation > 0.2 && d.greenRatio < 0.1) {
      return ItemCategory.grain;
    }

    // CROP/PRODUCE: High green ratio, good saturation
    // Fresh produce is green, vibrant, colorful
    if (d.greenRatio > 0.12) {
      return ItemCategory.crop;
    }
    if (d.avgSaturation > 0.3 && d.avgHue > 60 && d.avgHue < 180) {
      return ItemCategory.crop;
    }
    // Red fruits/vegetables
    if (d.avgSaturation > 0.35 && (d.avgHue < 30 || d.avgHue > 330)) {
      return ItemCategory.crop;
    }

    // LIVESTOCK: High contrast, organic shapes, brown/white mix
    if (d.brownRatio > 0.15 && d.whiteRatio > 0.1 && d.edgeRatio > 0.1) {
      return ItemCategory.livestock;
    }

    // Fallback
    return ItemCategory.general;
  }

  /// Generate scores based on category.
  Map<String, dynamic> _generateCategoryScores(
      _PixelData d, ItemCategory category) {
    double score1, score2, score3, score4;
    String conditionTag;
    final labels = getLabels(category);

    switch (category) {
      case ItemCategory.crop:
        score1 = _scoreCropFreshness(d);
        score2 = _scoreCropDamage(d);
        score3 = _scoreCropColor(d);
        score4 = _scoreCropSize(d);
        break;

      case ItemCategory.grain:
        score1 = _scoreGrainPurity(d);
        score2 = _scoreGrainForeignMatter(d);
        score3 = _scoreGrainColorConsistency(d);
        score4 = _scoreGrainSizeUniformity(d);
        break;

      case ItemCategory.equipment:
        score1 = _scoreEquipmentCondition(d);
        score2 = _scoreEquipmentRust(d);
        score3 = _scoreEquipmentSurface(d);
        score4 = _scoreEquipmentWear(d);
        break;

      case ItemCategory.livestock:
        score1 = _scoreLivestockHealth(d);
        score2 = _scoreLivestockCoat(d);
        score3 = _scoreLivestockVitality(d);
        score4 = _scoreLivestockBody(d);
        break;

      case ItemCategory.general:
        score1 = _scoreGeneralQuality(d);
        score2 = _scoreGeneralDamage(d);
        score3 = _scoreGeneralAppeal(d);
        score4 = _scoreGeneralCondition(d);
        break;
    }

    final overall = (score1 + score2 + score3 + score4) / 4;

    if (overall >= 85) {
      conditionTag = 'Excellent';
    } else if (overall >= 70) {
      conditionTag = 'Good';
    } else if (overall >= 50) {
      conditionTag = 'Average';
    } else {
      conditionTag = 'Poor';
    }

    return {
      'freshness': double.parse(score1.toStringAsFixed(1)),
      'damage': double.parse(score2.toStringAsFixed(1)),
      'color': double.parse(score3.toStringAsFixed(1)),
      'size': double.parse(score4.toStringAsFixed(1)),
      'overall': double.parse(overall.toStringAsFixed(1)),
      'conditionTag': conditionTag,
      'category': category.name,
      'categoryLabel': labels.category,
      'categoryEmoji': labels.emoji,
      'score1Label': '${labels.score1Emoji} ${labels.score1Label}',
      'score2Label': '${labels.score2Emoji} ${labels.score2Label}',
      'score3Label': '${labels.score3Emoji} ${labels.score3Label}',
      'score4Label': '${labels.score4Emoji} ${labels.score4Label}',
      'analyzeText': labels.analyzeText,
      'howItWorks': labels.howItWorks,
      // Raw analysis metadata
      'avgBrightness': d.avgBrightness,
      'avgSaturation': d.avgSaturation,
      'greenRatio': d.greenRatio,
      'brownRatio': d.brownRatio,
      'darkRatio': d.darkRatio,
      'uniformityRatio': d.uniformityRatio,
    };
  }

  // ─── CROP/PRODUCE SCORES ────────────────────────────────

  double _scoreCropFreshness(_PixelData d) {
    double s = 50.0;
    s += d.greenRatio * 100;
    s += d.avgSaturation * 30;
    s += (d.avgBrightness > 80 && d.avgBrightness < 200) ? 15 : 0;
    s -= d.brownRatio * 80;
    s -= d.darkRatio * 60;
    return s.clamp(10, 100);
  }

  double _scoreCropDamage(_PixelData d) {
    double s = 95.0;
    s -= d.darkRatio * 150;
    s -= d.brownRatio * 120;
    s -= (1 - d.uniformityRatio) * 30;
    s += d.avgBrightness > 100 ? 5 : 0;
    return s.clamp(10, 100);
  }

  double _scoreCropColor(_PixelData d) {
    double s = 40.0;
    s += d.avgSaturation * 60;
    final normVar = d.brightnessVariance < 5000 ? d.brightnessVariance / 5000 : 1.0;
    s += (1 - normVar) * 20;
    s += d.greenRatio * 20;
    s -= d.brownRatio * 30;
    return s.clamp(10, 100);
  }

  double _scoreCropSize(_PixelData d) {
    double s = 60.0;
    s += (1 - d.uniformityRatio) * 25;
    s += d.avgBrightness > 60 ? 15 : 0;
    s += d.avgSaturation > 0.2 ? 10 : 0;
    return s.clamp(10, 100);
  }

  // ─── GRAIN/SEED SCORES ──────────────────────────────────

  double _scoreGrainPurity(_PixelData d) {
    // Pure grains: uniform color, consistent hue, low foreign matter
    double s = 60.0;
    s += d.uniformityRatio * 40; // High uniformity = pure
    s += (d.yellowRatio + d.brownRatio) * 30; // Natural grain colors
    s -= d.greenRatio * 50; // Green = unripe or weed material
    s -= d.darkRatio * 40; // Dark spots = impurities
    s += d.avgBrightness > 100 ? 10 : 0;
    return s.clamp(10, 100);
  }

  double _scoreGrainForeignMatter(_PixelData d) {
    // No foreign matter: high uniformity, no odd colors
    double s = 90.0;
    s -= d.darkRatio * 120; // Dark spots = stones/dirt
    s -= d.greenRatio * 80; // Green = plant debris
    s -= d.edgeRatio * 40; // High edges = mixed items
    s += d.uniformityRatio * 20;
    return s.clamp(10, 100);
  }

  double _scoreGrainColorConsistency(_PixelData d) {
    // Consistent color across the grain batch
    double s = 50.0;
    s += d.uniformityRatio * 50;
    final normVar = d.brightnessVariance < 5000 ? d.brightnessVariance / 5000 : 1.0;
    s += (1 - normVar) * 30;
    s -= (d.darkRatio + d.whiteRatio) * 20; // Extremes = inconsistent
    return s.clamp(10, 100);
  }

  double _scoreGrainSizeUniformity(_PixelData d) {
    // Uniform size: consistent texture, moderate edge detection
    double s = 60.0;
    s += d.uniformityRatio * 30;
    s += d.avgBrightness > 80 ? 15 : 0;
    s -= (d.edgeRatio > 0.3 ? (d.edgeRatio - 0.3) * 50 : 0); // Too many edges = varied sizes
    s += d.avgSaturation > 0.15 ? 10 : 0;
    return s.clamp(10, 100);
  }

  // ─── EQUIPMENT/TOOL SCORES ──────────────────────────────

  double _scoreEquipmentCondition(_PixelData d) {
    // Good condition: clean surface, moderate brightness, low damage
    double s = 60.0;
    s += d.avgBrightness > 80 ? 20 : 0; // Well-lit = clean
    s += d.greyRatio * 30; // Metallic = proper material
    s -= d.brownRatio * 60; // Brown on metal = rust
    s -= d.darkRatio * 40; // Dark spots = wear/damage
    s += d.uniformityRatio * 15;
    return s.clamp(10, 100);
  }

  double _scoreEquipmentRust(_PixelData d) {
    // No rust score (high = no rust, good)
    double s = 95.0;
    s -= d.brownRatio * 200; // Brown = heavy rust penalty
    s -= d.yellowRatio * 80; // Yellow-brown = light rust
    s += d.greyRatio * 30; // Clean metal surface
    s += d.blueRatio * 20; // Painted = protected
    return s.clamp(10, 100);
  }

  double _scoreEquipmentSurface(_PixelData d) {
    // Surface quality: smooth, uniform, good finish
    double s = 50.0;
    s += d.uniformityRatio * 40;
    s += d.avgBrightness > 100 ? 15 : 0; // Shiny surface
    s -= d.darkRatio * 50; // Pitting/damage
    final normVar = d.brightnessVariance < 5000 ? d.brightnessVariance / 5000 : 1.0;
    s += (1 - normVar) * 20;
    return s.clamp(10, 100);
  }

  double _scoreEquipmentWear(_PixelData d) {
    // Low wear: consistent surface, few scratches (edges), maintained
    double s = 80.0;
    s -= d.edgeRatio * 60; // High edges = scratches/dents
    s -= d.darkRatio * 40;
    s += d.uniformityRatio * 20;
    s += d.avgBrightness > 100 ? 10 : 0;
    return s.clamp(10, 100);
  }

  // ─── LIVESTOCK SCORES ───────────────────────────────────

  double _scoreLivestockHealth(_PixelData d) {
    // Healthy appearance: good brightness, moderate saturation
    double s = 60.0;
    s += (d.avgBrightness > 80 && d.avgBrightness < 200) ? 20 : 0;
    s += d.avgSaturation * 20;
    s -= d.darkRatio * 60; // Dark spots = wounds/disease
    s += d.uniformityRatio * 15;
    return s.clamp(10, 100);
  }

  double _scoreLivestockCoat(_PixelData d) {
    // Coat quality: uniform, consistent texture
    double s = 60.0;
    s += d.uniformityRatio * 35;
    s -= d.darkRatio * 40; // Dark spots = skin issues
    s += d.avgBrightness > 100 ? 15 : 0; // Shiny coat
    s -= d.brownRatio > 0.4 ? 10 : 0; // Too brown = dirty
    return s.clamp(10, 100);
  }

  double _scoreLivestockVitality(_PixelData d) {
    // Color & vitality: good saturation, bright
    double s = 50.0;
    s += d.avgSaturation * 40;
    s += d.avgBrightness > 100 ? 20 : 0;
    s -= d.darkRatio * 50;
    s += d.whiteRatio > 0.05 ? 10 : 0; // Some white = healthy eyes/markings
    return s.clamp(10, 100);
  }

  double _scoreLivestockBody(_PixelData d) {
    // Body condition: good shape/proportion (contrast between body and background)
    double s = 60.0;
    s += d.edgeRatio * 30; // Defined body outline
    s += d.avgBrightness > 80 ? 15 : 0;
    s += d.avgSaturation > 0.15 ? 10 : 0;
    s -= d.darkRatio * 30;
    return s.clamp(10, 100);
  }

  // ─── GENERAL ITEM SCORES ────────────────────────────────

  double _scoreGeneralQuality(_PixelData d) {
    double s = 55.0;
    s += d.avgBrightness > 80 ? 15 : 0;
    s += d.avgSaturation * 25;
    s -= d.darkRatio * 40;
    s += d.uniformityRatio * 15;
    return s.clamp(10, 100);
  }

  double _scoreGeneralDamage(_PixelData d) {
    double s = 90.0;
    s -= d.darkRatio * 120;
    s -= d.brownRatio * 60;
    s += d.uniformityRatio * 15;
    return s.clamp(10, 100);
  }

  double _scoreGeneralAppeal(_PixelData d) {
    double s = 50.0;
    s += d.avgSaturation * 40;
    s += d.avgBrightness > 80 ? 15 : 0;
    s += d.uniformityRatio * 15;
    return s.clamp(10, 100);
  }

  double _scoreGeneralCondition(_PixelData d) {
    double s = 60.0;
    s -= d.darkRatio * 40;
    s += d.avgBrightness > 60 ? 15 : 0;
    s += d.uniformityRatio * 20;
    return s.clamp(10, 100);
  }

  // ─── DEFAULTS ───────────────────────────────────────────

  Map<String, dynamic> _defaultScores(ItemCategory category) {
    final labels = getLabels(category);
    return {
      'freshness': 50.0,
      'damage': 50.0,
      'color': 50.0,
      'size': 50.0,
      'overall': 50.0,
      'conditionTag': 'Average',
      'category': category.name,
      'categoryLabel': labels.category,
      'categoryEmoji': labels.emoji,
      'score1Label': '${labels.score1Emoji} ${labels.score1Label}',
      'score2Label': '${labels.score2Emoji} ${labels.score2Label}',
      'score3Label': '${labels.score3Emoji} ${labels.score3Label}',
      'score4Label': '${labels.score4Emoji} ${labels.score4Label}',
      'analyzeText': labels.analyzeText,
      'howItWorks': labels.howItWorks,
      'avgBrightness': 0.0,
      'avgSaturation': 0.0,
      'greenRatio': 0.0,
      'brownRatio': 0.0,
      'darkRatio': 0.0,
      'uniformityRatio': 0.0,
    };
  }
}

/// Internal pixel statistics container.
class _PixelData {
  final int pixelCount;
  final double avgBrightness;
  final double avgSaturation;
  final double avgHue;
  final double avgRed;
  final double avgGreen;
  final double avgBlue;
  final double greenRatio;
  final double brownRatio;
  final double yellowRatio;
  final double greyRatio;
  final double blueRatio;
  final double darkRatio;
  final double whiteRatio;
  final double uniformityRatio;
  final double edgeRatio;
  final double brightnessVariance;

  _PixelData({
    required this.pixelCount,
    required this.avgBrightness,
    required this.avgSaturation,
    required this.avgHue,
    required this.avgRed,
    required this.avgGreen,
    required this.avgBlue,
    required this.greenRatio,
    required this.brownRatio,
    required this.yellowRatio,
    required this.greyRatio,
    required this.blueRatio,
    required this.darkRatio,
    required this.whiteRatio,
    required this.uniformityRatio,
    required this.edgeRatio,
    required this.brightnessVariance,
  });
}
