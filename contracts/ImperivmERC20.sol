// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ImperivmERC20 is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
    constructor(address initialOwner)
        ERC20("Imperivm", "IMP")
        Ownable(initialOwner)
    {
         address[5] memory rotacionCAR = [
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
            0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
            0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
            0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,
            0x617F2E2fD72FD9D5503197092aC168c91465E7f2
        ];

        for (uint i = 0; i < rotacionCAR.length; i++) {
            _mint(rotacionCAR[i], 150 * (10 ** uint256(decimals())));
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}