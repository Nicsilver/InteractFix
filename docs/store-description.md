# Store copy

Text for the CurseForge and Wago Addons project pages.

## Summary (under 200 characters)

Makes the Interact with Mouseover key target and attack the enemy under your cursor, even while something else is targeted. For WoW Forever.

## Description

The Interact with Mouseover key keeps your current target. If you have a unit selected and hover an enemy, pressing the key does nothing useful. With no target it works as expected. InteractFix removes that limit, so one key does the right thing in each case.

Bind a key to Interact with Mouseover under Key Bindings > Targeting and use it as usual. The addon follows whichever key you choose, including a second key.

What the key does with InteractFix:

- Enemy under the cursor: targets it and starts attacking. Hunters also start Auto Shot.
- Friendly unit or NPC under the cursor that is not your target: clears the old target, so the next press interacts with it.
- Anything else: the key behaves exactly as it does without the addon.

How it works: interacting and changing target in one key press is blocked for addons, so InteractFix watches the unit under your cursor and swaps your Interact key to a small secure macro button only while a target would be in the way. In every other situation the key is handed back to the game. It works in combat.

On the first login the addon turns on the SoftTargetInteract console variable once, because the game's interact fallback needs it. It never changes that setting again.

Limits:

- Only Hunters get the Auto Shot line.
- A friendly unit needs a second press: the first press clears or switches the target, the second interacts.
- In combat the first press on a friendly unit always clears the target, even if that unit was already your target.
- If another addon sets an override binding on the same key, whichever sets it last wins.
- Built for the WoW Forever client (interface 16001). Other clients may need changes.

Source code and bug reports: https://github.com/Nicsilver/InteractFix

## Feature bullets

- One key to target and attack the enemy under the cursor
- Works while another unit is already targeted
- Friendly units and NPCs: clears the old target so the next press interacts
- Follows your own Interact with Mouseover binding, including a second key
- Works in combat
- No settings, no slash commands, no libraries
- MIT licensed
