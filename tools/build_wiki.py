"""Build the repository Wiki and recipe reference from the shipped content."""
import argparse
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/wiki'
def read(path):return json.loads(path.read_text(encoding='utf-8'))

def pages():
    data=ROOT/'godot/data';en=read(ROOT/'godot/locale/en.json')
    items=read(data/'items.json');recipes=read(data/'recipes.json');mobs=read(data/'mobs.json');structures=read(data/'structures.json');regions=read(data/'regions.json')
    name=lambda id:en['item.'+id+'.name']
    bag=lambda values:', '.join(f'{name(k)} ×{int(v)}' for k,v in values.items())
    content={}
    content['Home.md']=f'''# The Mossbound Atlas Wiki

Find a path. Make a home. Bring the world together.

An offline, single-player pixel art wilderness RPG. The world is seeded and persistent: your camps, gardens, restored waystones, discoveries and lost belongings remain part of the same journey.

This reference describes the implemented game. Current content includes **{len(items)} items, {len(recipes)} recipes, {len(structures)} building pieces, five regions, 30 discovery sites, 25 creatures, eight travelers and 16 rotating requests**. Repeatable trials open deeper challenges after each completion.

- [First steps](First-Steps.md)
- [World and progression](World-and-Progression.md)
- [Items and crafting](Items-and-Crafting.md)
- [Building and farming](Building-and-Farming.md)
- [Combat and field guide](Combat-and-Field-Guide.md)
- [Requests and expeditions](Requests-and-Expeditions.md)
- [Difficulty, death and saves](Difficulty-Death-and-Saves.md)
- [Controls and languages](Controls-and-Languages.md)
- [Changelog](Changelog.md)
- [Development and licenses](Development-and-Licenses.md)

Download Windows builds from the repository's [Releases](https://github.com/ProgrammingWithYagle/Open_World_Survival_RPG_CODEX/releases). Extract the entire ZIP before launching the game executable.
'''
    content['First-Steps.md']='''# First steps

1. Begin a journey. Pick a name and optional seed. **Normal + Easycore** is the default. Game difficulty and death consequences are independent choices.
2. Speak to Mara, the gray-haired cartographer beside the camp hearth. Your next objective stays on the HUD and in the journal.
3. Gather eight wood and six stone nearby. Interact with a resource to animate a harvest; the character selects the best appropriate owned axe or pick. An equipped weapon can also strike resources.
4. Make a workbench in Crafting, then place it from Building. Nearby storage chests contribute materials automatically. The starter chest contains a small reserve.
5. Gather amber, prepare food and bandages, then follow the eastern trail to the first waystone. Restoring it costs eight wood, six stone and two amber.
6. Choose Bloom, Ember or Gale. Prepare before challenging Old Briar. In Peaceful, make the restoration offering instead of fighting.

The backpack lists what each item does. Use food and water explicitly; items are not consumed automatically. Start a garden, replenish water at a spring or well, and keep spare materials in a chest. If your pack cannot hold an enemy or site reward, it remains as a persistent dropped supply bundle.

Left click places a selected building. Right click or controller B cancels placement. R dismantles the piece under the pointer and returns it when its contents, production queue and incoming deliveries are clear.
'''
    content['World-and-Progression.md']='''# World and progression

The overworld is 1,024 × 1,024 tiles. Chunks stream around you; the seed determines terrain, resources and landmark positions. Roads to the story waystones and discovery sites stay traversable. The atlas begins mostly unexplored; visiting and surveying reveal it.

| Region | Identity and resources | Warden |
| --- | --- | --- |
| Brackenreach | Woodland, berries, wood, mint and amber | Old Briar |
| Reedglass Fen | Marshes, glass reeds, clay, copper and dew gel | The Reedmother |
| Cinderstep | Ashland, iron, sunroots and sunblossom | Cinder Heart |
| Stormpine Heights | Mountain pine, storm shards, sage and wind feathers | The Storm Stag |
| Hollow Meridian | Old courtyards, survey relics, glass and orchids | The Atlas Keeper |

The first three regional victories unlock copper, iron and stormglass crafting. Defeat the first four wardens before facing the Atlas Keeper. The ending preserves your world for continued building, requests, rematches and deeper trials.

Every region has a supply cache, survey tower, three-current seal, spring, returning grove and expedition arch. Search caches once, survey land, match seal inscriptions, or tend a grove once per day. Discoveries stay in the journal.

## Currents

- **Bloom:** faster plant regrowth and garden growth.
- **Ember:** faster queued processing and improved mineral harvests.
- **Gale:** faster travel and lower sprint stamina use.

Currents take effect after restoring the region's waystone. Change the choice by interacting with that waystone again.

Rain and storms follow seeded world-time patterns. Storms and cold mountain rain increase exposure. Shelter, hearths, protective coats and warm provisions help. The game pauses in menus and does not advance while closed.
'''
    item_rows=['# Items and crafting','','Search the backpack and crafting lists by item name. Costs can be paid from your pack and nearby chests. Each recipe lists its tier and station. Processing recipes queue ingredients in the station; collect the output there when ready.','','## Items','','| Item | Kind | Tier | Use |','| --- | --- | --- | --- |']
    for key,value in items.items():item_rows.append(f'| {name(key)} | {value["kind"]} | {value.get("tier",1)} | {en[value["description_key"]]} |')
    item_rows+=['','## Recipes','','| Recipe / result | Materials | Station | Tier |','| --- | --- | --- | --- |']
    for key,value in recipes.items():
        title=en[value['name_key']]+' → ' if 'name_key' in value else ''
        title+=name(value['result']['id'])+' ×'+str(value['result']['count'])
        costs={v['id']:v['count'] for v in value['ingredients']}
        item_rows.append(f'| {title} | {bag(costs)} | {name(value["station"]) if value["station"] else "By hand"} | {value["tier"]} |')
    content['Items-and-Crafting.md']='\n'.join(item_rows)+'\n'
    content['Building-and-Farming.md']='''# Building and farming

Foundations and furnishings occupy separate layers. Place walls, furniture and stations on timber floors, paving or rugs. Gates toggle open and closed. Bridges cross water. Important story landmarks and travelers cannot be blocked by construction.

Hearths and shelters let you set a return point and rest. Lanterns and hearths illuminate the camp after dark. Exposure falls near shelter. Wells and courtyard springs supply drinking water.

## Gardens and food

Plant a seed in a garden, return when it matures, and harvest produce plus one replacement seed. Choose vegetables, grain, berries, reeds, mushrooms or sunroots. Empty, sprouting, growing and mature plots have different artwork. Bloom, the Green Thumb skill and the reed charm shorten growth. A nearby scarecrow adds one crop per harvest.

Grind grain into flour at a mill, then bake flatbread. Cook regional fish after cleaning them into recipe portions. Honey tea, chowder, roasted roots, smoked fish and other provisions offer distinct timed benefits. One charm can be equipped independently of your coat and weapon.

Apiaries produce honey. Fish traps must stand beside water. Their produce takes world time to accumulate.

## Production and couriers

Stations hold up to five queued batches. Ingredients are charged when queued, finished output remains in the station, and dismantling cannot erase work in progress. Ember and a windmill within four tiles reduce processing time by 25% each.

For a courier route, place a board, chest and hearth within three tiles at both ends. Restore the regions containing both camps. Choose a destination board and send the source chest's materials. They remain safe in transit and arrive after 30 seconds of world time. A destination chest cannot be dismantled while a shipment is incoming.

Travel between distant hearths after restoring both regions. Lose nearby enemies before departing.
'''
    combat=['# Combat and field guide','','Aim with the mouse or right stick. Blade and axe favor close combat; spears reach farther; bows and resonance focuses fire projectiles. Attack windups, hits and recovery have distinct animation phases. Dodge before an attack lands, then use the recovery window. Sprinting and actions consume stamina; short recovery delays prevent instant refills.','','Coats, charms, skills and food effects change your preparation. The field guide records observed creatures, kills, behaviors and supplies. These are base Normal statistics; difficulty changes hostile health and incoming damage.','','| Creature | Region | Health | Hit | Pattern | Supplies |','| --- | --- | --- | --- | --- | --- |']
    for key,value in mobs.items():combat.append(f'| {en[value["name_key"]]} | {en[regions[value["region"]]["name_key"]]} | {value["health"]} | {value["damage"]} | {value["pattern"]} | {bag({v["id"]:v["count"] for v in value["drops"]})} |')
    content['Combat-and-Field-Guide.md']='\n'.join(combat)+'\n'
    content['Requests-and-Expeditions.md']='''# Requests and expeditions

Eight travelers offer rotating supply requests. Complete one request per traveler per world day to earn amber, provisions, experience and camp goodwill. Goodwill unlocks more stock in that traveler's trade menu. Rewards and prices are shown before you deliver or buy, and inventory transactions either complete fully or leave your materials untouched.

Expedition arches lead to enclosed regional trials. Survive three waves to earn a cache and unlock the next depth. Later depths increase enemy strength and wave size; scaling is bounded. The pause menu and journal let you withdraw. Death still follows your journey's chosen death rules.

Trial location, wave, defeated enemies and live enemy health are saved. Reloading continues the same expedition. Peaceful players can study the ruins with a stone-and-amber offering instead of combat.

Wardens can be challenged again after victory. You can also collect the field guide, discover all 30 sites, tend groves, catch regional fish, develop farms, furnish camps and connect courier outposts.
'''
    content['Difficulty-Death-and-Saves.md']='''# Difficulty, death and saves

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
'''
    content['Controls-and-Languages.md']='''# Controls and languages

| Action | Keyboard and mouse | Controller |
| --- | --- | --- |
| Move | WASD | Left stick |
| Aim | Mouse | Right stick |
| Interact / gather | E | A |
| Attack / place | Left click | RT |
| Dodge / cancel placement | Space / right click | B |
| Sprint | Shift | Hold left stick click |
| Backpack | Tab | Y |
| Crafting | C | X |
| Atlas | M | Back |
| Cycle tools | 1–4 | LB / RB |
| Bandage / water | 5 / 6 | Backpack item buttons |
| Dismantle | R at the pointer | Right stick click at the controller aim |
| Pause | Escape | Start |

Menus pause the world. Losing focus pauses a normal play session. Use the mouse wheel to zoom the atlas and drag it to pan. The field guide and journal live with the other backpack tabs.

Choose **English, 简体中文, 繁體中文, Español or 日本語** from the title screen or Settings. Item names and descriptions, dialogue, requests, difficulty explanations and the changelog use the selected language. All fonts are bundled for offline use. The language setting applies to the interface; player-written journey names stay as entered.

Settings also contain music, effects, fullscreen, reduced camera motion and game difficulty.
'''
    releases=read(data/'releases.json')
    changes=['# Changelog','']
    for release in releases:
        changes+=['## '+release['version']+' · '+release['date'],'',en[release['text_key']],'']
        changes += ['- '+en[key] for key in release.get('entries',[])]+['']
    content['Changelog.md']='\n'.join(changes)
    content['Development-and-Licenses.md']='''# Development and licenses

The project uses Godot 4.5.1 and its Compatibility renderer. Open `godot/project.godot` to work from source. Runtime logic is separated into core state, activities, world streaming, actors and UI. Content and localization are JSON generated from the authored production scripts.

Run the Python tests, Godot runtime suite and live-scene integration suite before changes are published. Native visual suites capture language layouts and sprite animation at normal and quarter speed. The repository retains source artwork, hashes, audio composition recipes and verification reports. Performance figures apply to the hardware and scenarios recorded in those reports.

Art was created for this project with image generation, then normalized, inspected and revised. It is not represented as hand-drawn. Music is composed from original note/chord sequences and synthesized locally; effects use original synthesis and foley recipes. No copied commercial game sprites or audio samples are included.

The source is under the repository's MIT license. Godot is MIT licensed. Atkinson Hyperlegible, Lora and Noto Sans CJK are bundled under their respective SIL Open Font License texts. See `godot/fonts`, `docs/ASSETS.md`, and the license files in the Windows download.

See [design research](../DESIGN_RESEARCH.md) for the primary sources that informed the game structure, and [implementation status](../IMPLEMENTATION_STATUS.md) for verification limits and remaining work.
'''
    return content

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True)
    failures=[]
    for name,body in pages().items():
        path=OUT/name
        if args.check:
            if not path.exists() or path.read_text(encoding='utf-8')!=body:failures.append(name)
        else:path.write_text(body,encoding='utf-8')
    changelog=pages()['Changelog.md']
    if args.check:
        if not (ROOT/'CHANGELOG.md').exists() or (ROOT/'CHANGELOG.md').read_text(encoding='utf-8')!=changelog:failures.append('CHANGELOG.md')
    else:(ROOT/'CHANGELOG.md').write_text(changelog,encoding='utf-8')
    if failures:raise SystemExit('Wiki is out of date: '+', '.join(failures))
    print('Wiki: 11 pages '+('verified' if args.check else 'built'))

if __name__=='__main__':main()
