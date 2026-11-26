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
# Smoothness on NVIDIA (measured, 5-minute runs in the world, 3.3 -> 4.1 fps):
#   VICTORY_CARD_BUFFERS_MIN_KB=64 / _MB=1536: every title buffer from 64 KiB in the card's memory
#     (default on 8 GB cards: 16 MiB and up, 512 MiB in all; the rest crossed the bus at every
#     shader load and atomic). 3.31 -> 3.46 fps, copying back 73 -> 43 ms.
#   VICTORY_D3D12_BACKGROUND=0: the driver stops re-optimising shaders on 4 threads at ~90% each
#     beside the game. 3.46 -> 4.14 fps, preparing 85 -> 57 ms.
#   VICTORY_SUBMIT_FRAMES=2 / VICTORY_SUBMIT_DEPTH=128: the title starts its next frame while ours
#     prepares the last one (default 1: they took turns, 197 ms a frame waiting at presents).
#     4.10 -> 4.59 fps, 0 ms at presents.
# VICTORY_AMBIENT_AIR=1 bounds the blue sky light the air holds without rays.
# NVIDIA fixes: low 4 GiB kept at start (#157), clear rectangles 16 at a time (#185).
# -Faces: the console wave64 program 369cbe906ea72764, which the NVIDIA driver refused at every
#   frame, translated in the fork's wide form for it alone (VICTORY_WAVE_WIDE_ONLY); a candidate
#   for the facial animation. Measured: no device loss in 5 minutes.
param([switch]$NoWarm, [switch]$Faces)
$victory = Join-Path $PSScriptRoot 'target\diag\victory.exe'
if (-not $NoWarm -and (Test-Path $victory)) {
    Write-Host 'Preparing new shaders (warm --used)...'
    $env:VICTORY_D3D12_ADAPTER = 'NVIDIA'
    Push-Location $PSScriptRoot
    try { & $victory warm --used 2>$null | Select-Object -Last 1 } catch { Write-Host "warm skipped: $_" } finally { Pop-Location }
}
# The run's log goes to a file, as in the measured runs: printed in the console window, its
# thousands of lines a minute held the game's threads while the window drew them (stutters).
$logs = 'D:ictory-data\logs'
New-Item -ItemType Directory -Force $logs | Out-Null
$log = Join-Path $logs ('play-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
Write-Host "Starting the game. Its log: $log"
& "$PSScriptRoot\scripts\play.ps1" -Exe 'D:\victory-data\game\game_scarlett_master.exe' -Console series-s -More @{
    VICTORY_D3D12_ADAPTER = 'NVIDIA'; VICTORY_AMBIENT = '1'; VICTORY_AMBIENT_AIR = '1'
    VICTORY_TEXTURE_SPILL = '1'; VICTORY_TEXTURE_SPILL_KEEP_MB = '6144'
    VICTORY_TEXTURE_ROOM_PERCENT = '95'; VICTORY_WINDOW_MAX = '1920x1080'; VICTORY_OUTPUT = '1920x1080'
    VICTORY_PIPELINE_BOOK = '1'; VICTORY_PIPELINE_WAIT_MS = '24'
    VICTORY_CARD_BUFFERS_MIN_KB = '64'; VICTORY_CARD_BUFFERS_MB = '1536'; VICTORY_D3D12_BACKGROUND = '0'
    VICTORY_SUBMIT_FRAMES = '2'; VICTORY_SUBMIT_DEPTH = '128'
    VICTORY_WAVE_WIDE_ONLY = $(if ($Faces) { '369cbe906ea72764' } else { '' })
} *> $log
Write-Host "The game has closed. Its log: $log"
