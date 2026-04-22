// DateRangePickerViewController.swift
// SmartFinance
 
import UIKit
 
final class DateRangePickerViewController: UIViewController {
 
    var initialStartDate: Date?
    var initialEndDate: Date?
    var onConfirm: ((Date?, Date?) -> Void)?
 
    private let accent = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
 
    private let startPicker = UIDatePicker()
    private let endPicker   = UIDatePicker()
    private let startSwitch = UISwitch()
    private let endSwitch   = UISwitch()
 
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Sana oralig'i"
        setupUI()
    }
 
    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Sana oralig'ini tanlang"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
 
        // ── Start date ────────────────────────────────────────────
        let startCard  = makeCard()
        let startLabel = makeRowLabel("Dan (boshlang'ich)")
 
        startSwitch.isOn        = initialStartDate != nil
        startSwitch.onTintColor = accent
        startSwitch.translatesAutoresizingMaskIntoConstraints = false
        startSwitch.addTarget(self, action: #selector(startSwitchChanged), for: .valueChanged)
 
        startPicker.datePickerMode        = .date
        startPicker.preferredDatePickerStyle = .compact
        startPicker.tintColor             = accent
        startPicker.isEnabled             = startSwitch.isOn
        startPicker.alpha                 = startSwitch.isOn ? 1 : 0.4
        startPicker.date                  = initialStartDate ?? Date()
        startPicker.translatesAutoresizingMaskIntoConstraints = false
 
        let startRow = makeHRow(label: startLabel, control: startSwitch)
        startCard.addSubview(startRow)
        startCard.addSubview(startPicker)
 
        NSLayoutConstraint.activate([
            startRow.topAnchor.constraint(equalTo: startCard.topAnchor, constant: 14),
            startRow.leadingAnchor.constraint(equalTo: startCard.leadingAnchor, constant: 16),
            startRow.trailingAnchor.constraint(equalTo: startCard.trailingAnchor, constant: -16),
 
            startPicker.topAnchor.constraint(equalTo: startRow.bottomAnchor, constant: 10),
            startPicker.leadingAnchor.constraint(equalTo: startCard.leadingAnchor, constant: 16),
            startPicker.bottomAnchor.constraint(equalTo: startCard.bottomAnchor, constant: -14),
        ])
 
        // ── End date ──────────────────────────────────────────────
        let endCard  = makeCard()
        let endLabel = makeRowLabel("Gacha (tugash)")
 
        endSwitch.isOn        = initialEndDate != nil
        endSwitch.onTintColor = accent
        endSwitch.translatesAutoresizingMaskIntoConstraints = false
        endSwitch.addTarget(self, action: #selector(endSwitchChanged), for: .valueChanged)
 
        endPicker.datePickerMode          = .date
        endPicker.preferredDatePickerStyle = .compact
        endPicker.tintColor               = accent
        endPicker.isEnabled               = endSwitch.isOn
        endPicker.alpha                   = endSwitch.isOn ? 1 : 0.4
        endPicker.date                    = initialEndDate ?? Date()
        endPicker.translatesAutoresizingMaskIntoConstraints = false
 
        let endRow = makeHRow(label: endLabel, control: endSwitch)
        endCard.addSubview(endRow)
        endCard.addSubview(endPicker)
 
        NSLayoutConstraint.activate([
            endRow.topAnchor.constraint(equalTo: endCard.topAnchor, constant: 14),
            endRow.leadingAnchor.constraint(equalTo: endCard.leadingAnchor, constant: 16),
            endRow.trailingAnchor.constraint(equalTo: endCard.trailingAnchor, constant: -16),
 
            endPicker.topAnchor.constraint(equalTo: endRow.bottomAnchor, constant: 10),
            endPicker.leadingAnchor.constraint(equalTo: endCard.leadingAnchor, constant: 16),
            endPicker.bottomAnchor.constraint(equalTo: endCard.bottomAnchor, constant: -14),
        ])
 
        // ── Buttons ───────────────────────────────────────────────
        let confirmBtn = UIButton(type: .system)
        confirmBtn.setTitle("Qo'llash", for: .normal)
        confirmBtn.setTitleColor(.white, for: .normal)
        confirmBtn.titleLabel?.font   = .systemFont(ofSize: 17, weight: .semibold)
        confirmBtn.backgroundColor    = accent
        confirmBtn.layer.cornerRadius = 14
        confirmBtn.translatesAutoresizingMaskIntoConstraints = false
        confirmBtn.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
 
        let clearBtn = UIButton(type: .system)
        clearBtn.setTitle("Filterni tozalash", for: .normal)
        clearBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        clearBtn.setTitleColor(.systemRed, for: .normal)
        clearBtn.translatesAutoresizingMaskIntoConstraints = false
        clearBtn.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
 
        [titleLabel, startCard, endCard, confirmBtn, clearBtn].forEach { view.addSubview($0) }
 
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
 
            startCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            startCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            startCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
 
            endCard.topAnchor.constraint(equalTo: startCard.bottomAnchor, constant: 12),
            endCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            endCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
 
            confirmBtn.topAnchor.constraint(equalTo: endCard.bottomAnchor, constant: 24),
            confirmBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirmBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirmBtn.heightAnchor.constraint(equalToConstant: 54),
 
            clearBtn.topAnchor.constraint(equalTo: confirmBtn.bottomAnchor, constant: 10),
            clearBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
 
    // MARK: - Helpers
 
    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor    = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }
 
    private func makeRowLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }
 
    private func makeHRow(label: UILabel, control: UIView) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(label)
        row.addSubview(control)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            control.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            control.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            row.heightAnchor.constraint(equalToConstant: 32),
        ])
        return row
    }
 
    // MARK: - Actions
 
    @objc private func startSwitchChanged() {
        startPicker.isEnabled = startSwitch.isOn
        UIView.animate(withDuration: 0.2) {
            self.startPicker.alpha = self.startSwitch.isOn ? 1 : 0.4
        }
    }
 
    @objc private func endSwitchChanged() {
        endPicker.isEnabled = endSwitch.isOn
        UIView.animate(withDuration: 0.2) {
            self.endPicker.alpha = self.endSwitch.isOn ? 1 : 0.4
        }
    }
 
    @objc private func confirmTapped() {
        let start = startSwitch.isOn ? startPicker.date : nil
        let end   = endSwitch.isOn   ? endPicker.date   : nil
        onConfirm?(start, end)
        dismiss(animated: true)
    }
 
    @objc private func clearTapped() {
        onConfirm?(nil, nil)
        dismiss(animated: true)
    }
}
