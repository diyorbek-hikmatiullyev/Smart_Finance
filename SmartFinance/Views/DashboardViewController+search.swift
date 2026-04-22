// DashboardViewController+Search.swift
// SmartFinance
// Search va Filter panel — DashboardViewController dan ajratilgan
 
import UIKit
 
// MARK: - Search & Filter Setup
 
extension DashboardViewController {
 
    // MARK: - Build
 
    func buildSearchFilterPanel() {
        searchFilterPanel.backgroundColor = .systemBackground
        searchFilterPanel.isHidden = true
        searchFilterPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchFilterPanel)
 
        // ── Search TextField ──────────────────────────────────────
        searchTextField.placeholder        = "Qidirish..."
        searchTextField.backgroundColor    = .secondarySystemBackground
        searchTextField.layer.cornerRadius = 12
        searchTextField.returnKeyType      = .search
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
 
        let iconBox = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        let iconImg = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iconImg.tintColor   = .secondaryLabel
        iconImg.frame       = CGRect(x: 10, y: 8, width: 18, height: 18)
        iconImg.contentMode = .scaleAspectFit
        iconBox.addSubview(iconImg)
        searchTextField.leftView     = iconBox
        searchTextField.leftViewMode = .always
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
 
        let xConf = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        closeSearchBtn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: xConf), for: .normal)
        closeSearchBtn.tintColor = .tertiaryLabel
        closeSearchBtn.translatesAutoresizingMaskIntoConstraints = false
        closeSearchBtn.addTarget(self, action: #selector(collapseSearch), for: .touchUpInside)
 
        // ── Filter Pills ──────────────────────────────────────────
        filterScrollView.showsHorizontalScrollIndicator = false
        filterScrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        filterScrollView.translatesAutoresizingMaskIntoConstraints = false
 
        filterStack.axis    = .horizontal
        filterStack.spacing = 8
        filterStack.translatesAutoresizingMaskIntoConstraints = false
 
        styleFilterPill(categoryFilterBtn, title: "Kategoriya", icon: "tag.fill",         active: false)
        styleFilterPill(dateFilterBtn,     title: "Sana",       icon: "calendar",          active: false)
        styleFilterPill(clearFilterBtn,    title: "Tozalash",   icon: "xmark.circle.fill", active: false)
 
        categoryFilterBtn.addTarget(self, action: #selector(showCategoryPicker), for: .touchUpInside)
        dateFilterBtn.addTarget(self,     action: #selector(showDatePicker),     for: .touchUpInside)
        clearFilterBtn.addTarget(self,    action: #selector(clearAllFilters),    for: .touchUpInside)
 
        // isHidden o'rniga alpha — UIStackView o'lchamini o'zgartirmaydi
        clearFilterBtn.alpha                    = 0
        clearFilterBtn.isUserInteractionEnabled = false
 
        [categoryFilterBtn, dateFilterBtn, clearFilterBtn].forEach {
            filterStack.addArrangedSubview($0)
        }
        filterScrollView.addSubview(filterStack)
 
        let sep = UIView()
        sep.backgroundColor = UIColor.separator.withAlphaComponent(0.4)
        sep.translatesAutoresizingMaskIntoConstraints = false
 
        [searchTextField, closeSearchBtn, filterScrollView, sep].forEach {
            searchFilterPanel.addSubview($0)
        }
 
        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: searchFilterPanel.topAnchor, constant: 10),
            searchTextField.leadingAnchor.constraint(equalTo: searchFilterPanel.leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: closeSearchBtn.leadingAnchor, constant: -8),
            searchTextField.heightAnchor.constraint(equalToConstant: 40),
 
            closeSearchBtn.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor),
            closeSearchBtn.trailingAnchor.constraint(equalTo: searchFilterPanel.trailingAnchor, constant: -16),
            closeSearchBtn.widthAnchor.constraint(equalToConstant: 28),
            closeSearchBtn.heightAnchor.constraint(equalToConstant: 28),
 
            filterScrollView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 8),
            filterScrollView.leadingAnchor.constraint(equalTo: searchFilterPanel.leadingAnchor),
            filterScrollView.trailingAnchor.constraint(equalTo: searchFilterPanel.trailingAnchor),
            filterScrollView.heightAnchor.constraint(equalToConstant: 36),
            filterScrollView.bottomAnchor.constraint(equalTo: searchFilterPanel.bottomAnchor, constant: -8),
 
            filterStack.topAnchor.constraint(equalTo: filterScrollView.topAnchor),
            filterStack.bottomAnchor.constraint(equalTo: filterScrollView.bottomAnchor),
            filterStack.leadingAnchor.constraint(equalTo: filterScrollView.contentLayoutGuide.leadingAnchor),
            filterStack.trailingAnchor.constraint(equalTo: filterScrollView.contentLayoutGuide.trailingAnchor),
            filterStack.heightAnchor.constraint(equalTo: filterScrollView.frameLayoutGuide.heightAnchor),
 
            sep.bottomAnchor.constraint(equalTo: searchFilterPanel.bottomAnchor),
            sep.leadingAnchor.constraint(equalTo: searchFilterPanel.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: searchFilterPanel.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
 
    // MARK: - Pill Styling
 
    func styleFilterPill(_ btn: UIButton, title: String, icon: String, active: Bool) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(
            systemName: icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        )
        config.imagePadding   = 5
        config.imagePlacement = .leading
        config.baseBackgroundColor = active ? accent : UIColor.secondarySystemBackground
        config.baseForegroundColor = active ? .white : .secondaryLabel
        config.cornerStyle         = .capsule
        config.contentInsets       = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            return a
        }
        btn.configuration = config
        btn.translatesAutoresizingMaskIntoConstraints = false
    }
 
    func updatePillStyle(_ btn: UIButton, title: String, icon: String, active: Bool) {
        var config = btn.configuration
        config?.title = title
        config?.image = UIImage(
            systemName: icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        )
        config?.baseBackgroundColor = active ? accent : UIColor.secondarySystemBackground
        config?.baseForegroundColor = active ? .white : .secondaryLabel
        btn.configuration = config
 
        if active {
            UIView.animate(withDuration: 0.2) {
                btn.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
            } completion: { _ in
                UIView.animate(withDuration: 0.15) { btn.transform = .identity }
            }
        }
    }
 
    // MARK: - Expand / Collapse
 
    @objc func expandSearch() {
        guard !isSearchExpanded else { return }
        isSearchExpanded = true
 
        // Kontent alpha ni tiklash (oldingi yopilishdan keyin reset qilingan bo'lishi mumkin)
        searchTextField.alpha  = 1
        closeSearchBtn.alpha   = 1
        filterScrollView.alpha = 1
 
        searchFilterPanel.isHidden = false
        updateFilterPillStyles()
 
        UIView.animate(
            withDuration: 0.38, delay: 0,
            usingSpringWithDamping: 0.82, initialSpringVelocity: 0.2,
            options: .curveEaseInOut
        ) {
            self.balanceLabel.alpha  = 0
            self.searchIconBtn.alpha = 0
            self.plusBtn.alpha       = 0
 
            self.carouselHeightConstraint.constant    = 0
            self.carouselScrollView.alpha             = 0
            self.carouselPageControl.alpha            = 0
            self.filterPanelHeightConstraint.constant = 103
 
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.carouselScrollView.isHidden  = true
            self.carouselPageControl.isHidden = true
            self.searchTextField.becomeFirstResponder()
        }
    }
 
    @objc func collapseSearch() {
        guard isSearchExpanded else { return }
        isSearchExpanded = false
 
        // Filter state tozalash
        selectedCategory = nil
        startDate        = nil
        endDate          = nil
        viewModel.setSearchQuery("")
        viewModel.setCategoryFilter(nil)
        viewModel.setDateRangeFilter(start: nil, end: nil)
 
        searchTextField.resignFirstResponder()
        searchTextField.text = nil
 
        // ✅ Panel ichidagi kontent animatsiyadan OLDIN darhol yo'qoladi
        searchTextField.alpha  = 0
        closeSearchBtn.alpha   = 0
        filterScrollView.alpha = 0
 
        carouselScrollView.isHidden  = false
        carouselPageControl.isHidden = false
 
        UIView.animate(
            withDuration: 0.38, delay: 0,
            usingSpringWithDamping: 0.82, initialSpringVelocity: 0.2,
            options: .curveEaseInOut
        ) {
            self.balanceLabel.alpha  = 1
            self.searchIconBtn.alpha = 1
            self.plusBtn.alpha       = 1
 
            self.carouselHeightConstraint.constant    = 320
            self.carouselScrollView.alpha             = 1
            self.carouselPageControl.alpha            = 1
            self.filterPanelHeightConstraint.constant = 0
 
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.searchFilterPanel.isHidden = true
            self.viewModel.reloadFromLocal()
        }
    }
 
    // MARK: - Search Text
 
    @objc func searchTextChanged() {
        viewModel.setSearchQuery(searchTextField.text ?? "")
    }
 
    // MARK: - Category Filter
 
    @objc func showCategoryPicker() {
        let alert = UIAlertController(
            title: "Kategoriya tanlang",
            message: nil,
            preferredStyle: .actionSheet
        )
 
        alert.addAction(UIAlertAction(
            title: selectedCategory == nil ? "✓ Barchasi" : "Barchasi",
            style: .default
        ) { [weak self] _ in
            self?.selectedCategory = nil
            self?.viewModel.setCategoryFilter(nil)
            self?.updateFilterPillStyles()
        })
 
        for cat in allCategories {
            let title = (selectedCategory == cat) ? "✓ \(cat)" : cat
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.selectedCategory = cat
                self?.viewModel.setCategoryFilter(cat)
                self?.updateFilterPillStyles()
            })
        }
 
        alert.addAction(UIAlertAction(title: "Bekor qilish", style: .cancel))
 
        if let popover = alert.popoverPresentationController {
            popover.sourceView = categoryFilterBtn
            popover.sourceRect = categoryFilterBtn.bounds
        }
        present(alert, animated: true)
    }
 
    // MARK: - Date Range Filter
 
    @objc func showDatePicker() {
        let vc = DateRangePickerViewController()
        vc.initialStartDate = startDate
        vc.initialEndDate   = endDate
        vc.onConfirm = { [weak self] (start: Date?, end: Date?) in
            guard let self else { return }
            self.startDate = start
            self.endDate   = end
            self.viewModel.setDateRangeFilter(start: start, end: end)
            self.updateFilterPillStyles()
        }
        vc.modalPresentationStyle = .formSheet
        if #available(iOS 16.0, *) {
            if let sheet = vc.sheetPresentationController {
                sheet.detents               = [.medium()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            }
        }
        present(vc, animated: true)
    }
 
    // MARK: - Clear Filters
 
    @objc func clearAllFilters() {
        selectedCategory = nil
        startDate        = nil
        endDate          = nil
        viewModel.setCategoryFilter(nil)
        viewModel.setDateRangeFilter(start: nil, end: nil)
        updateFilterPillStyles()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        // collapseSearch() CHAQIRILMAYDI — panel ochiq qoladi
    }
 
    // MARK: - Update Pill Styles
 
    func updateFilterPillStyles() {
        let catActive = selectedCategory != nil
        let catTitle  = catActive ? (selectedCategory ?? "Kategoriya") : "Kategoriya"
        updatePillStyle(categoryFilterBtn, title: catTitle, icon: "tag.fill", active: catActive)
 
        let dateActive = startDate != nil || endDate != nil
        let dateTitle: String
        if let s = startDate, let e = endDate {
            let f = DateFormatter()
            f.dateFormat = "dd.MM"
            dateTitle = "\(f.string(from: s))–\(f.string(from: e))"
        } else if startDate != nil || endDate != nil {
            dateTitle = "Sana ✓"
        } else {
            dateTitle = "Sana"
        }
        updatePillStyle(dateFilterBtn, title: dateTitle, icon: "calendar", active: dateActive)
 
        let anyActive = catActive || dateActive
        UIView.animate(withDuration: 0.2) {
            self.clearFilterBtn.alpha                    = anyActive ? 1.0 : 0.0
            self.clearFilterBtn.isUserInteractionEnabled = anyActive
        }
        if anyActive {
            updatePillStyle(clearFilterBtn, title: "Tozalash", icon: "xmark.circle.fill", active: false)
        }
    }
}
