# Gaia's releases of stable-diffusion.cpp

Each `gaia-*` tag is published by `.github/workflows/gaia-release.yml` (see
GAIA.md, "Releases"). This file records, per release, what each zip is, how
it was built, the libraries it asks for, and its size and sha256. The sizes
and digests below were read from the published release (its body and
`SHA256SUMS`, written by the release job) and checked against the zips
downloaded back from GitHub with `sha256sum -c SHA256SUMS`; none was typed.
Gaia's recipe rows pin a zip by its url, size and digest, and the tag is the
fork pin.

## gaia-master-1079-a3c49b1-3 (16 November 2026)

- Release: https://github.com/BudEcosystem/stable-diffusion.cpp/releases/tag/gaia-master-1079-a3c49b1-3
- Tag commit: `7d36e560288afea7f948114b5049895cd0ac2c35` (`sd-server --version`
  says `stable-diffusion.cpp version gaia-master-1079-a3c49b1-3, commit 7d36e56`
  in every job). Annotated tag object `74794a78fe59274a685a8b86ee38efd46620507c`.
- Workflow run: https://github.com/BudEcosystem/stable-diffusion.cpp/actions/runs/43812480937
  (every job and the release passed on the first run of this tag).
- Patch-stack base: upstream `master-1079-a3c49b1`, with the six patches of
  GAIA.md's table (`fe1341d`, `34a81ce`, `9ced7a3`, `a52a37a`, `63701a6`,
  `e8831ef`) unchanged from `gaia-master-1079-a3c49b1-1` and `-2`; above them
  only Gaia's own files (`GAIA.md`, `gaia/`, this workflow). Submodules as
  upstream pins them at a3c49b1: ggml `d803c238`, thirdparty/libwebp
  `0c9546f7`, thirdparty/libwebm `5bf12267`, thirdparty/cutlass `ad7b2f5e`.

### The zips

All six are flat zips (`zip -j` of `build/bin`), the layout of the processor
zip Gaia already fetches: `sd-server`, `sd-cli`, `libstable-diffusion.so`,
`libggml.so*`, `libggml-base.so*` (ggml 0.27.0), one `libggml-cpu-<variant>.so`
per processor class, `libwebp.so*`, `libwebpmux.so*`, `libsharpyuv.so*`,
`libwebm.so`, `ggml.txt`, `stable-diffusion.cpp.txt`; a GPU zip adds its
backend library. Every job built on Ubuntu 24.04 (glibc 2.39) with upstream's
`ubuntu-latest-cmake` options: `-DSD_BUILD_SHARED_LIBS=ON -DGGML_NATIVE=OFF
-DSD_BUILD_SHARED_GGML_LIB=ON -DGGML_BACKEND_DL=ON -DGGML_CPU_ALL_VARIANTS=ON
-DSD_SERVER_BUILD_FRONTEND=OFF -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
-DCMAKE_INSTALL_RPATH=$ORIGIN`, Release.

Every asset's url is
`https://github.com/BudEcosystem/stable-diffusion.cpp/releases/download/gaia-master-1079-a3c49b1-3/<asset>`.

| Job | Asset | Size (bytes) | sha256 |
|---|---|---|---|
| linux-x86_64 (processor) | `sd-gaia-master-1079-a3c49b1-3-bin-Linux-Ubuntu-24.04-x86_64.zip` | 27583050 | `093b02b899a94017cd5a99e7feb6d01eccebf4120e843f06a248a97b7c94a6d6` |
| cuda-x64 | `sd-gaia-master-1079-a3c49b1-3-bin-Linux-Ubuntu-24.04-x86_64-cuda-12.8.zip` | 166260553 | `9d495cd041a0451eb6f62e0d71210d5be9b836911cc1ecd53d76377809d9136b` |
| cuda-arm64 | `sd-gaia-master-1079-a3c49b1-3-bin-Linux-Ubuntu-24.04-aarch64-cuda-13.4.zip` | 225168635 | `e7bd610dca0d4f96f0ea41aa95dc17f0393b95dd09a93d2c229e154b56170456` |
| cpu-arm64-v8.0 (processor) | `sd-gaia-master-1079-a3c49b1-3-bin-Linux-Ubuntu-24.04-aarch64.zip` | 23552446 | `8ae1d30dc3880e98522c36405020efa4b8a0fb27e5e1a5111668caddaac184e0` |
| vulkan-x64 | `sd-gaia-master-1079-a3c49b1-3-bin-Linux-Ubuntu-24.04-x86_64-vulkan.zip` | 37951498 | `b6808eb855e80f3d4cb71298e480a669baa87778072805ba45b0cab4a1867f97` |
| rocm-x64 | `sd-gaia-master-1079-a3c49b1-3-bin-Linux-Ubuntu-24.04-x86_64-rocm-10.0.zip` | 256591400 | `0237d09ed6177186631c9b5b9eeeb090c82cfd5027f41edb7d734e7048098da5` |

