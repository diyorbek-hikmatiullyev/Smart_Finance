//
//  ProfileImageStorage.swift
//  SmartFinance
//

import UIKit
import FirebaseAuth
import FirebaseStorage

enum ProfileImageStorage {

    static func uploadProfileImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }

        let storage = Storage.storage().reference()
        let profileRef = storage.child("profile_images/\(uid).jpg")

        profileRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            profileRef.downloadURL { url, error in
                if let urlString = url?.absoluteString {
                    completion(.success(urlString))
                } else if let error = error {
                    completion(.failure(error))
                }
            }
        }
    }
}
