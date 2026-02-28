import os
from flask import Flask, request, jsonify
import torch
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from skimage.metrics import structural_similarity as ssim
import cv2

app = Flask(__name__)

# Ensure uploads directory exists
UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

print("Loading pre-trained ResNet18 model...")
# Load pretrained model
model = models.resnet18(pretrained=True)
model = torch.nn.Sequential(*list(model.children())[:-1])  # Remove classification layer
model.eval()
print("Model loaded successfully!")

# Image preprocessing
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
])

def extract_features(image_path):
    image = Image.open(image_path).convert("RGB")
    image = transform(image).unsqueeze(0)

    with torch.no_grad():
        features = model(image)

    return features.flatten().numpy()

def compute_similarity(before_path, after_path):
    try:
        # Deep feature similarity
        feat1 = extract_features(before_path)
        feat2 = extract_features(after_path)

        cosine_sim = cosine_similarity([feat1], [feat2])[0][0]

        # Structural similarity (pixel level)
        img1 = cv2.imread(before_path)
        img2 = cv2.imread(after_path)

        if img1 is None or img2 is None:
            raise ValueError("Could not read one or both images with OpenCV")

        img1 = cv2.resize(img1, (256, 256))
        img2 = cv2.resize(img2, (256, 256))

        gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
        gray2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)

        structural_sim, _ = ssim(gray1, gray2, full=True)

        # Combined score (70% deep features, 30% structural)
        final_score = (0.7 * cosine_sim) + (0.3 * structural_sim)

        return float(cosine_sim), float(structural_sim), float(final_score)
    except Exception as e:
        print(f"Error computing similarity: {e}")
        return 0.0, 0.0, 0.0

def dispute_decision(score):
    if score > 0.85:
        return "No Significant Change", "images_match", 0
    elif score > 0.65:
        return "Minor Variation", "partial_refund", 0.5 # 50% refund modifier
    else:
        return "Major Difference - Possible Damage", "valid_complaint", 1.0 # 100% refund modifier

@app.route('/compare', methods=['POST'])
def compare_images():
    if 'image1' not in request.files or 'image2' not in request.files:
        return jsonify({'error': 'Both image1 and image2 are required'}), 400

    file1 = request.files['image1']
    file2 = request.files['image2']

    if file1.filename == '' or file2.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    path1 = os.path.join(UPLOAD_FOLDER, 'img1_temp.jpg')
    path2 = os.path.join(UPLOAD_FOLDER, 'img2_temp.jpg')

    try:
        file1.save(path1)
        file2.save(path2)

        cosine_sim, struct_sim, final_score = compute_similarity(path1, path2)
        desc, verdict, refund_modifier = dispute_decision(final_score)

        return jsonify({
            'success': True,
            'similarity': float(final_score * 100), # Return out of 100 for Flutter
            'cosine_similarity': float(cosine_sim * 100),
            'structural_similarity': float(struct_sim * 100),
            'description': desc,
            'verdict': verdict,
            'refund_modifier': refund_modifier
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
    finally:
        # Cleanup
        if os.path.exists(path1): os.remove(path1)
        if os.path.exists(path2): os.remove(path2)

if __name__ == '__main__':
    # Run on 0.0.0.0 so physical Android devices can reach it via local IP
    app.run(host='0.0.0.0', port=5000, debug=True)
