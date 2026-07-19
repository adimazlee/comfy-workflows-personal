#!/bin/bash
# =========================================================================
# Custom provisioning script — Velora Wan 2.2 Fun Control & Animate (FINAL FIXED)
# =========================================================================
echo "=== 1. Mempersiapkan Environment ==="
# Pastikan huggingface_hub terupdate
pip install -U "huggingface_hub[cli]"

# Deteksi path ComfyUI
if [ -d "/workspace/ComfyUI" ]; then
    COMFY_DIR="/workspace/ComfyUI"
elif [ -d "/root/ComfyUI" ]; then
    COMFY_DIR="/root/ComfyUI"
else
    COMFY_DIR="/workspace/ComfyUI"
    mkdir -p "$COMFY_DIR"
fi
echo "✅ Menggunakan direktori ComfyUI di: $COMFY_DIR"

# Buat folder yang diperlukan
WORKFLOW_DIR="$COMFY_DIR/user/default/workflows"
DIFFUSION_DIR="$COMFY_DIR/models/diffusion_models"
TEXT_ENCODER_DIR="$COMFY_DIR/models/text_encoders"
VAE_DIR="$COMFY_DIR/models/vae"
LORA_DIR="$COMFY_DIR/models/loras"
CLIP_VISION_DIR="$COMFY_DIR/models/clip_vision"
DETECTION_DIR="$COMFY_DIR/models/detection"
SAM2_DIR="$COMFY_DIR/models/sam2"

mkdir -p "$WORKFLOW_DIR" "$DIFFUSION_DIR" "$TEXT_ENCODER_DIR" "$VAE_DIR" "$LORA_DIR" "$CLIP_VISION_DIR" "$DETECTION_DIR" "$SAM2_DIR"

echo "=== 2. Download Workflows ==="
REPO_BASE="https://raw.githubusercontent.com/adimazlee/comfy-workflows-personal/refs/heads/main"
curl -fSLC - "$REPO_BASE/video_wan2_2_14B_fun_control.json" -o "$WORKFLOW_DIR/video_wan2_2_14B_fun_control.json" || echo "⚠️ Gagal download workflow fun control"
curl -fSLC - "$REPO_BASE/template_purz_wan22_animate_auto_character_replace.json" -o "$WORKFLOW_DIR/template_purz_wan22_animate_auto_character_replace.json" || echo "⚠️ Gagal download workflow animate"

echo "=== 3. Download Shared Models ==="
echo "📥 Text Encoder..."
hf download Comfy-Org/Wan_2.1_ComfyUI_Repackaged split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors --local-dir "$COMFY_DIR" || echo "⚠️ Gagal"

echo "📥 VAE..."
hf download Comfy-Org/Wan_2.1_ComfyUI_Repackaged split_files/vae/wan_2.1_vae.safetensors --local-dir "$COMFY_DIR" || echo "⚠️ Gagal"

echo "📥 Clip Vision..."
hf download Comfy-Org/Wan_2.1_ComfyUI_Repackaged split_files/clip_vision/clip_vision_h.safetensors --local-dir "$COMFY_DIR" || echo "⚠️ Gagal"

echo "=== 4. Download Wan 2.2 Fun Control Models ==="
echo "📥 Fun Control High Noise..."
hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged split_files/diffusion_models/wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors --local-dir "$COMFY_DIR" || echo "⚠️ Gagal"

echo "📥 Fun Control Low Noise..."
hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged split_files/diffusion_models/wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors --local-dir "$COMFY_DIR" || echo "⚠️ Gagal"

echo "=== 5. Download Detection & Segmentation Models (WAJIB untuk Animate) ==="
echo "📥 ViTPose ONNX..."
curl -fSLC - "https://huggingface.co/JunkyByte/easy_ViTPose/resolve/main/onnx/wholebody/vitpose-l-wholebody.onnx" -o "$DETECTION_DIR/vitpose-l-wholebody.onnx" || echo "⚠️ Gagal download ViTPose"

echo "📥 YOLOv10m ONNX..."
curl -fSLC - "https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx" -o "$DETECTION_DIR/yolov10m.onnx" || echo "⚠️ Gagal download YOLOv10m"

echo "📥 SAM2.1 Model..."
hf download Kijai/sam2-safetensors sam2.1_hiera_base_plus.safetensors --local-dir "$SAM2_DIR" || echo "⚠️ Gagal download SAM2"

echo "=== 6. Download Wan 2.2 Animate & LoRAs ==="
echo "📥 Animate Model (Kijai)..."
hf download Kijai/WanVideo_comfy_fp8_scaled Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors --local-dir "$DIFFUSION_DIR" || echo "⚠️ Gagal"

echo "📥 Relight LoRA..."
hf download Kijai/WanVideo_comfy LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors --local-dir "$LORA_DIR" || echo "⚠️ Gagal"

echo "📥 Lightx2v LoRA..."
hf download Kijai/WanVideo_comfy Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors --local-dir "$LORA_DIR" || echo "⚠️ Gagal"

echo "=== 7. Verifikasi ==="
echo "📂 Isi folder Diffusion Models:"
ls -lh "$DIFFUSION_DIR" | grep -iE "wan2.2|Wan2_2" || echo "⚠️ PERINGATAN: Tidak ada file model Wan 2.2 yang terdeteksi!"

echo ""
echo "✅ PROVISIONING SELESAI!"
echo "💡 Silakan restart ComfyUI Anda agar custom nodes dan model baru terdeteksi."
