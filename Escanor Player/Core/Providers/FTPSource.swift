//
//  FTPSource.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation
import Network

// MARK: - FTP Source

final class FTPSource: RemoteSource {
    private let client: FTPClient
    private let filter: ItemFilter

    var displayName: String { "FTP \(client.hostDisplay)" }

    init(host: String, port: Int?, username: String?, password: String?, passive: Bool?, filter: ItemFilter = .videoAndDirectories) {
        self.client = FTPClient(
            host: host,
            port: port ?? 21,
            username: username,
            password: password,
            passive: passive ?? true
        )
        self.filter = filter
    }

    func list(at path: String) async throws -> [RemoteItem] {
        let entries = try await client.list(path: path)
        return entries.compactMap { entry in
            guard filter.allows(name: entry.name, isDirectory: entry.isDirectory) else { return nil }
            return RemoteItem(
                path: entry.path,
                name: entry.name,
                isDirectory: entry.isDirectory,
                size: entry.size,
                modifiedAt: entry.modifiedAt
            )
        }
    }

    func openFile(at path: String) async throws -> String {
        // Prefer a credentialed FTP URL for streaming; caller can fallback to download if needed.
        return client.makeFileURL(for: path).absoluteString
    }
}

// MARK: - FTP Client

private struct FTPEntry {
    let path: String
    let name: String
    let isDirectory: Bool
    let size: Int?
    let modifiedAt: Date?
}

private struct FTPReply {
    let code: Int
    let message: String
}

