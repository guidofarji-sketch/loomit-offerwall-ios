//
//  LoomitOfferwallBridgeWrapper.swift
//  LoomitOfferwallCore
//
//  @objc wrapper class for Unity iOS bridge.
//
//  This class lives INSIDE the SDK pod and exposes synchronous @objc methods
//  that wrap the async OfferwallSdk actor. It also implements OfferwallListener
//  to forward callbacks to Unity via UnitySendMessage.
//
//  Architecture: C# → C functions (.m) → @objc methods (this class) → OfferwallSdk (actor)
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// @objc wrapper that bridges Unity ↔ OfferwallSdk actor.
/// Lives INSIDE the SDK pod so it links against the SDK at build time.
@objc public class LoomitOfferwallBridgeWrapper: NSObject {

    @objc public static let shared = LoomitOfferwallBridgeWrapper()

    private let sdk = OfferwallSdk.shared
    private var unityGameObject: String = "LoomitOfferwallManager"
    private var isSdkInitialized: Bool = false

    // MARK: - UnitySendMessage

    @_silgen_name("UnitySendMessage")
    private func UnitySendMessage(_ gameObject: UnsafePointer<CChar>, _ method: UnsafePointer<CChar>, _ message: UnsafePointer<CChar>)

    private func sendToUnity(_ method: String, _ message: String) {
        let go = unityGameObject
        go.withCString { gameObjectPtr in
            method.withCString { methodPtr in
                message.withCString { messagePtr in
                    UnitySendMessage(gameObjectPtr, methodPtr, messagePtr)
                }
            }
        }
    }

    // MARK: - View Controller Helpers

    @_silgen_name("UnityGetGLViewController")
    private func UnityGetGLViewController() -> UIViewController?

    private func getTopmostViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first else {
            return UnityGetGLViewController()
        }

        var topVC = window.rootViewController
        while let presentedVC = topVC?.presentedViewController {
            if presentedVC.view == nil || presentedVC.isBeingDismissed {
                break
            }
            topVC = presentedVC
        }

