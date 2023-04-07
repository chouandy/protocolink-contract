// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FeeBase} from './FeeBase.sol';
import {IFeeCalculator} from '../interfaces/IFeeCalculator.sol';

/// @notice Fee calculator for ERC20::transferFrom action. This will also cause ERC721::transferFrom being executed and fail in transaction.
contract TransferFromFeeCalculator is IFeeCalculator, FeeBase {
    bytes32 private constant _META_DATA = bytes32(bytes('erc20:transfer-from'));

    constructor(address router, uint256 feeRate) FeeBase(router, feeRate) {}

    function getFees(
        address to,
        bytes calldata data
    ) external view returns (address[] memory, uint256[] memory, bytes32) {
        // Token transfrom signature:'transferFrom(address,address,uint256)', selector:0x23b872dd
        (, , uint256 amount) = abi.decode(data[4:], (address, address, uint256));

        address[] memory tokens = new address[](1);
        tokens[0] = to;

        uint256[] memory fees = new uint256[](1);
        fees[0] = calculateFee(amount);
        return (tokens, fees, _META_DATA);
    }

    function getDataWithFee(bytes calldata data) external view returns (bytes memory) {
        (address from, address to, uint256 amount) = abi.decode(data[4:], (address, address, uint256));
        amount = calculateAmountWithFee(amount);
        return abi.encodePacked(data[:4], abi.encode(from, to, amount));
    }
}
