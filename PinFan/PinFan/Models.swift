import Foundation

struct PinballMachine: Identifiable, Codable, Hashable {
    var id: Int { machineKey }
    
    let machineKey: Int
    let machineName: String
    let machineNameFormatted: String?
    let slugName: String?
    let machineAbbrev: String?
    let manufName: String?
    let machineManufacturer: Int?
    let machineYear: Int?
    let machineManufactured: String?
    let machineReleasetype: String?
    let machineReleaseformat: String?
    let machineProductionStatus: String?
    let machineType: String?
    let machineGeneration: Int?
    let machineProdrun: Int?
    let machineIpdb: Int?
    let machineRating: Double?
    let machineRatingCount: Int?
    let machineRank: Int?
    let machinePriceAverage: Double?
    let machinePriceLastUpdated: String?
    let machineVisitcount: Int?
    let machineDisplay: String?
    let machinePlunger: String?
    let machineCabinet: String?
    let machineDroptargets: Int?
    let machineBumpers: Int?
    let machineFlippers: Int?
    let machineRamps: Int?
    let machineCaptiveballs: Int?
    let machineMultiball: Int?
    let machineMagnets: Int?
    let machinePlayers: Int?
    let machineBuyin: Int?
    let machineMiniorbits: Int?
    let machineCustomspeech: Int?
    let machineSpindiscs: Int?
    let machineKickback: Int?
    let machineShakermotor: Int?
    let machinePlayfieldlevels: Int?
    let machineSpinners: Int?
    let machineRetheme: Int?
    let machineOrnament: String?
    let machineToys: String?
    let machineSlogans: String?
    let machineComments: String?
    let imageSha1: String?
    let imageRelPath: String?
    
    
    // User collection states
    var isFavorite: Bool = false
    var isOwned: Bool = false
    var personalNotes: String = ""
    
    // Edition fields
    let baseName: String?
    let editionName: String?
    var editions: [MachineEdition] = []
    
    // Clean formatted fields for UI
    var displayName: String {
        machineNameFormatted ?? machineName
    }
    
    var yearString: String {
        if let year = machineYear {
            return String(year)
        }
        return "Unknown"
    }
    
    var ratingString: String {
        if let rating = machineRating, rating > 0 {
            return String(format: "%.2f ★", rating)
        }
        return "N/A"
    }
    
    var rankString: String {
        if let rank = machineRank, rank > 0 {
            if let type = machineType?.uppercased(), (type == "SS" || type == "EM") {
                return "\(type) #\(rank)"
            }
            return "#\(rank)"
        }
        return "Unranked"
    }
    
    var priceString: String {
        if let price = machinePriceAverage, price > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: price)) ?? "N/A"
        }
        return "N/A"
    }
    
    var typeLabel: String {
        switch machineType?.lowercased() {
        case "ss": return "Solid State"
        case "em": return "Electro-Mechanical"
        default: return machineType?.uppercased() ?? "Pinball"
        }
    }
}

struct HighScore: Identifiable, Codable, Hashable {
    var id: Int { scoreId }
    
    let scoreId: Int
    let machineKey: Int
    let scoreValue: Int
    let playerInitials: String
    let scoreDate: String
    let notes: String
    
    var formattedScore: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: scoreValue)) ?? "\(scoreValue)"
    }
}

struct MachineEdition: Identifiable, Codable, Hashable {
    var id: Int { machineKey }
    let machineKey: Int
    let editionName: String
    let imageRelPath: String?
}

struct DatabaseVersionInfo: Codable {
    let version: Int
    let lastUpdated: String
    let machineCount: Int
    let dbFilename: String?
    let fileSizeBytes: Int?
    let sha256: String?
    
    enum CodingKeys: String, CodingKey {
        case version
        case lastUpdated = "last_updated"
        case machineCount = "machine_count"
        case dbFilename = "db_filename"
        case fileSizeBytes = "file_size_bytes"
        case sha256
    }
}
