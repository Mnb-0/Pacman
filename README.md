# Pacman (x86 MASM)

A console Pacman game written in 32-bit x86 assembly (MASM) using the [Irvine32](http://asmirvine.com/) library and the Win32 `PlaySound` API.

> **Status: work in progress.** The menu, welcome and instruction screens, sound, and level-1 maze rendering are done. The game loop (player and ghost movement, scoring, collisions), level select, and high scores are not implemented yet.

## Done so far

- Centered welcome screen with the intro theme (`winmm.lib` `PlaySound`, async)
- Main menu: Start, Select Level, Instructions, High Scores, Exit
- Level-1 maze drawn from a 30-row × 120-column map
- Data already in place for 3 levels: per-level speeds (150/125/100 ms), ghost spawn positions, 5 ghosts, lives, score, and a high-score file

## Planned

- Game loop with arrow-key movement and wall collision
- Ghost AI, pellet and fruit scoring, lives
- Levels 2–3
- Persistent high scores (`highscores.txt`)

## Building

Requirements: Windows, Visual Studio with the MASM build customization, and Irvine32 installed at `C:\Irvine32`.

1. Open `Pacman.sln` in Visual Studio.
2. Build for **x86 / Debug**.
3. Run from the project directory so the `.wav` files are found.

If Irvine32 is installed somewhere else, update the include and library paths under *Project → Properties*.
