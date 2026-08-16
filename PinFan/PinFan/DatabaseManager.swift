import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let dbName = "pinside_database.db"
    
    private let selectFields = """
    SELECT 
        machine_key, machine_name, machine_name_formatted, slug_name, machine_abbrev, 
        manuf_name, machine_manufacturer, machine_year, machine_manufactured, machine_releasetype, 
        machine_releaseformat, machine_production_status, machine_type, machine_generation, machine_prodrun, 
        machine_ipdb, machine_rating, machine_rating_count, machine_rank, machine_price_average, 
        machine_price_last_updated, machine_visitcount, machine_display, machine_plunger, machine_cabinet, 
        machine_droptargets, machine_bumpers, machine_flippers, machine_ramps, machine_captiveballs, 
        machine_multiball, machine_magnets, machine_players, machine_buyin, machine_miniorbits, 
        machine_customspeech, machine_spindiscs, machine_kickback, machine_shakermotor, machine_playfieldlevels, 
        machine_spinners, machine_retheme, machine_ornament, machine_toys, machine_slogans, 
        machine_comments, image_sha1, image_rel_path, is_favorite, is_owned, 
        personal_notes, base_name, edition_name 
    FROM machines
    """
    
    private init() {
        setupDatabase()
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    private func setupDatabase() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("DB Manager Error: Documents directory not found.")
            return
        }
        
        let writableDBURL = documentsURL.appendingPathComponent(dbName)
        
        // Copy DB from bundle if not exists in Documents
        if !fileManager.fileExists(atPath: writableDBURL.path) {
            guard let bundleDBURL = Bundle.main.url(forResource: "pinside_database", withExtension: "db") else {
                print("DB Manager Error: DB not found in bundle.")
                return
            }
            do {
                try fileManager.copyItem(at: bundleDBURL, to: writableDBURL)
                print("DB Manager: Copied bundle database to Documents directory.")
            } catch {
                print("DB Manager Error: Failed to copy database: \(error.localizedDescription)")
                return
            }
        } else {
            print("DB Manager: Database file already exists in Documents directory.")
        }
        
        // Open DB
        if sqlite3_open(writableDBURL.path, &db) != SQLITE_OK {
            print("DB Manager Error: Failed to open SQLite database.")
            return
        }
        
        print("DB Manager: Successfully opened SQLite database.")
        
        // Perform migrations (add custom user state columns)
        addStateColumnsIfNeeded()
        
        // Populate base_name and edition_name if they are empty
        populateBaseAndEditionNamesIfNeeded()
    }
    
    private func addStateColumnsIfNeeded() {
        // We run alter table statements. If they fail (e.g., column already exists), SQLite returns SQLITE_ERROR, which we can safely ignore.
        let alterFav = "ALTER TABLE machines ADD COLUMN is_favorite INTEGER DEFAULT 0;"
        let alterOwned = "ALTER TABLE machines ADD COLUMN is_owned INTEGER DEFAULT 0;"
        let alterNotes = "ALTER TABLE machines ADD COLUMN personal_notes TEXT DEFAULT '';"
        let alterBase = "ALTER TABLE machines ADD COLUMN base_name TEXT DEFAULT '';"
        let alterEdition = "ALTER TABLE machines ADD COLUMN edition_name TEXT DEFAULT '';"
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, alterFav, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
        
        if sqlite3_prepare_v2(db, alterOwned, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
        
        if sqlite3_prepare_v2(db, alterNotes, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
        
        if sqlite3_prepare_v2(db, alterBase, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
        
        if sqlite3_prepare_v2(db, alterEdition, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
        
        // CREATE high_scores TABLE
        let createHighScoresTable = """
        CREATE TABLE IF NOT EXISTS high_scores (
            score_id INTEGER PRIMARY KEY AUTOINCREMENT,
            machine_key INTEGER,
            score_value INTEGER,
            player_initials TEXT,
            score_date TEXT,
            notes TEXT
        );
        """
        if sqlite3_prepare_v2(db, createHighScoresTable, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Query Helper Methods
    
    private func getString(statement: OpaquePointer?, index: Int32) -> String? {
        guard let cString = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: cString)
    }
    
    private func getInt(statement: OpaquePointer?, index: Int32) -> Int? {
        if sqlite3_column_type(statement, index) == SQLITE_NULL { return nil }
        return Int(sqlite3_column_int(statement, index))
    }
    
    private func getDouble(statement: OpaquePointer?, index: Int32) -> Double? {
        if sqlite3_column_type(statement, index) == SQLITE_NULL { return nil }
        return sqlite3_column_double(statement, index)
    }
    
    private func parseMachine(statement: OpaquePointer?) -> PinballMachine {
        let key = Int(sqlite3_column_int(statement, 0))
        let name = getString(statement: statement, index: 1) ?? "Unknown"
        let nameFormatted = getString(statement: statement, index: 2)
        let slug = getString(statement: statement, index: 3)
        let abbrev = getString(statement: statement, index: 4)
        let manuf = getString(statement: statement, index: 5)
        let manufacturer = getInt(statement: statement, index: 6)
        let year = getInt(statement: statement, index: 7)
        let manufactured = getString(statement: statement, index: 8)
        let releasetype = getString(statement: statement, index: 9)
        let releaseformat = getString(statement: statement, index: 10)
        let prodstatus = getString(statement: statement, index: 11)
        let type = getString(statement: statement, index: 12)
        let generation = getInt(statement: statement, index: 13)
        let prodrun = getInt(statement: statement, index: 14)
        let ipdb = getInt(statement: statement, index: 15)
        let rating = getDouble(statement: statement, index: 16)
        let ratingCount = getInt(statement: statement, index: 17)
        let rank = getInt(statement: statement, index: 18)
        let price = getDouble(statement: statement, index: 19)
        let priceLastUpdated = getString(statement: statement, index: 20)
        let visitcount = getInt(statement: statement, index: 21)
        let display = getString(statement: statement, index: 22)
        let plunger = getString(statement: statement, index: 23)
        let cabinet = getString(statement: statement, index: 24)
        let droptargets = getInt(statement: statement, index: 25)
        let bumpers = getInt(statement: statement, index: 26)
        let flippers = getInt(statement: statement, index: 27)
        let ramps = getInt(statement: statement, index: 28)
        let captiveballs = getInt(statement: statement, index: 29)
        let multiball = getInt(statement: statement, index: 30)
        let magnets = getInt(statement: statement, index: 31)
        let players = getInt(statement: statement, index: 32)
        let buyin = getInt(statement: statement, index: 33)
        let orbits = getInt(statement: statement, index: 34)
        let speech = getInt(statement: statement, index: 35)
        let spindiscs = getInt(statement: statement, index: 36)
        let kickback = getInt(statement: statement, index: 37)
        let shakermotor = getInt(statement: statement, index: 38)
        let playfieldlevels = getInt(statement: statement, index: 39)
        let spinners = getInt(statement: statement, index: 40)
        let retheme = getInt(statement: statement, index: 41)
        let ornament = getString(statement: statement, index: 42)
        let toys = getString(statement: statement, index: 43)
        let slogans = getString(statement: statement, index: 44)
        let comments = getString(statement: statement, index: 45)
        let sha1 = getString(statement: statement, index: 46)
        let relpath = getString(statement: statement, index: 47)
        let isFav = sqlite3_column_int(statement, 48) == 1
        let isOwn = sqlite3_column_int(statement, 49) == 1
        let notes = getString(statement: statement, index: 50) ?? ""
        let baseName = getString(statement: statement, index: 51)
        let editionName = getString(statement: statement, index: 52)
        
        return PinballMachine(
            machineKey: key,
            machineName: name,
            machineNameFormatted: nameFormatted,
            slugName: slug,
            machineAbbrev: abbrev,
            manufName: manuf,
            machineManufacturer: manufacturer,
            machineYear: year,
            machineManufactured: manufactured,
            machineReleasetype: releasetype,
            machineReleaseformat: releaseformat,
            machineProductionStatus: prodstatus,
            machineType: type,
            machineGeneration: generation,
            machineProdrun: prodrun,
            machineIpdb: ipdb,
            machineRating: rating,
            machineRatingCount: ratingCount,
            machineRank: rank,
            machinePriceAverage: price,
            machinePriceLastUpdated: priceLastUpdated,
            machineVisitcount: visitcount,
            machineDisplay: display,
            machinePlunger: plunger,
            machineCabinet: cabinet,
            machineDroptargets: droptargets,
            machineBumpers: bumpers,
            machineFlippers: flippers,
            machineRamps: ramps,
            machineCaptiveballs: captiveballs,
            machineMultiball: multiball,
            machineMagnets: magnets,
            machinePlayers: players,
            machineBuyin: buyin,
            machineMiniorbits: orbits,
            machineCustomspeech: speech,
            machineSpindiscs: spindiscs,
            machineKickback: kickback,
            machineShakermotor: shakermotor,
            machinePlayfieldlevels: playfieldlevels,
            machineSpinners: spinners,
            machineRetheme: retheme,
            machineOrnament: ornament,
            machineToys: toys,
            machineSlogans: slogans,
            machineComments: comments,
            imageSha1: sha1,
            imageRelPath: relpath,
            isFavorite: isFav,
            isOwned: isOwn,
            personalNotes: notes,
            baseName: baseName,
            editionName: editionName
        )
    }
    
    // MARK: - API Methods
    
    func getStats() -> (totalCount: Int, averageRating: Double) {
        var total = 0
        var avg = 0.0
        
        let queryTotal = "SELECT COUNT(*) FROM machines;"
        let queryAvg = "SELECT AVG(machine_rating) FROM machines WHERE machine_rating > 0;"
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryTotal, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                total = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)
        
        if sqlite3_prepare_v2(db, queryAvg, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                avg = sqlite3_column_double(statement, 0)
            }
        }
        sqlite3_finalize(statement)
        
        return (total, avg)
    }
    
    func getFeaturedMachines() -> [PinballMachine] {
        // Fetch top 10 rated machines
        let query = "\(selectFields) WHERE machine_rating > 0 AND machine_rank > 0 ORDER BY machine_rating DESC LIMIT 10;"
        var statement: OpaquePointer?
        var list: [PinballMachine] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var m = parseMachine(statement: statement)
                if let base = m.baseName {
                    m.editions = fetchEditions(baseName: base, manufName: m.manufName ?? "")
                }
                list.append(m)
            }
        }
        sqlite3_finalize(statement)
        return list
    }
    
    func getRandomMachine() -> PinballMachine? {
        let query = "\(selectFields) ORDER BY RANDOM() LIMIT 1;"
        var statement: OpaquePointer?
        var machine: PinballMachine? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                var m = parseMachine(statement: statement)
                if let base = m.baseName {
                    m.editions = fetchEditions(baseName: base, manufName: m.manufName ?? "")
                }
                machine = m
            }
        }
        sqlite3_finalize(statement)
        return machine
    }
    
    func getRandomTop100Machine() -> PinballMachine? {
        let query = """
        SELECT * FROM (
            \(selectFields)
            WHERE machine_rating > 0 AND machine_rank > 0
            ORDER BY machine_rating DESC
            LIMIT 100
        ) ORDER BY RANDOM() LIMIT 1;
        """
        var statement: OpaquePointer?
        var machine: PinballMachine? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                var m = parseMachine(statement: statement)
                if let base = m.baseName {
                    m.editions = fetchEditions(baseName: base, manufName: m.manufName ?? "")
                }
                machine = m
            }
        }
        sqlite3_finalize(statement)
        return machine
    }
    
    func getUniqueManufacturers() -> [String] {
        let query = "SELECT DISTINCT manuf_name FROM machines WHERE manuf_name IS NOT NULL AND manuf_name != '' ORDER BY manuf_name ASC;"
        var statement: OpaquePointer?
        var list: [String] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let name = getString(statement: statement, index: 0) {
                    list.append(name)
                }
            }
        }
        sqlite3_finalize(statement)
        return list
    }
    
    func fetchMachines(queryText: String, manufacturer: String?, releaseType: String?, decade: String?, displayType: String?, page: Int, limit: Int = 20) -> [PinballMachine] {
        var query = "\(selectFields) WHERE 1=1"
        var params: [String] = []
        
        if !queryText.isEmpty {
            query += " AND (machine_name LIKE ? OR machine_abbrev LIKE ?)"
            params.append("%\(queryText)%")
            params.append("%\(queryText)%")
        }
        
        if let manufacturer = manufacturer, !manufacturer.isEmpty {
            query += " AND manuf_name = ?"
            params.append(manufacturer)
        }
        
        if let releaseType = releaseType, !releaseType.isEmpty {
            query += " AND machine_releasetype = ?"
            params.append(releaseType)
        }
        
        if let decade = decade, !decade.isEmpty {
            if decade == "1930s-40s" {
                query += " AND machine_year >= 1930 AND machine_year <= 1949"
            } else {
                let cleanDecade = decade.replacingOccurrences(of: "s", with: "")
                if let startYear = Int(cleanDecade) {
                    query += " AND machine_year >= ? AND machine_year <= ?"
                    params.append(String(startYear))
                    params.append(String(startYear + 9))
                }
            }
        }
        
        if let displayType = displayType, !displayType.isEmpty {
            if displayType.lowercased() == "dmd" {
                query += " AND machine_display LIKE '%dot matrix%'"
            } else if displayType.lowercased() == "lcd" {
                query += " AND machine_display LIKE '%lcd%'"
            } else if displayType.lowercased() == "reels" {
                query += " AND machine_display LIKE '%reel%'"
            } else if displayType.lowercased() == "alphanumeric" {
                query += " AND machine_display LIKE '%alphanumeric%'"
            } else {
                query += " AND machine_display LIKE ?"
                params.append("%\(displayType)%")
            }
        }
        query += " GROUP BY base_name, manuf_name"
        query += " ORDER BY CASE WHEN machine_rank > 0 THEN 0 ELSE 1 END ASC, machine_rank ASC, machine_name ASC LIMIT ? OFFSET ?;"
        
        var statement: OpaquePointer?
        var list: [PinballMachine] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            var index: Int32 = 1
            
            for param in params {
                sqlite3_bind_text(statement, index, (param as NSString).utf8String, -1, nil)
                index += 1
            }
            
            let offset = (page - 1) * limit
            sqlite3_bind_int(statement, index, Int32(limit))
            sqlite3_bind_int(statement, index + 1, Int32(offset))
            
            while sqlite3_step(statement) == SQLITE_ROW {
                var m = parseMachine(statement: statement)
                if let base = m.baseName {
                    m.editions = fetchEditions(baseName: base, manufName: m.manufName ?? "")
                }
                list.append(m)
            }
        } else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            print("DB Manager Query Error: \(errorMsg)")
        }
        sqlite3_finalize(statement)
        return list
    }
    
    func getCollection(onlyFavorites: Bool) -> [PinballMachine] {
        let filter = onlyFavorites ? "is_favorite = 1" : "is_owned = 1"
        let query = "\(selectFields) WHERE \(filter) ORDER BY machine_name ASC;"
        var statement: OpaquePointer?
        var list: [PinballMachine] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var m = parseMachine(statement: statement)
                if let base = m.baseName {
                    m.editions = fetchEditions(baseName: base, manufName: m.manufName ?? "")
                }
                list.append(m)
            }
        }
        sqlite3_finalize(statement)
        return list
    }
    
    // MARK: - Write Operations
    
    func setFavorite(key: Int, isFavorite: Bool) {
        let query = "UPDATE machines SET is_favorite = ? WHERE machine_key = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, isFavorite ? 1 : 0)
            sqlite3_bind_int(statement, 2, Int32(key))
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func setOwned(key: Int, isOwned: Bool) {
        let query = "UPDATE machines SET is_owned = ? WHERE machine_key = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, isOwned ? 1 : 0)
            sqlite3_bind_int(statement, 2, Int32(key))
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func updateNotes(key: Int, notes: String) {
        let query = "UPDATE machines SET personal_notes = ? WHERE machine_key = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (notes as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 2, Int32(key))
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func getMachine(byKey key: Int) -> PinballMachine? {
        let query = "\(selectFields) WHERE machine_key = ?;"
        var statement: OpaquePointer?
        var machine: PinballMachine? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(key))
            if sqlite3_step(statement) == SQLITE_ROW {
                var m = parseMachine(statement: statement)
                if let base = m.baseName {
                    m.editions = fetchEditions(baseName: base, manufName: m.manufName ?? "")
                }
                machine = m
            }
        }
        sqlite3_finalize(statement)
        return machine
    }
    
    // MARK: - High Scores CRUD Operations
    
    func fetchHighScores(machineKey: Int) -> [HighScore] {
        let query = "SELECT score_id, machine_key, score_value, player_initials, score_date, notes FROM high_scores WHERE machine_key = ? ORDER BY score_value DESC;"
        var statement: OpaquePointer?
        var list: [HighScore] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(machineKey))
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let key = Int(sqlite3_column_int(statement, 1))
                let val = Int(sqlite3_column_int(statement, 2))
                let initls = getString(statement: statement, index: 3) ?? "???"
                let dateStr = getString(statement: statement, index: 4) ?? ""
                let notesStr = getString(statement: statement, index: 5) ?? ""
                
                list.append(HighScore(scoreId: id, machineKey: key, scoreValue: val, playerInitials: initls, scoreDate: dateStr, notes: notesStr))
            }
        }
        sqlite3_finalize(statement)
        return list
    }
    
    func addHighScore(machineKey: Int, scoreValue: Int, playerInitials: String, scoreDate: String, notes: String) -> Bool {
        let query = "INSERT INTO high_scores (machine_key, score_value, player_initials, score_date, notes) VALUES (?, ?, ?, ?, ?);"
        var statement: OpaquePointer?
        var success = false
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(machineKey))
            sqlite3_bind_int(statement, 2, Int32(scoreValue))
            sqlite3_bind_text(statement, 3, (playerInitials as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (scoreDate as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (notes as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                success = true
            }
        }
        sqlite3_finalize(statement)
        return success
    }
    
    func updateHighScore(scoreId: Int, scoreValue: Int, playerInitials: String, scoreDate: String, notes: String) -> Bool {
        let query = "UPDATE high_scores SET score_value = ?, player_initials = ?, score_date = ?, notes = ? WHERE score_id = ?;"
        var statement: OpaquePointer?
        var success = false
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(scoreValue))
            sqlite3_bind_text(statement, 2, (playerInitials as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (scoreDate as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (notes as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 5, Int32(scoreId))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                success = true
            }
        }
        sqlite3_finalize(statement)
        return success
    }
    
    func deleteHighScore(scoreId: Int) -> Bool {
        let query = "DELETE FROM high_scores WHERE score_id = ?;"
        var statement: OpaquePointer?
        var success = false
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(scoreId))
            if sqlite3_step(statement) == SQLITE_DONE {
                success = true
            }
        }
        sqlite3_finalize(statement)
        return success
    }
    
    func fetchEditions(baseName: String, manufName: String) -> [MachineEdition] {
        let query = "SELECT machine_key, edition_name, image_rel_path FROM machines WHERE base_name = ? AND manuf_name = ? ORDER BY machine_name ASC;"
        var statement: OpaquePointer?
        var list: [MachineEdition] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (baseName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (manufName as NSString).utf8String, -1, nil)
            while sqlite3_step(statement) == SQLITE_ROW {
                let key = Int(sqlite3_column_int(statement, 0))
                let edition = getString(statement: statement, index: 1) ?? "Standard"
                let img = getString(statement: statement, index: 2)
                list.append(MachineEdition(machineKey: key, editionName: edition, imageRelPath: img))
            }
        }
        sqlite3_finalize(statement)
        return list
    }
    
    private func populateBaseAndEditionNamesIfNeeded() {
        // Check if there are rows where base_name is empty or null
        let checkQuery = "SELECT COUNT(*) FROM machines WHERE base_name = '' OR base_name IS NULL;"
        var checkStatement: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, checkQuery, -1, &checkStatement, nil) == SQLITE_OK {
            if sqlite3_step(checkStatement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(checkStatement, 0))
            }
        }
        sqlite3_finalize(checkStatement)
        
        if count > 0 {
            print("DB Manager: Populating base_name and edition_name for \(count) machines...")
            let fetchQuery = "SELECT machine_key, machine_name FROM machines;"
            var fetchStatement: OpaquePointer?
            var updates: [(key: Int, base: String, edition: String)] = []
            
            if sqlite3_prepare_v2(db, fetchQuery, -1, &fetchStatement, nil) == SQLITE_OK {
                while sqlite3_step(fetchStatement) == SQLITE_ROW {
                    let key = Int(sqlite3_column_int(fetchStatement, 0))
                    if let name = getString(statement: fetchStatement, index: 1) {
                        let (base, edition) = parseName(name)
                        updates.append((key, base, edition))
                    }
                }
            }
            sqlite3_finalize(fetchStatement)
            
            // Run updates in a single transaction for speed
            sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
            let updateQuery = "UPDATE machines SET base_name = ?, edition_name = ? WHERE machine_key = ?;"
            var updateStatement: OpaquePointer?
            if sqlite3_prepare_v2(db, updateQuery, -1, &updateStatement, nil) == SQLITE_OK {
                for update in updates {
                    sqlite3_bind_text(updateStatement, 1, (update.base as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(updateStatement, 2, (update.edition as NSString).utf8String, -1, nil)
                    sqlite3_bind_int(updateStatement, 3, Int32(update.key))
                    sqlite3_step(updateStatement)
                    sqlite3_reset(updateStatement)
                }
            }
            sqlite3_finalize(updateStatement)
            sqlite3_exec(db, "COMMIT;", nil, nil, nil)
            print("DB Manager: Completed base_name and edition_name migration.")
        }
    }
    
    private func parseName(_ name: String) -> (String, String) {
        if name.hasSuffix(")") {
            if let openParenIndex = name.lastIndex(of: "(") {
                let base = String(name[..<openParenIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                let nextIndex = name.index(after: openParenIndex)
                let endIndex = name.index(before: name.endIndex)
                if nextIndex < endIndex {
                    let edition = String(name[nextIndex..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                    return (base, edition)
                }
            }
        }
        return (name.trimmingCharacters(in: .whitespacesAndNewlines), "Standard")
    }
    
    func mergeRemoteDatabase(from tempURL: URL) -> Bool {
        guard let db = self.db else { return false }
        
        let attachSQL = "ATTACH DATABASE ? AS new_db;"
        var attachStmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, attachSQL, -1, &attachStmt, nil) == SQLITE_OK else {
            print("DB Sync Error: Failed to prepare ATTACH statement.")
            return false
        }
        
        sqlite3_bind_text(attachStmt, 1, (tempURL.path as NSString).utf8String, -1, nil)
        let attachRes = sqlite3_step(attachStmt)
        sqlite3_finalize(attachStmt)
        
        if attachRes != SQLITE_DONE {
            let err = String(cString: sqlite3_errmsg(db))
            print("DB Sync Error: Failed to attach remote database: \(err)")
            try? FileManager.default.removeItem(at: tempURL)
            return false
        }
        
        print("DB Sync: Remote database attached successfully. Starting safe merge transaction...")
        
        let mergeSQL = """
        BEGIN TRANSACTION;
        
        INSERT INTO main.machines (
            machine_key, machine_name, machine_name_formatted, slug_name, machine_abbrev,
            manuf_name, machine_manufacturer, machine_year, machine_manufactured, machine_releasetype,
            machine_releaseformat, machine_production_status, machine_type, machine_generation, machine_prodrun,
            machine_ipdb, machine_rating, machine_rating_count, machine_rank, machine_price_average,
            machine_price_last_updated, machine_visitcount, machine_display, machine_plunger, machine_cabinet,
            machine_droptargets, machine_bumpers, machine_flippers, machine_ramps, machine_captiveballs,
            machine_multiball, machine_magnets, machine_players, machine_buyin, machine_miniorbits,
            machine_customspeech, machine_spindiscs, machine_kickback, machine_shakermotor, machine_playfieldlevels,
            machine_spinners, machine_retheme, machine_ornament, machine_toys, machine_slogans,
            machine_comments, image_sha1, image_rel_path, is_favorite, is_owned,
            personal_notes, base_name, edition_name
        )
        SELECT
            n.machine_key, n.machine_name, n.machine_name_formatted, n.slug_name, n.machine_abbrev,
            n.manuf_name, n.machine_manufacturer, n.machine_year, n.machine_manufactured, n.machine_releasetype,
            n.machine_releaseformat, n.machine_production_status, n.machine_type, n.machine_generation, n.machine_prodrun,
            n.machine_ipdb, n.machine_rating, n.machine_rating_count, n.machine_rank, n.machine_price_average,
            n.machine_price_last_updated, n.machine_visitcount, n.machine_display, n.machine_plunger, n.machine_cabinet,
            n.machine_droptargets, n.machine_bumpers, n.machine_flippers, n.machine_ramps, n.machine_captiveballs,
            n.machine_multiball, n.machine_magnets, n.machine_players, n.machine_buyin, n.machine_miniorbits,
            n.machine_customspeech, n.machine_spindiscs, n.machine_kickback, n.machine_shakermotor, n.machine_playfieldlevels,
            n.machine_spinners, n.machine_retheme, n.machine_ornament, n.machine_toys, n.machine_slogans,
            n.machine_comments, n.image_sha1, n.image_rel_path,
            COALESCE(o.is_favorite, 0),
            COALESCE(o.is_owned, 0),
            COALESCE(o.personal_notes, ''),
            n.base_name, n.edition_name
        FROM new_db.machines n
        LEFT JOIN main.machines o ON n.machine_key = o.machine_key
        ON CONFLICT(machine_key) DO UPDATE SET
            machine_name = excluded.machine_name,
            machine_name_formatted = excluded.machine_name_formatted,
            slug_name = excluded.slug_name,
            machine_abbrev = excluded.machine_abbrev,
            manuf_name = excluded.manuf_name,
            machine_manufacturer = excluded.machine_manufacturer,
            machine_year = excluded.machine_year,
            machine_manufactured = excluded.machine_manufactured,
            machine_releasetype = excluded.machine_releasetype,
            machine_releaseformat = excluded.machine_releaseformat,
            machine_production_status = excluded.machine_production_status,
            machine_type = excluded.machine_type,
            machine_generation = excluded.machine_generation,
            machine_prodrun = excluded.machine_prodrun,
            machine_ipdb = excluded.machine_ipdb,
            machine_rating = excluded.machine_rating,
            machine_rating_count = excluded.machine_rating_count,
            machine_rank = excluded.machine_rank,
            machine_price_average = excluded.machine_price_average,
            machine_price_last_updated = excluded.machine_price_last_updated,
            machine_visitcount = excluded.machine_visitcount,
            machine_display = excluded.machine_display,
            machine_plunger = excluded.machine_plunger,
            machine_cabinet = excluded.machine_cabinet,
            machine_droptargets = excluded.machine_droptargets,
            machine_bumpers = excluded.machine_bumpers,
            machine_flippers = excluded.machine_flippers,
            machine_ramps = excluded.machine_ramps,
            machine_captiveballs = excluded.machine_captiveballs,
            machine_multiball = excluded.machine_multiball,
            machine_magnets = excluded.machine_magnets,
            machine_players = excluded.machine_players,
            machine_buyin = excluded.machine_buyin,
            machine_miniorbits = excluded.machine_miniorbits,
            machine_customspeech = excluded.machine_customspeech,
            machine_spindiscs = excluded.machine_spindiscs,
            machine_kickback = excluded.machine_kickback,
            machine_shakermotor = excluded.machine_shakermotor,
            machine_playfieldlevels = excluded.machine_playfieldlevels,
            machine_spinners = excluded.machine_spinners,
            machine_retheme = excluded.machine_retheme,
            machine_ornament = excluded.machine_ornament,
            machine_toys = excluded.machine_toys,
            machine_slogans = excluded.machine_slogans,
            machine_comments = excluded.machine_comments,
            image_sha1 = excluded.image_sha1,
            image_rel_path = excluded.image_rel_path,
            base_name = excluded.base_name,
            edition_name = excluded.edition_name;
            
        COMMIT;
        """
        
        var success = true
        var errmsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, mergeSQL, nil, nil, &errmsg) != SQLITE_OK {
            let error = errmsg != nil ? String(cString: errmsg!) : "Unknown error"
            print("DB Sync Error: Failed to execute merge SQL: \(error)")
            sqlite3_free(errmsg)
            sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
            success = false
        }
        
        sqlite3_exec(db, "DETACH DATABASE new_db;", nil, nil, nil)
        try? FileManager.default.removeItem(at: tempURL)
        
        if success {
            print("DB Sync: Merge completed successfully with 100% user data preservation.")
            populateBaseAndEditionNamesIfNeeded()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("DatabaseDidUpdate"), object: nil)
            }
        }
        
        return success
    }
}
