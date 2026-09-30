# PYT Gate Generator

Make your own Transport Fever 2 toll gate model work with
[Pay Your Tolls 2](https://steamcommunity.com/sharedfiles/filedetails/?id=3800813265):
counted, charged, named and listed, with no script and no dependency.

**Generator (runs in your browser, nothing is uploaded):**
https://themanhun.github.io/pyt-gate-generator/

Fill in the form, download the generated `.con` file, drop it into your
mod at `res/construction/asset/` with the file name shown, and ship your
model as usual. Without Pay Your Tolls your gate is simply a decoration.

The full contract for hand-written files is in
[PYT_COMPATIBLE_GATES.md](PYT_COMPATIBLE_GATES.md).

## Transport Fever 3

Switch the page to **TF3** for [Pay Your Tolls on Transport Fever 3](https://mod.io/g/transportfever3/m/pay-your-tolls)
(mod.io, including Xbox and PlayStation). In TF3 a toll is found by the placed **model's file name**: any model whose
file name starts with `pyt_gate_` becomes a toll, counted in an 18 m circle around its origin. The TF3 generator writes
a build entry (`.con.lua`, shown under Road Constructions), a self-contained placement script (`.script.lua`) and the
lines for your `_content.json`, with optional Direction / Lanes choices across up to six models.

The page is a single static `index.html`. Pull requests welcome.

## Licence

Free to use and modify in any Transport Fever 2 or 3 mod, with a credit to
"Pay Your Tolls" and a link to its Workshop page or this page. Your own
models and assets stay yours. No dependency required. Full text:
[LICENSE.txt](LICENSE.txt).
