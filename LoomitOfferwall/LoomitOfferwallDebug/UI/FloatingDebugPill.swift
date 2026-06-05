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
        self.window = window
        
        let pillView = createPillView()
        window.addSubview(pillView)
        window.isHidden = false
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
    
    private func createPillView() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.9)
        container.layer.cornerRadius = 20
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        container.layer.shadowOpacity = 0.3
        
        let icon = UIImageView(image: UIImage(systemName: "ladybug.fill"))
        icon.tintColor = .white
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = "Debug"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(icon)
        container.addSubview(label)
        
        // Position at right center of screen
        if let window = window {
            container.frame = CGRect(
                x: window.bounds.width - 90,
                y: window.bounds.height / 2 - 20,
                width: 80,
                height: 40
            )
        }
        
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20),
            
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 6),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10)
        ])
        
        return container
    }
    
    @objc private func handleTap() {
        onTap?()
    }
}
