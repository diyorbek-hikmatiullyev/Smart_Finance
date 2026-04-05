//
//  DashboardExtensions.swift
//  SmartFinance
//
//  Created by Diyorbek Xikmatullayev on 27/03/26.
//

import Foundation
import UIKit

// Jadvalda sanalar bo'yicha guruhlash uchun model
struct GroupedTransactions {
    let date: String
    var transactions: [Transaction]
}

extension Date {
    func toString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: self)
    }
}
