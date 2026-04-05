//
//  SceneDelegate.swift
//  SmartFinance
//
//  Created by Diyorbek Xikmatullayev on 22/03/26.
//

//import UIKit
//import FirebaseAuth
//
//class SceneDelegate: UIResponder, UIWindowSceneDelegate {
//
//    var window: UIWindow?
//
//    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//        guard let windowScene = (scene as? UIWindowScene) else { return }
//
//        window = UIWindow(windowScene: windowScene)
//        
//        // 💡 LOGIN TEKSHIRUVI:
//        // Agar foydalanuvchi kirgan bo'lsa - Dashboard, bo'lmasa - AuthViewController
//        let rootVC: UIViewController
//        if FirebaseAuth.Auth.auth().currentUser != nil {
////            rootVC = MainTabBarController()
//            rootVC = AuthViewController()
//        } else {
//            rootVC = AuthViewController()
//        }
//        
//        let navVC = UINavigationController(rootViewController: rootVC)
//        window?.rootViewController = navVC
//        window?.makeKeyAndVisible()
//    }
//
//    func sceneDidDisconnect(_ scene: UIScene) {
//        // Called as the scene is being released by the system.
//        // This occurs shortly after the scene enters the background, or when its session is discarded.
//        // Release any resources associated with this scene that can be re-created the next time the scene connects.
//        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
//    }
//
//    func sceneDidBecomeActive(_ scene: UIScene) {
//        // Called when the scene has moved from an inactive state to an active state.
//        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
//    }
//
//    func sceneWillResignActive(_ scene: UIScene) {
//        // Called when the scene will move from an active state to an inactive state.
//        // This may occur due to temporary interruptions (ex. an incoming phone call).
//    }
//
//    func sceneWillEnterForeground(_ scene: UIScene) {
//        // Called as the scene transitions from the background to the foreground.
//        // Use this method to undo the changes made on entering the background.
//    }
//
//    func sceneDidEnterBackground(_ scene: UIScene) {
//        // Called as the scene transitions from the foreground to the background.
//        // Use this method to save data, release shared resources, and store enough scene-specific state information
//        // to restore the scene back to its current state.
//
//        // Save changes in the application's managed object context when the application transitions to the background.
//        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
//    }
//
//
//}
//

//
//  SceneDelegate.swift
//  SmartFinance
//
//  Muallif: Diyorbek Xikmatullayev
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        // ✅ MANTIQ:
        // - Hech kim kirmagan     → AuthViewController
        // - Anonim foydalanuvchi  → AuthViewController (mehmon sessiyasi qayta yuklanmaydi)
        // - Haqiqiy foydalanuvchi → MainTabBarController
        let root = makeRootViewController()
        window?.rootViewController = root
        window?.makeKeyAndVisible()

        // NotificationCenter orqali ekranlar almashinuvi
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSwitchToMainApp),
            name: Notification.Name("switchToMainApp"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSwitchToAuth),
            name: Notification.Name("switchToAuth"),
            object: nil
        )
    }

    // MARK: - Root ekranni tanlash
    private func makeRootViewController() -> UIViewController {
        let user = Auth.auth().currentUser

        // Haqiqiy (email yoki Google) foydalanuvchi bo'lsa — bevosita MainApp
        if let user = user, !user.isAnonymous {
            return UINavigationController(rootViewController: MainTabBarController())
        }

        // Qolgan barcha holat (hech kim yo'q, yoki anonim) — Auth
        return UINavigationController(rootViewController: AuthViewController())
    }

    // MARK: - Ekran almashtirish (login muvaffaqiyatli)
    func switchToMainApp() {
        guard let window = window else { return }
        let mainVC = UINavigationController(rootViewController: MainTabBarController())
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve) {
            window.rootViewController = mainVC
        }
    }

    // MARK: - Ekran almashtirish (logout)
    func switchToAuth() {
        guard let window = window else { return }
        let authVC = UINavigationController(rootViewController: AuthViewController())
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve) {
            window.rootViewController = authVC
        }
    }

    // MARK: - Notification handlers
    @objc private func handleSwitchToMainApp() { switchToMainApp() }
    @objc private func handleSwitchToAuth()    { switchToAuth() }

    // MARK: - Scene Lifecycle
    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}
 
