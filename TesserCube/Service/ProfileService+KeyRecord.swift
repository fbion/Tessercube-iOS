//
//  ProfileService+KeyRecord.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-9-3.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import DMSOpenPGP

extension ProfileService {

 func addNewKey(userID: String, passphrase: String?, generateKeyData: GenerateKeyData, _ completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let newKey = try KeyFactory.key(from: generateKeyData)

                // TODO: KeyRecord insert here. Should Refactoring here when we support sub-key feature
                try self.addNewContact(keyUserID: userID, key: newKey)

                // Should be the secret invalidated when passcode is removed? If not then use `.WhenUnlocked`
                try self.keyChain
                    .authenticationPrompt("Authenticate to update your password")   // this auth request should be in background queue
                    .set(passphrase ?? "", key: newKey.longIdentifier)

                completion(nil)
            } catch let error {
                print("error")
                completion(error)
            }
        }
    }

    func addNewKey(armoredKey: String, passphrase: String?, _ completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let key = try KeyFactory.key(from: armoredKey, passphrase: passphrase)

                // TODO: only check contact's keys before add key when we support sub-key feature
                if self.keys.value.contains(where: { $0.longIdentifier == key.longIdentifier }) {
                    throw TCError.keysAlreadyExsit
                }
                // Only create one Contact from key's primary userID
                let userID = key.keyRing.publicKeyRing.primaryKey.primaryUserID ?? ""

                // TODO: KeyRecord insert here. Should Refactoring here when we support sub-key feature
                try self.addNewContact(keyUserID: userID, key: key)

                try self.keyChain
                    .authenticationPrompt("Authenticate to update your password")   // this auth request should be in background queue
                    .set(passphrase ?? "", key: key.longIdentifier)

//                var currentKeys = self.keys.value
//                currentKeys.append(key)
//                self.keys.accept(currentKeys)

                completion(nil)
            } catch let error {
                completion(error)
            }
        }
    }

    func decryptKey(armoredKey: String, passphrase: String?, _ completion: @escaping (TCKey?, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let key = try KeyFactory.key(from: armoredKey, passphrase: passphrase)
                completion(key, nil)
            } catch let error {
                completion(nil, error)
            }
        }
    }

    func addKey(_ tckey: TCKey, passphrase: String?, _ completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                // Only create one Contact from key's primary userID
                let userIDs = tckey.keyRing.publicKeyRing.primaryKey.userIDs

                // TODO: KeyRecord insert here. Should Refactoring here when we support sub-key feature
                try userIDs.forEach { try self.addNewContact(keyUserID: $0, key: tckey) }

                try self.keyChain
                    .authenticationPrompt("Authenticate to update your password")   // this auth request should be in background queue
                    .set(passphrase ?? "", key: tckey.longIdentifier)

                // Should not reload keys manually. Observe KeyRocrd change and update from top of source
//                var currentKeys = self.keys.value
//                currentKeys.append(tckey)
//                self.keys.accept(currentKeys)

                completion(nil)
            } catch let error {
                completion(error)
            }
        }
    }

}