### What each zip asks for

Read with `readelf -d` over every file (the job logs, and the downloaded zips).
Besides each other's files, every zip asks for libc.so.6, libm.so.6,
libgcc_s.so.1, libstdc++.so.6, libgomp.so.1 and the loader
(ld-linux-x86-64.so.2 or ld-linux-aarch64.so.1), which are in the `system`
list of Gaia's sd.cpp recipe. Beyond those:

| Job | Libraries from outside the zip | Where Gaia gets them |
|---|---|---|
| linux-x86_64 | none | - |
| cpu-arm64-v8.0 | none | - |
| cuda-x64 | libcuda.so.1; libcudart.so.12, libcublas.so.12, libcublasLt.so.12 | the driver; the runtime `cudart-12.8-x64` (llama.cpp b11200's CUDA 12.8 runtime, built from the same `nvidia/cuda:12.8.2` image) |
| cuda-arm64 | libcuda.so.1; libcudart.so.13, libcublas.so.13, libcublasLt.so.13 | the driver; the runtime `cudart-llama-b11200-13.4-arm64` (built from the same `nvidia/cuda:13.4.1` image) |
| vulkan-x64 | libvulkan.so.1 | the machine's Vulkan loader, which finds the machine's drivers |
| rocm-x64 | libamdhip64.so.7, libhipblas.so.3, librocblas.so.5 | the machine's ROCm (the same three the llama.cpp b11200 `ubuntu-rocm-10.0-x64` row asks the machine for; on the Strix Halo's Ubuntu 26.10 they come from the archive's ROCm 10.0, HALO-DISCOVERY §3.1) |

NCCL is off in both CUDA builds (`-DGGML_CUDA_NCCL=OFF`, as llama.cpp's
release builds), so no zip asks for libnccl. `libstable-diffusion.so` carries
its own CUDA kernels (CUTLASS INT8 GEMM, CuTe attention) and asks for the
driver, libcudart and libcublas itself (`readelf -d`: libcuda.so.1,
libcudart.so.1x, libcublas.so.1x; `libggml-cuda.so` adds libcublasLt.so.1x), so
`sd-server` needs the CUDA runtime laid beside it even to print its version.
The ROCm `libstable-diffusion.so` likewise asks for libamdhip64.so.7 and
libhipblas.so.3.

### CUDA

- cuda-x64: CUDA 12.8.2 (`nvidia/cuda:12.8.2-devel-ubuntu24.04`, the image
  llama.cpp b11200's `ubuntu-cuda-12.8-x64` is built in), so a driver that
  states CUDA 12.8 or later runs it. `CMAKE_CUDA_ARCHITECTURES=75-real;80-real;86-real;89-real;90;120-real`.
  `cuobjdump` on `libggml-cuda.so`: SASS sm_75, sm_80, sm_86 (the RTX 3080),
  sm_89, sm_90, sm_120a (ggml turns 12x into its 12xa targets), PTX
  compute_90, which the driver compiles for any newer device (10.x, 11.x,
  12.1). `libstable-diffusion.so`: the same SASS with sm_120 in place of
  sm_120a, PTX compute_90.
- cuda-arm64: CUDA 13.4.1 (`nvidia/cuda:13.4.1-devel-ubuntu24.04` on GitHub's
  `ubuntu-24.04-arm` runner, sbsa; the image of llama.cpp b11200's
  `ubuntu-cuda-13.4-arm64`), a driver stating CUDA 13.4 or later.
  `CMAKE_CUDA_ARCHITECTURES=75-real;80-real;86-real;89-real;90;100-real;110-real;120-real;121-real`.
  `cuobjdump` on `libggml-cuda.so`: SASS sm_75, sm_80, sm_86, sm_89, sm_90
  (Grace Hopper), sm_100 (Grace Blackwell), sm_110 (Thor), sm_120a, sm_121a
  (the GB10), PTX compute_90. This replaces the GB10-only source build
  (compute 12.1 alone): the same zip serves every NVIDIA aarch64 machine of
  compute 7.5 or later.

### The ARMv8.0 processor zip

The aarch64 processor zip holds every ggml processor variant of a Linux
aarch64 build: `armv8.0_1`, `armv8.2_1` (dot product), `armv8.2_2` (+FP16),
`armv8.2_3` (+SVE), `armv8.6_1` (+I8MM), `armv8.6_2` (+SVE2), `armv9.2_1`,
`armv9.2_2` (+SME). ggml's loader scores each against the processor's own
feature bits at run time and loads the best it can run, down to `armv8.0_1`.
Everything loaded whatever the processor (sd-server, sd-cli,
libstable-diffusion, libggml, libggml-base, WebP, WebM and `armv8.0_1`) is
compiled with `-march=armv8-a`. The job checks it: `objdump -d` finds 0 dot
product, int8/bf16 matrix, SVE or half-precision arithmetic instructions in
each of those files, and on an emulated Cortex-A53 (`qemu-aarch64 -cpu
cortex-a53`) `sd-server --list-devices` printed
`load_backend: loaded CPU backend from .../libggml-cpu-armv8.0_1.so` and
`CPU	ARMv8 Processor rev 4 (v8l)`. A Gaia row for it therefore needs no
`cpu_features` condition. GCC 14, because GCC 13 does not know the `sme`
feature of the armv9.2 variants.

### Vulkan

vulkan-x64: upstream's `ubuntu-latest-cmake-vulkan` job (`-DSD_VULKAN=ON`)
in an `ubuntu:24.04` container, with Ubuntu 24.04's `libvulkan-dev`, `glslc`
and `spirv-headers`. One `libggml-vulkan.so` for any Vulkan GPU (AMD, NVIDIA,
Intel); the shaders are compiled into it.

### ROCm and the GPU targets

rocm-x64: ROCm 10.0.0 from AMD's wheels (`rocm[libraries,devel]==10.0.0`
from `https://stable.repo.amd.com/rocm/whl-next/`, TheRock), as upstream
sd.cpp's `ubuntu-latest-rocm` job and llama.cpp b11200's `ubuntu-24-rocm` job
install theirs, `-DSD_HIPBLAS=ON -DHIP_PLATFORM=amd`, the HIP compiler the
wheels' `hipconfig -l` names.

The GPU target list is
`gfx908;gfx90a;gfx942;gfx950;gfx1010;gfx1011;gfx1012;gfx1030;gfx1031;gfx1032;gfx1033;gfx1034;gfx1035;gfx1036;gfx1100;gfx1101;gfx1102;gfx1103;gfx1150;gfx1151;gfx1152;gfx1200;gfx1201`,
and `libggml-hip.so` holds code for each of the 23 (its `amdgcn-amd-amdhsa--gfx*`
bundle names, read in the job). Why this list:

- amd-1's G4 has not recorded a gfx list of its own (HALO-DISCOVERY.md G4
  names rows, not targets). What amd-1 did measure is the Strix Halo's GPU,
  gfx1151 (KFD `gfx_target_version 110501`, HALO-DISCOVERY §1), and the ROCm
  row it measured serving there: llama.cpp b11200's
  `llama-b11200-bin-ubuntu-rocm-10.0-x64.tar.gz`, 86 of 86 cases, the row G4
  puts first (HALO-DISCOVERY §3.1, §6 step 5).
