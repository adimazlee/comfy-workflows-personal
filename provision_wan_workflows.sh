#!/bin/bash
# =========================================================================
# Custom provisioning script — Velora Wan 2.2 GPU Instance
# Gunakan via variabel PROVISIONING_SCRIPT (BUKAN PROVISIONING_COMFYUI_WORKFLOWS)
# karena provisioner_comfyui bawaan gagal parsing multi-URL comma-separated
# (terbukti dari log: "HTTP Error 404" saat mencoba fetch seluruh string
# gabungan 4 URL sebagai satu alamat).
#
# Cara pakai:
#   1. Upload file ini ke repo GitHub kamu (adimazlee/comfy-workflows-personal)
#   2. Set env var PROVISIONING_SCRIPT ke raw URL file ini
#   3. HAPUS / kosongkan PROVISIONING_COMFYUI_WORKFLOWS supaya tidak konflik
# =========================================================================
set -e

WORKFLOW_DIR="/workspace/ComfyUI/user/default/workflows"
DIFFUSION_DIR="/workspace/ComfyUI/models/diffusion_models"
TEXT_ENCODER_DIR="/workspace/ComfyUI/models/text_encoders"
VAE_DIR="/workspace/ComfyUI/models/vae"
LORA_DIR="/workspace/ComfyUI/models/loras"

mkdir -p "$WORKFLOW_DIR" "$DIFFUSION_DIR" "$TEXT_ENCODER_DIR" "$VAE_DIR" "$LORA_DIR"

echo "[provision_wan] === Download 4 workflow JSON ==="
REPO_BASE="https://raw.githubusercontent.com/adimazlee/comfy-workflows-personal/refs/heads/main"

download_workflow() {
    local filename="$1"
    echo "[provision_wan] Downloading workflow: $filename"
    if ! curl -fSL "$REPO_BASE/$filename" -o "$WORKFLOW_DIR/$filename"; then
        echo "[provision_wan] ⚠️  GAGAL download workflow $filename — dilewati, lanjut yang lain"
    fi
}

download_workflow "template_purz_wan22_animate_auto_character_replace.json"
download_workflow "video_wan2_2_14B_fun_control.json"
download_workflow "video_wan2_2_14B_i2v.json"
download_workflow "video_wan2_2_14B_t2v.json"

echo "[provision_wan] === Download model files (ini yang paling lama, ~120GB total) ==="
HF_BASE="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files"

download_model() {
    local url="$1"
    local dest="$2"
    local filename
    filename=$(basename "$dest")
    if [ -f "$dest" ]; then
        echo "[provision_wan] ✅ $filename sudah ada, skip"
        return
    fi
    echo "[provision_wan] Downloading model: $filename"
    if ! curl -fSL "$url" -o "$dest"; then
        echo "[provision_wan] ⚠️  GAGAL download $filename — CEK MANUAL, workflow terkait tidak akan jalan tanpa ini"
    fi
}

# --- Shared: text encoder + VAE (dipakai semua workflow Wan) ---
download_model "$HF_BASE/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "$TEXT_ENCODER_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
download_model "$HF_BASE/vae/wan_2.1_vae.safetensors" \
    "$VAE_DIR/wan_2.1_vae.safetensors"

# --- T2V ---
download_model "$HF_BASE/diffusion_models/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors" \
    "$DIFFUSION_DIR/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors"
download_model "$HF_BASE/diffusion_models/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors" \
    "$DIFFUSION_DIR/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors"

# --- I2V ---
download_model "$HF_BASE/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors" \
    "$DIFFUSION_DIR/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"
download_model "$HF_BASE/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors" \
    "$DIFFUSION_DIR/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"

# --- Fun Control ---
download_model "$HF_BASE/diffusion_models/wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors" \
    "$DIFFUSION_DIR/wan2.2_fun_control_high_noise_14B_fp8_scaled.safetensors"
download_model "$HF_BASE/diffusion_models/wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors" \
    "$DIFFUSION_DIR/wan2.2_fun_control_low_noise_14B_fp8_scaled.safetensors"

# --- Animate (character replace) — sumber BEDA: repo Kijai, bukan Comfy-Org ---
CLIP_VISION_DIR="/workspace/ComfyUI/models/clip_vision"
mkdir -p "$CLIP_VISION_DIR"

download_model "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors" \
    "$DIFFUSION_DIR/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"
download_model "$HF_BASE/clip_vision/clip_vision_h.safetensors" \
    "$CLIP_VISION_DIR/clip_vision_h.safetensors"
download_model "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors" \
    "$LORA_DIR/WanAnimate_relight_lora_fp16.safetensors"
download_model "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" \
    "$LORA_DIR/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"

# ⚠️ CATATAN:
# 1. sam2.1_hiera_base_plus.safetensors TIDAK perlu di-download manual — node
#    "DownloadAndLoadSAM2Model" di workflow ini auto-fetch sendiri saat pertama
#    kali dipakai.
# 2. vitpose-l-wholebody.onnx & yolov10m.onnx — lokasi/repo pastinya tergantung
#    custom node "OnnxDetectionModelLoader" yang dipakai, belum saya konfirmasi
#    exact URL-nya. Setelah workflow ini di-load di ComfyUI, cek apakah 2 model
#    ini juga auto-download seperti SAM2, atau perlu manual — laporkan kalau
#    masih missing setelah "Install Missing Custom Nodes" dijalankan.
# 3. Custom node packages (WanAnimateToVideo, PoseAndFaceDetection, VHS_LoadVideo,
#    dkk) TIDAK di-handle script ini — install lewat ComfyUI Manager >
#    "Install Missing Custom Nodes" setelah workflow di-load pertama kali.

echo "[provision_wan] === Selesai ==="
echo "[provision_wan] Cek hasil: ls -la $WORKFLOW_DIR && du -sh $DIFFUSION_DIR/*"
