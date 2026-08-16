import json
import sqlite3
import os
import hashlib
import time
from datetime import datetime, timezone

def parse_name(name):
    if not name:
        return "", "Standard"
    name = str(name).strip()
    if name.endswith(")"):
        open_paren_idx = name.rfind("(")
        if open_paren_idx != -1:
            base = name[:open_paren_idx].strip()
            edition = name[open_paren_idx + 1:-1].strip()
            if base and edition:
                return base, edition
    return name, "Standard"

def compute_sha256(filepath):
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        for byte_block in iter(lambda: f.read(65536), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def main():
    json_path = "pinside_database.json"
    sqlite_path = "pinside_database.db"
    bundle_sqlite_path = os.path.join("PinFan", "PinFan", "pinside_database.db")
    version_path = "version.json"
    
    if not os.path.exists(json_path):
        print(f"Error: {json_path} does not exist. Please run the download script first.")
        return
        
    print(f"Reading {json_path}...")
    with open(json_path, 'r', encoding='utf-8') as f:
        machines = json.load(f)
        
    print(f"Loaded {len(machines)} machines.")
    
    # Remove existing db if it exists
    if os.path.exists(sqlite_path):
        os.remove(sqlite_path)
        
    conn = sqlite3.connect(sqlite_path)
    cursor = conn.cursor()
    
    # Create machines table with all schema fields
    cursor.execute("""
    CREATE TABLE machines (
        machine_key INTEGER PRIMARY KEY,
        machine_name TEXT,
        machine_name_formatted TEXT,
        slug_name TEXT,
        machine_abbrev TEXT,
        manuf_name TEXT,
        machine_manufacturer INTEGER,
        machine_year INTEGER,
        machine_manufactured TEXT,
        machine_releasetype TEXT,
        machine_releaseformat TEXT,
        machine_production_status TEXT,
        machine_type TEXT,
        machine_generation INTEGER,
        machine_prodrun INTEGER,
        machine_ipdb INTEGER,
        machine_rating REAL,
        machine_rating_count INTEGER,
        machine_rank INTEGER,
        machine_price_average REAL,
        machine_price_last_updated TEXT,
        machine_visitcount INTEGER,
        machine_display TEXT,
        machine_plunger TEXT,
        machine_cabinet TEXT,
        machine_droptargets INTEGER,
        machine_bumpers INTEGER,
        machine_flippers INTEGER,
        machine_ramps INTEGER,
        machine_captiveballs INTEGER,
        machine_multiball INTEGER,
        machine_magnets INTEGER,
        machine_players INTEGER,
        machine_buyin INTEGER,
        machine_miniorbits INTEGER,
        machine_customspeech INTEGER,
        machine_spindiscs INTEGER,
        machine_kickback INTEGER,
        machine_shakermotor INTEGER,
        machine_playfieldlevels INTEGER,
        machine_spinners INTEGER,
        machine_retheme INTEGER,
        machine_ornament TEXT,
        machine_toys TEXT,
        machine_slogans TEXT,
        machine_comments TEXT,
        image_sha1 TEXT,
        image_rel_path TEXT,
        is_favorite INTEGER DEFAULT 0,
        is_owned INTEGER DEFAULT 0,
        personal_notes TEXT DEFAULT '',
        base_name TEXT DEFAULT '',
        edition_name TEXT DEFAULT ''
    )
    """)
    
    # Also create empty high_scores table schema for fresh installs
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS high_scores (
        score_id INTEGER PRIMARY KEY AUTOINCREMENT,
        machine_key INTEGER,
        score_value INTEGER,
        player_initials TEXT,
        score_date TEXT,
        notes TEXT
    )
    """)
    
    # Base columns from Pinside JSON
    base_columns = [
        "machine_key", "machine_name", "machine_name_formatted", "slug_name", "machine_abbrev",
        "manuf_name", "machine_manufacturer", "machine_year", "machine_manufactured",
        "machine_releasetype", "machine_releaseformat", "machine_production_status",
        "machine_type", "machine_generation", "machine_prodrun", "machine_ipdb",
        "machine_rating", "machine_rating_count", "machine_rank", "machine_price_average",
        "machine_price_last_updated", "machine_visitcount", "machine_display",
        "machine_plunger", "machine_cabinet", "machine_droptargets", "machine_bumpers",
        "machine_flippers", "machine_ramps", "machine_captiveballs", "machine_multiball",
        "machine_magnets", "machine_players", "machine_buyin", "machine_miniorbits",
        "machine_customspeech", "machine_spindiscs", "machine_kickback", "machine_shakermotor",
        "machine_playfieldlevels", "machine_spinners", "machine_retheme", "machine_ornament",
        "machine_toys", "machine_slogans", "machine_comments", "image_sha1", "image_rel_path"
    ]
    
    all_columns = base_columns + ["is_favorite", "is_owned", "personal_notes", "base_name", "edition_name"]
    placeholders = ", ".join(["?"] * len(all_columns))
    insert_sql = f"INSERT INTO machines ({', '.join(all_columns)}) VALUES ({placeholders})"
    
    print("Inserting records into SQLite...")
    records = []
    for m in machines:
        row = []
        for col in base_columns:
            val = m.get(col)
            if isinstance(val, (list, dict)):
                val = json.dumps(val, ensure_ascii=False)
            row.append(val)
            
        # Defaults for user state
        row.append(0) # is_favorite
        row.append(0) # is_owned
        row.append("") # personal_notes
        
        # Computed base_name and edition_name
        name = m.get("machine_name") or ""
        base, edition = parse_name(name)
        row.append(base)
        row.append(edition)
        
        records.append(row)
        
    cursor.executemany(insert_sql, records)
    
    # Create indexes
    print("Creating indexes...")
    cursor.execute("CREATE INDEX idx_machines_name ON machines (machine_name)")
    cursor.execute("CREATE INDEX idx_machines_slug ON machines (slug_name)")
    cursor.execute("CREATE INDEX idx_machines_manuf ON machines (manuf_name)")
    cursor.execute("CREATE INDEX idx_machines_year ON machines (machine_year)")
    cursor.execute("CREATE INDEX idx_machines_rank ON machines (machine_rank)")
    cursor.execute("CREATE INDEX idx_machines_base ON machines (base_name)")
    cursor.execute("CREATE INDEX idx_machines_fav ON machines (is_favorite)")
    cursor.execute("CREATE INDEX idx_machines_owned ON machines (is_owned)")
    cursor.execute("CREATE INDEX idx_highscores_machine ON high_scores (machine_key)")
    
    conn.commit()
    conn.close()
    
    db_size = os.path.getsize(sqlite_path)
    db_sha256 = compute_sha256(sqlite_path)
    now = datetime.now(timezone.utc)
    version_timestamp = int(time.time())
    
    # Generate version.json
    version_info = {
        "version": version_timestamp,
        "last_updated": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "machine_count": len(machines),
        "db_filename": "pinside_database.db",
        "file_size_bytes": db_size,
        "sha256": db_sha256
    }
    
    with open(version_path, 'w', encoding='utf-8') as f:
        json.dump(version_info, f, indent=2)
        
    print(f"SQLite database created successfully at '{sqlite_path}' ({db_size / (1024*1024):.2f} MB).")
    print(f"Generated '{version_path}' (Version {version_timestamp}, SHA256: {db_sha256[:8]}...).")
    
    # If app bundle location exists, sync there too
    if os.path.exists(os.path.dirname(bundle_sqlite_path)):
        import shutil
        shutil.copyfile(sqlite_path, bundle_sqlite_path)
        print(f"Updated app bundle database at '{bundle_sqlite_path}'.")

if __name__ == '__main__':
    main()
