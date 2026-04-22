
import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

       
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
//        if let user = user, !user.isAnonymous {
//            return UINavigationController(rootViewController: MainTabBarController())
//        }
//
//        // Qolgan barcha holat (hech kim yo'q, yoki anonim) — Auth
//        return UINavigationController(rootViewController: AuthViewController())
        
        if let user = user, !user.isAnonymous {
            return MainTabBarController()
        }
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
 
