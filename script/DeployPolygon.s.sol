// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployCREATE3Factory} from './DeployCREATE3Factory.s.sol';
import {DeployRouter} from './DeployRouter.s.sol';
import {DeployAaveV2FlashLoanCallback} from './callbacks/DeployAaveV2FlashLoanCallback.s.sol';
import {DeployAaveV3FlashLoanCallback} from './callbacks/DeployAaveV3FlashLoanCallback.s.sol';
import {DeployBalancerV2FlashLoanCallback} from './callbacks/DeployBalancerV2FlashLoanCallback.s.sol';

contract DeployPolygon is
    DeployCREATE3Factory,
    DeployRouter,
    DeployAaveV2FlashLoanCallback,
    DeployAaveV3FlashLoanCallback,
    DeployBalancerV2FlashLoanCallback
{
    address public constant DEPLOYER = 0xDdbe07CB6D77e81802C55bB381546c0DA51163dd;

    /// @notice Set up deploy parameters and deploy contracts whose `deployedAddress` equals `UNDEPLOYED`.
    function setUp() external {
        create3FactoryConfig = Create3FactoryConfig({
            deployedAddress: 0xB9504E656866cCB985Aa3f1Af7b8B886f8485Df6,
            deployer: DEPLOYER
        });

        routerConfig = RouterConfig({
            deployedAddress: 0x3fa3B62F0c9c13733245A778DE4157E47Cf5bA21,
            wrappedNative: 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            deployer: DEPLOYER,
            owner: DEPLOYER,
            pauser: DEPLOYER,
            defaultCollector: DEPLOYER,
            signer: 0xffFf5a88840FF1f168E163ACD771DFb292164cFA,
            feeRate: 20
        });

        aaveV2FlashLoanCallbackConfig = AaveV2FlashLoanCallbackConfig({
            deployedAddress: 0x27BfAC5fb25C3853C2F48cF0e5B2F89Ea03C0104,
            aaveV2Provider: 0xd05e3E715d945B59290df0ae8eF85c1BdB684744,
            feeRate: 5
        });

        aaveV3FlashLoanCallbackConfig = AaveV3FlashLoanCallbackConfig({
            deployedAddress: 0x6ea614B4C520c8abC9B0F50803Bef964D4DA81EB,
            aaveV3Provider: 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb,
            feeRate: 5
        });

        balancerV2FlashLoanCallbackConfig = BalancerV2FlashLoanCallbackConfig({
            deployedAddress: 0x08b3d2c773C08CF21746Cf16268d2E092881c208,
            balancerV2Vault: 0xBA12222222228d8Ba445958a75a0704d566BF2C8,
            feeRate: 5
        });
    }

    function _run() internal override {
        // create3 factory
        address deployedCreate3FactoryAddress = _deployCreate3Factory();

        // router
        address deployedRouterAddress = _deployRouter(deployedCreate3FactoryAddress);

        // callback
        _deployAaveV2FlashLoanCallback(deployedCreate3FactoryAddress, deployedRouterAddress);
        _deployAaveV3FlashLoanCallback(deployedCreate3FactoryAddress, deployedRouterAddress);
        _deployBalancerV2FlashLoanCallback(deployedCreate3FactoryAddress, deployedRouterAddress);
    }
}
