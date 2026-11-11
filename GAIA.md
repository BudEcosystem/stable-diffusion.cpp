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
| 1 | pending | `feat(server): add --generation-info-paths to keep file-system paths out of generation records` | A server start option: `--generation-info-paths relative` writes every path in `generation_info` (API answers and the image text chunk) relative to its configured folder, or as a bare file name, never as an absolute path or one that climbs out with `..`. | Answers no longer name files of the machine; Gaia's front stops rewriting records (`info.rs`, the sd surface plan SD2, finding 6). |
| 2 | pending | `fix(server): restore the OpenAI edit init-image policy from #2167` | #2167's rule, dropped by #2198: on `/v1/images/edits`, a model without reference conditioning, or a request with a mask or a `strength`, takes the first upload as `init_image`. | UNet img2img and inpaint edits through the OpenAI route stop silently ignoring their picture (finding 5). |
| 3 | pending | `feat(server): switch ADetailer per request on the OpenAI and native routes` | An `adetailer` request field (on/off) beside the existing `ad_prompt`, `ad_negative_prompt`, `extra_ad_args`, on `/v1/images/generations`, `/v1/images/edits` and `/sdcpp/v1/img_gen`. | A detector copy no longer details every picture; a request chooses (`adetailer: false` was refused with cause `engine`). |
| 4 | pending | `feat(server): answer background "transparent" with alpha or a clear refusal` | `background: "transparent"` on the OpenAI routes and `/sdcpp/v1/img_gen`: families whose decoder yields alpha return RGBA; every other family is refused, naming the family. | Transparent pictures are served where the engine draws them, refused by name elsewhere (no silent opaque picture). |
| 5 | pending | `feat(server): accept PhotoMaker ID images and PuLID ID embeddings per request` | Request fields for PhotoMaker ID images (and the v2 ID embeds) and the PuLID ID embedding and weight; the weights stay start-time. | Identity inputs per request instead of one start-time folder (sd surface plan 3.8, 3.12). |
| 6 | pending | `feat(server): add the /sdcpp/v1/vid_upscale job route` | RelayVSR and SeedVR2 video upscaling as an asynchronous job, sharing `sd-cli -M vid_upscale`'s code. | Video upscaling through the server rather than a one-shot runner (sd surface plan 3.12, SD17). |

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

## The rule

A Gaia change goes in as a new patch: its own commit, on top of the stack, in
upstream's style, touching upstream code only as far as the change needs.
Gaia's own files (`GAIA.md`, `gaia/`) are never mixed into a patch, and a patch
never mixes a Gaia-only behaviour into upstream code. Never push to upstream
from this clone; the fork's remote is `origin`.
