// CategoryRecognizer.swift
// SmartFinance
// Vendor & Category Recognition - 3 qatlamli yondashuv
// 1. INN → aniq vendor
// 2. Do'kon nomi → keyword
// 3. Mahsulot nomlari → keyword (OCR chek uchun)
 
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
 
    // QATLAM 2: Do'kon nomi → keyword matching
    private let vendorKeywordMap: [(keywords: [String], category: ExpenseCategory)] = [
        (["bozor", "market", "super", "food", "korzinka", "makro", "havas",
          "non", "meat", "grocery", "baraka", "anglesey", "deli", "cafe",
          "restoran", "oshxona", "lavash", "burger", "pizza", "sushi"], .food),
        (["taxi", "uber", "yandex", "avto", "bus", "metro",
          "fuel", "benzin", "yoqilg'i", "zapravka", "metan"], .transport),
        (["kiyim", "fashion", "style", "boutique", "zara", "next",
          "textile", "shoes", "poyabzal", "sport", "adidas", "nike"], .clothing),
        (["dorixona", "apteka", "pharma", "dori", "shifo",
          "clinic", "tibbiy", "health", "najot", "shifobaxsh"], .pharmacy),
        (["tech", "electronic", "artel", "samsung", "apple",
          "kompyuter", "telefon", "gadget", "texnomart", "mediapark"], .electronics),
        (["gaz", "elektr", "suv", "communal", "utility",
          "internet", "mobile", "uzmobile", "beeline", "ucell"], .utilities),
    ]
 
    // QATLAM 3: Mahsulot nomlari → kategoriya
    // OCR orqali o'qilgan chek matnidan mahsulot nomini aniqlash uchun
    private let productKeywordMap: [(keywords: [String], category: ExpenseCategory)] = [
 
        // 🥗 Oziq-ovqat mahsulotlari
        ([
            // Sabzavot va mevalar
            "salat", "помидор", "pomidor", "bodring", "karam", "sabzi",
            "kartoshka", "piyoz", "sarimsoq", "limon", "olma", "banan",
            "uzum", "anor", "o'rik", "shaftoli", "qovun", "tarvuz",
            // Go'sht
            "go'sht", "мясо", "mol", "qo'y", "tovuq", "baliq",
            "kolbasa", "sosiska", "vetchina", "kotlet",
            // Sut mahsulotlari
            "sut", "qatiq", "kefir", "qaymoq", "sariyog", "tvorog",
            "pishloq", "yogurt", "молоко", "сметана",
            // Non va un mahsulotlari
            "non", "bread", "lavash", "tort", "pechene", "печенье",
            "un", "makaron", "pasta", "guruch", "don",
            // Ichimliklar
            "suv", "juice", "sharbat", "kompot", "чай", "kofe",
            "coca", "pepsi", "sprite", "limonad",
            // Boshqa oziq-ovqat
            "yog'", "tuz", "shakar", "asal", "jem", "варенье",
            "konserv", "funchoza", "shohona", "manti", "somsa",
            "osh", "palov", "lag'mon", "шурпа"
        ], .food),
 
        // 👕 Kiyim-kechak
        ([
            "ko'ylak", "shim", "futbolka", "sviter", "palto", "kurtka",
            "платье", "брюки", "рубашка", "носки", "джинсы",
            "poyabzal", "туфли", "кроссовки", "ботинки",
            "belbog", "galstuk", "шарф", "перчатки",
            "ichki kiyim", "белье", "носки", "колготки"
        ], .clothing),
 
        // 💊 Dorixona / Salomatlik
        ([
            "dori", "tablet", "капсул", "витамин", "vitamin",
            "aspirin", "paracetamol", "antibiotik", "sirop",
            "malham", "крем", "bandaj", "vata", "shpris",
            "тонометр", "термометр", "маска", "перчатки медицинские"
        ], .pharmacy),
 
        // 📱 Elektronika
        ([
            "telefon", "планшет", "noutbuk", "kompyuter",
            "наушники", "quloqchin", "zaryadka", "кабель", "провод",
            "batareya", "батарейка", "chiroq", "лампа", "розетка",
            "принтер", "сканер", "клавиатура", "мышка"
        ], .electronics),
 
        // ⚡ Kommunal
        ([
            "gaz", "elektr", "электр", "свет", "suv хизмати",
            "internet", "wi-fi", "wi fi", "aloqa", "связь"
        ], .utilities),
 
        // 🚗 Transport
        ([
            "benzin", "дизель", "yoqilg'i", "moy", "масло",
            "shinа", "шина", "запчасть", "ehtiyot", "avtobus",
            "metro", "taksi", "taxi"
        ], .transport),
    ]
 
    // MARK: - Asosiy funksiya (do'kon nomi uchun)
 
    func recognize(inn: String?, vendorName: String?) -> (vendor: String, category: ExpenseCategory) {
 
        // 1-qatlam: INN bo'yicha
        if let inn = inn?.trimmingCharacters(in: .whitespaces),
           let vendorInfo = innDictionary[inn] {
            return (vendorInfo.name, vendorInfo.category)
        }
 
        // 2-qatlam: Do'kon nomi bo'yicha keyword search
        if let name = vendorName?.lowercased() {
            for entry in vendorKeywordMap {
                if entry.keywords.contains(where: { name.contains($0) }) {
                    return (vendorName ?? "Noma'lum", entry.category)
                }
            }
        }
 
        return (vendorName ?? "Noma'lum do'kon", .other)
    }
 
    // MARK: - OCR Chek uchun: mahsulot nomlaridan kategoriya aniqlash
 
    /// Chek matnidagi barcha qatorlarni tahlil qilib eng ko'p uchraydigan kategoriyani qaytaradi
    func recognizeFromReceiptText(_ fullText: String) -> ExpenseCategory? {
        let lines = fullText.lowercased().components(separatedBy: "\n")
 
        // Har bir kategoriya uchun nechta mahsulot topilganini hisoblash
        var scores: [ExpenseCategory: Int] = [:]
 
        for line in lines {
            // Raqam va summa qatorlarini o'tkazib yuborish
            // (faqat harf bo'lgan qatorlarni tekshiramiz)
            let letterCount = line.filter { $0.isLetter }.count
            guard letterCount > 2 else { continue }
 
            // Kassir, STIR, sana kabi texnik qatorlarni o'tkazib yuborish
            let skipWords = ["kassir", "stir", "savdo", "chek", "pos", "sana",
                             "hammasi", "jami", "chegirma", "to'lov", "tolov",
                             "qqs", "mxik", "tovar", "олди", "sotdi", "receipt"]
            if skipWords.contains(where: { line.contains($0) }) { continue }
 
            for entry in productKeywordMap {
                if entry.keywords.contains(where: { line.contains($0) }) {
                    scores[entry.category, default: 0] += 1
                }
            }
        }
 
        // Eng yuqori ballni qaytarish
        return scores.max(by: { $0.value < $1.value })?.key
    }
 
    // MARK: - To'liq OCR tahlil (do'kon nomi + mahsulotlar kombinatsiyasi)
 
    /// Do'kon nomidan kategoriya topilmasa mahsulot nomlaridan qidiradi
    func recognizeFromReceipt(
        inn: String?,
        vendorName: String?,
        fullReceiptText: String
    ) -> (vendor: String, category: ExpenseCategory) {
 
        // 1. Avval oddiy recognize
        let (resolvedVendor, category) = recognize(inn: inn, vendorName: vendorName)
 
        // 2. Agar kategoriya aniqlanmagan bo'lsa — chek matnidan qidirish
        if category == .other {
            if let detectedCategory = recognizeFromReceiptText(fullReceiptText) {
                return (resolvedVendor, detectedCategory)
            }
        }
 
        return (resolvedVendor, category)
    }
}
