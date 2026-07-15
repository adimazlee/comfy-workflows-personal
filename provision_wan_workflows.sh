#!/bin/bash
# =========================================================================
# Custom provisioning script — Velora Wan 2.2 GPU Instance (FIXED)
# =========================================================================
set -e

WORKFLOW_DIR="/workspace/ComfyUI/user/default/workflows"
DIFFUSION_DIR="/workspace/ComfyUI/models/diffusion_models"
TEXT_ENCODER_DIR="/workspace/ComfyUI/models/text_encoders"
VAE_DIR="/workspace/ComfyUI/models/vae"
LORA_DIR="/workspace/ComfyUI/models/loras"
CLIP_VISION_DIR="/workspace/ComfyUI/models/clip_vision"

mkdir -p "$WORKFLOW_DIR" "$DIFFUSION_DIR" "$TEXT_ENCODER_DIR" "$VAE_DIR" "$LORA_DIR" "$CLIP_VISION_DIR"

echo "[provision_wan] === 1. Download Workflows ==="
REPO_BASE="https://raw.githubusercontent.com/adimazlee/comfy-workflows-personal/refs/heads/main"
download_workflow() {
    local filename="$1"
    echo "[provision_wan] Downloading workflow: $filename"
    if ! curl -fSL "$REPO_BASE/$filename" -o "$WORKFLOW_DIR/$filename"; then
        echo "[provision_wan] ⚠️ GAGAL download workflow $filename"
    fi
}
download_workflow "template_purz_wan22_animate_auto_character_replace.json"
download_workflow "video_wan2_2_14B_fun_control.json"
download_workflow "video_wan2_2_14B_i2v.json"
download_workflow "video_wan2_2_14B_t2v.json"

echo "[provision_wan] === 2. Download Model Files ==="
HF_BASE="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files"

download_model() {
    local url="$1"
    local dest="$2"
    local filename
    filename=$(basename "$dest")
    
    # ✅ PERBAIKAN 1: Cek apakah file adalah file error HTML (ukuran < 10MB)
    if [ -f "$dest" ]; then
        local size=$(stat -c%s "$dest" 2>/dev/null || echo "0")
        if [ "$size" -gt 10000000 ]; then
            echo "[provision_wan] ✅ $filename sudah ada dan valid ($(($size/1024/1024)) MB), skip."
            return 0
        else
            echo "[provision_wan] ⚠️ $filename rusak/terlalu kecil ($(($size/1024)) KB). Menghapus dan download ulang..."
            rm -f "$dest"
        fi
    fi
    
    echo "[provision_wan] ⬇️ Downloading: $filename (Ini bisa memakan waktu 几个 menit untuk file besar...)"
    
    # ✅ PERBAIKAN 2: Tambahkan ?download=true, User-Agent, dan Timeout panjang
    # Hugging Face sering memblokir curl tanpa User-Agent atau mengembalikan HTML
    if ! curl -fSL -A "Mozilla/5.0" --connect-timeout 30 --max-time 3600 "${url}?download=true" -o "$dest"; then
        echo "[provision_wan] ❌ GAGAL download $filename. Cek URL atau koneksi."
        rm -f "$dest" # Hapus file sampah jika gagal
        return 1
    fi
    
    # ✅ PERBAIKAN 3: Validasi akhir
    local final_size=$(stat -c%s "$dest" 2>/dev/null || echo "0")
    if [ "$final_size" -lt 10000000 ]; then
        echo "[provision_wan] ❌ Download selesai tapi file terlalu kecil. Kemungkinan diblokir HF."
        rm -f "$dest"
        return 1
    fi
    
    echo "[provision_wan] ✅ SUKSES: $filename ($(($final_size/1024/1024)) MB)"
}

# --- Shared ---
download_model "$HF_BASE/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "$TEXT_ENCODER_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
download_model "$HF_BASE/vae/wan_2.1_vae.safetensors" \
    "$VAE_DIR/wan_2.1_vae.safetensors"

# --- Fun Control ---
download_model "$HF_BASE/diffusion_models/wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors" \
    "$DIFFUSION_DIR/wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors"
download_model "$HF_BASE/diffusion_models/wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors" \
    "$DIFFUSION_DIR/wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors"

# --- Animate ---
download_model "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors?download=true" \
    "$DIFFUSION_DIR/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"
download_model "$HF_BASE/clip_vision/clip_vision_h.safetensors" \
    "$CLIP_VISION_DIR/clip_vision_h.safetensors"
download_model "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors?download=true" \
    "$LORA_DIR/WanAnimate_relight_lora_fp16.safetensors"
download_model "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors?download=true" \
    "$LORA_DIR/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"

echo "[provision_wan] === ✅ SELESAI! ==="
echo "[provision_wan] Ringkasan file di diffusion_models:"
ls -lh "$DIFFUSION_DIR"
