
// CurrencyService.swift
// SmartFinance
// Real-time valyuta kurslari — ExchangeRate-API (tekin, ro'yxatsiz)
// Endpoint: https://open.er-api.com/v6/latest/UZS

import Foundation

// MARK: - Model

struct CurrencyRate {
    let code: String
    let name: String
    let flag: String
    let rateToUZS: Double   // 1 unit = X UZS
}

// MARK: - Cache

private struct RateCache {
    let rates: [CurrencyRate]
    let fetchedAt: Date

    /// 1 soat davomida kesh ishlaydi
    var isValid: Bool {
        Date().timeIntervalSince(fetchedAt) < 3600
    }
}

// MARK: - CurrencyService

final class CurrencyService {

    static let shared = CurrencyService()
    private init() {}

    // Tekin, kalitsiz API — open.er-api.com
    private let apiURL = "https://open.er-api.com/v6/latest/USD"

    private var cache: RateCache?

    // UserDefaults da so'nggi kurslarni saqlash (offline fallback)
    private let udKey = "sf_cached_rates_v1"

    // Asosiy valyutalar ro'yxati (kod, o'zbek nomi, bayroq)
    private let currencyMeta: [(code: String, name: String, flag: String)] = [
        ("UZS", "O'zbek so'mi",   "🇺🇿"),
        ("USD", "AQSh dollari",   "🇺🇸"),
        ("EUR", "Yevro",          "🇪🇺"),
        ("RUB", "Rossiya rubli",  "🇷🇺"),
        ("GBP", "Britaniya funt", "🇬🇧"),
        ("CNY", "Xitoy yuani",    "🇨🇳"),
        ("KZT", "Qozog'iston tenge", "🇰🇿"),
    ]

    // MARK: - Public API

    /// Valyuta kurslarini oladi. Kesh yangi bo'lsa — keshdan, aks holda tarmoqdan.
    func fetchRates(completion: @escaping ([CurrencyRate]) -> Void) {
        // 1. Kesh yangi bo'lsa qaytarish
        if let cache = cache, cache.isValid {
            completion(cache.rates)
            return
        }

        // 2. Tarmoqdan olish
        guard let url = URL(string: apiURL) else {
            completion(fallbackRates())
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let usdRates = json["rates"] as? [String: Double] else {
                // Tarmoq xatosi — offline keshdan foydalanish
                DispatchQueue.main.async {
                    completion(self?.loadFromUserDefaults() ?? self?.fallbackRates() ?? [])
                }
                return
            }

            let rates = self.buildRates(usdRates: usdRates)
            self.cache = RateCache(rates: rates, fetchedAt: Date())
            self.saveToUserDefaults(rates: rates)

            DispatchQueue.main.async {
                completion(rates)
            }
        }.resume()
    }

    // MARK: - Rate building

    /// USD bazasidagi kurslardan UZS bazasiga o'tkazish
    /// Agar API UZS kursini qaytarsa: 1 USD = X UZS → 1 EUR = (X / eurusd) UZS
    private func buildRates(usdRates: [String: Double]) -> [CurrencyRate] {
        guard let uzsPerUsd = usdRates["UZS"], uzsPerUsd > 0 else {
            return fallbackRates()
        }

        var result: [CurrencyRate] = []

        for meta in currencyMeta {
            let rateToUZS: Double

            if meta.code == "UZS" {
                rateToUZS = 1.0
            } else if meta.code == "USD" {
                rateToUZS = uzsPerUsd
            } else if let usdToCurrency = usdRates[meta.code], usdToCurrency > 0 {
                // 1 currency = (uzsPerUsd / usdToCurrency) UZS
                rateToUZS = uzsPerUsd / usdToCurrency
            } else {
                continue // Kurs topilmadi — o'tkazib yuborish
            }

            result.append(CurrencyRate(
                code: meta.code,
                name: meta.name,
                flag: meta.flag,
                rateToUZS: rateToUZS
            ))
        }

        return result.isEmpty ? fallbackRates() : result
    }

    // MARK: - Offline fallback (so'nggi ma'lum kurslar, 2025-yil bazasida)

    func fallbackRates() -> [CurrencyRate] {
        return [
            CurrencyRate(code: "UZS", name: "O'zbek so'mi",      flag: "🇺🇿", rateToUZS: 1),
            CurrencyRate(code: "USD", name: "AQSh dollari",       flag: "🇺🇸", rateToUZS: 12_850),
            CurrencyRate(code: "EUR", name: "Yevro",              flag: "🇪🇺", rateToUZS: 13_920),
            CurrencyRate(code: "RUB", name: "Rossiya rubli",      flag: "🇷🇺", rateToUZS: 140),
            CurrencyRate(code: "GBP", name: "Britaniya funt",     flag: "🇬🇧", rateToUZS: 16_200),
            CurrencyRate(code: "CNY", name: "Xitoy yuani",        flag: "🇨🇳", rateToUZS: 1_760),
            CurrencyRate(code: "KZT", name: "Qozog'iston tenge",  flag: "🇰🇿", rateToUZS: 26),
        ]
    }

    // MARK: - UserDefaults persistence

    private func saveToUserDefaults(rates: [CurrencyRate]) {
        let dict = rates.map { ["code": $0.code, "name": $0.name, "flag": $0.flag, "rate": $0.rateToUZS] as [String: Any] }
        UserDefaults.standard.set(dict, forKey: udKey)
    }

    private func loadFromUserDefaults() -> [CurrencyRate]? {
        guard let arr = UserDefaults.standard.array(forKey: udKey) as? [[String: Any]] else { return nil }
        let rates = arr.compactMap { d -> CurrencyRate? in
            guard let code = d["code"] as? String,
                  let name = d["name"] as? String,
                  let flag = d["flag"] as? String,
                  let rate = d["rate"] as? Double else { return nil }
            return CurrencyRate(code: code, name: name, flag: flag, rateToUZS: rate)
        }
        return rates.isEmpty ? nil : rates
    }
}

