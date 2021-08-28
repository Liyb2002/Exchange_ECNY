// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import './interfaces/ERC20.sol';

contract mock_token is ERC20 {

    string public constant name = "mock_token";
    uint8 public constant decimals = 18;
    string public constant symbol = "mock_token";
    uint public constant supply = 1 * 10**8 * 10**uint(decimals); // 100 million

    /**
     * @dev ERC20 token to mock mock_token, send all balance to the deployer
     */
    constructor() public {
        _balances[msg.sender] = supply;
        _totalSupply = supply;
    }
    
}