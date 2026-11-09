# Changelog

## 1.1.1

- Second pet option: the key now also starts your own attack on the target, including while a mouse button is held to turn the camera. Before, only the pet attacked.

## 1.1.0

- New settings page (`/interactfix`, or Options > AddOns > InteractFix) with two options, both off by default.
- Option: the key also sends your pet at the living hostile unit under the cursor, including when you have no target yet.
- Option: with nothing under the cursor, the key sends your pet at your living hostile target. In that state the key no longer does the stock interact fallback.
- Both options need a pet. Changes made in combat are saved at once and take effect when combat ends.

## 1.0.0

- First release.
- The Interact with Mouseover key targets and attacks the enemy under the cursor, even while another unit is targeted.
- A friendly unit or NPC under the cursor that is not your target clears the old target, so the next press interacts with it.
- In combat, a friendly unit under the cursor always clears the target first, so the key keeps working through a whole fight.
- Hunters also start Auto Shot on the enemy.
