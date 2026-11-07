# InteractFix

![InteractFix icon](art/icon-128.png)

Makes the **Interact with Mouseover** key switch to the enemy under your cursor, even while something else is targeted.

## What it fixes

The stock Interact with Mouseover binding keeps your current target. With a target selected, hovering an enemy and pressing the key does nothing useful; with no target it works. InteractFix removes that sticking point so one key does the right thing:

- Enemy under the cursor: targets it and starts attacking (Hunters also start Auto Shot).
- Friendly unit or NPC under the cursor that isn't your target: drops the old target out of the way, so the next press interacts with it.
- Anything else: the key behaves exactly as stock.

## Install

InteractFix is built for the WoW Forever client.

- **CurseForge:** install it from the InteractFix page on CurseForge, either with the CurseForge app (pick the WoW Forever client) or by downloading the file and unpacking it as described under Manual install.
- **Wago Addons:** download the latest file from the InteractFix page on Wago Addons and unpack it as described under Manual install.
- **Manual install:** download the latest zip from the [GitHub releases](https://github.com/Nicsilver/InteractFix/releases) and unpack the `InteractFix` folder into `World of Warcraft/_forever_/Interface/AddOns/`, so that `InteractFix.toc` sits at `AddOns/InteractFix/InteractFix.toc`. You can also clone this repository there as `InteractFix`. Restart the game or type `/reload`.

Then bind a key to **Interact with Mouseover** under Key Bindings > Targeting. The addon follows whichever key you bind, including a second key.

On the first login it turns on the `SoftTargetInteract` console variable once, because the stock interact fallback needs it. It never touches that setting again.

## How it works

`InteractUnit` is a protected function, so an addon can't call it, and can't change your target and interact in the same key press. Instead a secure state driver watches the unit under the cursor. Only while a target would get in the way, it overrides your Interact key with a secure macro button:

- enemy under the cursor: `/target [@mouseover]` plus `/startattack`
- non-enemy: `/cleartarget` in combat (always), `/target` out of combat when it isn't already your target

In every other state the override is removed and Blizzard's own binding runs. Binding overrides can't change in combat, so the key is read from your bindings outside combat and the secure code picks the button inside it.

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
