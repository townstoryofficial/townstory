// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "./GameOwnerUpgradeable.sol";

contract TownStoryBackpackUpgradeable is Initializable, ERC1155Upgradeable, ERC2981Upgradeable, GameOwnerUpgradeable, PausableUpgradeable, ERC1155SupplyUpgradeable {
    mapping(address => mapping(uint256 => uint256)) private tokenIdEnumerate;
    mapping(address => uint256) private tokenIdCount;
    mapping(uint256 => uint256) private _maxSupply;

    bool private _allPausedEnumerate;
    bool private _fromPausedEnumerate;

    uint256[] private _transferLockedId;
    address public notLockedOperator;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC1155_init("https://townstory.io/nft/backpack/{id}.json");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Supply_init();

        __GameOwner_init();
        __ERC2981_init();
        _setDefaultRoyalty(_msgSender(), 500);
    }

    function gameMintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyGame {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 getMaxSupply = maxSupply(ids[i]);
            if (getMaxSupply > 0) {
                require(totalSupply(ids[i]) + amounts[i] <= getMaxSupply, "TownStory: Minting would exceed max supply");
            }
        }
        _mintBatch(to, ids, amounts, data);
    }

    function gameBurnBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyGame {
        _burnBatch(to, ids, amounts);
    }

    function gameBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyGame {
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function gameSetApproval(
        address owner,
        address operator,
        bool approved
    ) public onlyGame {
        _setApprovalForAll(owner, operator, approved);
    }

    // Lock
    function isNftLocked(uint256 _id) public view returns (bool) {
        bool _isLocked = false;
        for (uint256 i = 0; i < _transferLockedId.length; ++i) {
            if (_id == _transferLockedId[i]) {
                _isLocked = true;
            }
        }
        return _isLocked;
    }

    function isNftLockedBatch(uint256[] memory _ids) public view returns (bool, bool[] memory) {
        bool _isLocked = false;
        bool[] memory batchIsLocked = new bool[](_ids.length);

        for (uint256 i = 0; i < _ids.length; i++) {
            batchIsLocked[i] = isNftLocked(_ids[i]);
            if (batchIsLocked[i]) {
                _isLocked = true;
            }
        }

        return (_isLocked, batchIsLocked);
    }

    function lockedTransferId() public view returns (uint256[] memory) {
        uint length = _transferLockedId.length;

        uint256[] memory ids = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            ids[i] = _transferLockedId[i];
        }
        return ids;
    }

    function setLockedTransferId(uint256[] memory _ids) public onlyOwner {
        _transferLockedId = _ids;
    }

    function setNotLockedOperator(address _notLockedOperator) public onlyOwner {
        notLockedOperator = _notLockedOperator;
    }

    // Owner
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setAllPausedEnumerate(bool _toPaused) public onlyOwner {
        _allPausedEnumerate = _toPaused;
    }

    function setFromPausedEnumerate(bool _fromPaused) public onlyOwner {
        _fromPausedEnumerate = _fromPaused;
    }

    // MaxSupply
    function _setMaxSupply(uint256 _id, uint256 _amount) internal {
        _maxSupply[_id] = _amount;
    }

    function setMaxSupplyBatch(uint256[] memory ids, uint256[] memory amounts) public onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            _setMaxSupply(ids[i], amounts[i]);
        }
    }

    function maxSupply(uint256 id) public view returns (uint256) {
        return _maxSupply[id];
    }

    // Royalty
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) public onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function resetTokenRoyalty(uint256 _tokenId) public onlyOwner {
        _resetTokenRoyalty(_tokenId);
    }

    // Supply
    function totalSupplyBatch(uint256[] memory ids) public view returns (uint256[] memory) {
        uint256[] memory batchSupply = new uint256[](ids.length);

        for (uint256 i = 0; i < ids.length; ++i) {
            batchSupply[i] = totalSupply(ids[i]);
        }

        return batchSupply;
    }

    // Enumerate
    function enumeratePausedStatus() public view returns (bool, bool) {
        return (_allPausedEnumerate, _fromPausedEnumerate);
    }

    function getTokenIdCount(address addr) public view returns (uint256) {
        return tokenIdCount[addr];
    }
    
    function getEnumerateTokenId(address addr) public view returns (uint256[] memory) {
        uint256 idCount = tokenIdCount[addr];
        uint256[] memory arr = new uint256[](idCount);
        
        for (uint256 i = 0; i < idCount; ++i) {
            arr[i] = tokenIdEnumerate[addr][i];
        }
        return arr;
    }

    function getEnumerateBalance(address addr) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory ids = getEnumerateTokenId(addr);
        address[] memory addressEnumerate = new address[](ids.length);
        for (uint i = 0; i < ids.length; ++i) {
            addressEnumerate[i] = addr;
        }

        uint256[] memory gameBalance = balanceOfBatch(addressEnumerate, ids);
        return (ids, gameBalance);
    }

    function _addTokenIdEnumeration(address _to, uint256[] memory _ids) private {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256[] memory toIdEnumerate = getEnumerateTokenId(_to);

            bool idExist = false;
            for (uint256 i2 = 0; i2 < toIdEnumerate.length; i2++) {
                if (toIdEnumerate[i2] == _ids[i]) {
                    idExist = true;
                }
            }

            if (!idExist) {
                uint256 length = tokenIdCount[_to];
                tokenIdEnumerate[_to][length] = _ids[i];
                tokenIdCount[_to] += 1;
            }
        }
    }

    function _removeTokenIdEnumeration(address _from, uint256[] memory _ids, uint256[] memory _amounts) private {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 fromBalance = balanceOf(_from, _ids[i]);
            // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
            // then delete the last slot (swap and pop).
            if (_amounts[i] == fromBalance) {
                uint256 lastIndex = tokenIdCount[_from] - 1;
                uint256 lastIndexId = tokenIdEnumerate[_from][lastIndex];

                if (_ids[i] != lastIndexId) {
                    uint256[] memory fromIdEnumerate = getEnumerateTokenId(_from);
                    for(uint256 i3 = 0; i3 < fromIdEnumerate.length; i3++) {
                        if (_ids[i] == fromIdEnumerate[i3]) {
                            tokenIdEnumerate[_from][i3] = lastIndexId;
                        }
                    }
                }

                tokenIdCount[_from] -= 1;
                delete tokenIdEnumerate[_from][lastIndex];
            }
        }
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {   
        // Lock
        if (from != address(0) && to != address(0) && notLockedOperator != operator) {
            (bool isLocked, ) = isNftLockedBatch(ids);
            require(!isLocked, "TownStory: Transfer locked");
        }

        if (!_allPausedEnumerate && to != address(0) && from != to) {
            _addTokenIdEnumeration(to, ids);
        }
        
        if (!_allPausedEnumerate && !_fromPausedEnumerate && from != address(0) && to != from) {
            _removeTokenIdEnumeration(from, ids, amounts);
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}