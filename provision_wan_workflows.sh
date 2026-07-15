#!/bin/bash
# =========================================================================
# Custom provisioning script — Velora Wan 2.2 (Robust Version)
# =========================================================================
set -e

# 1. DETEKSI PATH COMFYUI SECARA DINAMIS (Mencegah download ke folder salah)
if [ -d "/workspace/ComfyUI" ]; then
    COMFY_DIR="/workspace/ComfyUI"
elif [ -d "/root/ComfyUI" ]; then
    COMFY_DIR="/root/ComfyUI"
elif [ -d "/home/ubuntu/ComfyUI" ]; then
    COMFY_DIR="/home/ubuntu/ComfyUI"
elif [ -d "/app/ComfyUI" ]; then
    COMFY_DIR="/app/ComfyUI"
else
    echo "❌ ERROR: Direktori ComfyUI tidak ditemukan! Membuat di /workspace/ComfyUI sebagai fallback."
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
SAM2_DIR="$COMFY_DIR/models/sam2"

mkdir -p "$SAM2_DIR"
mkdir -p "$WORKFLOW_DIR" "$DIFFUSION_DIR" "$TEXT_ENCODER_DIR" "$VAE_DIR" "$LORA_DIR" "$CLIP_VISION_DIR"

echo "[provision_wan] === 1. Download Workflows ==="
REPO_BASE="https://raw.githubusercontent.com/adimazlee/comfy-workflows-personal/refs/heads/main"
# Tambahan -C - untuk RESUME download jika putus
curl -fSLC - "$REPO_BASE/video_wan2_2_14B_fun_control.json" -o "$WORKFLOW_DIR/video_wan2_2_14B_fun_control.json"
curl -fSLC - "$REPO_BASE/template_purz_wan22_animate_auto_character_replace.json" -o "$WORKFLOW_DIR/template_purz_wan22_animate_auto_character_replace.json"

echo "[provision_wan] === 2. Download Shared Models ==="
HF_BASE="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files"
curl -fSLC - "$HF_BASE/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" -o "$TEXT_ENCODER_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
curl -fSLC - "$HF_BASE/vae/wan_2.1_vae.safetensors" -o "$VAE_DIR/wan_2.1_vae.safetensors"

echo "[provision_wan] === 3. Download Fun Control Models ==="
curl -fSLC - "$HF_BASE/diffusion_models/wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors" -o "$DIFFUSION_DIR/wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors"
curl -fSLC - "$HF_BASE/diffusion_models/wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors" -o "$DIFFUSION_DIR/wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors"

echo "[provision_wan] === 4. Download Animate Models ==="
curl -fSLC - "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors" -o "$DIFFUSION_DIR/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"
curl -fSLC - "$HF_BASE/clip_vision/clip_vision_h.safetensors" -o "$CLIP_VISION_DIR/clip_vision_h.safetensors"
curl -fSLC - "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors" -o "$LORA_DIR/WanAnimate_relight_lora_fp16.safetensors"
curl -fSLC - "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" -o "$LORA_DIR/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"

echo "[provision_wan] === 5. Download SAM2 Model ==="
curl -fSLC - "https://huggingface.co/Kijai/sam2-safetensors/resolve/main/sam2.1_hiera_base_plus.safetensors" -o "$SAM2_DIR/sam2.1_hiera_base_plus.safetensors"

echo "[provision_wan] === ✅ SELESAI! ==="
echo "[provision_wan] Memverifikasi file yang terdownload..."
ls -lh "$DIFFUSION_DIR" | grep -E "wan2.2|Wan2_2" || echo "⚠️ Peringatan: Beberapa file model mungkin gagal didownload."
