// SPDX-License-Identifier: MIT


pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CFT is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    constructor() {
        _disableInitializers(); // Prevent the implementation contract from being initialized
    }

    function initialize() public initializer {
        __ERC20_init("Crestfi Token", "CFT");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        _mint(msg.sender, 1000000000 ether); // Mint initial supply to the deployer
    }

    // Override _authorizeUpgrade for upgrade authorization
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