- This list is that row's own target list, as llama.cpp b11200's release
  workflow (`.github/workflows/release.yml`, job `ubuntu-24-rocm`) builds it,
  and the list HALO-DISCOVERY §3.1 read out of that row's `libggml-hip.so`.
  It holds gfx1151, so the zip serves the Halo, and it is a vendor's release
  list rather than one box's value.
- ROCm 10.0.0 for the same reason: it is that row's ROCm and the ROCm of the
  Halo's Ubuntu 26.10, and the zip asks the machine for the same three
  libraries that row does.

Upstream sd.cpp's own Linux list at a3c49b1 (`build.yml`,
`ubuntu-latest-rocm`, ROCm 10.1.0) also has gfx900, gfx906, gfx90c and
gfx1153. They are left out to stay with the row measured on the Halo; they
can be added in a later tag if a Gaia row needs them.

### Not verified here

The zips were built and checked in CI (identity, device code, libraries,
the ARMv8.0 floor). The cuda-x64 zip was run on an RTX 3080 (compute 8.6) for
FORK1 (externals plan, FORK1-REPORT.md). None of the others has been run on
its GPU yet: cuda-arm64 on the GB10, vulkan-x64 and rocm-x64 on the Strix Halo
(amd-1's HALO-DISCOVERY §6 step 8), cpu-arm64-v8.0 on a real ARMv8.0 board.
