//
//  BonjourDiscovery.swift
//  Escanor Player
//
//  Created by Mohamed Ali on 16/11/2025.
//

import Foundation
import Network
import Combine

struct DiscoveredSMB: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let host: String
    let port: Int
}

final class BonjourDiscovery: NSObject, ObservableObject {
    @Published private(set) var services: [DiscoveredSMB] = []
    @Published private(set) var isSearching = false

    private let browser = NetServiceBrowser()
    private var currentServices: [NetService] = []
    private let serviceTypes = ["_smb._tcp"]

    override init() {
        super.init()
        browser.delegate = self
    }

    func start() {
        services.removeAll()
        currentServices.removeAll()
        browser.stop()
        isSearching = true
        for type in serviceTypes {
            browser.searchForServices(ofType: type, inDomain: "local.")
        }
    }

    func stop() {
        browser.stop()
        isSearching = false
    }
}

extension BonjourDiscovery: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        currentServices.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        if let idx = currentServices.firstIndex(of: service) {
            currentServices.remove(at: idx)
            DispatchQueue.main.async {
                self.services.removeAll { $0.name == service.name }
            }
        }
    }
}

extension BonjourDiscovery: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let hostName = sender.hostName else { return }
        let discovered = DiscoveredSMB(name: sender.name, host: hostName, port: sender.port)
        DispatchQueue.main.async {
            self.services.append(discovered)
        }
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
#if DEBUG
        print("Failed to resolve: \(sender.name) error: \(errorDict)")
#endif
    }
}

