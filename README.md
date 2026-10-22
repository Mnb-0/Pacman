# Pacman (x86 MASM)

A console Pacman game written in 32-bit x86 assembly (MASM), using the [Irvine32](http://asmirvine.com/) library and the Win32 console and `PlaySound` APIs.

## Features

- **3 levels:** each has its own 120×30 maze and gets harder:

  | Level | Ghosts | Ghost speed | Chases Pacman |
  |---|---|---|---|
  | 1 | 2 | 150 ms/step | 60% of moves |
  | 2 | 3 | 125 ms/step | 75% |
  | 3 | 5 | 100 ms/step | 90% |

- **Ghost AI:**
  - Ghosts leave the house one at a time and never reverse unless they're cornered.
  - On each step a ghost either heads straight for Pacman or wanders, with the chase odds above.
- **Power pellets:** the four `O`s turn the ghosts blue for 7 seconds. Blue ghosts are slower and can be eaten.
- **Scoring:**

  | Item | Points |
  |---|---|
  | Dot | 10 |
  | Power pellet | 50 |
  | Blue ghost | 200 |

- **Lives:** you have 3. Losing one resets Pacman and the ghosts, and the dots you've eaten stay eaten.
- **Pause and resume:** P pauses the game. Esc returns to the menu, where **Resume Game** picks up where you left off.
- **High scores:** the top 5 names and scores are saved to `highscores.dat`.
- **Sound:** intro music, chomping, eating power pellets and ghosts, and death.
- **No flicker:** the playfield is drawn with `WriteConsoleOutputCharacter` / `WriteConsoleOutputAttribute`, which don't move the cursor. Drawing the bottom-right cell therefore never scrolls the window.

## Controls

| Key | Action |
|---|---|
| Arrow keys / W A S D | Move. A turn is queued and taken as soon as there's an opening. |
| P | Pause / resume |
| Esc | Back to the menu (the game stays resumable) |

## Building

Requirements:
- Windows
- Visual Studio 2022, or the Build Tools with the **Desktop development with C++** workload (it includes MASM)
- Irvine32, installed at `C:\Irvine32`

**From the command line:**

```bat
build.bat
```

If Irvine32 is somewhere else, set `IRVINE=<path>` first.

**In Visual Studio:**
1. Open `Pacman.sln`.
2. Build for **x86 / Debug**.

Run the game from the project folder so it finds the `.wav` files. The console should be at least 120×30, which is the Windows Terminal default.

## Code layout

Everything is in [`main.asm`](main.asm):

| Part | Procedures |
|---|---|
| Menu and screens | `displayWelcome`, `displayMenu`, `displayInstructions`, `GameOverScreen` |
| Game loop | `GameLoop` runs on a 25 ms tick: `HandleInput` → `MovePlayer` → `MoveGhosts` → `CheckCollisions` → `DrawEntities` |
| Levels | `LoadLevel` copies a maze into `grid` and keeps dots on every other row and column, so the large open mazes stay playable |
| Ghost AI | `ChooseGhostDir` |
| Drawing | `DrawRow`, `DrawCell`, `DrawHud`, `PutChar`, `PutString` |
| High scores | `LoadHighScores`, `SaveHighScores`, `RecordHighScore`, `ShowHighScores` |
