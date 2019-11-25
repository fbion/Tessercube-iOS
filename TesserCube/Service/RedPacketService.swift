//
//  RedPacketService.swift
//  TesserCube
//
//  Created by jk234ert on 11/12/19.
//  Copyright © 2019 Sujitech. All rights reserved.
//

import Foundation
import Web3

class RedPacketService {
    static let shared = RedPacketService()
    private let web3 = Web3(rpcURL: "HTTP://127.0.0.1:7545")
    
    func checkNetworkStatus() {
        web3.clientVersion { (response) in
            switch response.status {
            case .failure(let error):
                print("clientVersion failed with error: \(error.localizedDescription)")
            case .success(let version):
                print("clientVersion: \(version)")
            }
        }
        
        web3.net.version { (response) in
            switch response.status {
            case .failure(let error):
                print("netVersion failed with error: \(error.localizedDescription)")
            case .success(let version):
                print("netVersion: \(version)")
            }
        }
        
        web3.net.peerCount { (response) in
            switch response.status {
            case .failure(let error):
                print("peerCount failed with error: \(error.localizedDescription)")
            case .success(let quantity):
                print("peerCount: \(quantity.quantity)")
            }
        }
        
        web3.eth.gasPrice { (response) in
            switch response.status {
            case .failure(let error):
                print("gasPrice failed with error: \(error.localizedDescription)")
            case .success(let quantity):
                print("gasPrice: \(quantity.quantity)")
            }
        }
        
        web3.eth.accounts { (response) in
            switch response.status {
            case .failure(let error):
                print("accounts failed with error: \(error.localizedDescription)")
            case .success(let accounts):
                print("accounts count: \(accounts.count)")
            }
        }
    }
    
    func deployMockContract(address: String) {
        do {
            let decoder = JSONDecoder()
            let byteCode = try EthereumData(ethereumValue: mockContractBytes)
            
            let abi = try decoder.decode([ABIObject].self, from: mockContractABI.data(using: .utf8)!)
            let contract = web3.eth.Contract(abi: abi, address: nil)
            guard let invocation = contract.deploy(byteCode: byteCode, parameters: "hello") else {
                return
            }
            let constructor = contract.constructor
            let paramCount = invocation.parameters.count
            invocation.send(from: try! EthereumAddress(hex: "0x317070c46F1D9e4912C745F8006e780CeddaA028", eip55: false), gas: EthereumQuantity(quantity: BigUInt(3000000)), gasPrice: 0) { (data, error) in
                print("")
            }
        } catch {
            print("deploy failed with error: \(error.localizedDescription)")
        }
    }
}


let mockContractBytes = """
608060405234801561001057600080fd5b5060405161039238038061039283398101604052805101805161003a906000906020840190610041565b50506100dc565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061008257805160ff19168380011785556100af565b828001600101855582156100af579182015b828111156100af578251825591602001919060010190610094565b506100bb9291506100bf565b5090565b6100d991905b808211156100bb57600081556001016100c5565b90565b6102a7806100eb6000396000f30060806040526004361061004b5763ffffffff7c010000000000000000000000000000000000000000000000000000000060003504166320965255811461005057806393a09352146100da575b600080fd5b34801561005c57600080fd5b50610065610135565b6040805160208082528351818301528351919283929083019185019080838360005b8381101561009f578181015183820152602001610087565b50505050905090810190601f1680156100cc5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b3480156100e657600080fd5b506040805160206004803580820135601f81018490048402850184019095528484526101339436949293602493928401919081908401838280828437509497506101cc9650505050505050565b005b60008054604080516020601f60026000196101006001881615020190951694909404938401819004810282018101909252828152606093909290918301828280156101c15780601f10610196576101008083540402835291602001916101c1565b820191906000526020600020905b8154815290600101906020018083116101a457829003601f168201915b505050505090505b90565b80516101df9060009060208401906101e3565b5050565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061022457805160ff1916838001178555610251565b82800160010185558215610251579182015b82811115610251578251825591602001919060010190610236565b5061025d929150610261565b5090565b6101c991905b8082111561025d57600081556001016102675600a165627a7a72305820751dc4b63878eba922b00b509acff4b9b25507caaf5cddad33e2208252b561f70029
"""

let mockContractABI = """
[{"constant":true,"inputs":[],"name":"getValue","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_str","type":"string"}],"name":"setValue","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[{"name":"_str","type":"string"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"}]
"""
