//
//  Logger.swift
//  AnyGPT
//
//  Created on 2025
//

import Foundation
import Cocoa

class Logger {
    static let shared = Logger()

    private let logDirectory: URL
    private let logFile: URL
    private let maxLogSize: Int64 = 10 * 1024 * 1024 // 10 MB
    private let dateFormatter: DateFormatter
    private let logQueue = DispatchQueue(label: "dev.anygpt.logger", qos: .background)

    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    private init() {
        // Setup log directory
        let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        logDirectory = libraryPath.appendingPathComponent("Logs/AnyGPT")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)

        // Setup log file
        logFile = logDirectory.appendingPathComponent("anygpt.log")

        // Setup date formatter
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        // Rotate log if needed
        rotateLogIfNeeded()
    }

    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        // Check if verbose logging is enabled for debug messages
        let verboseEnabled = UserDefaults.standard.bool(forKey: "EnableVerboseLogging")
        if level == .debug && !verboseEnabled {
            return
        }

        let timestamp = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent

        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(function): \(message)\n"

        logQueue.async {
            self.writeToFile(logMessage)
        }

        // Also print to console in debug builds
        #if DEBUG
        print(logMessage.trimmingCharacters(in: .newlines))
        #endif
    }

    private func writeToFile(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logFile.path) {
            // Append to existing file
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            // Create new file
            try? data.write(to: logFile, options: .atomic)
        }

        // Check if rotation is needed
        rotateLogIfNeeded()
    }

    private func rotateLogIfNeeded() {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: logFile.path),
              let fileSize = attributes[.size] as? Int64,
              fileSize > maxLogSize else {
            return
        }

        // Create backup filename with timestamp
        let backupName = "anygpt_\(Date().timeIntervalSince1970).log"
        let backupURL = logDirectory.appendingPathComponent(backupName)

        // Move current log to backup
        try? FileManager.default.moveItem(at: logFile, to: backupURL)

        // Clean up old backups (keep only last 5)
        cleanupOldLogs()
    }

    private func cleanupOldLogs() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: [.creationDateKey], options: [])

            let logFiles = files.filter { $0.lastPathComponent.starts(with: "anygpt_") && $0.pathExtension == "log" }

            if logFiles.count > 5 {
                // Sort by creation date
                let sortedFiles = logFiles.sorted {
                    let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 < date2
                }

                // Delete oldest files
                let filesToDelete = sortedFiles.prefix(logFiles.count - 5)
                for file in filesToDelete {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            // Ignore errors during cleanup
        }
    }

    func revealLogsInFinder() {
        NSWorkspace.shared.selectFile(logFile.path, inFileViewerRootedAtPath: logDirectory.path)
    }

    func clearLogs() {
        logQueue.async {
            // Delete all log files
            if let files = try? FileManager.default.contentsOfDirectory(at: self.logDirectory, includingPropertiesForKeys: nil) {
                for file in files where file.pathExtension == "log" {
                    try? FileManager.default.removeItem(at: file)
                }
            }
            self.log("Logs cleared", level: .info)
        }
    }

    func exportLogs() -> URL? {
        let exportPath = FileManager.default.temporaryDirectory.appendingPathComponent("AnyGPT_Logs_\(Date().timeIntervalSince1970).zip")

        logQueue.sync {
            // Create a zip of all log files
            let task = Process()
            task.launchPath = "/usr/bin/zip"
            task.arguments = ["-r", exportPath.path, "."]
            task.currentDirectoryPath = logDirectory.path

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            task.launch()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                return exportPath
            }
        }

        return nil
    }

    // Get recent log entries for display in UI
    func getRecentLogs(lines: Int = 100) -> String {
        guard FileManager.default.fileExists(atPath: logFile.path) else {
            return "No logs available"
        }

        do {
            let content = try String(contentsOf: logFile, encoding: .utf8)
            let allLines = content.components(separatedBy: .newlines)

            let recentLines = allLines.suffix(lines)
            return recentLines.joined(separator: "\n")
        } catch {
            return "Error reading logs: \(error.localizedDescription)"
        }
    }
}