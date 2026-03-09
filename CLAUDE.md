# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VSGames is a multi-game launcher built with [Processing](https://processing.org/) (Java-based creative coding framework). The root directory is the Processing sketch folder. A launcher menu lets the player choose a game; each game is a `GameBase` subclass.

**Current games:** SuperXOX, Nine Men's Morris, Mangala, Reversi, Connect Four, Dots & Boxes, Gomoku, Checkers, Hex

## Build & Run

- **IDE**: Open the root `VSGames` folder in Processing IDE (it will load `VSGames.pde`) and press Run
- **Export to macOS app**: `./export.sh` — requires Processing.app at `/Applications/Processing.app`
- **Run exported app**: `open build/VSGames.app` (use `open -n` for second instance for LAN testing)
- No external dependencies beyond Processing's built-in `processing.net.*` library

## Architecture

All `.pde` files compile into a single Java program sharing the same scope. Processing doesn't support packages/namespaces, so each game uses a prefix on its classes, functions, and constants to avoid collisions.

### Core Files

| File | Role |
|------|------|
| `VSGames.pde` | Entry point: `setup()`, `draw()`, input dispatch, launcher menu UI |
| `GameBase.pde` | Abstract class all games extend: `getName()`, `getColor()`, `init()`, `render()`, `onMousePressed()`, `onKeyPressed()`, `onEscape()` |
| `Effects.pde` | Shared `Particle` class + generic `updateParticles()`/`drawParticles()` helpers |

### Adding a New Game

1. Create files with a unique prefix (e.g., `PNG` for Pong → `PNGGame.pde`, `PNGRenderer.pde`, etc.)
2. Extend `GameBase` in your main game class
3. Register it in `VSGames.pde` → `setup()` → `games` array
4. Update this CLAUDE.md

### SuperXOX (prefix: `SXO`)

Ultimate Tic-Tac-Toe with local 2-player, AI, and LAN multiplayer.

| File | Role |
|------|------|
| `SXOGame.pde` | Game class + state + logic, constants (`SXO_MENU`, `SXO_PLAYING`, etc.) |
| `SXOBoard.pde` | `SXOBoard` — 9×9 board logic, active grid constraint, move validation |
| `SXOSmallBoard.pde` | `SXOSmallBoard` — single 3×3 grid with win/draw detection |
| `SXOAI.pde` | Minimax with alpha-beta pruning (depth 4), free functions (`sxoFindBestMove`, etc.) |
| `SXORenderer.pde` | `SXORenderer` class — all drawing + color constants (`SXO_COLOR_*`) |
| `SXONetwork.pde` | `SXONetwork` class — LAN multiplayer via TCP, hex room codes |

### Nine Men's Morris (prefix: `NMM`)

Three-phase strategy game (place → move → fly) on a 24-node board with mill mechanics.

| File | Role |
|------|------|
| `NMMGame.pde` | Game class + state machine + logic, constants (`NMM_MENU`, `NMM_PLAYING`, etc.) |
| `NMMBoard.pde` | `NMMBoard` — 24 positions, adjacency graph, mill detection, phase management |
| `NMMAI.pde` | Minimax + alpha-beta (depth 4-5), free functions (`nmmFindBestMove`, etc.) |
| `NMMRenderer.pde` | `NMMRenderer` class — board drawing + color constants (`NMM_COLOR_*`) |

### Mangala (prefix: `MNG`)

Turkish mancala — sowing mechanic with capture and extra turn rules.

| File | Role |
|------|------|
| `MNGGame.pde` | Game class + state machine + logic, constants (`MNG_MENU`, etc.) |
| `MNGBoard.pde` | `MNGBoard` — 14 pits (6+store per player), sow/capture/extra-turn logic |
| `MNGAI.pde` | Minimax + alpha-beta (depth 10), free functions (`mngFindBestMove`, etc.) |
| `MNGRenderer.pde` | `MNGRenderer` class — horizontal board + color constants (`MNG_COLOR_*`) |

### Reversi (prefix: `REV`)

Classic Othello — 8×8 board, disc flipping, auto-pass.

