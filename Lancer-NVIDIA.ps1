# GTA VI with the Belobug fork on the RTX 2070 SUPER (8 GB): no ray tracing.
# Series S profile, 1080p output (VICTORY_OUTPUT; the saved settings ask 3840x2160): 3D at 1280x720 upscaled.
# VICTORY_TEXTURE_SPILL=1: once the card's 8 GB are full, textures go to the PC's memory
#   (read by the card over PCIe) instead of staying missing; stops while less than
#   6 GB of commit is left (VICTORY_TEXTURE_SPILL_KEEP_MB), so Windows never runs out.
# VICTORY_AMBIENT_AIR=1 bounds the blue sky light the air holds without rays.
# NVIDIA fixes ported: address space below 4 GiB kept at start (#157),
#   clear rectangles 16 at a time (#185); the compiler guard (#158) is already in.
& "$PSScriptRoot\scripts\play.ps1" -Exe 'D:\victory-data\game\game_scarlett_master.exe' -Console series-s -More @{
    VICTORY_D3D12_ADAPTER = 'NVIDIA'; VICTORY_AMBIENT = '1'; VICTORY_AMBIENT_AIR = '1'
    VICTORY_TEXTURE_SPILL = '1'; VICTORY_TEXTURE_SPILL_KEEP_MB = '6144'
    VICTORY_TEXTURE_ROOM_PERCENT = '95'; VICTORY_WINDOW_MAX = '1920x1080'; VICTORY_OUTPUT = '1920x1080'
} @args
