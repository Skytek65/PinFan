import urllib.request
import urllib.parse
import urllib.error
import json
import re
import time
import os

def get_session_and_token():
    url = "https://pinside.com/pinball/machine"
    headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:151.0) Gecko/20100101 Firefox/151.0",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
    }
    
    req = urllib.request.Request(url, headers=headers)
    print("Fetching Pinside main page to establish session...")
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            headers_dict = response.info()
            cookies = headers_dict.get_all('Set-Cookie', [])
            session_cookie = None
            for cookie in cookies:
                if 'pinsideSession=' in cookie:
                    session_cookie = cookie.split('pinsideSession=')[1].split(';')[0]
                    break
            
            body = response.read().decode('utf-8', errors='replace')
            token_match = re.search(r"var token\s*=\s*'([a-f0-9]+)'", body)
            token = token_match.group(1) if token_match else ""
            
            print(f"Session established: {session_cookie}")
            print(f"CSRF Token: {token}")
            return session_cookie, token
    except Exception as e:
        print(f"Failed to get session/token: {e}")
        return None, None

def fetch_page(session_cookie, token, page, limit=25):
    url = "https://pinside.com/api/pinsidesearch/listMachines"
    params = {
        "query": "",
        "token": token,
        "machine_releasetype": "",
        "machine_generation": "",
        "sort_by": "machine_name",
        "sort_order": "ASC",
        "page": page,
        "limit": limit,
        "records_per_page": limit,
        "per_page": limit
    }
    url_parts = list(urllib.parse.urlparse(url))
    url_parts[4] = urllib.parse.urlencode(params)
    full_url = urllib.parse.urlunparse(url_parts)
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:151.0) Gecko/20100101 Firefox/151.0",
        "Accept": "application/json, text/javascript, */*; q=0.01",
        "Accept-Language": "en-US,en;q=0.9",
        "X-Requested-With": "XMLHttpRequest",
    }
    if session_cookie:
        headers["Cookie"] = f"pinsideSession={session_cookie}"
        
    req = urllib.request.Request(full_url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            data = json.loads(response.read().decode('utf-8'))
            return data
    except Exception as e:
        print(f"Error fetching page {page}: {e}")
        return None

def main():
    session_cookie, token = get_session_and_token()
    if not session_cookie or not token:
        print("Aborting download due to session initialization failure.")
        return
        
    all_machines = {}
    page = 1
    total_pages = 1
    
    while page <= total_pages:
        data = fetch_page(session_cookie, token, page=page, limit=25)
        if not data or not data.get('success'):
            print(f"Failed to retrieve data for page {page}. Retrying in 2 seconds...")
            time.sleep(2)
            continue
            
        machines = data.get('machine_list', [])
        for m in machines:
            key = m.get('machine_key')
            if key:
                all_machines[key] = m
                
        total_pages = data.get('total_page_count', 1)
        if page % 10 == 0 or page == total_pages:
            print(f"Progress: Page {page}/{total_pages} fetched. Unique machines collected so far: {len(all_machines)}")
            
        page += 1
        # Polite delay to prevent rate-limiting/IP ban
        time.sleep(0.15)
        
    # Convert dict to list sorted by machine name
    sorted_machines = sorted(all_machines.values(), key=lambda x: str(x.get('machine_name', '')))
    
    output_filename = "pinside_database.json"
    with open(output_filename, 'w', encoding='utf-8') as f:
        json.dump(sorted_machines, f, indent=2, ensure_ascii=False)
        
    print(f"\nDownload completed successfully! Saved {len(sorted_machines)} machines to '{output_filename}'.")

if __name__ == '__main__':
    main()
