//
//  AuthManager.swift
//  SmartFinance
//
//  Created by Diyorbek Xikmatullayev on 28/03/26.
//

//import Foundation
//import FirebaseAuth
//
//class AuthManager {
//    static let shared = AuthManager()
//    
//    // 1. Ro'yxatdan o'tish (Sign Up)
//    func signUp(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
//        Auth.auth().createUser(withEmail: email, password: password) { result, error in
//            if let error = error {
//                completion(false, error.localizedDescription)
//                return
//            }
//            completion(true, nil)
//        }
//    }
//    
//    // 2. Kirish (Sign In)
//    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
//        Auth.auth().signIn(withEmail: email, password: password) { result, error in
//            if let error = error {
//                completion(false, error.localizedDescription)
//                return
//            }
//            completion(true, nil)
//        }
//    }
//    
//    // 3. Foydalanuvchi kirganmi yoki yo'q?
//    func isUserLoggedIn() -> Bool {
//        return Auth.auth().currentUser != nil
//    }
//}

import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

// MARK: - Auth Xatolari (Foydalanuvchiga chiqariladigan xabarlar)
enum AuthError: LocalizedError {
    case weakPassword
    case emailAlreadyInUse
    case invalidEmail
    case wrongPassword
    case userNotFound
    case networkError
    case passwordMismatch
    case passwordTooShort
    case passwordNeedsUppercase
    case passwordNeedsNumber
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .weakPassword:          return "Parol juda kuchsiz. Kamida 8 ta belgi, 1 ta katta harf va 1 ta raqam bo'lishi kerak."
        case .emailAlreadyInUse:     return "Bu email allaqachon ro'yxatdan o'tgan."
        case .invalidEmail:          return "Email manzil noto'g'ri formatda."
        case .wrongPassword:         return "Parol noto'g'ri kiritildi."
        case .userNotFound:          return "Bu email bilan foydalanuvchi topilmadi."
        case .networkError:          return "Internet aloqasi yo'q. Tarmoqni tekshiring."
        case .passwordMismatch:      return "Parollar mos kelmadi. Qayta tekshiring."
        case .passwordTooShort:      return "Parol kamida 8 ta belgidan iborat bo'lishi kerak."
        case .passwordNeedsUppercase:return "Parolda kamida 1 ta katta harf bo'lishi kerak."
        case .passwordNeedsNumber:   return "Parolda kamida 1 ta raqam bo'lishi kerak."
        case .unknown(let msg):      return msg
        }
    }
}

// MARK: - AuthManager (Singleton)
final class AuthManager {

    static let shared = AuthManager()
    private init() {}

    // MARK: - Joriy foydalanuvchi
    var currentUser: User? {
        return Auth.auth().currentUser
    }

    var isUserLoggedIn: Bool {
        return Auth.auth().currentUser != nil
    }

    var isAnonymous: Bool {
        return Auth.auth().currentUser?.isAnonymous ?? false
    }

    // MARK: - Parol validatsiyasi (Regex)
    func validatePassword(_ password: String) -> AuthError? {
        if password.count < 8 { return .passwordTooShort }

        let uppercaseRegex = ".*[A-Z]+.*"
        if NSPredicate(format: "SELF MATCHES %@", uppercaseRegex).evaluate(with: password) == false {
            return .passwordNeedsUppercase
        }

        let numberRegex = ".*[0-9]+.*"
        if NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: password) == false {
            return .passwordNeedsNumber
        }

