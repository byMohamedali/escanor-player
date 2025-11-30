# Escanor Player - Provider System Specification

## Overview
This document describes how Escanor Player should implement and structure provider sources (local shares, network shares, and cloud services), including models, enums, persistence, flows, and MVP scope.  
The goal is to create a clean, future-proof architecture that supports all types of shares, while keeping the MVP implementation simple: **Local Folder + SMB only**.

---

# 1. Provider Types (Add Share Screen)

The “Add Share” screen lists provider options such as SMB, FTP, Dropbox, Google Drive, etc.  
This list must be fully data-driven using two enums:

---

## 1.1 ProviderCategory

Groups provider types visually in the UI.

```swift
enum ProviderCategory: String, CaseIterable, Identifiable {
    case local
    case network
    case cloud
    case other

    var id: Self { self }

    var title: String {
        switch self {
        case .local: return "Local Shares"
        case .network: return "Network Shares"
        case .cloud: return "Cloud Services"
        case .other: return "Other"
        }
    }
}
```

---

## 1.2 ProviderKind

Represents each “Add XXX” option.

```swift
enum ProviderKind: String, CaseIterable, Identifiable, Codable {
    case localFolder
    case smb
    case ftp
    case nfs
    case webdav
    case googleDrive
    case dropbox
    case oneDrive
    case box
    case directURL
    case browser
    case usbCable

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .localFolder: return "Add Local Folder"
        case .smb:         return "Add SMB"
        case .ftp:         return "Add FTP"
        case .nfs:         return "Add NFS"
        case .webdav:      return "Add WebDAV"
        case .googleDrive: return "Add Google Drive"
        case .dropbox:     return "Add Dropbox"
        case .oneDrive:    return "Add OneDrive"
        case .box:         return "Add Box"
        case .directURL:   return "Direct URL"
        case .browser:     return "Browser"
        case .usbCable:    return "USB Cable"
        }
    }

    var category: ProviderCategory {
        switch self {
        case .localFolder: return .local
        case .smb, .ftp, .nfs, .webdav: return .network
        case .googleDrive, .dropbox, .oneDrive, .box: return .cloud
        case .directURL, .browser, .usbCable: return .other
        }
    }

    var systemImage: String {
        switch self {
        case .localFolder: return "folder"
        case .smb:         return "server.rack"
        case .ftp:         return "arrow.up.arrow.down.circle"
        case .nfs:         return "square.stack.3d.down.forward"
        case .webdav:      return "externaldrive"
        case .googleDrive: return "triangle"
        case .dropbox:     return "shippingbox"
        case .oneDrive:    return "cloud"
        case .box:         return "cube.box"
        case .directURL:   return "link"
        case .browser:     return "safari"
        case .usbCable:    return "cable.connector"
        }
    }

    // MVP scope
    var isImplementedInMVP: Bool {
        switch self {
        case .localFolder, .smb:
            return true
        default:
            return false
        }
    }
}
```

---

# 2. AddShareView (UI)

A fully data-driven UI.

```swift
struct AddShareView: View {
    private let providers = ProviderKind.allCases

    var body: some View {
        List {
            ForEach(ProviderCategory.allCases) { category in
                Section(category.title) {
                    ForEach(providers.filter { $0.category == category }) { provider in
                        Button {
                            handle(provider)
                        } label: {
                            HStack {
                                Image(systemName: provider.systemImage)
                                Text(provider.displayName)
                            }
                        }
                        .disabled(!provider.isImplementedInMVP)
                        .opacity(provider.isImplementedInMVP ? 1 : 0.4)
                    }
                }
            }
        }
        .navigationTitle("Add Share")
    }

    private func handle(_ provider: ProviderKind) {
        // MVP: handle only .localFolder and .smb
    }
}
```

---

# 3. Saved Shares

Saved shares appear under “Saved Shares” and represent configured connections.

---

## 3.1 SavedShare model

```swift
struct SavedShare: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var kind: SavedShareKind
    var lastAccess: Date?

    init(name: String, kind: SavedShareKind) {
        self.id = UUID()
        self.name = name
        self.kind = kind
        self.lastAccess = nil
    }
}
```

---

## 3.2 SavedShareKind

Supports all future sources.  
For MVP, only `.localFolder` and `.smb` are required.

```swift
enum SavedShareKind: Codable, Equatable {
    case localFolder(url: URL)
    case smb(host: String, username: String?, password: String?)
    case ftp(host: String)
    case nfs(host: String)
    case webdav(url: URL)
    case googleDrive(accountID: String)
    case dropbox(accountID: String)
    case oneDrive(accountID: String)
    case box(accountID: String)
    case directURL(url: URL)
}
```

---

# 4. Persistence (Defaults)

Use `Defaults` with iCloud sync.

```swift
extension Defaults.Keys {
    static let savedShares = Key<[SavedShare]>("savedShares", iCloud: true) { [] }
}
```

---

# 5. SavedSharesStore

```swift
final class SavedSharesStore: ObservableObject {
    @Default(.savedShares) private var storedShares
    @Published private(set) var shares: [SavedShare] = []

    init() {
        shares = storedShares
    }

    func add(_ share: SavedShare) {
        shares.append(share)
        storedShares = shares
    }

    func remove(_ share: SavedShare) {
        shares.removeAll { $0.id == share.id }
        storedShares = shares
    }
}
```

---

# 6. MVP Flow Requirements

## MVP must support:

### **Local Folder**
- Pick folder (via Files app)
- Create `SavedShareKind.localFolder(url:)`
- Save to `SavedSharesStore`
- Browse folder contents
- Play video using PlayerKit

### **SMB**
- “Add SMB” → simple form:
  - Name  
  - Host  
  - Username  
  - Password
- Save as `SavedShareKind.smb`
- Browse SMB directory tree
- Play files via PlayerKit (stream URL or direct access layer)

---

# 7. What is NOT in MVP

Do NOT implement:
- FTP
- WebDAV
- NFS
- Google Drive
- Dropbox
- OneDrive
- Box
- Direct URL
- Browser uploader
- USB cable import

These are scheduled for future phases.

---

# End of Document
