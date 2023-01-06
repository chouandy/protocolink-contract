// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Router, IRouter} from "../src/Router.sol";
import {FlashLoanCallbackBalancerV2, IFlashLoanCallbackBalancerV2} from "../src/FlashLoanCallbackBalancerV2.sol";
import {IBalancerV2Vault} from "../src/interfaces/balancerV2/IBalancerV2Vault.sol";

contract FlashLoanCallbackBalancerV2Test is Test {
    using SafeERC20 for IERC20;

    IBalancerV2Vault public constant balancerV2Vault = IBalancerV2Vault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    address public user;
    IRouter public router;
    IFlashLoanCallbackBalancerV2 public flashLoanCallback;

    // Empty arrays
    address[] tokensOutEmpty;
    uint256[] amountsOutMinEmpty;
    IRouter.Logic[] logicsEmpty;

    function setUp() external {
        user = makeAddr("user");

        router = new Router();
        flashLoanCallback = new FlashLoanCallbackBalancerV2(address(router), address(balancerV2Vault));

        vm.label(address(router), "Router");
        vm.label(address(flashLoanCallback), "FlashLoanCallbackBalancerV2");
        vm.label(address(USDC), "USDC");
    }

    function testExecuteBalancerV2FlashLoan(uint256 amountIn) external {
        vm.assume(amountIn > 1e6);
        IERC20 token = USDC;
        amountIn = bound(amountIn, 1, token.balanceOf(address(balancerV2Vault)));
        vm.label(address(token), "Token");

        address[] memory tokens = new address[](1);
        tokens[0] = address(token);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountIn;

        // Encode logics
        IRouter.Logic[] memory logics = new IRouter.Logic[](1);
        logics[0] = _logicBalancerV2FlashLoan(tokens, amounts);

        // Execute
        vm.prank(user);
        router.execute(tokensOutEmpty, amountsOutMinEmpty, logics);

        assertEq(token.balanceOf(address(router)), 0);
        assertEq(token.balanceOf(address(flashLoanCallback)), 0);
        assertEq(token.balanceOf(address(user)), 0);
    }

    function _logicBalancerV2FlashLoan(address[] memory tokens, uint256[] memory amounts)
        public
        view
        returns (IRouter.Logic memory)
    {
        IRouter.AmountInConfig[] memory configsEmpty = new IRouter.AmountInConfig[](0);

        // Encode logic
        address receiver = address(flashLoanCallback);
        bytes memory userData = _encodeExecuteUserSet(tokens, amounts);

        return IRouter.Logic(
            address(balancerV2Vault), // to
            abi.encodeWithSelector(IBalancerV2Vault.flashLoan.selector, receiver, tokens, amounts, userData),
            configsEmpty,
            address(flashLoanCallback) // entrant
        );
    }

    function _encodeExecuteUserSet(address[] memory tokens, uint256[] memory amounts)
        public
        view
        returns (bytes memory)
    {
        // Encode logics
        IRouter.Logic[] memory logics = new IRouter.Logic[](tokens.length);
        IRouter.AmountInConfig[] memory configsEmpty = new IRouter.AmountInConfig[](0);

        for (uint256 i = 0; i < tokens.length; i++) {
            // Encode transfering token to the flash loan callback
            logics[i] = IRouter.Logic(
                address(tokens[i]), // to
                abi.encodeWithSelector(IERC20.transfer.selector, address(flashLoanCallback), amounts[i]),
                configsEmpty,
                address(0) // entrant
            );
        }

        // Encode executeUserSet data
        return abi.encodeWithSelector(IRouter.executeUserSet.selector, tokensOutEmpty, amountsOutMinEmpty, logics);
    }
}
