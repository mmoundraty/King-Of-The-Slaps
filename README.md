# King of The Slaps

King of The Slaps is a Roblox game that mixes three classics: King of the Hill, Spleef and a slap battle. Everyone fights over the platforms in the middle of the arena. Standing on one earns you points, and slapping other players off is how you keep it. The floor crumbles under your feet while you do it. Game Link: https://www.roblox.com/games/116487592197166/King-of-The-Slaps

## How a round works

1. **Intermission (15 seconds).** Players wait in the lobby. A round needs at least 3 players to start; until then the timer reads "3 players required to start!".
2. **Spawn.** When the round starts, everyone respawns in a ring around the arena, facing the middle. You're held in the air for 3 seconds with a 3‑2‑1‑GO countdown, so nobody gets a head start.
3. **The round (4 minutes).** Climb the platforms, collect points and slap people off. In the last 60 seconds every point counts double.
4. **Results.** When time runs out, a results screen shows the top three with their avatars, plus runners-up. The rankings boards around the map update with the top 10, and the winner (or winners, on a tie) gets a Win added to their leaderboard stats.

## Scoring

Every second you stand on a platform, you earn points. Higher tiers are worth more:

| Platform | Points per second | Last 60 seconds |
|---|---|---|
| Purple (bottom) | 1 | 2 |
| Green | 2 | 4 |
| Red (top) | 3 | 6 |

If you're on more than one at once, you get the highest one. You don't earn points while you're held in the air after spawning. The current leader glows, and their name shows on everyone's screen, so everyone knows who to go after.

## Slapping and items

Everyone gets the Slap Glove. A slap hits anyone within 7 studs, knocks them back hard and ragdolls them for a moment. It has a 1-second cooldown.

Power-ups spawn on random tiles during the round (about one for every 3 players). Walk over one to pick it up. You can only hold one at a time, and it lasts 20 seconds:

| Power-up | What it does |
|---|---|
| Bazooka | Fires a rocket that explodes and ragdolls anyone caught in the blast |
| Banana Peel | Lobs banana peels at other players |
| Speed Coil | +20 walk speed |
| Gravity Coil | Cuts your gravity to a quarter, for much higher jumps |

There's also Carpet Bombana, which fires a spread of 15 bananas at once. It isn't a normal drop; admins can give it to themselves from the admin panel.

## Admin tools

Players ranked 254 or higher in the game's group get an admin panel. From it they can:

- start or end a round early
- kick a player by name
- ban a player for a number of minutes (`name, minutes`; the default is 5)
- give themselves a Carpet Bombana

## Project layout

The game runs from the Roblox Studio place. `src/` holds the game's scripts as files, sorted by where they live in Studio:

```
src/
├─ server/
│  ├─ ServerScriptService/   game logic: rounds, scoring, spleef tiles, ragdolls, power-ups, admin
│  ├─ ServerStorage/         scripts inside the power-up tools (Bazooka, Banana Peel, coils, Carpet Bombana)
│  └─ StarterPack/           the Slap Glove
├─ client/                   per-player scripts: timer, leader text, results screen, spawn countdown,
│                            spleef tile visuals, knockback, projectile rendering, admin panel
└─ shared/
   └─ GameConfig.luau        settings that the server and client both need
```

File names tell you what kind of script each one is:

- `.legacy.luau`: a server Script
- `.local.luau`: a LocalScript
- `.luau`: a ModuleScript

### The main scripts

- **RoundManager:** the heart of the game. It runs the intermission and round timers, gives out points, tracks the leader, spawns players in the ring, sends the results, updates the rankings boards and hands out wins.
- **SpleefTiles** (server) and **SpleefTilesClient** (client): the server decides when a tile falls and when it can be stood on. Each player's game plays the fade and shrink locally. This keeps the network quiet: the server only sends "this tile is falling" instead of every frame of the animation.
- **PowerupHandler:** spawns power-ups and gives them to whoever touches them.
- **ProjectileManager** and **RenderProjectile:** the server simulates bazooka and banana shots, and each client draws them.
- **RagdollSystem:** briefly turns a character into a ragdoll when they get slapped or blown up.
- **Killbrick:** kills anyone who touches a part tagged `Killbrick`. To make a new hazard, tag a part; no script is needed.
- **Leaderboard:** creates each player's `leaderstats`. `Duration` holds the current round's points and `Wins` holds total wins.
- **AdminAccess** (server) and **AdminPanel** (client): the admin panel.

### Changing settings

Values that both the server and the client rely on live in `src/shared/GameConfig.luau`. Change them there and both sides stay in sync:

| Setting | What it controls |
|---|---|
| `SPAWN_ANCHOR_TIME` | How long players are held in the air at round start (and the countdown length) |
| `RANKING_ABBREVIATIONS` | The "st / nd / rd" after rank numbers |
| `SPLEEF_FADE_TIME` | How long a tile takes to fade out or come back |

Settings that only one script uses stay at the top of that script. For example, round length, intermission length, the player minimum and the double-points window are at the top of `RoundManager`, and tile hold times are at the top of `SpleefTiles`.
