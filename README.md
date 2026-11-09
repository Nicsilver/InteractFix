# InteractFix

![InteractFix icon](art/icon-128.png)

Makes the **Interact with Mouseover** key switch to the enemy under your cursor, even while something else is targeted.

## What it fixes

The stock Interact with Mouseover binding keeps your current target. With a target selected, hovering an enemy and pressing the key does nothing useful; with no target it works. InteractFix removes that sticking point so one key does the right thing:

- Enemy under the cursor: targets it and starts attacking (Hunters also start Auto Shot).
- Friendly unit or NPC under the cursor that isn't your target: drops the old target out of the way, so the next press interacts with it.
- Anything else: the key behaves exactly as stock.

Two optional settings (both off by default) also send your pet, see [Settings](#settings).

## Install

InteractFix is built for the WoW Forever client.

- **CurseForge:** install it from the [InteractFix page on CurseForge](https://www.curseforge.com/wow/addons/interactfix), either with the CurseForge app (pick the WoW Forever client) or by downloading the file and unpacking it as described under Manual install.
- **Wago Addons:** download the latest file from the [InteractFix page on Wago Addons](https://addons.wago.io/addons/interactfix) and unpack it as described under Manual install.
- **Manual install:** download the latest zip from the [GitHub releases](https://github.com/Nicsilver/InteractFix/releases) and unpack the `InteractFix` folder into `World of Warcraft/_forever_/Interface/AddOns/`, so that `InteractFix.toc` sits at `AddOns/InteractFix/InteractFix.toc`. You can also clone this repository there as `InteractFix`. Restart the game or type `/reload`.

Then bind a key to **Interact with Mouseover** under Key Bindings > Targeting. The addon follows whichever key you bind, including a second key.

On the first login it turns on the `SoftTargetInteract` console variable once, because the stock interact fallback needs it. It never touches that setting again.

## How it works

`InteractUnit` is a protected function, so an addon can't call it, and can't change your target and interact in the same key press. Instead a secure state driver watches the unit under the cursor. Only while a target would get in the way, it overrides your Interact key with a secure macro button:

- enemy under the cursor: `/target [@mouseover]` plus `/startattack` (and `/petattack [@mouseover,harm,nodead,pet]` with the first pet option)
- non-enemy: `/cleartarget` in combat (always), `/target` out of combat when it isn't already your target
- no unit under the cursor and a hostile target, with the second pet option: `/petattack [@target,harm,nodead,pet]`

With the pet options on and a pet out, two more states get the override (see Settings). In every other state the override is removed and Blizzard's own binding runs. Binding overrides can't change in combat, so the key is read from your bindings outside combat and the secure code picks the button inside it.

## Settings

`/interactfix` opens the InteractFix page in the game's settings (Options > AddOns). Both options are off by default, so nothing changes until you turn one on. Both only act while your pet exists; without a pet the key behaves exactly as above.

- **Pet attacks the enemy under the cursor:** the key sends the pet at a living hostile unit under the cursor, in addition to targeting it and starting your attack. This also covers an enemy under the cursor while you have no target, where the stock key would have handled it.
- **Pet attacks your hostile target when nothing is under the cursor:** with no unit under the cursor and a living hostile target selected, the key sends the pet at that target.

The pet is never sent at a friendly unit, a dead unit or a unit you can't attack.

Secure bindings can't be rewritten in combat. A setting changed during combat is saved at once, InteractFix says so in chat, and it takes effect when combat ends.

With the second option on, the key no longer does the stock interact fallback in that state: while a living hostile target is selected and nothing is under the cursor, pressing it only sends the pet, so it won't loot or use a nearby object. Deselect the target to interact as usual.

## Limits

- Only Hunters get an Auto Shot line. Wand classes don't.
- A friendly unit needs a second press: the first press clears or switches the target, the second interacts.
- In combat the addon can't tell whether the friendly unit under the cursor is already your target, so the first press always clears the target, even if it was that unit.
- Built for the Forever client (interface 16001). Other clients may need changes.
- If another addon rebinds the same key with an override binding, whichever sets it last wins.

## Releasing

Pushing a tag that starts with `v` runs the [BigWigs packager](https://github.com/BigWigsMods/packager) through GitHub Actions. It builds the zip and uploads it to GitHub releases, and to CurseForge and Wago Addons when the `X-Curse-Project-ID` and `X-Wago-ID` lines in the TOC hold real IDs and the `CF_API_TOKEN` and `WAGO_API_TOKEN` repository secrets exist. The release notes come from `CHANGELOG.md`.

## Building the icon

`art/icon.svg` is the source. `python art/build.py <addon folder>` renders it to `icon.tga` (needs `resvg_py` and `pillow`).

## License

MIT, see [LICENSE](LICENSE).
