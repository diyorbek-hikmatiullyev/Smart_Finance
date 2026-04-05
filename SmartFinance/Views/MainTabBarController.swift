//
//  ViewController.swift
//  SmartFinance
//
//  Created by Diyorbek Xikmatullayev on 22/03/26.
//

import UIKit
import ESTabBarController

class MainTabBarController: ESTabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
    }

    private func setupTabBar() {
        // Tab bar orqa foni va soyasi
        self.tabBar.backgroundColor = .systemBackground
        self.tabBar.shadowImage = UIImage()
        self.tabBar.backgroundImage = UIImage()
        
        // 1-Item: Asosiy (Dashboard)
        let homeVC = DashboardViewController() // O'zingiz yaratgan ekran
        let navHome = UINavigationController(rootViewController: homeVC)
        navHome.tabBarItem = ESTabBarItem(ExampleBasicContentView(), title: "Asosiy", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))

        // 2-Item: O'rtadagi Katta Kamera tugmasi — QR Skaner
        let cameraVC = QRScannerViewController()
        let navCamera = UINavigationController(rootViewController: cameraVC)
        
        // Bu maxsus content view tugmani tepaga biroz chiqarib qo'yadi
        let centerItem = ESTabBarItem(ExampleBouncesContentView(), title: nil, image: UIImage(systemName: "camera"), selectedImage: UIImage(systemName: "camera.fill"))
        navCamera.tabBarItem = centerItem

        // 3-Item: Profil sozlamalari
        let profileVC = ProfilViewController() // 👈 Shuni o'zgartirdik
        let navProfile = UINavigationController(rootViewController: profileVC)
        navProfile.tabBarItem = ESTabBarItem(ExampleBasicContentView(),
                                            title: "Profil",
                                            image: UIImage(systemName: "person"),
                                            selectedImage: UIImage(systemName: "person.fill"))
        
        // Controllerlarni Tab barga biriktirish
        self.viewControllers = [navHome, navCamera, navProfile]
    }
}

// MARK: - 🎨 Dizayn Klasslari (Tugmani tepaga chiqarish va sakrash animatsiyasi uchun)

class ExampleBasicContentView: ESTabBarItemContentView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        textColor = .secondaryLabel
        highlightTextColor = .systemTeal
        iconColor = .secondaryLabel
        highlightIconColor = .systemTeal
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

class ExampleBouncesContentView: ESTabBarItemContentView {
    
    private let outerButtonSize: CGFloat = 60
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        textColor = .secondaryLabel
        highlightTextColor = .systemTeal
        iconColor = .secondaryLabel
        highlightIconColor = .systemTeal
        
        self.imageView.backgroundColor = .systemTeal
        self.imageView.layer.cornerRadius = outerButtonSize / 2
        self.imageView.tintColor = .white
        
        // 🖼 Rasmni markazda proporsional saqlash
        self.imageView.contentMode = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // ✅ Rasm yuklanayotganida uning chetlariga bo'sh joy (Padding) qo'shamiz
    override func updateDisplay() {
        super.updateDisplay()
        
        // Agar rasm mavjud bo'lsa, unga ichki padding berib kichraytiramiz
        if let currentImage = self.imageView.image {
            // 📐 Padding miqdori (Qanchalik katta bo'lsa, kamera shunchalik kichrayadi)
            let padding: CGFloat = 12
            
            // Rasmga chetlaridan bo'sh joy berish
            let insetImage = currentImage.withAlignmentRectInsets(UIEdgeInsets(top: -padding, left: -padding, bottom: -padding, right: -padding))
            self.imageView.image = insetImage
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.frame = CGRect(x: (self.bounds.width - outerButtonSize) / 2,
                                      y: (self.bounds.height - outerButtonSize) / 2 - 15,
                                      width: outerButtonSize,
                                      height: outerButtonSize)
    }
    
    // MARK: - Sustlashtirilgan Animatsiya
    override func selectAnimation(animated: Bool, completion: (() -> Void)?) {
        self.bounceAnimation()
        completion?()
    }
    
    private func bounceAnimation() {
        let implodeAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        
        // Sakrash kuchi ancha kamaytirildi (1.0 ga yaqin)
        implodeAnimation.values = [1.0, 0.94, 1.05, 0.98, 1.01, 1.0]
        implodeAnimation.duration = 0.6 // Biroz sekinroq
        
        implodeAnimation.calculationMode = CAAnimationCalculationMode.cubic
        imageView.layer.add(implodeAnimation, forKey: nil)
    }
}
