// QRScannerViewController.swift
// SmartFinance
// Kamera tab — QR/Chek skaner + BottomSheet integratsiyasi

import UIKit
import AVFoundation

final class QRScannerViewController: UIViewController {

    // MARK: - AV Properties
    private var captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Helpers
    private let recognizer = CategoryRecognizer()

    // MARK: - UI
    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let scanFrameView: UIView = {
        let v = UIView()
        v.layer.borderColor = UIColor.white.cgColor
        v.layer.borderWidth = 2
        v.layer.cornerRadius = 16
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.text = "QR kodni ramka ichiga oling"
        l.textColor = .white
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlayUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    // MARK: - Camera Setup

    private func setupCamera() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showNoCameraAlert()
            return
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr, .ean13, .ean8, .code128]
        }

        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.frame = view.layer.bounds
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    private func setupOverlayUI() {
        view.addSubview(overlayView)
        view.addSubview(scanFrameView)
        view.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scanFrameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanFrameView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            scanFrameView.widthAnchor.constraint(equalToConstant: 240),
            scanFrameView.heightAnchor.constraint(equalToConstant: 240),

            hintLabel.topAnchor.constraint(equalTo: scanFrameView.bottomAnchor, constant: 20),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        // Ramka ortasini shaffof qilish
        let maskLayer = CAShapeLayer()
        let outerPath = UIBezierPath(rect: UIScreen.main.bounds)
        let innerRect = CGRect(
            x: (UIScreen.main.bounds.width - 240) / 2,
            y: (UIScreen.main.bounds.height - 240) / 2 - 40,
            width: 240,
            height: 240
        )
        let innerPath = UIBezierPath(roundedRect: innerRect, cornerRadius: 16)
        outerPath.append(innerPath)
        maskLayer.path = outerPath.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer
    }

    // MARK: - QR URL Parsing

    /// Tekshiruv QR URL sini parse qiladi (O'z.Tekshiruv formati)
//    private func parseCheckURL(_ urlString: String) -> ScannedExpense? {
//        guard let url = URL(string: urlString),
//              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
//            return nil
//        }
//
//        let params = components.queryItems ?? []
//        func param(_ key: String) -> String? {
//            params.first(where: { $0.name == key })?.value
//        }
//
//        // Summa olish (t=12500 yoki s=12500)
//        let amountStr = param("t") ?? param("s") ?? param("sum") ?? "0"
//        let amount = Double(amountStr.replacingOccurrences(of: ",", with: ".")) ?? 0
//
//        // Do'kon INN va nomi
//        let inn = param("i") ?? param("inn")
//        let vendorName = param("n") ?? param("name")
//
//        let (resolvedName, category) = CategoryRecognizer().recognize(
//            inn: inn,
//            vendorName: vendorName
//        )
//
//        // Sana (t=20240115T143000 formatida bo'lishi mumkin)
//        var date = Date()
//        if let dateStr = param("d") ?? param("date") {
//            let formatter = DateFormatter()
//            formatter.dateFormat = "yyyyMMdd'T'HHmmss"
//            date = formatter.date(from: dateStr) ?? Date()
//        }
//
//        return ScannedExpense(
//            amount: amount,
//            vendorName: resolvedName,
//            category: category,
//            date: date,
//            rawURL: urlString
//        )
//    }
    private func parseCheckURL(_ urlString: String) -> ScannedExpense? {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let params = components.queryItems ?? []
        
        // Yordamchi funksiya: bir nechta kalit so'zlarni tekshirish uchun
        func getValue(for keys: [String]) -> String? {
            return params.first(where: { keys.contains($0.name) })?.value
        }

        // 1. Summani olish (s, totalSum yoki t)
        let rawAmount = getValue(for: ["s", "totalSum", "t", "sum"]) ?? "0"
        var amount = Double(rawAmount.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        // O'zbekiston cheklarida summa tiyinlarda bo'lsa (oxirgi ikki raqam tiyin)
        // Agar summa juda katta bo'lsa, uni 100 ga bo'lamiz
        if amount > 100000 && rawAmount.count > 5 {
            amount = amount / 100
        }

        // 2. Do'kon ma'lumotlari
        let inn = getValue(for: ["i", "inn", "tin"])
        let vendorName = getValue(for: ["n", "name", "terminalName"]) ?? "Noma'lum do'kon"

        // 3. CategoryRecognizer orqali tekshirish
        let (resolvedName, category) = recognizer.recognize(
            inn: inn,
            vendorName: vendorName
        )

        // 4. Sana (d yoki dateTime)
        var date = Date()
        if let dateStr = getValue(for: ["d", "date", "dateTime", "time"]) {
            let formatter = DateFormatter()
            // O'zbekiston cheklaridagi standart format: 20240115T143000
            formatter.dateFormat = "yyyyMMdd'T'HHmmss"
            date = formatter.date(from: dateStr) ?? Date()
        }

        return ScannedExpense(
            amount: amount,
            vendorName: resolvedName == "Noma'lum" ? vendorName : resolvedName,
            category: category,
            date: date,
            rawURL: urlString
        )
    }
    // MARK: - Show Bottom Sheet

    func showSuccessSheet(expense: ScannedExpense) {
        captureSession.stopRunning()

        let sheet = ScanResultBottomSheetVC(expense: expense)
        sheet.delegate = self
        sheet.modalPresentationStyle = .pageSheet
        present(sheet, animated: true)
    }

    // MARK: - Alerts

    private func showNoCameraAlert() {
        let alert = UIAlertController(
            title: "Kamera mavjud emas",
            message: "Simulatorda kamera ishlamaydi. Haqiqiy qurilmada sinab ko'ring.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async { self.present(alert, animated: true) }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {

        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }

        // Bir marta skanerlash uchun sessiyani to'xtatamiz
        captureSession.stopRunning()

        // Haptic
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // URL parse qilish
        if let expense = parseCheckURL(stringValue) {
            showSuccessSheet(expense: expense)
        } else {
            // Agar URL mos kelmasa — fallback expense
            let fallback = ScannedExpense(
                amount: 0,
                vendorName: "Noma'lum",
                category: .other,
                date: Date(),
                rawURL: stringValue
            )
            showSuccessSheet(expense: fallback)
        }
        print("Skanerlangan matn: \(stringValue)")
    }
}

