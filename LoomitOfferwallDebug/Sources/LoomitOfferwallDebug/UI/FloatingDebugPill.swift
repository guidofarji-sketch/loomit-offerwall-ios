//
//  FloatingDebugPill.swift
//  LoomitOfferwallDebug
//
//  Pill flotante que aparece al detectar shake, similar a Android.
//

import UIKit

/// Pill flotante que aparece temporalmente para abrir el debug panel
@MainActor
final class FloatingDebugPill {
    
    private var pillView: UIView?
    private var window: UIWindow?
    
    var onTap: (() -> Void)?
    
    func show() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }
        
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .statusBar + 1
        window.makeKeyAndVisible()
        self.window = window
        
        let pillView = createPillView(in: scene.screen.bounds)
        window.addSubview(pillView)
        self.pillView = pillView
        
        // Animate in from right
        pillView.transform = CGAffineTransform(translationX: 100, y: 0)
        UIView.animate(withDuration: 0.3) {
            pillView.transform = .identity
        }
        
        // Add tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        pillView.addGestureRecognizer(tap)
    }
    
    func hide() {
        guard let pillView = pillView else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            pillView.transform = CGAffineTransform(translationX: 100, y: 0)
            pillView.alpha = 0
        }) { [weak self] _ in
            self?.pillView?.removeFromSuperview()
            self?.pillView = nil
            self?.window?.isHidden = true
            self?.window = nil
        }
    }
    
    private func createPillView(in screenBounds: CGRect) -> UIView {
        let pillWidth: CGFloat = 80
        let pillHeight: CGFloat = 40
        let container = UIView(frame: CGRect(
            x: screenBounds.width - pillWidth - 10,
            y: screenBounds.height / 2 - pillHeight / 2,
            width: pillWidth,
            height: pillHeight
        ))
        container.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.9)
        container.layer.cornerRadius = pillHeight / 2
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        container.layer.shadowOpacity = 0.3
        
        let icon = UIImageView(image: UIImage(systemName: "ladybug.fill"))
        icon.tintColor = .white
        icon.frame = CGRect(x: 10, y: 10, width: 20, height: 20)
        icon.contentMode = .scaleAspectFit
        
        let label = UILabel(frame: CGRect(x: 36, y: 0, width: 38, height: pillHeight))
        label.text = "Debug"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white
        
        container.addSubview(icon)
        container.addSubview(label)
        
        return container
    }
    
    @objc private func handleTap() {
        onTap?()
    }
}
