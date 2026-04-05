//
//  AuthSessionProvider.swift
//  SmartFinance
//

import Foundation
import FirebaseAuth

protocol AuthSessionProviding: AnyObject {
    var currentUserID: String? { get }
    var hasSignedInUser: Bool { get }
}

/// Firebase Auth sessiyasini View va ViewModel dan ajratadi (test va almashtirish uchun protokol).
final class AuthSessionProvider: AuthSessionProviding {
    static let shared = AuthSessionProvider()
    private init() {}

    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }

    var hasSignedInUser: Bool {
        Auth.auth().currentUser != nil
    }
}
