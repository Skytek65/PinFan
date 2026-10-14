import urllib.request
import json
import sqlite3
import os
import re

def normalize_name(s):
    s = str(s or '').strip()
    if s.endswith(', The'):
        s = 'The ' + s[:-5]
    elif s.endswith(', A'):
        s = 'A ' + s[:-3]
    # Remove parens edition info for matching base
    s = re.sub(r'\s*\([^)]*\)', '', s)
    s = re.sub(r'[^a-zA-Z0-9]', '', s).lower()
    return s

def clean_text(text):
    if not text:
        return ""
    t = str(text).strip()
    if t.startswith("unistr('") and t.endswith("')"):
        t = t[8:-2]
    t = t.replace("''", "'")
    t = t.replace("\r\n", "\n").replace("\r", "\n")
    # Clean leading/trailing quotes if wrapping whole string
    if (t.startswith("'") and t.endswith("'")) or (t.startswith('"') and t.endswith('"')):
        t = t[1:-1].strip()
    return t

def clean_comment_text(text):
    t = clean_text(text)
    # Normalize multiple newlines
    t = re.sub(r'\n{3,}', '\n\n', t)
    return t

def main():
    opdb_cache = "opdb-v2.json"
    if not os.path.exists(opdb_cache):
        print("Downloading OPDB v2 dataset (~5.6MB)...")
        url = "https://mp-data.sfo3.cdn.digitaloceanspaces.com/opdb-v2.json"
        urllib.request.urlretrieve(url, opdb_cache)
        print("Downloaded OPDB cache.")
    else:
        print("Using cached opdb-v2.json.")

    with open(opdb_cache, 'r', encoding='utf-8') as f:
        opdb = json.load(f)

    with open("pinside_database.json", 'r', encoding='utf-8') as f:
        pinside = json.load(f)

    print(f"Loaded {len(pinside)} Pinside machines and {len(opdb.get('entries', []))} OPDB entries.")

    opdb_machines = [e for e in opdb.get('entries', []) if e.get('entryType') == 'machine']
    
    by_ipdb = {}
    by_norm_name_year = {}
    by_norm_name = {}

    for e in opdb_machines:
        ipdb = e.get('ipdbId')
        if ipdb and ipdb > 0:
            by_ipdb[ipdb] = e
        raw_name = e.get('name') or ''
        norm = normalize_name(raw_name)
        year = e.get('year')
        if norm:
            if (norm, year) not in by_norm_name_year and year:
                by_norm_name_year[(norm, year)] = e
            if norm not in by_norm_name:
                by_norm_name[norm] = e

    matched_count = 0
    high_res_count = 0
    rules_count = 0
    people_count = 0

    enriched_pinside = []
    for m in pinside:
        ipdb = m.get('machine_ipdb')
        raw_name = m.get('machine_name') or ''
        norm = normalize_name(raw_name)
        year = m.get('machine_year')

        match = None
        if ipdb and ipdb in by_ipdb:
            match = by_ipdb[ipdb]
        elif (norm, year) in by_norm_name_year:
            match = by_norm_name_year[(norm, year)]
        elif norm in by_norm_name:
            match = by_norm_name[norm]

        image_high_res = ""
        playfield_img = ""
        cabinet_img = ""
        rules_url = ""
        opdb_id = ""
        designers = ""
        artists = ""
        software = ""
        sound = ""

        if match:
            matched_count += 1
            opdb_id = match.get('opdbId') or ""
            rules_url = match.get('pinballRulesUrl') or ""
            if rules_url:
                rules_count += 1

            # Extract high-res images
            images = match.get('images', [])
            for img in images:
                itype = img.get('type')
                urls = img.get('urls', {})
                best_url = urls.get('large') or urls.get('medium') or urls.get('small') or ""
                if not best_url:
                    continue

                if itype == 'backglass' and not image_high_res:
                    image_high_res = best_url
                elif itype == 'playfield' and not playfield_img:
                    playfield_img = best_url
                elif itype == 'cabinet' and not cabinet_img:
                    cabinet_img = best_url

            # If no backglass, use cabinet or playfield as hero
            if not image_high_res:
                image_high_res = cabinet_img or playfield_img

            if image_high_res:
                high_res_count += 1

            # Extract people
            people = match.get('people', [])
            d_list = [p['name'] for p in people if p.get('role') == 'design']
            a_list = [p['name'] for p in people if p.get('role') == 'art']
            s_list = [p['name'] for p in people if p.get('role') == 'software']
            snd_list = [p['name'] for p in people if p.get('role') in ['music', 'sound']]

            designers = ", ".join(dict.fromkeys(d_list))
            artists = ", ".join(dict.fromkeys(a_list))
            software = ", ".join(dict.fromkeys(s_list))
            sound = ", ".join(dict.fromkeys(snd_list))

            if designers or artists or software or sound:
                people_count += 1

        # Text cleanups
        comments = clean_comment_text(m.get('machine_comments') or '')
        slogans = clean_text(m.get('machine_slogans') or '')
        toys = clean_text(m.get('machine_toys') or '')

        m_enriched = dict(m)
        m_enriched['image_high_res'] = image_high_res
        m_enriched['playfield_image_url'] = playfield_img
        m_enriched['cabinet_image_url'] = cabinet_img
        m_enriched['rules_sheet_url'] = rules_url
        m_enriched['opdb_id'] = opdb_id
        m_enriched['designer_name'] = designers
        m_enriched['artist_name'] = artists
        m_enriched['software_name'] = software
        m_enriched['sound_name'] = sound
        m_enriched['machine_comments'] = comments
        m_enriched['machine_slogans'] = slogans
        m_enriched['machine_toys'] = toys

        enriched_pinside.append(m_enriched)

    print(f"Enrichment Summary:")
    print(f"  Matched machines: {matched_count} / {len(pinside)} ({matched_count/len(pinside)*100:.1f}%)")
    print(f"  High-res artwork: {high_res_count} / {len(pinside)} ({high_res_count/len(pinside)*100:.1f}%)")
    print(f"  Creators credits: {people_count} / {len(pinside)}")
    print(f"  Rulesheet URLs:   {rules_count} / {len(pinside)}")

    with open("pinside_database.json", 'w', encoding='utf-8') as f:
        json.dump(enriched_pinside, f, indent=2, ensure_ascii=False)
    print("Saved enriched pinside_database.json successfully.")

if __name__ == '__main__':
    main()
