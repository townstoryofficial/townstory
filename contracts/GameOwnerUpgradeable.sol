// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract GameOwnerUpgradeable is Initializable, OwnableUpgradeable {
    mapping (address => bool) private gameRoles;
    uint256 public gameRolesCount;

    modifier onlyGame {
        require(gameRoles[_msgSender()], "TownStory: Permission denied");
        _;
    }

    function __GameOwner_init() internal onlyInitializing {
    }

    function __GameOwner_init_unchained() internal onlyInitializing {  
    }

    function _isGameOwner(address _addr) internal view returns(bool) {
        return gameRoles[_addr];
    }

    function _addGameOwner(address _addr) internal {
        require(!_isGameOwner(_addr), "TownStory: Owner already exists");
        gameRolesCount++;
        gameRoles[_addr] = true;
    }

    function _removeGameOwner(address _addr) internal {
        require(_isGameOwner(_addr), "TownStory: Owner does not exist");
        gameRolesCount--;
        gameRoles[_addr] = false;
    }

    function addGameOwnerBatch(address[] memory _addrs) public onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            _addGameOwner(_addrs[i]);
        }
    }

    function removeGameOwnerBatch(address[] memory _addrs) public onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            _removeGameOwner(_addrs[i]);
        }
    }

    function isGameOwner(address addr) public view returns(bool) {
        return _isGameOwner(addr);
    }

    uint256[48] private __gap;
}