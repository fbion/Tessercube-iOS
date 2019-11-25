//
//  CreateRedPacketViewController.swift
//  TesserCube
//
//  Created by jk234ert on 11/12/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import DMS_HDWallet_Cocoa

class CreateRedPacketViewController: TCBaseViewController {
    
    private let deployButton: TCActionButton = {
        let button = TCActionButton()
        button.color = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Deploy Contract", for: .normal)
        return button
    }()
    
    override func configUI() {
        super.configUI()

        title = "Create Red Packet"
        if #available(iOS 13.0, *) {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(CreateRedPacketViewController.closeBarButtonItemPressed(_:)))
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(CreateRedPacketViewController.closeBarButtonItemPressed(_:)))
        }
        
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        stackView.addArrangedSubview(deployButton)

        // Bind button action
        deployButton.addTarget(self, action: #selector(CreateRedPacketViewController.deployContract(_:)), for: .touchUpInside)
    }
}

extension CreateRedPacketViewController {

    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @objc private func deployContract(_ sender: UIButton) {
        guard let firstWalletModel = WalletService.default.walletModels.value.first else {
            return
        }
        do {
            let address = try firstWalletModel.hdWallet?.address()
            RedPacketService.shared.deployMockContract(address: address ?? "")
        } catch {
            print("error: \(error.localizedDescription)")
            return
        }
        
    }

}

