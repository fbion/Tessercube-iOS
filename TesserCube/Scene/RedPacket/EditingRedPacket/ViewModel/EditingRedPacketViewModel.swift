//
//  EditingRedPacketViewModel.swift
//  TesserCube
//
//  Created by Cirno MainasuK on 2020-1-10.
//  Copyright © 2020 Sujitech. All rights reserved.
//

import os
import Foundation
import RxSwift
import RxCocoa
import RxSwiftUtilities
import BigInt

final class EditingRedPacketViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    let createActivityIndicator = ActivityIndicator()
    
    // Input
    let redPacketSplitType = BehaviorRelay(value: SplitType.average)
    
    let walletModels = BehaviorRelay<[WalletModel]>(value: [])
    let selectWalletModel = BehaviorRelay<WalletModel?>(value: nil)
    
    let amount = BehaviorRelay(value: Decimal(0))       // user input value. default 0
    let share = BehaviorRelay(value: 1)
    
    let name = BehaviorRelay(value: "")
    let message = BehaviorRelay(value: "")
    
    let selectTokenType = BehaviorRelay(value: RedPacketTokenSelectViewModel.SelectTokenType.eth)
    
    // Output
    let isCreating: Driver<Bool>
    let canDismiss = BehaviorRelay(value: true)
    let amountInputCoinCurrencyUnitLabelText: Driver<String>
    let minimalAmount = BehaviorRelay(value: RedPacketService.redPacketMinAmount)
    let total = BehaviorRelay(value: Decimal(0))     // should not 0 after user input amount
    let sendRedPacketButtonText: Driver<String>
    let walletBalanceForSelectToken: Driver<BigUInt?>
    let walletSectionFooterViewText: Driver<String>
    
    enum TableViewCellType {
        case wallet                 // select a wallet to send red packet
        case token                  // select token type
        case amount                 // input the amount for send
        case share                  // input the count for shares
        case name                   // input the sender name
        case message                // input the comment message
    }
    
    let sections: [[TableViewCellType]] = [
        [
            .wallet,
            .token,
        ],
        [
            .amount,
            .share,
        ],
        [
            .name,
            .message,
        ],
    ]
    
    override init() {
        isCreating = createActivityIndicator.asDriver()
        amountInputCoinCurrencyUnitLabelText = redPacketSplitType.asDriver()
            .map { type in type == .average ? "ETH per share" : "ETH" }
        sendRedPacketButtonText = total.asDriver()
            .map { total in
                guard total > 0, let totalInETH = NumberFormatter.decimalFormatterForETH.string(from: total as NSNumber) else {
                    return "Send"
                }
                
                return "Send \(totalInETH) ETH"
        }
        
        let _walletBalanceForSelectToken = selectTokenType.asDriver()
            .withLatestFrom(selectWalletModel.asDriver()) {
                return ($0, $1)
            }
            .flatMapLatest { (selectTokenType, selectWalletModel) -> Driver<BigUInt?> in
                guard let walletModel = selectWalletModel else {
                    return Driver.just(nil)
                }
                switch selectTokenType {
                case .eth:
                    return walletModel.balance.asDriver()
                case .erc20(let walletToken):
                    return Observable.from(object: walletToken)
                        .map { $0.balance }
                        .asDriver(onErrorJustReturn: nil)
                }
            }
        walletBalanceForSelectToken = _walletBalanceForSelectToken
        
        walletSectionFooterViewText = _walletBalanceForSelectToken.asDriver()
            .withLatestFrom(selectTokenType.asDriver()) { (balance, selectTokenType) -> String in
                let placeholder = "Current balance: - "

                let decimals: Int
                let symbol: String
                switch selectTokenType {
                case .eth:
                    decimals = 18
                    symbol = "ETH"
                case let .erc20(walletToken):
                    guard let token = walletToken.token else {
                        return placeholder
                    }
                    
                    decimals = token.decimals
                    symbol = token.symbol
                }
        
                let _balanceInDecimal = balance
                    .flatMap { Decimal(string: String($0)) }
                    .map { balance in balance / pow(10, decimals) }
                
                guard let balanceInDecimal = _balanceInDecimal else {
                    return placeholder
                }
                
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.minimumIntegerDigits = 1
                formatter.maximumFractionDigits = (decimals + 1) / 2
                formatter.groupingSeparator = ""
                
                return formatter.string(from: balanceInDecimal as NSNumber).flatMap { decimalString in
                    return "Current balance: \(decimalString) \(symbol)"
                    } ?? placeholder
            }
        
        super.init()
        
        // Update default select wallet model when wallet model pool change
        walletModels.asDriver()
            .map { $0.first }
            .drive(selectWalletModel)
            .disposed(by: disposeBag)
        
        Driver.combineLatest(share.asDriver(), redPacketSplitType.asDriver()) { share, splitType -> Decimal in
            switch splitType {
            case .average:
                return RedPacketService.redPacketMinAmount
            case .random:
                return Decimal(share) * RedPacketService.redPacketMinAmount
            }
        }
        .drive(minimalAmount)
        .disposed(by: disposeBag)
        
        Driver.combineLatest(redPacketSplitType.asDriver(), amount.asDriver(), share.asDriver()) { splitType, amount, share -> Decimal in
            switch splitType {
            case .random:
                return amount
            case .average:
                return amount * Decimal(share)
            }
        }
        .drive(total)
        .disposed(by: disposeBag)
        
        isCreating.asDriver()
            .map { !$0 }
            .drive(canDismiss)
            .disposed(by: disposeBag)
        
        // Reset select token type to .eth when select new wallet
        selectWalletModel.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.selectTokenType.accept(.eth)
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension EditingRedPacketViewModel {
    
    enum SplitType: Int, CaseIterable {
        case average
        case random
        
        var title: String {
            switch self {
            case .average:
                return "Average"
            case .random:
                return "Random"
            }
        }
    }
    
}

// MARK: - UITableViewDataSource
extension EditingRedPacketViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch sections[indexPath.section][indexPath.row] {
        case .wallet:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SelectWalletTableViewCell.self), for: indexPath) as! SelectWalletTableViewCell
            walletModels.asDriver()
                .drive(_cell.viewModel.walletModels)
                .disposed(by: _cell.disposeBag)
            _cell.viewModel.selectWalletModel.asDriver()
                .drive(selectWalletModel)
                .disposed(by: _cell.disposeBag)
            cell = _cell
            
        case .token:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SelectTokenTableViewCell.self), for: indexPath) as! SelectTokenTableViewCell
            selectTokenType.asDriver()
                .map { type -> String in
                    switch type {
                    case .eth:                      return "ETH"
                    case let .erc20(walletToken):   return walletToken.token?.name ?? "-"
                    }
                }
                .drive(_cell.tokenNameTextField.rx.text)
                .disposed(by: disposeBag)
            
            cell = _cell
            
        case .amount:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputRedPacketAmoutTableViewCell.self), for: indexPath) as! InputRedPacketAmoutTableViewCell
            
            // Bind coin currency unit label text to label
            amountInputCoinCurrencyUnitLabelText.asDriver()
                .drive(_cell.coinCurrencyUnitLabel.rx.text)
                .disposed(by: _cell.disposeBag)
            
            _cell.amount.asDriver()
                .drive(amount)
                .disposed(by: _cell.disposeBag)
            
            minimalAmount.asDriver()
                .drive(_cell.minimalAmount)
                .disposed(by: _cell.disposeBag)
            
            cell = _cell
            
        case .share:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputRedPacketShareTableViewCell.self), for: indexPath) as! InputRedPacketShareTableViewCell
            
            _cell.share.asDriver()
                .drive(share)
                .disposed(by: disposeBag)
            
            cell = _cell
            
        case .name:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputRedPacketSenderTableViewCell.self), for: indexPath) as! InputRedPacketSenderTableViewCell
            
            _cell.nameTextField.rx.text.orEmpty.asDriver()
                .drive(name)
                .disposed(by: _cell.disposeBag)
            
            cell = _cell
            
        case .message:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputRedPacketMessageTableViewCell.self), for: indexPath) as! InputRedPacketMessageTableViewCell
            
            _cell.messageTextField.rx.text.orEmpty.asDriver()
                .drive(message)
                .disposed(by: _cell.disposeBag)
            
            cell = _cell
        }
        
        return cell
    }
    
}