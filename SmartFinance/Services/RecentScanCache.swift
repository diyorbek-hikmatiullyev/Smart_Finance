// RecentScanCache.swift
// SmartFinance
// Chek duplicate oldini olish uchun UserDefaults keshi
 
import Foundation
 
final class RecentScanCache {
    static let shared = RecentScanCache()
    private init() {}
 
    private let udKey = "sf_recent_scans_v1"
    // 24 soat ichida bir xil chek qayta saqlanmasin
    private let ttl: TimeInterval = 86_400
 
    private var cache: [String: Date] {
        get {
            guard let data = UserDefaults.standard.data(forKey: udKey),
                  let decoded = try? JSONDecoder().decode([String: Date].self, from: data)
            else { return [:] }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: udKey)
            }
        }
    }
 
    /// Shu key so'nggi 24 soat ichida saqlangan bo'lsa true qaytaradi
    func contains(_ key: String) -> Bool {
        let now = Date()
        var current = cache
        // Eskirgan yozuvlarni tozalash
        current = current.filter { now.timeIntervalSince($0.value) < ttl }
        cache = current
        return current[key] != nil
    }
 
    /// Yangi key ni keshga qo'shish
    func add(_ key: String) {
        var current = cache
        current[key] = Date()
        cache = current
    }
}
