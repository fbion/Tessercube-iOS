//
//  BackupMnemonicCollectionViewModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2019-11-8.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit

final public class BackupMnemonicCollectionViewModel: MnemonicCollectionViewModel {

    let wallet: Wallet

    public init(wallet: Wallet) {
        self.wallet = wallet
        super.init()
    }

}

extension BackupMnemonicCollectionViewModel {

    public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4 * 3    // 4 row * 3 col
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! MnemonicCollectionViewCell
        let mnemonic = wallet.mnemonic
        cell.wordTextField.text = mnemonic[indexPath.item]
        cell.wordTextField.isEnabled = false
        return cell
    }

}