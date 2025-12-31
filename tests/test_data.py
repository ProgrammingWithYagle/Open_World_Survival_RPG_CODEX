import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "godot" / "data"


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def test_item_data_is_valid():
    items = load_json(DATA_DIR / "items.json")
    assert items, "items.json should not be empty"
    for item_id, item in items.items():
        assert "name" in item, f"{item_id} missing name"
        assert "stack" in item, f"{item_id} missing stack"
        assert item["stack"] > 0, f"{item_id} stack must be positive"
        if "effects" in item:
            assert isinstance(item["effects"], dict), f"{item_id} effects must be a dict"
            for effect_key, value in item["effects"].items():
                assert effect_key in {"hunger", "thirst", "temperature", "health"}, (
                    f"{item_id} has unsupported effect {effect_key}"
                )
                assert isinstance(value, (int, float)), f"{item_id} effect {effect_key} must be numeric"


def test_recipes_reference_items():
    items = load_json(DATA_DIR / "items.json")
    recipes = load_json(DATA_DIR / "recipes.json")
    for recipe_id, recipe in recipes.items():
        result = recipe["result"]["id"]
        assert result in items, f"{recipe_id} result not in items"
        assert recipe["result"]["count"] > 0, f"{recipe_id} result count must be positive"
        for ingredient in recipe.get("ingredients", []):
            assert ingredient["id"] in items, f"{recipe_id} ingredient missing"
            assert ingredient["count"] > 0, f"{recipe_id} ingredient count must be positive"


def test_mob_data_is_valid():
    items = load_json(DATA_DIR / "items.json")
    mobs = load_json(DATA_DIR / "mobs.json")
    assert mobs, "mobs.json should not be empty"
    valid_behaviors = {"passive", "aggressive", "ranged", "patrol"}
    for mob_id, mob in mobs.items():
        assert "name" in mob, f"{mob_id} missing name"
        assert mob["behavior"] in valid_behaviors, f"{mob_id} behavior invalid"
        assert mob["health"] > 0, f"{mob_id} health must be positive"
        assert mob["speed"] > 0, f"{mob_id} speed must be positive"
        assert mob["aggro_range"] >= 0, f"{mob_id} aggro range must be non-negative"
        assert mob["attack_range"] >= 0, f"{mob_id} attack range must be non-negative"
        assert mob["attack_cooldown"] > 0, f"{mob_id} cooldown must be positive"
        assert mob["damage"] >= 0, f"{mob_id} damage must be non-negative"
        assert mob["biomes"], f"{mob_id} biomes list must not be empty"
        for drop in mob.get("drops", []):
            assert drop["id"] in items, f"{mob_id} drop {drop['id']} missing in items"
            assert drop["count"] > 0, f"{mob_id} drop count must be positive"
