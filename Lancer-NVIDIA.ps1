# GTA VI with the Belobug fork on the RTX 2070 SUPER (8 GB): no ray tracing.
# Series S profile, 1080p output (VICTORY_OUTPUT; the saved settings ask 3840x2160): 3D at 1280x720 upscaled.
# Textures: untouched. The title streams its own levels by distance (texLodScale in its settings).
#   VICTORY_TEXTURE_SPILL=1: once the card's 8 GB are full, textures go to the PC's memory
#   instead of staying missing; stops while less than 6 GB of commit is left.
# Shaders, loaded smartly:
#   1. before the game starts, the pipelines earlier runs used and the driver has not built yet
#      are built ahead (warm --used; seconds when nothing is new);
#   2. in game, VICTORY_PIPELINE_BOOK=1 records every new pipeline for the next warm-up;
#   3. VICTORY_PIPELINE_WAIT_MS=24: a frame waits at most 24 ms for a pipeline still being built
#      (500 by default: whole-second freezes); the object shows a frame or two later instead.
# VICTORY_AMBIENT_AIR=1 bounds the blue sky light the air holds without rays.
# NVIDIA fixes: low 4 GiB kept at start (#157), clear rectangles 16 at a time (#185).
param([switch]$NoWarm)
$victory = Join-Path $PSScriptRoot 'target\diag\victory.exe'
if (-not $NoWarm -and (Test-Path $victory)) {
    Write-Host 'Preparing new shaders (warm --used)...'
    $env:VICTORY_D3D12_ADAPTER = 'NVIDIA'
    Push-Location $PSScriptRoot
    try { & $victory warm --used 2>$null | Select-Object -Last 1 } catch { Write-Host "warm skipped: $_" } finally { Pop-Location }
}
& "$PSScriptRoot\scripts\play.ps1" -Exe 'D:\victory-data\game\game_scarlett_master.exe' -Console series-s -More @{
    VICTORY_D3D12_ADAPTER = 'NVIDIA'; VICTORY_AMBIENT = '1'; VICTORY_AMBIENT_AIR = '1'
    VICTORY_TEXTURE_SPILL = '1'; VICTORY_TEXTURE_SPILL_KEEP_MB = '6144'
    VICTORY_TEXTURE_ROOM_PERCENT = '95'; VICTORY_WINDOW_MAX = '1920x1080'; VICTORY_OUTPUT = '1920x1080'
    VICTORY_PIPELINE_BOOK = '1'; VICTORY_PIPELINE_WAIT_MS = '24'
}