| File | Role |
|------|------|
| `REVGame.pde` | Game class + state machine + logic, constants (`REV_MENU`, etc.) |
| `REVBoard.pde` | `REVBoard` — 8×8 grid, 8-direction flip logic, valid move detection |
| `REVAI.pde` | Minimax + alpha-beta (depth 6), positional weight matrix, corner strategy |
| `REVRenderer.pde` | `REVRenderer` class — green board + color constants (`REV_COLOR_*`) |

### Connect Four (prefix: `C4`)

Gravity-based 7×6 board — drop discs, connect 4 to win.

| File | Role |
|------|------|
| `C4Game.pde` | Game class + state machine + drop animation, constants (`C4_MENU`, etc.) |
| `C4Board.pde` | `C4Board` — 7×6 grid, gravity drop, 4-direction win detection |
| `C4AI.pde` | Minimax + alpha-beta (depth 7), center-column bias |
| `C4Renderer.pde` | `C4Renderer` class — blue board + color constants (`C4_COLOR_*`) |

### Dots & Boxes (prefix: `DAB`)

Line-drawing game on 5×5 dot grid — complete boxes for points + extra turns.

| File | Role |
|------|------|
| `DABGame.pde` | Game class + state machine + extra turn logic, constants (`DAB_MENU`, etc.) |
| `DABBoard.pde` | `DABBoard` — horizontal/vertical line tracking, box completion detection |
| `DABAI.pde` | Minimax + alpha-beta (depth 6-8), chain/double-cross strategy |
| `DABRenderer.pde` | `DABRenderer` class — dots/lines/boxes + color constants (`DAB_COLOR_*`) |

### Gomoku (prefix: `GMK`)

Five-in-a-row on 15×15 board.

| File | Role |
|------|------|
| `GMKGame.pde` | Game class + state machine, constants (`GMK_MENU`, etc.) |
| `GMKBoard.pde` | `GMKBoard` — 15×15 grid, 4-direction win detection |
| `GMKAI.pde` | Minimax + alpha-beta (depth 4), threat-based window evaluation, proximity candidates |
| `GMKRenderer.pde` | `GMKRenderer` class — Go-style board + color constants (`GMK_COLOR_*`) |

### Checkers (prefix: `CHK`)

Classic 8×8 checkers with mandatory capture, multi-jump chains, and king promotion.

| File | Role |
|------|------|
| `CHKGame.pde` | Game class + state machine + multi-jump tracking, constants (`CHK_MENU`, etc.) |
| `CHKBoard.pde` | `CHKBoard` — 8×8 grid (values: 0=empty, 1=P1, 2=P2, 3=P1king, 4=P2king), capture logic |
| `CHKAI.pde` | Minimax + alpha-beta (depth 7), piece value + position evaluation |
| `CHKRenderer.pde` | `CHKRenderer` class — checkerboard + color constants (`CHK_COLOR_*`) |

### Hex (prefix: `HEX`)

11×11 hex grid connection game — connect your two edges to win. No draws possible.

| File | Role |
|------|------|
| `HEXGame.pde` | Game class + state machine, constants (`HEX_MENU`, etc.) |
| `HEXBoard.pde` | `HEXBoard` — hex grid with offset coordinates, BFS win detection, neighbor calculation |
| `HEXAI.pde` | Minimax + alpha-beta (depth 3), shortest-path evaluation |
| `HEXRenderer.pde` | `HEXRenderer` class — hexagonal grid rendering, point-in-hex detection + colors (`HEX_COLOR_*`) |

### Key Conventions

- **Player values**: 1 = X, 2 = O, 3 = draw, 0 = empty/ongoing
- **Grid indexing**: Both big grid (9 sub-boards) and small grids (9 cells) use 0-8 index, row-major order
- **Active grid rule**: After a move in cell N, opponent must play in sub-board N (unless won/drawn → free choice, `activeGrid = -1`)
- **Network protocol**: Newline-delimited text (`MOVE:grid:cell\n`, `REMATCH\n`). Room codes = hex-encoded IP addresses
- **AI is always player 2** (O)
- **Canvas**: 800×900 pixels, shared across all games
- **ESC handling**: VSGames.pde intercepts ESC (prevents Processing exit), delegates to active game's `onEscape()`
- **Navigation**: Launcher → Game menu → Playing. ESC goes one level back.
