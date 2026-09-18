# Making a "Pay Your Tolls compatible" toll gate

> **Do not want to write the file by hand?** Use the free browser tool:
> https://themanhun.github.io/pyt-gate-generator/ -- fill in the form,
> download the generated `.con`, done. This page is the full contract
> behind it.

This is for Transport Fever 2 modders who want to ship their own toll
gate models (Singapore ERP gantries, French péage plazas, anything) and
have Pay Your Tolls count the traffic through them, charge the tolls,
and list them in its Toll Ways table. You write no script and take no
dependency: with Pay Your Tolls absent, your gate is simply a
decoration.

## The one rule

Ship your gate as a normal construction whose file name starts with
`pyt_gate_`:

```
<your mod>/res/construction/asset/pyt_gate_<yourmod>_<gate>.con
```

That prefix is the whole contract. Put YOUR MOD NAME after it, as
shown: two modders who both ship `pyt_gate_erp_gantry.con` would be
shipping the same path, and the game would load only one of them.
`pyt_gate_singapore_tolls_erp_gantry.con` can never collide. Pay Your Tolls scans placed
constructions every ten seconds and treats every `asset/pyt_gate_*.con`
as a toll gate, exactly like its own.

## How the counting works, so your model fits it

- Detection is a circle of 18 metres around the construction's
  position, sampled several times a second for cars, buses and trucks.
  Each vehicle is counted once per 20 seconds as one passage.
- So put the construction's origin on the road centreline, where the
  vehicles actually pass under your gate. If your model's origin is at
  one end of a 30 m plaza, only the half within 18 m counts.
- Vehicles are not stopped or slowed; this is free-flow tolling.
- Pricing, revenue, saves, naming ("Tollway N", renamable) and the UI
  are all Pay Your Tolls'. Your construction cannot change them, which
  is what keeps a broken pack from breaking anyone's save.

## Optional params for the icons

Pay Your Tolls reads three parameters from the placed construction, by
key. All are optional; a gate with none of them still counts, it just
shows no era or layout icon.

| key | uiType | values (index) | meaning |
|---|---|---|---|
| `ways` | COMBOBOX | 0, 1 | 0 = one-way, 1 = two-way |
| `lanes` | COMBOBOX | 0, 1, 2 | lanes each way: 1, 2, 3 |
| `pyt_era` | COMBOBOX | 0, 1, 2, 3 | 1850s, 1920s, 1980s, 1990s icon |

`ways` and `lanes` together pick one of the six layout icons (1w1l to
2w3l) and the label in the table ("4 lane 2 way"). `pyt_era` picks the
era icon. Use whichever indexes your model actually offers; a fixed
single-model gate can simply omit the params.

## A minimal road-less gate

This drops onto an existing road, the way Pay Your Tolls' own 1990s
open-road gantry does. Replace the model id with yours.

```lua
local transf = require "transf"
local vec3 = require "vec3"

function data()
    return {
        type = "STREET_CONSTRUCTION",
        description = {
            name = _("My ERP Gantry"),
            description = _("A toll gantry. Drop it onto a road you own. Pay Your Tolls compatible."),
        },
        availability = { yearFrom = 1998, yearTo = 0 },
        buildMode = "SINGLE",
        skipCollision = true,        -- it sits over an existing street
        snapping = { road = true },  -- placement ghost snaps to the road
        order = 1006,
        autoRemovable = false,

        params = {
            { key = "ways",  name = _("Direction"), uiType = "COMBOBOX",
              values = { _("One way"), _("Two way") }, defaultIndex = 1 },
            { key = "lanes", name = _("Lanes each way"), uiType = "COMBOBOX",
              values = { _("1"), _("2"), _("3") }, defaultIndex = 1 },
            { key = "pyt_era", name = _("Era icon"), uiType = "COMBOBOX",
              values = { _("1850s"), _("1920s"), _("1980s"), _("1990s") }, defaultIndex = 3 },
        },

        updateFn = function(params)
            local result = {}
            result.edgeLists = {}             -- no road of its own
            result.terrainAlignmentLists = {} -- pure overlay
            result.models = {
                {
                    id = "mymod/my_erp_gantry.mdl",
                    transf = transf.scaleRotZYXTransl(
                        vec3.new(1.0, 1.0, 1.0),
                        transf.degToRad(0.0, 0.0, 0.0),
                        vec3.new(0.0, 0.0, 0.0)
                    ),
                },
            }
            result.cost = 65000
            result.bulldozeCost = 5000
            result.maintenanceCost = 150
            return result
        end,
    }
end
```

Save it as `res/construction/asset/pyt_gate_mymod_erp_gantry.con`, ship
your `.mdl`, meshes and materials as usual, and you are done. A gate
that builds its own road works the same way; only the prefix matters.

## Things not to do

- Do not ship a file at one of Pay Your Tolls' own paths
  (`asset/epod_shared_gantry_*.con`, `asset/pyt_toll_booth.con`). It
  would override the real gate for every player who has both mods.
- Do not rename your construction file after publishing. The path is
  what a save references; renaming it removes every placed gate.
- Do not depend on Pay Your Tolls in `mod.lua`. The whole point is that
  your pack works without it.

## Insider Trader

Insider Trader, the companion mod, follows the same rule, so a
compatible gate is counted, synced and shown identically whether a
player runs Pay Your Tolls alone or both mods together.

## Version

Contract version 1, Pay Your Tolls 2 (v1.1, Decision 103). The prefix
and the three param keys will not change meaning; anything added later
will be a new key, never a redefinition.
