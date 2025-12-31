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


def test_recipes_reference_items():
    items = load_json(DATA_DIR / "items.json")
    recipes = load_json(DATA_DIR / "recipes.json")
    for recipe_id, recipe in recipes.items():
        result = recipe["result"]["id"]
        assert result in items, f"{recipe_id} result not in items"
        for ingredient in recipe.get("ingredients", []):
            assert ingredient["id"] in items, f"{recipe_id} ingredient missing"
