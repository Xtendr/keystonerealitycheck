#!/usr/bin/env python3
"""
Keystone Reality Check — Data Aggregator
Fetches Mythic+ run data from Raider.IO and compiles it into Data.lua.
Runs daily via GitHub Actions.
"""

import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

try:
    import requests
except ImportError:
    print("ERROR: 'requests' package required. Install with: pip install requests")
    sys.exit(1)

# ─── Configuration ────────────────────────────────────────────────────────────

RAIDERIO_BASE = "https://raider.io/api/v1/mythic-plus/runs"
SEASON = "season-mn-1"
REGIONS = ["us", "eu", "kr", "tw"]
MAX_PAGES = 10
REQUEST_DELAY = 0.35  # seconds between requests (stays well under 200/min)
MAX_RETRIES = 3

SEASON_DUNGEONS = {
    161: "Skyreach",
    239: "Seat of the Triumvirate",
    402: "Algeth'ar Academy",
    556: "Pit of Saron",
    557: "Windrunner Spire",
    558: "Magisters' Terrace",
    559: "Nexus-Point Xenas",
    560: "Maisara Caverns",
}

BRACKETS = {
    "low":   (2, 7),
    "mid":   (8, 11),
    "high":  (12, 15),
    "elite": (16, 99),
}

# All WoW spec IDs mapped to role for percentage calculation
SPEC_ROLES = {
    # Death Knight
    250: "tank", 251: "melee", 252: "melee",
    # Demon Hunter
    577: "melee", 581: "tank",
    # Druid
    102: "ranged", 103: "melee", 104: "tank", 105: "healer",
    # Evoker
    1467: "ranged", 1468: "healer", 1473: "ranged",
    # Hunter
    253: "ranged", 254: "ranged", 255: "melee",
    # Mage
    62: "ranged", 63: "ranged", 64: "ranged",
    # Monk
    268: "tank", 269: "melee", 270: "healer",
    # Paladin
    65: "healer", 66: "tank", 70: "melee",
    # Priest
    256: "healer", 257: "healer", 258: "ranged",
    # Rogue
    259: "melee", 260: "melee", 261: "melee",
    # Shaman
    262: "ranged", 263: "melee", 264: "healer",
    # Warlock
    265: "ranged", 266: "ranged", 267: "ranged",
    # Warrior
    71: "melee", 72: "melee", 73: "tank",
}


# ─── API Fetching ─────────────────────────────────────────────────────────────

def fetch_runs(region: str, dungeon: str, min_level: int, max_level: int, page: int) -> list:
    """Fetch a page of runs from Raider.IO."""
    params = {
        "season": SEASON,
        "region": region,
        "dungeon": dungeon,
        "page": page,
    }
    for attempt in range(MAX_RETRIES):
        try:
            resp = requests.get(RAIDERIO_BASE, params=params, timeout=30)
            if resp.status_code == 429:
                wait = 2 ** (attempt + 1)
                print(f"  Rate limited, waiting {wait}s...")
                time.sleep(wait)
                continue
            resp.raise_for_status()
            data = resp.json()
            return data.get("rankings", [])
        except requests.RequestException as e:
            if attempt < MAX_RETRIES - 1:
                time.sleep(2 ** attempt)
            else:
                print(f"  ERROR fetching {region}/{dungeon} page {page}: {e}")
                return []
    return []


def dungeon_slug(name: str) -> str:
    """Convert dungeon name to Raider.IO slug format."""
    return name.lower().replace("'", "").replace("-", "").replace(" ", "-").replace(".", "")


# ─── Aggregation ──────────────────────────────────────────────────────────────

