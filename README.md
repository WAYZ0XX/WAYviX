# WAYviX

**WAYviX** is a fork of [Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD)
(itself a fork of [VIctory](https://github.com/Marvisak/VIctory)), a compatibility layer
that runs an Xbox Series title natively on Windows from files the user supplies.
This fork is tuned for **NVIDIA cards with 8 GB of video memory** and **32 GB of RAM**.

**This repository contains no game files, code or assets.** You need your own copy
of the game. It is not affiliated with or endorsed by the game's developer or publisher.

## Where it stands (2026-11-27)

Tested on one machine: Windows 11, Intel Core i5-12600KF, 32 GB RAM, NVIDIA
GeForce RTX 2070 SUPER (8 GB), ray tracing off, 40 GB page file.

| | |
|---|---|
| Frame rate in the world | **5-12 fps**, median 129 ms a frame (about 7.5 fps) in 5-minute measured runs |
| Textures | almost all loaded; those that do not fit in the 8 GB are made over the budget and Windows moves them to RAM. The game does not pause for them: a texture not ready yet shows dark for a moment |
| Facial expressions | **not working**: faces stay frozen (see below) |
| Known glitches | simplified (low-poly) characters for a second or two after some camera cuts, while the game streams them; eyes sometimes look glowing white |
| Memory | about 26 GB private; a page file of 40 GB on a drive with room is needed with 32 GB of RAM |

Not working yet on NVIDIA: a few console compute programs written for 64-lane waves,
which the NVIDIA driver refuses (4 programs) or the translator cannot convert
(3 programs). Facial animation is very likely among them.

## What this fork changes

Measured one change at a time, five-minute runs in the world:

| Change | fps |
|---|---|
| Belobug's defaults on the RTX 2070 SUPER | 2.2 |
| New pipelines waited for 24 ms at most per frame (`VICTORY_PIPELINE_WAIT_MS`) | 3.3 |
| Every title buffer from 64 KiB in video memory (`VICTORY_CARD_BUFFERS_MIN_KB`) | 3.5 |
| The driver's background shader work off (`VICTORY_D3D12_BACKGROUND=0`) | 4.1 |
| Two frames in flight (`VICTORY_SUBMIT_FRAMES=2`) | 4.6 |
| `shadow::exact`: host buffers made outside the global lock, idle copies swept amortised | 6.0-6.3 |
| At most 16 ms of texture work a frame, no catch-up, each texture made on its own (`VICTORY_TEXTURE_STAGE_MS=16`, `VICTORY_TEXTURE_CATCHUP=0`, `VICTORY_TEXTURE_POOL=0`) | median 166 -> 129 ms a frame |

Code changes:

- **Textures over the card's budget when it is full** (`VICTORY_TEXTURE_SPILL=1`): textures the
  title fills are made in a default heap past the budget, and Windows moves to RAM what it must,
  instead of staying missing; stops while less than `VICTORY_TEXTURE_SPILL_KEEP_MB` (6144) of
  commit is left. (Made in a system-memory heap of pool L0 instead, `VICTORY_TEXTURE_SPILL_POOL=pc`,
  some showed as coloured noise on the RTX 2070 SUPER.) Aliasing barriers are given only to
  textures placed in a block (NVIDIA refused the list otherwise).
- **Translation threads no longer queue on one lock** (`shadow::exact`).
- **NVIDIA fixes ported** from Belobug pull requests: address space below 4 GiB kept at start
  (#157), clear rectangles 16 at a time (#185).
- **`VICTORY_WAVE_WIDE_ONLY=<hash>,...`**: the wide wave64 form for listed shaders alone.
- **`scripts/play.ps1 -Console series-s|series-x`**.

## How to run it

1. Build: `cargo build --locked --profile diag -p victory --features diagnostics`
2. Copy `victory.example.toml` to `victory.toml` and set your paths (outside this folder).
3. Use a page file whose initial size is its maximum (40 GB here): the overflow's safety check
   reads the limit Windows has now, not the one it may grow to.
4. Prepare the shaders once: `target\diagictory.exe shaders <the shader archives>`,
   then `target\diagictory.exe warm` (all known pipelines, about an hour once).
5. In the NVIDIA Control Panel, set **Shader Cache Size** to **Unlimited**.
6. Edit the game path in `Lancer-NVIDIA.ps1`, then run it from a normal (not administrator)
   PowerShell window. It builds new pipelines first (`warm --used`), then starts the game with
   every setting above.

---

# Upstream notes (Belobug/VIctory-Belobug-AMD)

The rest of this file is Belobug's README, kept as it was.


A fork of [VIctory](https://github.com/Marvisak/VIctory), a compatibility layer
that runs an Xbox Series title natively on Windows from files the user supplies.

## The goal

**A stable 30 fps or more without ray tracing, then as high a frame rate and as
low frame times as the PC allows**, on an AMD RX 7900 XTX first and on PCs with
32 GB (later 16 GB) of RAM.

The way there is **porting, not emulating**: patching the title's renderer so it
behaves the way a PC renderer does, rather than having the layer watch and copy
the console's shared memory every frame. Shaders are translated ahead of time
into a versioned store that is kept between builds. Ray tracing stays optional
and off by default. The picture comes after the frame rate: texture pop-in and
lighting that is too bright or too dark when walking indoors are next in line.

**This repository contains no game files, code or assets.** You need your own
copy of the game. It is not affiliated with or endorsed by the game's developer
or publisher.

## Where it stands (2026-11-26)

Tested on one machine only: Windows 11, Intel i9-12900K, 64 GB RAM, Radeon
RX 7900 XTX, ray tracing off.

| | |
|---|---|
| City street, Series S profile, renderer patches 1, 2, 5, 6 and 7 on | about 45 ms a frame (about 22 fps, 44.9 ms in run merge-5) |
| Same, patches 1, 2, 5 and 6 | 45.6 ms, p95 47 ms |
| Same, patches 1, 2 and 5 | 47.3 ms (about 21 fps), p95 49 ms |
| Series X profile, patches 1+2 | about 53 ms (about 19 fps) |
| Same scene before the patches | 57-75 ms (13-17 fps) |
| Shaders the title uses that translate | all of them (25,790 of 25,985; the rest are unused geometry shaders) |
| Memory | about 30 GB of private memory, 10.5 GB of VRAM: **64 GB of RAM recommended** for now |

It started at 280 ms a frame in the same scenes three days earlier. What sets
the frame now is the one thread that submits the title's work to the card
(about 40 ms); the card itself needs about 36 ms and now waits about 7 ms a frame with nothing queued.

### Renderer patches (off by default while they are tested)

| Switch | What it does |
|---|---|
| `VICTORY_PORT_CONSTANTS=1` | The title's 174 MB constants heap is read by the card where the title writes it: no uploads, no fills |
| `VICTORY_PORT_DESCRIPTORS=1` | The title's descriptor-table stores are patched (byte-checked) to report the slots they write, instead of a scan of ~600,000 slots a frame |
| `VICTORY_PORT_CBV=1` | Translated shaders read constant buffers in place as raw bytes (~22,000 fills a frame to none; -4.7 ms) |
| `VICTORY_PORT_GUARD=1` | The write guards' lock is shared by faults and refreshes, with a claim per 64 KiB block; the submission's planning runs beside it (title threads' waits 29 ms to ~2 ms a frame; -2 ms) |
| `VICTORY_PORT_JOURNAL=1` | The heaps' records are asked for at the title's submit, and the journal's notes are split into 64 parts with locks of their own (the submit thread's waits ~5 ms + 1 ms to ~0.3 ms; -1 to -3 ms) |

### Other switches

| Switch | What it does |
|---|---|
| `--console series-s` | The Series S profile: 1080p output, about 5 ms faster, a softer picture |
| `VICTORY_OUTPUT=1920x1080` | The title renders to that output size itself (Series X profile; about 16 ms less card time) |
| `VICTORY_FRAME_INTERVAL_MS=16.667` | Lets the title go above 30 fps (menus and videos reach 60; the game's clock stays right) |
| `VICTORY_AMBIENT_SETTLE` | How fast light settles after walking indoors (on by default, `250,3`; `0` turns it off) |
| `VICTORY_TEXTURE_STORE=1` | Converted textures kept between runs (about 8 ms a frame for now: off) |

What is known to be wrong:

- Trees, signs and far objects flicker in the distance in some places.
- Lighting is too bright or too dark after walking indoors, until the title has
  run for a while; rooms with little direct light are too dark without `-RayTracing`.
- Textures of what just came into view appear late while the title streams.
- The first run of a new build stutters while the driver makes pipelines
  (`victory warm` makes them ahead).
- Recording a frame in the world makes the title's own watchdog end it.

## How to run it

You need Windows 10/11 x64, a CPU with AVX2, a Direct3D 12 GPU with shader
model 6.6 and mesh shaders, Rust (the toolchain is pinned), the MSVC build
tools, and your own dump of the title.

```powershell
git clone https://github.com/avatarmanz/VIctory-7900XTX
cd VIctory-7900XTX
copy victory.example.toml victory.toml      # then set your paths, outside this folder
cargo build --locked --profile diag -p victory --features diagnostics
scripts\play.ps1 -Exe <path of your copy's executable>
```

`scripts\play.ps1 -Safe` leaves out the newest, faster ways; try it first when
something is wrong. `-RayTracing` turns the title's ray-traced indirect light on.

For PC FSR 4.1.2, set `[paths].fidelityfx_dir` in `victory.toml` or
`VICTORY_FIDELITYFX_DIR` to the folder containing AMD's signed
`amd_fidelityfx_upscaler_dx12.dll`. Use the DirectX 12 upscaler in
`Kits/FidelityFX/signedbin`. [AMD FSR SDK 2.4.0](https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/tree/v2.4.0/Kits/FidelityFX/signedbin)

`scripts\play.ps1 -Exe <path> -Fsr4K quality` selects 2560×1440 input for
the retail 1.0.2.1 Series X 4K SDR profile. `balanced` selects 2258×1270
and `performance` selects 1920×1080. All three output 3840×2160. With
`victory run` directly, set `VICTORY_FSR_4K` to the preset name.
The log reports the provider at context creation and the actual input and
output sizes at the first successful temporal dispatch. The title profile
and PC FidelityFX bridge were ported from [DexNom/VIctory](https://github.com/DexNom/VIctory/commit/ab34a8b21477c94da2a6cf07249138e8bc84602e).

On a hybrid-graphics PC, the runtime and offline pipeline checks prefer a
high-performance adapter with Shader Model 6.6. The runtime logs its adapter
name, PCI vendor and device IDs, and dedicated VRAM. Set
`VICTORY_D3D12_ADAPTER` to a zero-based DXGI index or part of the adapter's
name to select it explicitly. With the launcher, pass
`-More @{VICTORY_D3D12_ADAPTER='NVIDIA'}`.

Before the first run, ahead of time (both can be stopped and go on later):

```powershell
target\diag\victory.exe shaders <the shader archives>   # every shader translated, minutes
target\diag\victory.exe warm --used                     # pipelines earlier runs drew with, for a new driver or build
```

Commands, debugging switches and upstream's own description:
[docs/README-fxceless.md](docs/README-fxceless.md). Every `VICTORY_...` switch is
described in a comment where it is read.

## What is different here

In short; the reasons and the measurements are in [docs/findings.md](docs/findings.md).

- **List calls are written down, not carried out, on the title's threads**
  (`VICTORY_THIN`): eight threads of ours translate them.
- **Submissions are prepared by a thread of ours and joined**
  (`VICTORY_ASYNC_SUBMIT`, `VICTORY_JOIN_PARTS`), with what can be spread over
  threads spread: refreshes, compares (AVX2), descriptor records, landings.
- **What shaders wrote comes back beside the write guards**, by the dwords that
  changed, on a thread of its own (`VICTORY_RELAY`, `VICTORY_LAND`).
- **Buffer fills that need bytes still on the card are done on the card**
  (`VICTORY_CARD_STEPS`) instead of waiting for it.
- **The title's writes are caught more cheaply**: one view opened at a fault,
  blocks that rest, places in the title's code that look before they write.
- **Textures go up on a copy queue of their own** and a slot shows one only after
  its upload ran, which also ended a device loss that came every 15 minutes or so.
- **Boats float**: textures that shaders write and the title's CPU reads go back
  to title memory (from fxceless and Geckomacabre, on by default here).
- **Frame record and replay** with per-pass times and shader variants compared
  turn by turn ([docs/replay.md](docs/replay.md)).

## Credits

This is a tree of other people's work with more on top. The history is kept, and
commits taken from elsewhere name the commit and its author.

- **[VIctory](https://github.com/Marvisak/VIctory)** by Marvisak and its
  contributors: the loader, the runtime services, the Direct3D 12 back end and
  the shader recompiler.
- **[fxceless/victory-fork](https://github.com/fxceless/victory-fork)**: the fork
  this one started from, and the people whose pull requests it carries.
- **[DexNom/VIctory](https://github.com/DexNom/VIctory)**: ray tracing fixes,
  cube gradients, sparse textures.
- **[Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD)**:
  the ambient light idea, pipeline workers, and work by romainhedouin.
- **[FQY55kai/ZJOU-VICTORY](https://github.com/FQY55kai/ZJOU-VICTORY)**.
- **[myokex/victory-amd](https://github.com/myokex/victory-amd)**: the guard over
  every view of a page (with Spexivus, joroyt and tightfall), and Joshua Odom's
  reads into title memory.
- **Geckomacabre** and **cxy0072019-sketch**: the texture read-back.
- **[XCL](https://github.com/ivall/xcl)** (GPL-2.0-only) was read for how the same
  title behaves under another layer; no code of it is here.
- This fork's changes were made with [Claude Code](https://claude.com/claude-code).

## License

GPL-3.0-or-later, as VIctory. See [LICENSE](LICENSE); the one file that is not
covered is named in [docs/asset-policy.md](docs/asset-policy.md).