        return nil // ✅ Xato yo'q
    }

    // MARK: - Firebase xatosini AuthError ga o'girish
    private func mapFirebaseError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return .unknown(error.localizedDescription)
        }
        switch code {
        case .weakPassword:          return .weakPassword
        case .emailAlreadyInUse:     return .emailAlreadyInUse
        case .invalidEmail:          return .invalidEmail
        case .wrongPassword:         return .wrongPassword
        case .userNotFound:          return .userNotFound
        case .networkError:          return .networkError
        default:                     return .unknown(error.localizedDescription)
        }
    }

    // MARK: - 1. Ro'yxatdan o'tish (Sign Up)
    func signUp(email: String,
                password: String,
                confirmPassword: String,
                completion: @escaping (Result<User, AuthError>) -> Void) {

        // Parollar mosligini tekshirish
        guard password == confirmPassword else {
            completion(.failure(.passwordMismatch))
            return
        }

        // Parol murakkabligini tekshirish
        if let validationError = validatePassword(password) {
            completion(.failure(validationError))
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(self.mapFirebaseError(error)))
                return
            }
            guard let user = result?.user else {
                completion(.failure(.unknown("Foydalanuvchi yaratilmadi.")))
                return
            }
            completion(.success(user))
        }
    }

    // MARK: - 2. Kirish (Sign In)
    func signIn(email: String,
                password: String,
                completion: @escaping (Result<User, AuthError>) -> Void) {

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(self.mapFirebaseError(error)))
                return
            }
            guard let user = result?.user else {
                completion(.failure(.unknown("Kirish amalga oshmadi.")))
                return
            }
            completion(.success(user))
        }
    }

    // MARK: - 3. Chiqish (Sign Out)
    func signOut(completion: @escaping (Bool) -> Void) {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            completion(true)
        } catch {
            completion(false)
        }
    }

    // MARK: - 4. Parolni tiklash (Forgot Password)
    func resetPassword(email: String,
                       completion: @escaping (Result<Void, AuthError>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(self.mapFirebaseError(error)))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - 5. Anonim Kirish (Guest Mode)
    func signInAnonymously(completion: @escaping (Result<User, AuthError>) -> Void) {
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(self.mapFirebaseError(error)))
                return
            }
            guard let user = result?.user else {
                completion(.failure(.unknown("Mehmon sifatida kirish amalga oshmadi.")))
                return
            }
            completion(.success(user))
        }
    }

    // MARK: - 6. Google Sign-In
    func signInWithGoogle(presentingVC: UIViewController,
                          completion: @escaping (Result<User, AuthError>) -> Void) {

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(.unknown("Firebase clientID topilmadi.")))
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(.unknown(error.localizedDescription)))
                return
            }

            guard let googleUser = result?.user,
                  let idToken = googleUser.idToken?.tokenString else {
                completion(.failure(.unknown("Google tokenini olish muvaffaqiyatsiz bo'ldi.")))
                return
            }

            let accessToken = googleUser.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: accessToken)

            // Agar anonim foydalanuvchi bo'lsa — akkauntlarni birlashtirish
            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                self.linkAnonymousWithGoogle(credential: credential, completion: completion)
            } else {
                Auth.auth().signIn(with: credential) { result, error in
                    if let error = error {
                        completion(.failure(self.mapFirebaseError(error)))
                        return
                    }
                    guard let user = result?.user else {
                        completion(.failure(.unknown("Google orqali kirish amalga oshmadi.")))
                        return
                    }
                    completion(.success(user))
                }
            }
        }
    }

    // MARK: - 7. Account Linking: Anonim → Google
    private func linkAnonymousWithGoogle(credential: AuthCredential,
                                         completion: @escaping (Result<User, AuthError>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(.unknown("Joriy foydalanuvchi topilmadi.")))
            return
        }

        currentUser.link(with: credential) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                // Agar akkaunt allaqachon mavjud bo'lsa — oddiy sign-in qilish
                let nsError = error as NSError
                if nsError.code == AuthErrorCode.credentialAlreadyInUse.rawValue ||
                   nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    Auth.auth().signIn(with: credential) { result, error in
                        if let error = error {
                            completion(.failure(self.mapFirebaseError(error)))
                        } else if let user = result?.user {
                            completion(.success(user))
                        }
                    }
                } else {
                    completion(.failure(self.mapFirebaseError(error)))
                }
                return
            }
            guard let user = result?.user else {
                completion(.failure(.unknown("Akkauntlarni birlashtirish muvaffaqiyatsiz bo'ldi.")))
                return
            }
            completion(.success(user))
        }
    }
}