def aggregate_data() -> tuple[dict, dict]:
    """Aggregate spec run counts across all regions, dungeons, and brackets.
    Returns (regions_data, activity_to_map) tuple."""
    # Structure: regions[region][mapID][bracket][specID] = run_count
    regions = {}
    # Collect group_finder_activity_ids → map_challenge_mode_id mapping
    activity_to_map = {}

    for region in REGIONS:
        regions[region] = {}
        for map_id, dname in SEASON_DUNGEONS.items():
            regions[region][map_id] = {}
            slug = dungeon_slug(dname)

            for bracket_key, (min_lvl, max_lvl) in BRACKETS.items():
                spec_counts = {}  # specID -> run count
                role_totals = {"melee": 0, "ranged": 0, "healer": 0, "tank": 0}

                print(f"Fetching {region}/{dname}/{bracket_key} ({min_lvl}-{max_lvl})...")

                for page in range(MAX_PAGES):
                    time.sleep(REQUEST_DELAY)
                    rankings = fetch_runs(region, slug, min_lvl, max_lvl, page)

                    if not rankings:
                        break

                    filtered_count = 0
                    for entry in rankings:
                        run = entry.get("run", {})
                        mythic_level = run.get("mythic_level", 0)

                        # Extract activity IDs from dungeon metadata (once per dungeon)
                        dungeon_info = run.get("dungeon", {})
                        for act_id in dungeon_info.get("group_finder_activity_ids", []):
                            activity_to_map[act_id] = dungeon_info.get(
                                "map_challenge_mode_id", map_id
                            )

                        if mythic_level < min_lvl or mythic_level > max_lvl:
                            continue

                        filtered_count += 1
                        roster = run.get("roster", [])
                        for player in roster:
                            char = player.get("character", {})
                            spec = char.get("spec", {})
                            spec_id = spec.get("id")

                            if not spec_id:
                                spec_name = spec.get("name", "")
                                class_name = char.get("class", {}).get("name", "")
                                spec_id = resolve_spec_id(class_name, spec_name)

                            if spec_id and spec_id in SPEC_ROLES:
                                spec_counts[spec_id] = spec_counts.get(spec_id, 0) + 1
                                role = SPEC_ROLES[spec_id]
                                role_totals[role] = role_totals.get(role, 0) + 1

                    if filtered_count == 0:
                        break

                # Calculate role percentages (x10 for integer storage)
                bracket_data = {}
                for spec_id, runs in spec_counts.items():
                    role = SPEC_ROLES.get(spec_id, "melee")
                    total = role_totals.get(role, 1)
                    pct_x10 = round((runs / max(total, 1)) * 1000)  # percentage * 10
                    bracket_data[spec_id] = {"r": runs, "p": pct_x10}

                bracket_data["_runs"] = role_totals.get("tank", 0)
                regions[region][map_id][bracket_key] = bracket_data

    return regions, activity_to_map


# ─── Spec ID Resolution ──────────────────────────────────────────────────────

SPEC_NAME_TO_ID = {
    ("Death Knight", "Blood"): 250,
    ("Death Knight", "Frost"): 251,
    ("Death Knight", "Unholy"): 252,
    ("Demon Hunter", "Havoc"): 577,
    ("Demon Hunter", "Vengeance"): 581,
    ("Druid", "Balance"): 102,
    ("Druid", "Feral"): 103,
    ("Druid", "Guardian"): 104,
    ("Druid", "Restoration"): 105,
    ("Evoker", "Devastation"): 1467,
    ("Evoker", "Preservation"): 1468,
    ("Evoker", "Augmentation"): 1473,
    ("Hunter", "Beast Mastery"): 253,
    ("Hunter", "Marksmanship"): 254,
    ("Hunter", "Survival"): 255,
    ("Mage", "Arcane"): 62,
    ("Mage", "Fire"): 63,
    ("Mage", "Frost"): 64,
    ("Monk", "Brewmaster"): 268,
    ("Monk", "Windwalker"): 269,
    ("Monk", "Mistweaver"): 270,
    ("Paladin", "Holy"): 65,
    ("Paladin", "Protection"): 66,
    ("Paladin", "Retribution"): 70,
    ("Priest", "Discipline"): 256,
    ("Priest", "Holy"): 257,
    ("Priest", "Shadow"): 258,
    ("Rogue", "Assassination"): 259,
    ("Rogue", "Outlaw"): 260,
    ("Rogue", "Subtlety"): 261,
    ("Shaman", "Elemental"): 262,
    ("Shaman", "Enhancement"): 263,
    ("Shaman", "Restoration"): 264,
    ("Warlock", "Affliction"): 265,
    ("Warlock", "Demonology"): 266,
    ("Warlock", "Destruction"): 267,
    ("Warrior", "Arms"): 71,
    ("Warrior", "Fury"): 72,
    ("Warrior", "Protection"): 73,
}


