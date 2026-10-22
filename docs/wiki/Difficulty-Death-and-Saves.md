# Difficulty, death and saves

Game difficulty is independent from the consequences of dying.

| Difficulty | Incoming damage | Hostile health | Needs | Encounters |
| --- | --- | --- | --- | --- |
| Peaceful | None | Wildlife avoids you | No hunger or thirst loss | Story restoration through offerings |
| Easy | 70% | 80% | 60% | Fewer threats |
| Normal | 100% | 100% | 100% | Standard |
| Hard | 135% | 120% | 115% | More threats |
| Insane | 170% | 145% | 135% | Densest threats |

Change game difficulty in Settings during a journey. Death rules stay fixed for that journey.

| Death rule | Result |
| --- | --- |
| Easycore | Return home with carried items. |
| Mediumcore | Carried items stay in one recoverable grave. Camps and stored items remain. |
| Hardcore | The character is permanently retired. Its atlas remains viewable. |

## Saving

Save from the pause menu, use Save and return to title, or close the window. Autosaves run every 60 seconds of active world time. Multiple named journeys are supported.

Saves are stored separately from the installation in `%APPDATA%/Godot/app_userdata/The Mossbound Atlas/journeys`. Each complete generation has a checksum. Writes are validated in a temporary file before replacing the primary; three complete backup generations are kept. A damaged primary automatically falls back to a valid backup. A newer, unsupported save version is not overwritten. Hardcore retirement is also recorded separately so backup recovery does not revive a retired character.

Preserve the entire journeys folder when moving computers. Copying only the game executable does not transfer progress. Keep the complete game ZIP contents together when installing updates.
