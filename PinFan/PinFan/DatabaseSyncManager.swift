import Foundation
import Combine
import SwiftUI

@MainActor
class DatabaseSyncManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = DatabaseSyncManager()
    
    // Published UI States
    @Published var isChecking = false
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var updateAvailable = false
    @Published var remoteVersionInfo: DatabaseVersionInfo? = nil
    @Published var lastSyncDate: Date? = nil
    
    // Floating Status Toast for seamless automatic updates
    @Published var toastText: String? = nil
    @Published var isToastPresented = false
    
    // User configurable repo settings
    @Published var repoOwner: String {
        didSet {
            UserDefaults.standard.set(repoOwner, forKey: "pinfan_sync_repo_owner")
        }
    }
    @Published var repoName: String {
        didSet {
            UserDefaults.standard.set(repoName, forKey: "pinfan_sync_repo_name")
        }
    }
    @Published var branch: String {
        didSet {
            UserDefaults.standard.set(branch, forKey: "pinfan_sync_branch")
        }
    }
    
    private var downloadTask: URLSessionDownloadTask?
    private var downloadContinuation: CheckedContinuation<URL, Error>?
    
    private let localVersionKey = "pinfan_local_db_version"
    private let lastSyncDateKey = "pinfan_last_sync_date"
    private let lastAutoCheckDateKey = "pinfan_last_auto_check_date"
    
    override init() {
        self.repoOwner = UserDefaults.standard.string(forKey: "pinfan_sync_repo_owner") ?? "martisk"
        self.repoName = UserDefaults.standard.string(forKey: "pinfan_sync_repo_name") ?? "splendid-faraday"
        self.branch = UserDefaults.standard.string(forKey: "pinfan_sync_branch") ?? "main"
        
        if let timestamp = UserDefaults.standard.object(forKey: lastSyncDateKey) as? Date {
            self.lastSyncDate = timestamp
        }
        
        super.init()
    }
    
    var localVersion: Int {
        get {
            UserDefaults.standard.integer(forKey: localVersionKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: localVersionKey)
        }
    }
    
    var versionURL: URL? {
        let urlString = "https://raw.githubusercontent.com/\(repoOwner)/\(repoName)/\(branch)/version.json"
        return URL(string: urlString)
    }
    
    var databaseURL: URL? {
        let urlString = "https://raw.githubusercontent.com/\(repoOwner)/\(repoName)/\(branch)/pinside_database.db"
        return URL(string: urlString)
    }
    
    // MARK: - Check For Updates
    
    func checkForUpdates() async {
        guard let url = versionURL else {
            statusMessage = "Invalid repository URL configuration."
            return
        }
        
        isChecking = true
        statusMessage = "Checking for database updates..."
        
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                isChecking = false
                statusMessage = "Server returned status code \(code). Make sure repo is public or accessible."
                return
            }
            
            let decoder = JSONDecoder()
            let versionInfo = try decoder.decode(DatabaseVersionInfo.self, from: data)
            
            self.remoteVersionInfo = versionInfo
            self.isChecking = false
            
            if localVersion == 0 {
                // First time check
                self.updateAvailable = true
                self.statusMessage = "New database version available (\(versionInfo.machineCount) machines)."
            } else if versionInfo.version > localVersion {
                self.updateAvailable = true
                self.statusMessage = "Update available! Version from \(versionInfo.lastUpdated)."
            } else {
                self.updateAvailable = false
                self.statusMessage = "Database is up to date (Version \(versionInfo.version))."
            }
        } catch {
            isChecking = false
            statusMessage = "Check failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Daily Automatic Check & Background Sync
    
    func performDailyAutoCheckAndSync() {
        let lastCheck = UserDefaults.standard.object(forKey: lastAutoCheckDateKey) as? Date
        if let lastCheck = lastCheck, Calendar.current.isDateInToday(lastCheck) {
            // Already checked today
            return
        }
        
        Task {
            // Record today's check timestamp
            UserDefaults.standard.set(Date(), forKey: self.lastAutoCheckDateKey)
            
            await self.checkForUpdates()
            
            if self.updateAvailable {
                self.showToast("DOWNLOADING DATABASE UPDATE...", duration: nil)
                await self.downloadAndApplyUpdate()
                if let count = self.remoteVersionInfo?.machineCount {
                    self.showToast("DATABASE UPDATED // \(count) CABINETS SYNCED", duration: 4.0)
                } else {
                    self.showToast("DATABASE UPDATED SUCCESSFULLY", duration: 4.0)
                }
            }
        }
    }
    
    func showToast(_ text: String, duration: Double? = 3.5) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.toastText = text
            self.isToastPresented = true
        }
        
        if let duration = duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if self.toastText == text {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.isToastPresented = false
                    }
                }
            }
        }
    }
    
    func hideToast() {
        withAnimation(.easeOut(duration: 0.2)) {
            self.isToastPresented = false
            self.toastText = nil
        }
    }
    
    // MARK: - Download and Merge Database
    
    func downloadAndApplyUpdate() async {
        guard let dbURL = databaseURL else {
            statusMessage = "Invalid database download URL."
            return
        }
        
        isDownloading = true
        downloadProgress = 0.0
        statusMessage = "Downloading database update..."
        
        do {
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            
            let tempDownloadedURL: URL = try await withCheckedThrowingContinuation { continuation in
                self.downloadContinuation = continuation
                let task = session.downloadTask(with: dbURL)
                self.downloadTask = task
                task.resume()
            }
            
            statusMessage = "Merging database safely..."
            
            // Perform safe SQLite merge in DatabaseManager
            let success = DatabaseManager.shared.mergeRemoteDatabase(from: tempDownloadedURL)
            
            isDownloading = false
            
            if success {
                if let remoteVer = remoteVersionInfo?.version {
                    self.localVersion = remoteVer
                } else {
                    self.localVersion = Int(Date().timeIntervalSince1970)
                }
                
                let now = Date()
                self.lastSyncDate = now
                UserDefaults.standard.set(now, forKey: lastSyncDateKey)
                self.updateAvailable = false
                self.statusMessage = "Database successfully updated! All scores and favorites preserved."
            } else {
                self.statusMessage = "Merge failed. Local database unchanged."
            }
        } catch {
            isDownloading = false
            statusMessage = "Download failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Move file to a temporary file with .db extension in cache directory
        let tempDir = FileManager.default.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent(UUID().uuidString + ".db")
        
        do {
            try FileManager.default.moveItem(at: location, to: destinationURL)
            Task { @MainActor in
                self.downloadContinuation?.resume(returning: destinationURL)
                self.downloadContinuation = nil
            }
        } catch {
            Task { @MainActor in
                self.downloadContinuation?.resume(throwing: error)
                self.downloadContinuation = nil
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            Task { @MainActor in
                self.downloadProgress = progress
                let currentMB = Double(totalBytesWritten) / (1024 * 1024)
                let totalMB = Double(totalBytesExpectedToWrite) / (1024 * 1024)
                self.statusMessage = String(format: "Downloading: %.1f MB / %.1f MB (%.0f%%)", currentMB, totalMB, progress * 100)
            }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Task { @MainActor in
                self.downloadContinuation?.resume(throwing: error)
                self.downloadContinuation = nil
            }
        }
    }
}
