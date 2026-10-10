# =====================================================================
# windows_build.ps1 - DroidVM CI entry point (GitHub Actions, x64 Windows).
#
# Differences from the upstream entry point:
#   - Runs NON-INTERACTIVELY (no UAC relaunch; the runner is already elevated).
#   - Takes ISO / output paths from environment variables so the workflow
#     drives it, falling back to sane defaults.
#   - Picks the FIRST image index locally (no console prompt in CI).
#   - Points the driver / OpenSSH sources at the upstream defaults.
#
# The heavy lifting stays in the upstream windows/build.ps1 (unmodified).
# =====================================================================
$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# --- inputs (env overrides -> defaults) ---
$env:SRC_ISO      = if ($env:SRC_ISO)      { $env:SRC_ISO }      else { "$env:GITHUB_WORKSPACE\files\win11-arm64.iso" }
$env:OUT_QCOW     = if ($env:OUT_QCOW)     { $env:OUT_QCOW }     else { "$env:GITHUB_WORKSPACE\win11-droidvm.qcow2" }
$env:OUT_VMPKG    = if ($env:OUT_VMPKG)    { $env:OUT_VMPKG }    else { "$env:GITHUB_WORKSPACE\win11-droidvm.vmpkg" }

# Upstream defaults (kept explicit so they are obvious in the CI log).
$env:DRIVERS_DIR   = if ($env:DRIVERS_DIR)   { $env:DRIVERS_DIR }   else { "https://github.com/Droid-VM/gunyah-guest-drivers-windows/releases/download/dev/gunyah-arm64-drivers.zip" }
$env:OPENSSH_SRC   = if ($env:OPENSSH_SRC)   { $env:OPENSSH_SRC }   else { "https://github.com/PowerShell/Win32-OpenSSH/releases/download/10.0.0.0p2-Preview/OpenSSH-ARM64-v10.0.0.0.msi" }

$env:DVM_USERNAME  = if ($env:DVM_USERNAME)  { $env:DVM_USERNAME }  else { "USER" }
$env:DVM_PASSWORD  = if ($env:DVM_PASSWORD)  { $env:DVM_PASSWORD }  else { "DroidVM" }
$env:SSH_PUBKEY    = if ($env:SSH_PUBKEY)    { $env:SSH_PUBKEY }    else { "" }

$env:DISK_SIZE_MB      = if ($env:DISK_SIZE_MB)      { $env:DISK_SIZE_MB }      else { "25600" }
$env:VMPKG_COMPRESSION = if ($env:VMPKG_COMPRESSION) { $env:VMPKG_COMPRESSION } else { "auto" }
$env:EMS_SAC_SOURCE    = if ($env:EMS_SAC_SOURCE)    { $env:EMS_SAC_SOURCE }    else { "skip" }

$env:DRIVER_DIR     = "ZIP/drivers"
$env:DRIVER_INSTALL = "NetKVM rdmapool pvmpower vioinput viostor vioscsi viosnd viofs"
$env:DRIVER_CERT    = "ZIP/DroidVM_Test.cer"

$env:PATH = "C:\Program Files\qemu;" + $env:PATH
$env:QEMU_IMG_INSTALL = "1"

# Optional: compress the qcow2 clusters (zstd) to shrink the on-disk image.
if ($env:COMPRESS_QCOW -and $env:COMPRESS_QCOW -notmatch '^(0|false|no|off)$') { $env:COMPRESS = "1" }

# CI is non-interactive: resolve the image index to the first edition if the
# workflow did not pin one, so build.ps1 never reaches its Read-Host prompt.
if (-not $env:IMAGE_INDEX) { $env:IMAGE_INDEX = "1" }

Write-Host "==== DroidVM Windows builder (CI) ====" -ForegroundColor Cyan
Write-Host "SRC_ISO      = $env:SRC_ISO"
Write-Host "OUT_QCOW     = $env:OUT_QCOW"
Write-Host "OUT_VMPKG    = $env:OUT_VMPKG"
Write-Host "IMAGE_INDEX  = $env:IMAGE_INDEX"
Write-Host "DISK_SIZE_MB = $env:DISK_SIZE_MB"
Write-Host "COMPRESS     = $env:COMPRESS"
Write-Host "======================================" -ForegroundColor Cyan

& "$env:GITHUB_WORKSPACE\win11-arm64-image-builder\windows\build.ps1"