// MARK: - ScanResultDelegate

extension QRScannerViewController: ScanResultDelegate {

    func didConfirmExpense(_ expense: ScannedExpense) {
        // FirestoreService orqali saqlash
        FirestoreService.shared.saveExpense(expense) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.showSuccessBanner()
                    DispatchQueue.global(qos: .userInitiated).async {
                        self?.captureSession.startRunning()
                    }
                case .failure(let error):
                    if (error as NSError).code == 409 {
                        // Duplicate — foydalanuvchiga so'ra
                        self?.showDuplicateAlert(expense: expense)
                    } else {
                        self?.showErrorAlert(message: error.localizedDescription)
                    }
                }
            }
        }
    }

    func didCancelScan() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    // MARK: - Helper Banners

    private func showSuccessBanner() {
        let banner = UIView()
        banner.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
        banner.layer.cornerRadius = 12
        banner.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "✅ Xarajat saqlandi!"
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false

        banner.addSubview(label)
        view.addSubview(banner)

        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            label.topAnchor.constraint(equalTo: banner.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor, constant: -12),
            label.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -16),
        ])

        banner.alpha = 0
        UIView.animate(withDuration: 0.3) { banner.alpha = 1 } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0) { banner.alpha = 0 } completion: { _ in
                banner.removeFromSuperview()
            }
        }
    }

    private func showDuplicateAlert(expense: ScannedExpense) {
        let alert = UIAlertController(
            title: "⚠️ Allaqachon saqlangan",
            message: "Bu chek tizimda mavjud. Qayta saqlaysizmi?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ha, saqlash", style: .default) { [weak self] _ in
            // Force save — duplicate check o'tkazmasdan to'g'ridan saqlash
            // (bu yerda to'g'ridan writeExpense chaqirish kerak bo'lsa FirestoreService extend qiling)
            self?.captureSession.startRunning()
        })
        alert.addAction(UIAlertAction(title: "Bekor qilish", style: .cancel) { [weak self] _ in
            self?.captureSession.startRunning()
        })
        present(alert, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Xato", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.captureSession.startRunning()
        })
        present(alert, animated: true)
    }
}
