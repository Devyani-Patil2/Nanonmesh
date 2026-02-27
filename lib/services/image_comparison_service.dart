import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Real image comparison service for dispute resolution.
/// Compares complaint photo vs delivery photo using actual pixel analysis
/// instead of random similarity scores.
class ImageComparisonService {
  static final ImageComparisonService instance = ImageComparisonService._();
  ImageComparisonService._();

  /// Compare two images and return a real similarity score (0–100).
  /// Higher = more similar (complaint photo matches delivery photo).
  Future<Map<String, dynamic>> compareImages(
      File image1, File image2) async {
    try {
      final bytes1 = await image1.readAsBytes();
      final bytes2 = await image2.readAsBytes();
      return compareImageBytes(bytes1, bytes2);
    } catch (e) {
      return {'similarity': 50.0, 'method': 'error', 'verdict': 'manual_review'};
    }
  }

  /// Compare from raw bytes.
  Map<String, dynamic> compareImageBytes(Uint8List bytes1, Uint8List bytes2) {
    try {
      var img1 = img.decodeImage(bytes1);
      var img2 = img.decodeImage(bytes2);
      if (img1 == null || img2 == null) {
        return {'similarity': 50.0, 'method': 'decode_error', 'verdict': 'manual_review'};
      }

      // Resize both to same dimensions for fair comparison
      const compareSize = 100;
      final resized1 = img.copyResize(img1, width: compareSize, height: compareSize);
      final resized2 = img.copyResize(img2, width: compareSize, height: compareSize);

      // Method 1: Histogram comparison
      final histSimilarity = _compareHistograms(resized1, resized2);

      // Method 2: Mean pixel difference
      final pixelSimilarity = _comparePixels(resized1, resized2);

      // Method 3: Structural similarity (simplified SSIM)
      final structSimilarity = _structuralSimilarity(resized1, resized2);

      // Weighted average of all methods
      final similarity =
          histSimilarity * 0.3 + pixelSimilarity * 0.4 + structSimilarity * 0.3;

      // Determine verdict
      String verdict;
      double refundAmount = 0;

      if (similarity < 40) {
        // Very different images → complaint is likely valid
        verdict = 'valid_complaint';
        refundAmount = 500;
      } else if (similarity < 60) {
        // Somewhat different → partial issue
        verdict = 'partial_refund';
        refundAmount = 250;
      } else if (similarity < 80) {
        // Fairly similar → likely a false complaint
        verdict = 'false_complaint';
        refundAmount = 0;
      } else {
        // Very similar → definitely same product, no issue
        verdict = 'images_match';
        refundAmount = 0;
      }

      return {
        'similarity': double.parse(similarity.toStringAsFixed(1)),
        'histogramSimilarity': double.parse(histSimilarity.toStringAsFixed(1)),
        'pixelSimilarity': double.parse(pixelSimilarity.toStringAsFixed(1)),
        'structuralSimilarity': double.parse(structSimilarity.toStringAsFixed(1)),
        'verdict': verdict,
        'refundAmount': refundAmount,
        'method': 'multi_metric',
      };
    } catch (e) {
      return {'similarity': 50.0, 'method': 'error', 'verdict': 'manual_review'};
    }
  }