def resolve_spec_id(class_name: str, spec_name: str) -> int | None:
    return SPEC_NAME_TO_ID.get((class_name, spec_name))


# ─── Lua Output ───────────────────────────────────────────────────────────────

def write_lua(regions: dict, activity_to_map: dict, output_path: str):
    """Write the aggregated data as a Lua table to Data.lua."""
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    lines = []
    lines.append(f"-- Auto-generated by scripts/update_data.py — DO NOT EDIT MANUALLY")
    lines.append(f"-- Last updated: {now}")
    lines.append(f"-- Season: {SEASON}")
    lines.append(f"-- Source: Raider.IO API")
    lines.append("")
    lines.append("KeystoneRealityCheckData = {")
    lines.append(f'    updatedAt = "{now}",')
    lines.append(f'    season = "{SEASON}",')
    lines.append("")

    # Dungeon names
    lines.append("    dungeonNames = {")
    for map_id, name in sorted(SEASON_DUNGEONS.items()):
        lines.append(f'        [{map_id}] = "{name}",')
    lines.append("    },")
    lines.append("")

    # Activity ID → challenge mode map ID (for in-game key detection)
    lines.append("    activityToMapID = {")
    for act_id in sorted(activity_to_map.keys()):
        map_id = activity_to_map[act_id]
        dname = SEASON_DUNGEONS.get(map_id, "Unknown")
        lines.append(f"        [{act_id}] = {map_id},  -- {dname}")
    lines.append("    },")
    lines.append("")

    # Regions
    lines.append("    regions = {")
    for region in REGIONS:
        lines.append(f'        ["{region}"] = {{')
        region_data = regions.get(region, {})
        for map_id in sorted(SEASON_DUNGEONS.keys()):
            dungeon_data = region_data.get(map_id, {})
            lines.append(f"            [{map_id}] = {{ -- {SEASON_DUNGEONS[map_id]}")
            for bracket_key in ["low", "mid", "high", "elite"]:
                bracket_data = dungeon_data.get(bracket_key, {})
                if not bracket_data:
                    lines.append(f'                ["{bracket_key}"] = {{}},')
                    continue
                lines.append(f'                ["{bracket_key}"] = {{')
                total_runs = bracket_data.get("_runs", 0)
                if total_runs:
                    lines.append(f"                    _runs = {total_runs},")
                for spec_id in sorted(k for k in bracket_data if isinstance(k, int)):
                    entry = bracket_data[spec_id]
                    lines.append(
                        f"                    [{spec_id}] = {{r={entry['r']}, p={entry['p']}}},"
                    )
                lines.append("                },")
            lines.append("            },")
        lines.append("        },")
    lines.append("    },")
    lines.append("}")
    lines.append("")

    output = Path(output_path)
    output.write_text("\n".join(lines), encoding="utf-8")
    print(f"\nWrote {output} ({len(lines)} lines)")
    if activity_to_map:
        print(f"Activity ID mappings: {len(activity_to_map)}")


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    script_dir = Path(__file__).resolve().parent
    addon_dir = script_dir.parent
    output_path = addon_dir / "Data.lua"

    print(f"Keystone Reality Check — Data Aggregator")
    print(f"Season: {SEASON}")
    print(f"Regions: {', '.join(REGIONS)}")
    print(f"Dungeons: {len(SEASON_DUNGEONS)}")
    print(f"Brackets: {list(BRACKETS.keys())}")
    print(f"Output: {output_path}")
    print()

    regions, activity_to_map = aggregate_data()
    write_lua(regions, activity_to_map, str(output_path))

    # Summary
    total_specs = 0
    for region in regions.values():
        for dungeon in region.values():
            for bracket in dungeon.values():
                total_specs += len(bracket)
    print(f"Total spec entries: {total_specs}")


if __name__ == "__main__":
    main()
