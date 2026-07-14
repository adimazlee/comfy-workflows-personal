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

# ⚠️ CATATAN PENTING: Model Animate (wan2.2_animate_14B_bf16.safetensors) SENGAJA
# belum dimasukkan di sini — kita belum verifikasi 100% nama file & lokasi HF-nya
# yang cocok dengan workflow "template_purz_wan22_animate_auto_character_replace.json"
# punya kamu (nama template ini kelihatan seperti workflow komunitas custom, bukan
# template resmi Comfy-Org). Cek dulu isi JSON-nya (node CheckpointLoader/UNETLoader)
# untuk tau file & sumber pastinya, baru tambahkan baris download_model di sini.

echo "[provision_wan] === Selesai ==="
echo "[provision_wan] Cek hasil: ls -la $WORKFLOW_DIR && du -sh $DIFFUSION_DIR/*"