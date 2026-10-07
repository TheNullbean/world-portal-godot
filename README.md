# World Portal — The Stanley Parable trick in Godot 4

From the Nullbean video **"Are You Really in the Office? (The Stanley Parable)"**.

Two rooms, 100 m apart and 30 m apart in height. One doorway joins them, and you can't tell.

## Try it
1. Open this folder in **Godot 4.7** (Project Manager → Import → pick `project.godot`).
2. Press **F5**. WASD to walk, mouse to look, Esc to free the mouse.
3. Walk out of the office. Then turn around.

## How it works (3 steps, see `world_portal.gd`)
Every portal has a hidden camera and a "screen" (a quad in the door gap).

1. **Hidden camera:** each frame it is placed where you *would* be if you were standing at the partner door:
   `portal_cam = partner * FLIP * this.inverse() * your_camera`
2. **Skip the walls:** the hidden camera's near plane is pushed to the partner doorway, so the walls around it are not drawn.
3. **Teleport:** when your head reaches the doorway, `player.gd` moves you with the same formula. Your view is identical on both sides, so nothing seems to happen.

## Use it in your own scene
- Add `world_portal.gd` to a `Node3D` in a door gap. Its **blue axis (+Z) must point into the room you look from**.
- Add a second one anywhere else (same `size`), set each one's `partner` to the other.
- Copy the portal check at the bottom of `player.gd` into your own player.

## Known limits
- Each visible portal renders the scene again (performance cost).
- No portal-inside-portal (recursion) and no oblique near plane; keep doorways roughly facing the camera.
- Lighting does not travel through portals; light both rooms the same way.

## About the original
The Stanley Parable (2013, Source engine) uses Valve's `linked_portal_door` "world portals" for the same effect: its first map alone has 41 of them, and doors change their destination 76 times during play. Source: the game's own map files and the Valve Developer Community wiki page *linked_portal_door*.

License: MIT (see LICENSE).
