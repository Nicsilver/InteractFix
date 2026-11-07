# InteractFix

![InteractFix icon](art/icon-128.png)

Makes the **Interact with Mouseover** key switch to the enemy under your cursor, even while something else is targeted.

## What it fixes

The stock Interact with Mouseover binding keeps your current target. With a target selected, hovering an enemy and pressing the key does nothing useful; with no target it works. InteractFix removes that sticking point so one key does the right thing:

- Enemy under the cursor: targets it and starts attacking (Hunters also start Auto Shot).
- Friendly unit or NPC under the cursor that isn't your target: drops the old target out of the way, so the next press interacts with it.
- Anything else: the key behaves exactly as stock.

## Install

Download the latest release zip and unpack the `InteractFix` folder into `World of Warcraft/<client folder>/Interface/AddOns/`, or clone this repository there as `InteractFix`. Then bind a key to **Interact with Mouseover** under Key Bindings > Targeting. The addon follows whichever key you bind, including a second key.

On the first login it turns on the `SoftTargetInteract` console variable once, because the stock interact fallback needs it. It never touches that setting again.

## How it works

`InteractUnit` is a protected function, so an addon can't call it, and can't change your target and interact in the same key press. Instead a secure state driver watches the unit under the cursor. Only while a target would get in the way, it overrides your Interact key with a secure macro button:

- enemy under the cursor: `/target [@mouseover]` plus `/startattack`
- non-enemy that isn't your target: `/cleartarget` in combat, `/target` out of combat

In every other state the override is removed and Blizzard's own binding runs. Binding overrides can't change in combat, so the key is read from your bindings outside combat and the secure code picks the button inside it.

## Limits

- Only Hunters get an Auto Shot line. Wand classes don't.
- A friendly unit needs a second press: the first press clears or switches the target, the second interacts.
- Built for the Forever client (interface 16001). Other clients may need changes.
- If another addon rebinds the same key with an override binding, whichever sets it last wins.

## Building the icon

`art/icon.svg` is the source. `python art/build.py <addon folder>` renders it to `icon.tga` (needs `resvg_py` and `pillow`).

## License

MIT, see [LICENSE](LICENSE).
