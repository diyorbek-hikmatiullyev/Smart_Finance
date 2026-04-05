// CategoryRecognizer.swift
// SmartFinance
// Vendor & Category Recognition - 2 qatlamli yondashuv

import UIKit

struct VendorInfo {
    let name: String
    let category: ExpenseCategory
}

enum ExpenseCategory: String, CaseIterable, Codable {
    case food        = "Oziq-ovqat"
    case transport   = "Transport"
    case clothing    = "Kiyim"
    case pharmacy    = "Dorixona"
    case electronics = "Elektronika"
    case utilities   = "Kommunal"
    case other       = "Boshqa"

    var icon: String {
        switch self {
        case .food:        return "cart.fill"
        case .transport:   return "car.fill"
        case .clothing:    return "tshirt.fill"
        case .pharmacy:    return "cross.case.fill"
        case .electronics: return "desktopcomputer"
        case .utilities:   return "bolt.fill"
        case .other:       return "square.grid.2x2.fill"
        }
    }

    var color: UIColor {
        switch self {
        case .food:        return UIColor(red: 0.2,  green: 0.78, blue: 0.35, alpha: 1)
        case .transport:   return UIColor(red: 0.0,  green: 0.48, blue: 1.0,  alpha: 1)
        case .clothing:    return UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1)
        case .pharmacy:    return UIColor(red: 1.0,  green: 0.23, blue: 0.19, alpha: 1)
        case .electronics: return UIColor(red: 1.0,  green: 0.58, blue: 0.0,  alpha: 1)
        case .utilities:   return UIColor(red: 0.35, green: 0.55, blue: 0.82, alpha: 1)
        case .other:       return .systemGray
        }
    }
}

final class CategoryRecognizer {

    // QATLAM 1: INN → aniq vendor mapping
    private let innDictionary: [String: VendorInfo] = [
        "207229526" : VendorInfo(name: "Korzinka",      category: .food),
        "301386376" : VendorInfo(name: "Makro",         category: .food),
        "302442374" : VendorInfo(name: "Havas",         category: .food),
        "306465717" : VendorInfo(name: "Baraka Market", category: .food),
        "310600000" : VendorInfo(name: "Artel",         category: .electronics),
        "200430555" : VendorInfo(name: "UzAuto",        category: .transport),
        "302726150" : VendorInfo(name: "Next",          category: .clothing),
        "302726151" : VendorInfo(name: "Zara UZ",       category: .clothing),
        "307044442" : VendorInfo(name: "Najot Shifo",   category: .pharmacy),
    ]

    // QATLAM 2: Nom → keyword matching
    private let keywordMap: [(keywords: [String], category: ExpenseCategory)] = [
        (["bozor", "market", "super", "food", "korzinka", "makro", "havas",
          "non", "meat", "овощи", "grocery"], .food),
        (["taxi", "uber", "yandex", "avto", "bus", "metro",
          "fuel", "benzin", "yoqilg'i"], .transport),
        (["kiyim", "fashion", "style", "boutique", "zara",
          "next", "одежда", "textile", "shoes", "poyafzal"], .clothing),
        (["dorixona", "apteka", "pharma", "dori", "shifo",
          "clinic", "медицина", "health"], .pharmacy),
        (["tech", "electronic", "artel", "samsung", "apple",
          "kompyuter", "telefon", "gadget"], .electronics),
        (["gaz", "elektr", "suv", "communal", "utility",
          "internet", "mobile", "uzmobile", "beeline"], .utilities),
    ]

    /// INN yoki vendor nomi asosida kategoriyani aniqlaydi
    func recognize(inn: String?, vendorName: String?) -> (vendor: String, category: ExpenseCategory) {

        // 1-qatlam: INN bo'yicha
        if let inn = inn?.trimmingCharacters(in: .whitespaces),
           let vendorInfo = innDictionary[inn] {
            return (vendorInfo.name, vendorInfo.category)
        }

        // 2-qatlam: Nom bo'yicha keyword search
        if let name = vendorName?.lowercased() {
            for entry in keywordMap {
                if entry.keywords.contains(where: { name.contains($0) }) {
                    return (vendorName ?? "Noma'lum", entry.category)
                }
            }
        }

        // Fallback
        return (vendorName ?? "Noma'lum do'kon", .other)
    }
}
