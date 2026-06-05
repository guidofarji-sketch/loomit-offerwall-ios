//
//  DebugPanel.swift
//  LoomitOfferwallDebug
//
//  Entry point para la Debugging Suite del SDK.
//  Paridad con Android DebugPanel.kt
//

import UIKit
import LoomitOfferwallCore

/// Coordinador principal de la Debugging Suite.
/// Se activa automáticamente cuando debugging está habilitado.
@MainActor
public final class DebugPanel {

    public static let shared = DebugPanel()

    private var coordinator: DebugPanelCoordinator?
    private var isEnabled = false
    private var collector: DebugDataCollectorBridge?

    private init() {}
    
    /// Verifica si el debug panel está habilitado
    public static func isEnabled() -> Bool {
        return shared.isEnabled
    }
    
    /// Activa/desactiva el debug panel manualmente
    public static func setEnabled(_ enabled: Bool) {
        shared.isEnabled = enabled
        if enabled {
            shared.startMonitoring()
        } else {
            shared.stopMonitoring()
        }
    }

    /// Inicializa el DebugPanel e inyecta el DebugDataCollector en el SDK
    /// Debe llamarse después de setDebuggingEnabled en el SDK
    public static func initialize(dataCollector: DebugDataCollectorBridge) {
        shared.collector = dataCollector
        Task {
            await OfferwallSdk.shared.setDebugDataCollector(dataCollector)
            // Aplica el environment persistido (paridad con Android loadSavedEnvironmentPreference)
            await OfferwallSdk.shared.loadAndApplyDebugEnvironmentIfNeeded()
        }
    }

    /// Obtiene el collector inyectado (usado por DebugPanelViewController)
    internal static func getCollector() -> DebugDataCollectorBridge? {
        return shared.collector
    }
    
    /// Muestra el debug panel inmediatamente (para botón manual)
    public static func show(from viewController: UIViewController) {
        guard shared.isEnabled else { return }
        // Prevent multiple instances from being presented simultaneously
        guard !shared.isPresenting else {
            print("[DebugPanel] Already presenting, ignoring duplicate show request")
            return
        }
        shared.isPresenting = true
        shared.coordinator?.showDebugPanel(from: viewController) {
            shared.isPresenting = false
        }
    }
    
    private var isPresenting = false
    
    /// Inicia el monitoreo (shake detector)
    private func startMonitoring() {
        guard coordinator == nil else { return }
        coordinator = DebugPanelCoordinator()
        coordinator?.startMonitoring()
    }
    
    /// Detiene el monitoreo
    private func stopMonitoring() {
        coordinator?.stopMonitoring()
        coordinator = nil
    }
    
    /// Llamar desde OfferwallSdk cuando el debugging status cambia
    internal static func updateDebuggingStatus(_ status: Bool) {
        setEnabled(status)
    }
}

/// Coordinador interno que maneja el shake detector y la pill flotante
@MainActor
final class DebugPanelCoordinator {
    
    private var shakeDetector: ShakeDetector?
    private var floatingPill: FloatingDebugPill?
    private var isMonitoring = false
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        shakeDetector = ShakeDetector()
        shakeDetector?.onShake = { [weak self] in
            self?.showFloatingPill()
        }
        shakeDetector?.start()
    }
    
    func stopMonitoring() {
        isMonitoring = false
        shakeDetector?.stop()
        shakeDetector = nil
        hideFloatingPill()
    }
    
    private func showFloatingPill() {
        guard floatingPill == nil else { return }
        
        let pill = FloatingDebugPill()
        pill.onTap = { [weak self] in
            self?.hideFloatingPill()
            self?.showDebugPanel(from: nil)
        }
        pill.show()
        floatingPill = pill
        
        // Auto-hide after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.hideFloatingPill()
        }
    }
    
    private func hideFloatingPill() {
        floatingPill?.hide()
        floatingPill = nil
    }
    
    func showDebugPanel(from viewController: UIViewController?, onDismiss: (() -> Void)? = nil) {
        guard let topVC = viewController ?? UIApplication.shared.topViewController() else {
            onDismiss?()
            return
        }
        
        // Check if already presenting
        if let presented = topVC.presentedViewController as? UINavigationController,
           presented.viewControllers.first is DebugPanelViewController {
            print("[DebugPanelCoordinator] DebugPanel already presented, not presenting again")
            onDismiss?()
            return
        }
        
        let debugVC = DebugPanelViewController()
        let navVC = UINavigationController(rootViewController: debugVC)
        navVC.modalPresentationStyle = .fullScreen
        
        // Track dismissal to reset isPresenting flag
        debugVC.onDismiss = onDismiss
        
        topVC.present(navVC, animated: true)
    }
}

// MARK: - Helper Extensions

extension UIApplication {
    func topViewController() -> UIViewController? {
        guard let window = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return nil
        }
        return window.rootViewController?.topMostViewController()
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.topMostViewController() ?? nav
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        return self
    }
}
