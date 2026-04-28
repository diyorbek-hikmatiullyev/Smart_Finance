/// QRScannerViewController.swift
// SmartFinance
// QR Skaner + Chek rasmi OCR + Galereya
// Tuzatilgan versiya

import UIKit
import AVFoundation
import Vision

final class QRScannerViewController: UIViewController {

    // MARK: - AV Properties
    private var captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput = AVCapturePhotoOutput()
    private var isCapturingPhoto = false
    
    // QR bir marta ishlanishini kafolatlash
    private var isProcessingQR = false

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

    private let bottomPanel: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let captureButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.layer.borderColor = UIColor.white.cgColor
        btn.layer.borderWidth = 3
        btn.layer.cornerRadius = 36
        btn.backgroundColor = .clear

        let inner = UIView()
        inner.backgroundColor = .white
        inner.layer.cornerRadius = 28
        inner.isUserInteractionEnabled = false
        inner.translatesAutoresizingMaskIntoConstraints = false
        inner.tag = 101
        btn.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
            inner.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
            inner.widthAnchor.constraint(equalToConstant: 56),
            inner.heightAnchor.constraint(equalToConstant: 56),
        ])
        return btn
    }()

    private let galleryButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        let conf = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        btn.setImage(UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: conf), for: .normal)
        btn.tintColor = .white
        return btn
    }()

    private let galleryLabel: UILabel = {
        let l = UILabel()
        l.text = "Galereya"
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        l.font = .systemFont(ofSize: 11, weight: .medium)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let modeSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["QR Kod", "Chek rasmi"])
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white.withAlphaComponent(0.7)], for: .normal)
        sc.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private let flashButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        let conf = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        btn.setImage(UIImage(systemName: "bolt.slash.fill", withConfiguration: conf), for: .normal)
        btn.tintColor = .white
        return btn
    }()

    private let flashLabel: UILabel = {
        let l = UILabel()
        l.text = "Flash"
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        l.font = .systemFont(ofSize: 11, weight: .medium)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private var isFlashOn = false
    private var isQRMode: Bool { modeSegment.selectedSegmentIndex == 0 }
    
    // Overlay mask qayta hisoblash uchun
    private var maskApplied = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
        setupActions()
    }
    
    // FIX 1: Overlay mask frame'ni to'g'ri hisoblash uchun
    // viewDidLoad da view.frame hali final emas — shuning uchun viewDidLayoutSubviews ishlatiladi
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
        if !maskApplied {
            maskApplied = true
            applyOverlayMask()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isProcessingQR = false
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

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        // FIX 2: frame ni viewDidLayoutSubviews da o'rnatamiz, bu yerda faqat gravity
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0) // FIX 3: addSublayer emas, insertSublayer(at:0) — UI ustida qolmasin
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.addSubview(overlayView)
        view.addSubview(scanFrameView)
        view.addSubview(hintLabel)
        view.addSubview(modeSegment)
        view.addSubview(bottomPanel)

        let galleryStack = UIStackView(arrangedSubviews: [galleryButton, galleryLabel])
        galleryStack.axis = .vertical
        galleryStack.spacing = 6
        galleryStack.alignment = .center
        galleryStack.translatesAutoresizingMaskIntoConstraints = false

        let flashStack = UIStackView(arrangedSubviews: [flashButton, flashLabel])
        flashStack.axis = .vertical
        flashStack.spacing = 6
        flashStack.alignment = .center
        flashStack.translatesAutoresizingMaskIntoConstraints = false

        bottomPanel.addSubview(galleryStack)
        bottomPanel.addSubview(captureButton)
        bottomPanel.addSubview(flashStack)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            modeSegment.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            modeSegment.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            modeSegment.widthAnchor.constraint(equalToConstant: 220),
            modeSegment.heightAnchor.constraint(equalToConstant: 36),

            scanFrameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanFrameView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            scanFrameView.widthAnchor.constraint(equalToConstant: 240),
            scanFrameView.heightAnchor.constraint(equalToConstant: 240),

            hintLabel.topAnchor.constraint(equalTo: scanFrameView.bottomAnchor, constant: 20),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            bottomPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            bottomPanel.heightAnchor.constraint(equalToConstant: 72),

            captureButton.centerXAnchor.constraint(equalTo: bottomPanel.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: bottomPanel.bottomAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 72),
            captureButton.heightAnchor.constraint(equalToConstant: 72),

            galleryStack.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            galleryStack.centerXAnchor.constraint(equalTo: bottomPanel.centerXAnchor, constant: -110),
            galleryButton.widthAnchor.constraint(equalToConstant: 54),
            galleryButton.heightAnchor.constraint(equalToConstant: 54),

            flashStack.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            flashStack.centerXAnchor.constraint(equalTo: bottomPanel.centerXAnchor, constant: 110),
            flashButton.widthAnchor.constraint(equalToConstant: 54),
            flashButton.heightAnchor.constraint(equalToConstant: 54),
        ])

        // applyOverlayMask() ni viewDidLayoutSubviews ga ko'chirdik
        updateModeUI()
    }

    // FIX 4: view.bounds ishlatish — UIScreen.main.bounds ba'zi hollarda noto'g'ri
    private func applyOverlayMask() {
        let bounds = view.bounds
        let frameSize: CGFloat = 240
        let maskLayer = CAShapeLayer()
        let outerPath = UIBezierPath(rect: bounds)
        let innerRect = CGRect(
            x: (bounds.width - frameSize) / 2,
            y: (bounds.height - frameSize) / 2 - 40,
            width: frameSize,
            height: frameSize
        )
        let innerPath = UIBezierPath(roundedRect: innerRect, cornerRadius: 16)
        outerPath.append(innerPath)
        maskLayer.path = outerPath.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer
    }

    // MARK: - Actions Setup

    private func setupActions() {
        // FIX 5: captureButtonUp ni .touchUpInside dan olib tashlash
        // Aks holda tap bo'lganda captureButtonUp + captureButtonTapped ikkalasi chaqirilardi
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        captureButton.addTarget(self, action: #selector(captureButtonDown), for: .touchDown)
        captureButton.addTarget(self, action: #selector(captureButtonUp),
                                for: [.touchUpOutside, .touchCancel]) // touchUpInside olib tashlandi
        galleryButton.addTarget(self, action: #selector(openGallery), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        modeSegment.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
    }

    // MARK: - Mode UI

    private func updateModeUI() {
        if isQRMode {
            scanFrameView.isHidden = false
            hintLabel.text = "QR kodni ramka ichiga oling"
            captureButton.isHidden = true
            flashButton.isHidden = false
        } else {
            scanFrameView.isHidden = true
            hintLabel.text = "Chekni kamera oldiga tuting va rasmga oling"
            captureButton.isHidden = false
            flashButton.isHidden = false
        }
    }

    @objc private func modeChanged() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isProcessingQR = false // Rejim o'zgarganda qayta skanerlashga ruxsat
        UIView.animate(withDuration: 0.25) {
            self.updateModeUI()
        }
    }

    // MARK: - Capture Button Animation

    @objc private func captureButtonDown() {
        UIView.animate(withDuration: 0.1) {
            self.captureButton.viewWithTag(101)?.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }
    }

    @objc private func captureButtonUp() {
        UIView.animate(withDuration: 0.15,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.5) {
            self.captureButton.viewWithTag(101)?.transform = .identity
        }
    }

    @objc private func captureButtonTapped() {
        // FIX 6: Animatsiyani ham chaqirish (oldin faqat touchUpInside'ga ulangan edi)
        captureButtonUp()
        
        guard !isCapturingPhoto else { return }
        isCapturingPhoto = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        let settings = AVCapturePhotoSettings()
        if isFlashOn {
            settings.flashMode = .on
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Gallery

    @objc private func openGallery() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // FIX 7: Session ni background thread'da to'xtatish
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }

        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Flash

    @objc private func toggleFlash() {
        isFlashOn.toggle()
        let conf = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let iconName = isFlashOn ? "bolt.fill" : "bolt.slash.fill"
        flashButton.setImage(UIImage(systemName: iconName, withConfiguration: conf), for: .normal)
        flashButton.backgroundColor = isFlashOn
            ? UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 0.5)
            : UIColor.white.withAlphaComponent(0.15)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = isFlashOn ? .on : .off
        device.unlockForConfiguration()
    }

    // MARK: - OCR

    private func recognizeReceiptText(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            // FIX 8: Error ni log qilish
            if let error = error {
                print("❌ OCR xatosi: \(error.localizedDescription)")
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

            let fullText = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            print("📄 OCR natijasi:\n\(fullText)")

            DispatchQueue.main.async {
                self.parseReceiptText(fullText)
            }
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["uz", "ru", "en"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                // FIX 9: perform xatosini ushlash
                print("❌ VNImageRequestHandler xatosi: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isCapturingPhoto = false
                    self.showErrorAlert(message: "Rasmni qayta ishlashda xato: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Receipt Parsing

    private func parseReceiptText(_ text: String) {
        let lines = text.components(separatedBy: "\n")

        // 1. Do'kon nomi
        var vendorName = "Noma'lum do'kon"
        let knownStores = ["korzinka", "makro", "havas", "baraka", "next", "zara",
                           "artel", "texnomart", "mediapark", "najot"]
        for line in lines.prefix(6) {
            let lower = line.lowercased()
            if knownStores.contains(where: { lower.contains($0) }) {
                vendorName = line.trimmingCharacters(in: .whitespaces)
                break
            }
        }

        // 2. Summa
        var amount: Double = 0
        let sumKeywords = ["to'lov uchun", "tolov uchun", "jami chegirma",
                           "hammasi", "итого", "jami:", "to'landi"]

        for (i, line) in lines.enumerated() {
            let lower = line.lowercased()
            if sumKeywords.contains(where: { lower.contains($0) }) {
                let searchLines = [line] + (i + 1 < lines.count ? [lines[i + 1]] : [])
                for sl in searchLines {
                    if let found = extractAmount(from: sl), found > amount {
                        amount = found
                    }
                }
            }
        }

        if amount == 0 {
            for line in lines {
                if let found = extractAmount(from: line) {
                    amount = max(amount, found)
                }
            }
        }

        // 3. Sana
        var date = Date()
        let dateFormats = ["dd/MM/yyyy HH:mm:ss", "dd.MM.yyyy HH:mm:ss",
                           "dd.MM.yyyy HH:mm", "dd/MM/yyyy", "dd.MM.yyyy"]
        outer: for line in lines {
            let cleaned = line.trimmingCharacters(in: .whitespaces)
            for fmt in dateFormats {
                let f = DateFormatter()
                f.dateFormat = fmt
                if let parsed = f.date(from: cleaned) {
                    date = parsed
                    break outer
                }
            }
        }

        // FIX 10: recognizeFromReceipt ishlatish — mahsulot nomlaridan ham kategoriya aniqlash
        let (resolvedVendor, category) = recognizer.recognizeFromReceipt(
            inn: nil,
            vendorName: vendorName,
            fullReceiptText: text
        )

        let expense = ScannedExpense(
            amount: amount,
            vendorName: resolvedVendor == "Noma'lum" ? vendorName : resolvedVendor,
            category: category,
            date: date,
            rawURL: "ocr://receipt"
        )

        showSuccessSheet(expense: expense)
    }

    // MARK: - Amount Extraction

    private func extractAmount(from text: String) -> Double? {
        let pattern = #"(\d[\d\s]{1,10}[\.,]\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }

        let raw = String(text[range])
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(raw)
    }

    // MARK: - QR URL Parse

    private func parseCheckURL(_ urlString: String) -> ScannedExpense? {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

        let params = components.queryItems ?? []
        func getValue(for keys: [String]) -> String? {
            params.first(where: { keys.contains($0.name) })?.value
        }

        let rawAmount = getValue(for: ["s", "totalSum", "t", "sum"]) ?? "0"
        var amount = Double(rawAmount.replacingOccurrences(of: ",", with: ".")) ?? 0
        if amount > 100_000 && rawAmount.count > 5 { amount /= 100 }

        let inn = getValue(for: ["i", "inn", "tin"])
        let vendorName = getValue(for: ["n", "name", "terminalName"]) ?? "Noma'lum do'kon"
        let (resolvedName, category) = recognizer.recognize(inn: inn, vendorName: vendorName)

        var date = Date()
        if let dateStr = getValue(for: ["d", "date", "dateTime", "time"]) {
            let formatter = DateFormatter()
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

    // MARK: - Bottom Sheet

    func showSuccessSheet(expense: ScannedExpense) {
        // FIX 11: Session ni background thread'da to'xtatish
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
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
        guard isQRMode else { return }
        // FIX 12: isProcessingQR flag — bir QR bir necha marta ishlanishini oldini olish
        guard !isProcessingQR else { return }
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }

        isProcessingQR = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        print("📷 QR: \(stringValue)")
        
        if let expense = parseCheckURL(stringValue) {
            showSuccessSheet(expense: expense)
        } else {
            let fallback = ScannedExpense(
                amount: 0,
                vendorName: "Noma'lum",
                category: .other,
                date: Date(),
                rawURL: stringValue
            )
            showSuccessSheet(expense: fallback)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension QRScannerViewController: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        // FIX 13: Har doim isCapturingPhoto ni reset qilish (error bo'lsa ham)
        isCapturingPhoto = false
        
        if let error = error {
            print("❌ Rasm olishda xato: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.showErrorAlert(message: error.localizedDescription)
            }
            return
        }
        
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            DispatchQueue.main.async {
                self.showErrorAlert(message: "Rasm ma'lumotlarini o'qib bo'lmadi")
            }
            return
        }

        print("📸 Rasm olindi, OCR boshlanmoqda...")
        recognizeReceiptText(from: image)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension QRScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        if let image = info[.originalImage] as? UIImage {
            print("🖼 Galereyadan rasm tanlandi, OCR boshlanmoqda...")
            recognizeReceiptText(from: image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        // FIX 14: Bekor qilinganda session ni qayta ishga tushirish
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
}

// MARK: - ScanResultDelegate
// QRScannerViewController.swift ichidagi mavjud ScanResultDelegate extension bilan almashtiring
 
extension QRScannerViewController: ScanResultDelegate {
 
    func didConfirmExpense(_ expense: ScannedExpense) {
        guard let uid = AuthSessionProvider.shared.currentUserID else {
            showErrorAlert(message: "Foydalanuvchi tizimga kirmagan")
            return
        }
 
        // ✅ Duplicate key: amount + vendorName + chek sanasi (daqiqagacha)
        let dupKey = duplicateKey(for: expense)
 
        if RecentScanCache.shared.contains(dupKey) {
            showDuplicateConfirmAlert(expense: expense, uid: uid, dupKey: dupKey)
            return
        }
 
        RecentScanCache.shared.add(dupKey)
        saveExpense(expense, uid: uid)
    }
 
    // MARK: - Duplicate Key
 
    private func duplicateKey(for expense: ScannedExpense) -> String {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: expense.date)
        let dateStr = "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)-\(comps.hour ?? 0)-\(comps.minute ?? 0)"
        let vendor = expense.vendorName.lowercased().trimmingCharacters(in: .whitespaces)
        let amount = Int(expense.amount)
        return "\(vendor)_\(amount)_\(dateStr)"
    }
 
    // MARK: - Duplicate Alert
 
    private func showDuplicateConfirmAlert(expense: ScannedExpense, uid: String, dupKey: String) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        let amountStr = (formatter.string(from: NSNumber(value: expense.amount)) ?? "\(Int(expense.amount))") + " so'm"
 
        let alert = UIAlertController(
            title: "⚠️ Takroriy chek",
            message: "\(expense.vendorName) — \(amountStr)\n\nBu chek allaqachon saqlangan. Qayta saqlaysizmi?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Qayta saqlash", style: .destructive) { [weak self] _ in
            RecentScanCache.shared.add(dupKey)
            self?.saveExpense(expense, uid: uid)
        })
        alert.addAction(UIAlertAction(title: "Bekor qilish", style: .cancel) { [weak self] _ in
            self?.didCancelScan()
        })
        present(alert, animated: true)
    }
 
    // MARK: - Save
 
    private func saveExpense(_ expense: ScannedExpense, uid: String) {
        let input = NewTransactionInput(
            title: expense.vendorName,
            amount: expense.amount,
            isIncome: false,
            category: expense.category.rawValue,
            userID: uid
        )
 
        TransactionRepository.shared.createTransaction(input) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.showErrorAlert(message: error.localizedDescription)
                    return
                }
                self.showSuccessBanner()
                DispatchQueue.global(qos: .userInitiated).async {
                    if !self.captureSession.isRunning {
                        self.captureSession.startRunning()
                    }
                    self.isProcessingQR = false
                }
            }
        }
    }
 
    func didCancelScan() {
        isProcessingQR = false
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
 
    // MARK: - Success Banner
 
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
 
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Xato", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            DispatchQueue.global(qos: .userInitiated).async {
                self?.captureSession.startRunning()
                self?.isProcessingQR = false
            }
        })
        present(alert, animated: true)
    }
}