  /// Compare color histograms of two images.
  /// Returns 0–100 similarity score.
  double _compareHistograms(img.Image img1, img.Image img2) {
    const bins = 32;
    final hist1R = List.filled(bins, 0);
    final hist1G = List.filled(bins, 0);
    final hist1B = List.filled(bins, 0);
    final hist2R = List.filled(bins, 0);
    final hist2G = List.filled(bins, 0);
    final hist2B = List.filled(bins, 0);

    // Build histograms
    for (int y = 0; y < img1.height; y++) {
      for (int x = 0; x < img1.width; x++) {
        final p1 = img1.getPixel(x, y);
        final p2 = img2.getPixel(x, y);

        hist1R[(p1.r.toInt() * (bins - 1)) ~/ 255]++;
        hist1G[(p1.g.toInt() * (bins - 1)) ~/ 255]++;
        hist1B[(p1.b.toInt() * (bins - 1)) ~/ 255]++;

        hist2R[(p2.r.toInt() * (bins - 1)) ~/ 255]++;
        hist2G[(p2.g.toInt() * (bins - 1)) ~/ 255]++;
        hist2B[(p2.b.toInt() * (bins - 1)) ~/ 255]++;
      }
    }

    // Bhattacharyya distance for each channel
    final simR = _bhattacharyyaSimilarity(hist1R, hist2R);
    final simG = _bhattacharyyaSimilarity(hist1G, hist2G);
    final simB = _bhattacharyyaSimilarity(hist1B, hist2B);

    return ((simR + simG + simB) / 3 * 100).clamp(0, 100);
  }

  double _bhattacharyyaSimilarity(List<int> h1, List<int> h2) {
    final n1 = h1.reduce((a, b) => a + b).toDouble();
    final n2 = h2.reduce((a, b) => a + b).toDouble();
    if (n1 == 0 || n2 == 0) return 0;

    double bc = 0;
    for (int i = 0; i < h1.length; i++) {
      bc += sqrt((h1[i] / n1) * (h2[i] / n2));
    }
    return bc.clamp(0, 1);
  }

  /// Compare mean pixel values between images.
  /// Returns 0–100 similarity score.
  double _comparePixels(img.Image img1, img.Image img2) {
    double totalDiff = 0;
    final pixelCount = img1.width * img1.height;

    for (int y = 0; y < img1.height; y++) {
      for (int x = 0; x < img1.width; x++) {
        final p1 = img1.getPixel(x, y);
        final p2 = img2.getPixel(x, y);

        final diffR = (p1.r - p2.r).abs().toDouble();
        final diffG = (p1.g - p2.g).abs().toDouble();
        final diffB = (p1.b - p2.b).abs().toDouble();

        totalDiff += (diffR + diffG + diffB) / 3;
      }
    }

    final avgDiff = totalDiff / pixelCount;
    // Max possible diff is 255, so normalize
    return ((1 - avgDiff / 255) * 100).clamp(0, 100);
  }

  /// Simplified structural similarity (SSIM-like).
  /// Compares local luminance patterns between images.
  double _structuralSimilarity(img.Image img1, img.Image img2) {
    // Convert to grayscale luminance
    final lum1 = <double>[];
    final lum2 = <double>[];

    for (int y = 0; y < img1.height; y++) {
      for (int x = 0; x < img1.width; x++) {
        final p1 = img1.getPixel(x, y);
        final p2 = img2.getPixel(x, y);

        lum1.add(0.299 * p1.r.toDouble() + 0.587 * p1.g.toDouble() +
            0.114 * p1.b.toDouble());
        lum2.add(0.299 * p2.r.toDouble() + 0.587 * p2.g.toDouble() +
            0.114 * p2.b.toDouble());
      }
    }

    final n = lum1.length.toDouble();
    final mean1 = lum1.reduce((a, b) => a + b) / n;
    final mean2 = lum2.reduce((a, b) => a + b) / n;

    double var1 = 0, var2 = 0, covar = 0;
    for (int i = 0; i < lum1.length; i++) {
      var1 += (lum1[i] - mean1) * (lum1[i] - mean1);
      var2 += (lum2[i] - mean2) * (lum2[i] - mean2);
      covar += (lum1[i] - mean1) * (lum2[i] - mean2);
    }
    var1 /= n;
    var2 /= n;
    covar /= n;

    // SSIM formula constants
    const c1 = 6.5025; // (0.01 * 255)^2
    const c2 = 58.5225; // (0.03 * 255)^2

    final ssim = ((2 * mean1 * mean2 + c1) * (2 * covar + c2)) /
        ((mean1 * mean1 + mean2 * mean2 + c1) * (var1 + var2 + c2));

    return (ssim * 100).clamp(0, 100);
  }
}