        return topVC ?? UnityGetGLViewController()
    }

    // MARK: - API Key Resolution

    private func resolveApiKey() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "LoomitApiKey") as? String
    }

    // MARK: - Public API: Initialization

    @objc public func initialize(gameObject: String, clientId: String, userId: String?, appId: String?) {
        unityGameObject = gameObject.isEmpty ? "LoomitOfferwallManager" : gameObject

        print("[LoomitBridgeWrapper] initialize(gameObject=\(gameObject), clientId=\(clientId))")

        Task {
            // Guard: Skip duplicate initialization
            if self.isSdkInitialized {
                print("[LoomitBridgeWrapper] SDK already initialized (guard preventing duplicate init)")
                await self.sdk.setListener(self)
                return
            }

            if let apiKey = self.resolveApiKey(), !apiKey.isEmpty {
                await self.sdk.setLoomitApiKey(apiKey)
            } else {
                print("[LoomitBridgeWrapper] WARNING: No LoomitApiKey found in Info.plist")
            }

            if !clientId.isEmpty { await self.sdk.setClientId(clientId) }
            if let appId = appId, !appId.isEmpty { await self.sdk.setAppId(appId) }
            if let userId = userId, !userId.isEmpty { await self.sdk.setPublisherUserId(userId) }

            await self.sdk.registerAdapter(TapjoyAdapter())
            await self.sdk.registerAdapter(MyChipsAdapter())

            await self.sdk.setListener(self)

            self.isSdkInitialized = true
        }
    }

    // MARK: - Public API: User Management

    @objc public func setUserId(_ userId: String?) {
        Task { await sdk.setPublisherUserId(userId) }
    }

    @objc public func clearUserId() {
        Task { await sdk.clearPublisherUserId() }
    }

    @objc public func getUserId() -> String? {
        // Note: This is async internally but we can't await in @objc.
        // For now return nil; the .m bridge uses syncAwait pattern if needed.
        // The wrapper is called from .m which runs on main thread.
        // We'll use a synchronous wait for simple getters.
        let semaphore = DispatchSemaphore(value: 0)
        var result: String?
        Task {
            result = await sdk.getPublisherUserId()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    @objc public func getXifa() -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var result: String = ""
        Task {
            result = await sdk.xifa()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    // MARK: - Public API: Show/Close

    @objc public func show() {
        Task { @MainActor in
            guard let vc = self.getTopmostViewController() else {
                print("[LoomitBridgeWrapper] ERROR: No ViewController available for show()")
                self.sendToUnity("OnOfferwallShowFailed", "No ViewController")
                return
            }
            await self.sdk.show(from: vc)
        }
    }

    @objc public func showWithProviderAndAdSpace(providerOverride: String?, adSpace: String?) {
        let provider = providerOverride?.isEmpty == true ? nil : providerOverride
        let space = adSpace?.isEmpty == true ? nil : adSpace

        print("[LoomitBridgeWrapper] showWithProviderAndAdSpace: USER REQUEST")

        Task { @MainActor in
            guard let vc = self.getTopmostViewController() else {
                self.sendToUnity("OnOfferwallShowFailed", "No ViewController")
                return
            }
            await self.sdk.show(from: vc, providerOverride: provider, adSpace: space)
        }
    }

    @objc public func close() {
        Task { await sdk.close() }
    }

    @objc public func failoverToNext() {
        Task { @MainActor in
            guard let vc = self.getTopmostViewController() else {
                self.sendToUnity("OnOfferwallShowFailed", "Failover failed: No ViewController")
                return
            }
            _ = await self.sdk.failoverToNext(from: vc, adSpace: nil)
        }
    }

    // MARK: - Public API: Availability

    @objc public func hasAvailableOfferwall() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var result = false
        Task {
            result = await sdk.hasAvailableOfferwall()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    @objc public func getActiveProviderName() -> String? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: String?
        Task {
            result = await sdk.getActiveProviderName()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    @objc public func getAvailableProviders() -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var result: [String] = []
        Task {
            result = await sdk.getAvailableProviders()
            semaphore.signal()
        }
        semaphore.wait()
        let jsonArray = try? JSONEncoder().encode(result)
        return String(data: jsonArray ?? Data(), encoding: .utf8) ?? "[]"
    }

    // MARK: - Public API: Config

    @objc public func fetchConfig() {
        print("[LoomitBridgeWrapper] fetchConfig: USER REQUEST")
        Task {
            do {
                _ = try await sdk.fetchConfig()
                print("[LoomitBridgeWrapper] fetchConfig: SUCCESS")
            } catch {
                print("[LoomitBridgeWrapper] fetchConfig: FAILED - \(error.localizedDescription)")
                self.sendToUnity("OnConfigFetchFailed", "fetchConfig failed: \(error.localizedDescription)")
            }
        }
    }

    @objc public func initializeProviders() {
        print("[LoomitBridgeWrapper] initializeProviders: USER REQUEST")
        Task {
            await sdk.initAllFromPlan()
            print("[LoomitBridgeWrapper] initializeProviders: COMPLETED")
        }
    }

    @objc public func getLastSegmentName() -> String? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: String?
        Task {
            result = await sdk.getLastSegmentName()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    @objc public func hasActiveExperiments() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var result = false
        Task {
            result = await sdk.hasActiveExperiments()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    @objc public func getLastExperimentAssignments() -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var result: [ExperimentAssignment] = []
        Task {
            result = await sdk.getLastExperimentAssignments()
            semaphore.signal()
        }
        semaphore.wait()
        let assignmentsArray = result.map { exp -> [String: Any] in
            var dict: [String: Any] = [
                "name": exp.name,
                "group": exp.group ?? "",
                "isActive": exp.isActive
            ]
            if !exp.rawPayload.isEmpty {
                dict["rawPayload"] = exp.rawPayload
            }
            return dict
        }
        if let data = try? JSONSerialization.data(withJSONObject: assignmentsArray),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return "[]"
    }

    @objc public func getLastRawConfigResponse() -> String? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: String?
        Task {
            result = await sdk.getLastRawConfigResponse()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    @objc public func getProviderPlanJson() -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var result: [ProviderPlanEntry] = []
        Task {
            result = await sdk.getProviderPlan()
            semaphore.signal()
        }
        semaphore.wait()
        let planArray = result.map { entry -> [String: Any] in
            [
                "provider": entry.providerId,
                "placement": entry.placement ?? "",
                "credentials": entry.credentials.isEmpty ? "{}" : "[present]",
                "priority": entry.priority,
                "isActive": entry.isActive
            ]
        }
        if let data = try? JSONSerialization.data(withJSONObject: planArray),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return "[]"
    }

    @objc public func getLastConfigSource() -> String? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: String?
        Task {
            result = await sdk.getLastConfigSource()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    @objc public func getConfigRequestPreview(clientId: String, appId: String?) -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var result: String = ""
        Task {
            result = await sdk.getConfigRequestPreview(clientId: clientId, appId: appId?.isEmpty == true ? nil : appId)
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    // MARK: - Public API: Custom Properties

    @objc public func setCustomProperty(key: String, value: String?) {
        let sanitizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedKey.isEmpty else { return }
        let sanitizedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalValue = sanitizedValue?.isEmpty == true ? nil : sanitizedValue
        Task { await sdk.setCustomProperty(sanitizedKey, value: finalValue) }
    }

    @objc public func removeCustomProperty(key: String) {
        Task { await sdk.removeCustomProperty(key) }
    }

    @objc public func clearCustomProperties() {
        Task { await sdk.clearCustomProperties() }
    }

    @objc public func setCustomPropertiesFromJson(json: String) {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return }
        Task { await sdk.setCustomProperties(dict) }
    }

    // MARK: - Public API: Privacy

    @objc public func setPrivacyOverrides(subjectToGdpr: Bool, gdprConsent: Bool, ccpaOptOut: Bool,
                                          tcfConsentString: String?, usPrivacyString: String?) {
        let tcf = tcfConsentString?.isEmpty == true ? nil : tcfConsentString
        let usPrivacy = usPrivacyString?.isEmpty == true ? nil : usPrivacyString
        Task {
            await sdk.setPrivacy(
                tcfConsentString: tcf,
                usPrivacyString: usPrivacy,
                subjectToGdpr: subjectToGdpr,
                gdprConsent: gdprConsent,
                ccpaOptOut: ccpaOptOut
            )
        }
    }

    // MARK: - Public API: Advertising

    @objc public func setAdvertisingId(_ advertisingId: String?) {
        let adId = advertisingId?.isEmpty == true ? nil : advertisingId
        Task { await sdk.setAdvertisingId(adId) }
    }

    @objc public func setHasAdvertisingId(_ has: Bool) {
        Task { await sdk.setHasAdvertisingId(has) }
    }

    // MARK: - Public API: Debug

    @objc public func setDebuggingEnabled(_ enabled: Bool) {
        Task {
            await sdk.setDebuggingEnabled(enabled)
            if enabled {
                await MainActor.run {
                    let collector = DebugDataCollector()
                    DebugPanel.initialize(dataCollector: collector)
                    DebugPanel.setEnabled(true)
                }
            } else {
                await MainActor.run {
                    DebugPanel.setEnabled(false)
                }
            }
        }
    }

    @objc public func isDebuggingEnabled() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var result = false
        Task {
            result = await sdk.isDebuggingEnabled()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    @objc public func showDebugPanel() {
        Task { @MainActor in
            guard let viewController = self.getTopmostViewController() else {
                print("[LoomitBridgeWrapper] showDebugPanel: No view controller available")
                return
            }
            if !DebugPanel.isEnabled() {
                DebugPanel.setEnabled(true)
            }
            DebugPanel.show(from: viewController)
        }
    }

    // MARK: - Public API: Environment

    @objc public func setEnvironment(_ envString: String) {
        print("[LoomitBridgeWrapper] setEnvironment(\(envString))")
        Task {
            let environment: BackendEnvironment
            switch envString.lowercased() {
            case "live", "production":
                environment = .live
            case "test", "staging":
                environment = .test
            default:
                if let url = URL(string: envString) {
                    environment = .custom(baseURL: url)
                } else {
                    print("[LoomitBridgeWrapper] WARNING: Invalid environment '\(envString)', defaulting to live")
                    environment = .live
                }
            }
            await sdk.setEnvironment(environment)
        }
    }

    // MARK: - Public API: Tracking

    @objc public func enableTracking() {
        // Tracking is enabled by default; no separate API needed on iOS
    }

    @objc public func disableTracking() {
        // Tracking opt-out handled via setPrivacy on iOS
    }
}

// MARK: - OfferwallListener

extension LoomitOfferwallBridgeWrapper: OfferwallListener {

    public func offerwallDidInitialize() {
        print("[LoomitBridgeWrapper] offerwallDidInitialize: Providers ready - sending to Unity")
        sendToUnity("OnOfferwallInitialized", "")
    }

    public func offerwall(didFailToInitialize reason: String) {
        print("[LoomitBridgeWrapper] offerwall(didFailToInitialize): \(reason)")
        sendToUnity("OnOfferwallInitializationFailed", reason)
    }

    public func offerwall(didReceiveConfig result: Result<ConfigResponse, OfferwallError>) {
        switch result {
        case .success(let config):
            if let json = try? String(data: JSONEncoder().encode(config), encoding: .utf8) {
                print("[LoomitBridgeWrapper] offerwall(didReceiveConfig): Config received")
                sendToUnity("OnConfigFetched", json)
            }
        case .failure(let error):
            print("[LoomitBridgeWrapper] offerwall(didReceiveConfig): Failed - \(error.localizedDescription)")
            sendToUnity("OnConfigFetchFailed", error.localizedDescription)
        }
    }

    public func offerwall(didChangeAvailability available: Bool) {
        sendToUnity("OnOfferwallAvailabilityChanged", available ? "true" : "false")
    }

    public func offerwall(didShow providerKey: String, adSpace: String?) {
        sendToUnity("OnOfferwallShow", providerKey)
    }

    public func offerwall(didFailToShow error: OfferwallError, adSpace: String?) {
        sendToUnity("OnOfferwallShowFailed", error.localizedDescription)
    }

    public func offerwall(didClose providerKey: String) {
        sendToUnity("OnOfferwallClose", providerKey)
    }

    public func offerwall(didEarnRewardAmount amount: Int, currency: String, providerKey: String) {
        let json = "{\"provider\":\"\(providerKey)\",\"currency\":\"\(currency)\",\"amount\":\(amount)}"
        sendToUnity("OnOfferwallRewardReceived", json)
    }
}
