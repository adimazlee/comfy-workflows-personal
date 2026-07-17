#!/bin/bash
# =========================================================================
# Custom provisioning script — Velora Wan 2.2 Fun Control & Animate (FINAL)
# =========================================================================
# Hapus 'set -e' agar script tidak mati total jika 1 file gagal, tapi lanjut ke file berikutnya.

echo "=== 1. Mempersiapkan Environment ==="
# Pastikan huggingface-cli terinstall (JAUH lebih stabil daripada curl untuk file besar)
pip install -U "huggingface_hub[cli]"

# Deteksi path ComfyUI secara dinamis
if [ -d "/workspace/ComfyUI" ]; then
    COMFY_DIR="/workspace/ComfyUI"
elif [ -d "/root/ComfyUI" ]; then
    COMFY_DIR="/root/ComfyUI"
elif [ -d "/home/ubuntu/ComfyUI" ]; then
    COMFY_DIR="/home/ubuntu/ComfyUI"
else
    COMFY_DIR="/workspace/ComfyUI"
    mkdir -p "$COMFY_DIR"
fi
echo "✅ Menggunakan direktori ComfyUI di: $COMFY_DIR"

WORKFLOW_DIR="$COMFY_DIR/user/default/workflows"
DIFFUSION_DIR="$COMFY_DIR/models/diffusion_models"
TEXT_ENCODER_DIR="$COMFY_DIR/models/text_encoders"
VAE_DIR="$COMFY_DIR/models/vae"
LORA_DIR="$COMFY_DIR/models/loras"
CLIP_VISION_DIR="$COMFY_DIR/models/clip_vision"

mkdir -p "$WORKFLOW_DIR" "$DIFFUSION_DIR" "$TEXT_ENCODER_DIR" "$VAE_DIR" "$LORA_DIR" "$CLIP_VISION_DIR"

echo "=== 2. Download Workflows (via curl, karena file JSON kecil) ==="
REPO_BASE="https://raw.githubusercontent.com/adimazlee/comfy-workflows-personal/refs/heads/main"
curl -fSLC - "$REPO_BASE/video_wan2_2_14B_fun_control.json" -o "$WORKFLOW_DIR/video_wan2_2_14B_fun_control.json" || echo "⚠️ Gagal download workflow fun control"
curl -fSLC - "$REPO_BASE/template_purz_wan22_animate_auto_character_replace.json" -o "$WORKFLOW_DIR/template_purz_wan22_animate_auto_character_replace.json" || echo "️ Gagal download workflow animate"

echo "=== 3. Download Shared Models (Text Encoder, VAE, Clip Vision) ==="
# Workflow Anda menggunakan wan_2.1_vae dan umt5_xxl standar
echo " Downloading Text Encoder..."
huggingface-cli download Comfy-Org/Wan_2.1_ComfyUI_Repackaged split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors --local-dir "$COMFY_DIR" --local-dir-use-symlinks False || echo "️ Gagal download Text Encoder"

echo "📥 Downloading VAE..."
huggingface-cli download Comfy-Org/Wan_2.1_ComfyUI_Repackaged split_files/vae/wan_2.1_vae.safetensors --local-dir "$COMFY_DIR" --local-dir-use-symlinks False || echo "⚠️ Gagal download VAE"

echo "📥 Downloading Clip Vision..."
huggingface-cli download Comfy-Org/Wan_2.1_ComfyUI_Repackaged split_files/clip_vision/clip_vision_h.safetensors --local-dir "$COMFY_DIR" --local-dir-use-symlinks False || echo "⚠️ Gagal download Clip Vision"

echo "=== 4. Download Wan 2.2 Fun Control Models ==="
# Menggunakan repo 2.2 sesuai nama file di JSON Anda
echo "📥 Downloading Fun Control High Noise..."
huggingface-cli download Comfy-Org/Wan_2.2_ComfyUI_Repackaged split_files/diffusion_models/wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors --local-dir "$COMFY_DIR" --local-dir-use-symlinks False || echo "⚠️ Gagal download Fun Control High Noise"

echo "📥 Downloading Fun Control Low Noise..."
huggingface-cli download Comfy-Org/Wan_2.2_ComfyUI_Repackaged split_files/diffusion_models/wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors --local-dir "$COMFY_DIR" --local-dir-use-symlinks False || echo "⚠️ Gagal download Fun Control Low Noise"

echo "=== 5. Download Wan 2.2 Animate & LoRAs (Kijai) ==="
echo "📥 Downloading Animate Model (Kijai 2.2)..."
# Path spesifik untuk versi 2.2 di repo Kijai
huggingface-cli download Kijai/WanVideo_comfy_fp8_scaled Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors --local-dir "$DIFFUSION_DIR" --local-dir-use-symlinks False || echo "⚠️ Gagal download Animate Model"

echo " Downloading Relight LoRA..."
huggingface-cli download Kijai/WanVideo_comfy LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors --local-dir "$LORA_DIR" --local-dir-use-symlinks False || echo "⚠️ Gagal download Relight LoRA"

echo " Downloading Lightx2v LoRA..."
huggingface-cli download Kijai/WanVideo_comfy Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors --local-dir "$LORA_DIR" --local-dir-use-symlinks False || echo "⚠️ Gagal download Lightx2v LoRA"

echo "=== 6. Memverifikasi File yang Terdownload ==="
echo "📂 Isi folder Diffusion Models:"
ls -lh "$DIFFUSION_DIR" | grep -iE "wan2.2|Wan2_2" || echo "️ PERINGATAN: Tidak ada file model Wan 2.2 yang terdeteksi!"

echo " "
echo "✅ PROVISIONING SELESAI!"
echo "💡 Catatan: Model SAM2 (sam2.1_hiera_base_plus.safetensors) dan ONNX (vitpose/yolov10) akan otomatis didownload oleh ComfyUI Impact Pack/KJNodes saat pertama kali workflow dijalankan."
echo "💡 Silakan restart ComfyUI Anda agar custom nodes dan model baru terdeteksi."
