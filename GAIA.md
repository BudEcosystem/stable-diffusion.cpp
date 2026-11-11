# Gaia's fork of stable-diffusion.cpp

This branch (`gaia`) is upstream [leejet/stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp)
at a released tag, plus a short stack of small patches that Gaia's `sd.engine`
needs. Each patch is one commit, written in upstream's own style, additive (a
request that does not use the new field or option behaves byte for byte as
upstream), and could be offered upstream as it stands.

Upstream base: `master-1079-a3c49b1`

## The patches

In order, on top of the base. The commit ids are those of the tag
`gaia-master-1079-a3c49b1-1`; a rebase rewrites the ids, so the subject line is
the stable name of a patch.

| # | Commit | Subject | What it adds | The Gaia need it serves |
|---|---|---|---|---|
| 1 | `fe1341d` | `feat(server): add --path-free-generation-info to keep file-system paths out of generation records` | A server start option: every absolute path, or one that climbs out with `..`, under a `path`/`*_path` key of `generation_info` (API answers and the image text chunk) is written relative to its folder (a LoRA as the path it is requested by) or as a bare file name. | Answers no longer name files of the machine; Gaia's front stops rewriting records (`info.rs`; the sd surface plan, SD2, finding 6). |
| 2 | `34a81ce` | `fix(server): restore the OpenAI edit init-image policy from #2167` | #2167's rule, dropped by #2198: on `/v1/images/edits`, a model without reference conditioning, or a request with a mask or a `strength`, takes the first upload as `init_image`; families declaring a reference preset count as reference-conditioned. | UNet img2img and inpaint edits through the OpenAI route stop silently ignoring their picture (finding 5). |
| 3 | `9ced7a3` | `feat(server): switch ADetailer per request on the OpenAI and native routes` | An `adetailer` request field (on/off) beside `ad_prompt`, `ad_negative_prompt`, `extra_ad_args`, on `/v1/images/generations`, `/v1/images/edits` and `/sdcpp/v1/img_gen`; `true` without `--ad-model` is a parameter error. | A detector copy no longer details every picture; a request chooses (`adetailer: false` was refused with cause `engine`). |
| 4 | `a52a37a` | `feat(server): answer background "transparent" with alpha or a clear refusal` | `background: "transparent"` on the OpenAI routes and `/sdcpp/v1/img_gen`: families whose decoder yields alpha (4 image channels: Qwen Image Layered, Qwen Image 2.1, Ming-Image) return RGBA; every other family is refused by name. `sd_ctx_supports_alpha_output()` in the C API. | Transparent pictures served where the engine draws them, refused by name elsewhere, never a silent opaque picture. |
| 5 | `63701a6` | `feat(server): accept PhotoMaker ID images and PuLID ID embeddings per request` | Request fields `pm_id_images`, `pm_id_embed`, `pm_style_strength`, `pulid_id_embedding`, `pulid_id_weight`; embeddings pass as bytes (C API `id_embed_data`/`id_embedding_data`); the weights stay start-time and their absence is a parameter error. | Identity inputs per request instead of a start-time folder the server never read (sd surface plan 3.8, 3.12). |
| 6 | `e8831ef` | `feat(server): add the /sdcpp/v1/vid_upscale job route` | RelayVSR and SeedVR2 upscaling as a `vid_upscale` job (`--vid-upscale-model`, `--vid-upscale-vae`), through `run_video_upscale()`, which `sd-cli -M vid_upscale` now shares. | Video upscaling through the server instead of a one-shot runner (sd surface plan 3.12, SD17). |

## Moving to a new upstream release

```sh
git fetch upstream --tags
gaia/rebase.sh --check <new tag>   # optional trial: which patches conflict, gaia untouched
gaia/rebase.sh <new tag>
```

`gaia/rebase.sh` runs `git rebase --onto <new tag> <old base tag> gaia`, with the
old base read from the line above. When a patch conflicts it stops and names
that patch and its files: resolve them in the patch's own spirit, `git add`,
`git rebase --continue`, and run `gaia/rebase.sh <new tag>` again. Once the
stack stands on the new tag the script checks that every submodule is
initialised and pinned exactly as upstream pins it, and records the new base
in this file in its own commit.

Then:

1. Build (`cmake -B build -DCMAKE_BUILD_TYPE=Release` plus the backend flags
   Gaia's recipe uses) and run what tests upstream has.
2. Exercise each patch against a running `sd-server` as its commit message
   describes.
3. Update the commit ids in the table above, tag the tip
   `gaia-<new tag>-<serial>` (serial from 1 for each base), and push the branch
   and the tag to `origin` only.

When upstream adopts a patch (or fixes the same thing its own way), drop the
patch during the rebase (`git rebase --skip` at its conflict) and take it out
of the table.

## Releases

`.github/workflows/gaia-release.yml` is Gaia's own workflow. A push to `gaia`
builds the Linux x86_64 processor zip and checks that `sd-server --version`
names the pushed commit. A pushed `gaia-*` tag does the same, then publishes
the zip and its `SHA256SUMS` as the tag's GitHub release. The zip is built on
Ubuntu 24.04 with upstream's `ubuntu-latest-cmake` options and the web frontend
off, so its files carry the names upstream's own release zip uses. Gaia's
recipe reads its url, size and digest from the published release; nothing is
typed. The GB10's variants are compiled from the tag by Gaia itself, so the
workflow builds x86_64 alone. Upstream's `build.yml` is left as upstream has
it.

## The rule

A Gaia change goes in as a new patch: its own commit, on top of the stack, in
upstream's style, touching upstream code only as far as the change needs.
Gaia's own files (`GAIA.md`, `gaia/`, `.github/workflows/gaia-release.yml`) are never mixed into a patch, and a patch
never mixes a Gaia-only behaviour into upstream code. Never push to upstream
from this clone; the fork's remote is `origin`.