private actor FTPClient {
    let host: String
    let port: Int
    let username: String?
    let password: String?
    let passive: Bool

    var hostDisplay: String { port == 21 ? host : "\(host):\(port)" }

    private var controlConnection: NWConnection?
    private var controlBuffer = Data()
    private var isConnected = false

    init(host: String, port: Int, username: String?, password: String?, passive: Bool) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.passive = passive
    }

    // MARK: Public API

    func list(path: String) async throws -> [FTPEntry] {
        try await ensureLoggedIn()

        let dataConnection = try await openPassiveDataConnection()
        let normalizedPath = normalized(path)
        let listReply = try await sendCommand("LIST \(normalizedPath)")
        guard listReply.code == 150 || listReply.code == 125 else {
            throw ftpError("LIST failed: \(listReply.message)")
        }

        let listingData = try await receiveData(from: dataConnection)
        let _ = try? await readReply() // Swallow final 226/250 message if available.

        guard let listingString = String(data: listingData, encoding: .utf8) else {
            throw ftpError("Unable to decode directory listing")
        }

        let lines = listingString.components(separatedBy: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return lines.compactMap { parseUnixList($0, in: normalizedPath) }
    }

    func makeFileURL(for path: String) -> URL {
        let normalizedPath = normalized(path)
        var components = URLComponents()
        components.scheme = "ftp"
        components.host = host
        components.port = port
        components.user = username
        components.password = password
        components.path = normalizedPath
        return components.url ?? URL(string: "ftp://\(hostDisplay)\(normalizedPath)")!
    }

    // MARK: Connection lifecycle

    private func ensureLoggedIn() async throws {
        if isConnected { return }
        try await openControlConnection()
        let greeting = try await readReply()
        guard greeting.code == 220 else {
            throw ftpError("Server rejected connection: \(greeting.message)")
        }

        let user = username?.isEmpty == false ? username! : "anonymous"
        let pass = password ?? "guest"
        let userReply = try await sendCommand("USER \(user)")
        if userReply.code == 331 { // Need password
            let passReply = try await sendCommand("PASS \(pass)")
            guard passReply.code == 230 || passReply.code == 202 else {
                throw ftpError("Authentication failed: \(passReply.message)")
            }
        } else if userReply.code != 230 && userReply.code != 202 {
            throw ftpError("Authentication failed: \(userReply.message)")
        }

        // Binary mode to avoid text mangling.
        _ = try? await sendCommand("TYPE I")
        isConnected = true
    }

    private func openControlConnection() async throws {
        guard controlConnection == nil else { return }
        let portValue = NWEndpoint.Port(rawValue: UInt16(port)) ?? .init(integerLiteral: 21)
        let connection = NWConnection(host: NWEndpoint.Host(host), port: portValue, using: .tcp)
        controlConnection = connection
        try await start(connection)
    }

    private func openPassiveDataConnection() async throws -> NWConnection {
        guard passive else {
            throw ftpError("Active mode not supported")
        }
        do {
            let reply = try await sendCommand("PASV")
            guard reply.code == 227 else {
                throw ftpError("PASV failed: \(reply.message)")
            }

            let (host, port) = try parsePassiveHostAndPort(from: reply.message)
            let portValue = NWEndpoint.Port(rawValue: UInt16(port)) ?? .init(integerLiteral: 21)
            let connection = NWConnection(host: NWEndpoint.Host(host), port: portValue, using: .tcp)
            try await start(connection)
            return connection
        } catch {
            // Try EPSV as a fallback for servers that only support extended passive.
            let epsv = try await sendCommand("EPSV")
            guard epsv.code == 229, let port = parseExtendedPassivePort(from: epsv.message) else {
                throw error
            }
            let portValue = NWEndpoint.Port(rawValue: UInt16(port)) ?? .init(integerLiteral: 21)
            let connection = NWConnection(host: NWEndpoint.Host(host), port: portValue, using: .tcp)
            try await start(connection)
            return connection
        }
    }

    private func start(_ connection: NWConnection) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            var resumed = false
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume(returning: ())
                case .failed(let error):
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume(throwing: error)
                case .cancelled:
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume(throwing: ftpError("Connection cancelled"))
                default:
                    break
                }
            }
            connection.start(queue: .global())
        }
    }

    // MARK: Command/response helpers

    private func sendCommand(_ command: String) async throws -> FTPReply {
        let line = command + "\r\n"
        try await send(Data(line.utf8))
        return try await readReply()
    }

    private func send(_ data: Data) async throws {
        guard let controlConnection else { throw ftpError("Control connection unavailable") }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            controlConnection.send(content: data, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }

    private func readReply() async throws -> FTPReply {
        var lines: [String] = []
        while true {
            if let line = nextLine() {
                lines.append(line)
                if replyIsComplete(lines: lines) {
                    return try parseReply(lines: lines)
                }
                continue
            }
            let chunk = try await receiveControlChunk()
            guard !chunk.isEmpty else { throw ftpError("Connection closed") }
            controlBuffer.append(chunk)
        }
    }

    private func receiveControlChunk() async throws -> Data {
        guard let controlConnection else { throw ftpError("Control connection unavailable") }
        return try await withCheckedThrowingContinuation { continuation in
            controlConnection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, isComplete, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                } else if isComplete {
                    continuation.resume(returning: Data())
                } else {
                    continuation.resume(throwing: ftpError("Unknown control receive state"))
                }
            }
        }
    }

    private func nextLine() -> String? {
        guard let range = controlBuffer.range(of: Data([13, 10])) else { return nil }
        let lineData = controlBuffer.subdata(in: 0..<range.lowerBound)
        controlBuffer.removeSubrange(0..<range.upperBound)
        return String(data: lineData, encoding: .utf8)
    }

    private func parseReply(lines: [String]) throws -> FTPReply {
        guard let first = lines.first else { throw ftpError("Empty reply") }
        let trimmed = first.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3, let code = Int(trimmed.prefix(3)) else {
            throw ftpError("Bad reply: \(first)")
        }

        let strip: (String) -> String = { line in
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.count >= 4 {
                return String(trimmedLine.dropFirst(4))
            }
            return ""
        }

        let messageParts: [String]
        if trimmed.dropFirst(3).first == "-" {
            messageParts = lines.map(strip)
        } else {
            messageParts = [strip(first)]
        }
        let message = messageParts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return FTPReply(code: code, message: message)
    }

    private func replyIsComplete(lines: [String]) -> Bool {
        guard let first = lines.first else { return false }
        let trimmed = first.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return false }
        let codePrefix = trimmed.prefix(3)
        if trimmed.dropFirst(3).first != "-" {
            return true
        }
        guard let last = lines.last else { return false }
        let lastTrimmed = last.trimmingCharacters(in: .whitespacesAndNewlines)
        return lastTrimmed.hasPrefix(codePrefix + " ") || lastTrimmed == codePrefix
    }

    // MARK: Data transfer

    private func receiveData(from connection: NWConnection) async throws -> Data {
        var output = Data()
        while true {
            let (data, isComplete): (Data, Bool) = try await withCheckedThrowingContinuation { continuation in
                connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    if let data {
                        continuation.resume(returning: (data, isComplete))
                        return
                    }
                    continuation.resume(returning: (Data(), isComplete))
                }
            }

            output.append(data)
            if isComplete { break }
        }
        connection.cancel()
        return output
    }

    // MARK: Parsing helpers

    private func parsePassiveHostAndPort(from message: String) throws -> (String, Int) {
        // Expected: entering Passive Mode (h1,h2,h3,h4,p1,p2)
        guard let start = message.firstIndex(of: "("), let end = message.firstIndex(of: ")"), end > start else {
            throw ftpError("Invalid PASV response: \(message)")
        }
        let payload = message[message.index(after: start)..<end]
        let parts = payload.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 6 else { throw ftpError("Invalid PASV host/port: \(message)") }
        let host = parts.prefix(4).map(String.init).joined(separator: ".")
        let port = (parts[4] << 8) + parts[5]
        return (host, port)
    }

    private func parseExtendedPassivePort(from message: String) -> Int? {
        // Expected format: Entering Extended Passive Mode (|||port|)
        guard let start = message.firstIndex(of: "("), let end = message.firstIndex(of: ")"), end > start else {
            return nil
        }
        let payload = message[message.index(after: start)..<end]
        let parts = payload.split(separator: "|")
        guard parts.count >= 4, let port = Int(parts[3]) else { return nil }
        return port
    }

    private func normalized(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmed.isEmpty { return "/" }
        return "/" + trimmed
    }

    private func parseUnixList(_ text: String, in basePath: String) -> FTPEntry? {
        // Expect format: drwxr-xr-x  4 user group 4096 Jan 01 12:34 Name
        let components = text.components(separatedBy: .whitespaces).compactMap { $0.isEmpty ? nil : $0 }
        guard components.count >= 9 else { return nil }

        let permissions = components[0]
        let size = Int(components[4])
        let dateString = components[5..<8].joined(separator: " ")
        let name = components[8..<components.count].joined(separator: " ")
        guard name != "." && name != ".." else { return nil }

        let isDir: Bool
        if let first = permissions.first {
            isDir = first == "d"
        } else {
            isDir = false
        }

        let entryDate = parseUnixDate(dateString)
        let cleanedBase = basePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let fullPath = cleanedBase.isEmpty ? name : "\(cleanedBase)/\(name)"

        return FTPEntry(
            path: fullPath,
            name: name,
            isDirectory: isDir,
            size: isDir ? nil : size,
            modifiedAt: entryDate
        )
    }

    private func parseUnixDate(_ raw: String) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let thisYear = calendar.component(.year, from: now)

        let nearFormatter = DateFormatter()
        nearFormatter.calendar = calendar
        nearFormatter.locale = Locale(identifier: "en_US_POSIX")
        nearFormatter.dateFormat = "MMM dd HH:mm yyyy"

        let farFormatter = DateFormatter()
        farFormatter.calendar = calendar
        farFormatter.locale = Locale(identifier: "en_US_POSIX")
        farFormatter.dateFormat = "MMM dd yyyy"

        if let near = nearFormatter.date(from: raw + " \(thisYear)") {
            if near > now, let lastYear = calendar.date(byAdding: .year, value: -1, to: near) {
                return lastYear
            }
            return near
        }
        return farFormatter.date(from: raw)
    }
}

private func ftpError(_ message: String) -> NSError {
    NSError(domain: "FTPSource", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
}
