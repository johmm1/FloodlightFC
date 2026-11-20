# FloodlightFC

An original 3D football simulation built with Godot 4.5. The current development target is Android, with landscape touch controls and a scalable rendering baseline for mobile hardware.

## Current foundation

- 11 vs 11 match setup: 22 on-pitch players using two team formations
- 3D pitch with markings, goals, simple stadium stands and floodlight fixtures
- Ball rigid-body physics with passing and shooting impulses
- Team movement AI with formation positioning and ball pressure
- Automatic player switching to the nearest home-team player
- Mobile landscape HUD with virtual movement zone, PASS, SHOOT, SPRINT and pause
- Keyboard fallback for desktop testing
- Godot Compatibility renderer selected for broader Android GPU support

## Controls

### Android
- Left lower screen: virtual movement joystick
- Right side: SHOOT, PASS and SPRINT
- Pause button: top-right corner

### Desktop testing
- WASD or arrow keys: move
- Shift: sprint
- J: pass
- K: shoot
- Esc: pause

## Development status

This is the first playable 11v11 foundation, not a finished eFootball-level product. The current player meshes and stadium are lightweight procedural placeholders. The next production stages are:
1. Import and optimize licensed/owned realistic player and stadium GLB assets.
2. Add skeletal locomotion, dribbling, passing, shooting, tackling and goalkeeper animations.
3. Improve ball control, possession, team tactics, goalkeeper logic, fouls and match restarts.
4. Profile on real Android devices, add graphics presets and prepare a signed Android build.

## Build

Open this repository in Godot 4.5 or newer. Configure the Android export templates and Android SDK in Godot Editor before exporting an APK/AAB. No signed APK is included in this source update.
