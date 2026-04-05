//
//  GroupedTransactions.swift
//  SmartFinance
//

import Foundation

struct GroupedTransactions {
    let date: String
    var transactions: [Transaction]
}

enum TransactionGrouping {
    static func group(_ transactions: [Transaction]) -> [GroupedTransactions] {
        var map: [String: [Transaction]] = [:]
        for t in transactions {
            let k = t.date?.toString() ?? "Noma'lum"
            map[k, default: []].append(t)
        }
        return map.map { GroupedTransactions(date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }
}

extension Date {
    func toString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: self)
    }
}
