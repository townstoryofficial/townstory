// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "./GameOwnerUpgradeable.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

struct AccountInfo {
    uint256 tokenId;
    uint256 passId;
    address owner;
    address holder;
}

contract TownStoryAccountUpgradeable is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable, PausableUpgradeable, GameOwnerUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    
    address private signer;
    string private baseURI;
    bool public userAccountUnique;
    mapping(uint256 => uint256) private gamePass;
    mapping(uint256 => uint256) private passAccountId;
    mapping (uint256 => address) private holders;

    event AccountMinted(address indexed sender, uint256 indexed accountId, address indexed accountHolder);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("TownStory Account", "TSA");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();

        __ERC2981_init();
        __GameOwner_init();

        _tokenIdCounter._value = 1;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setUserAccountUnique(bool _userAccountUnique) public onlyOwner {
        userAccountUnique = _userAccountUnique;
    }

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

    function createAccount(address to) public onlyGame returns (uint256, address) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        AccountHolder holder = new AccountHolder(this, tokenId);
        holders[tokenId] = address(holder);

        emit AccountMinted(to, tokenId, address(holder));

        return (tokenId, holders[tokenId]);
    }

    function createAccountById(address to, uint256 tokenId) public onlyGame returns (uint256, address) {
        _safeMint(to, tokenId);

        AccountHolder holder = new AccountHolder(this, tokenId);
        holders[tokenId] = address(holder);

        emit AccountMinted(to, tokenId, address(holder));

        return (tokenId, holders[tokenId]);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyGame override(ERC721Upgradeable) {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyGame override(ERC721Upgradeable) {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public onlyGame override(ERC721Upgradeable) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    // Game pass
    function bindGamePass(uint256[] memory accountIds, uint256[] memory passIds) public onlyGame {
        for (uint256 i = 0; i < accountIds.length; i++) {
            require(gamePass[accountIds[i]] == 0 && passAccountId[passIds[i]] == 0, "TownStory: Already bound");
            gamePass[accountIds[i]] = passIds[i];
            passAccountId[passIds[i]] = accountIds[i];
        }
    }

    function unbindGamePass(uint256[] memory accountIds) public onlyGame {
        for (uint256 i = 0; i < accountIds.length; i++) {
            uint256 passId = gamePass[accountIds[i]];
            require(passId > 0 && passAccountId[passId] > 0, "TownStory: Not bound"); 
            gamePass[accountIds[i]] = 0;
            passAccountId[passId] = 0;
        }
    }

    function getGamePass(uint256 accountId) public view returns (uint256) {
        return gamePass[accountId];
    }

    function getPassAccountId(uint256 passId) public view returns (uint256) {
        return passAccountId[passId];
    }

    function gameTransfer(address from, address to, uint256 tokenId) public onlyGame returns (bool) {
        _transfer(from, to, tokenId);
        return true;
    }

    function gameApprove(address to, uint256 tokenId) public onlyGame returns (bool) {
        _approve(to, tokenId);
        return true;
    }

    function gameBurn(uint256 tokenId) public onlyGame returns (bool) {
        _burn(tokenId);
        return true;
    }

    function accountInfoById(uint256 _tokenId) public view returns (AccountInfo memory) {
        address gameOwner = ownerOf(_tokenId);
        address holder = holders[_tokenId];
        uint256 _passId = getGamePass(_tokenId);

        return AccountInfo({
            tokenId: _tokenId,
            passId: _passId,
            owner: gameOwner,
            holder: holder
        });
    }

    function accountInfo(address _address) public view returns (AccountInfo memory) {
        uint256 _tokenId = tokenOfOwnerByIndex(_address, 0);
        address gameOwner = ownerOf(_tokenId);
        address holder = holders[_tokenId];
        uint256 _passId = getGamePass(_tokenId);

        return AccountInfo({
            tokenId: _tokenId,
            passId: _passId,
            owner: gameOwner,
            holder: holder
        });
    }

    function accountInfoBatch(address _address) public view returns (AccountInfo[] memory) {
        uint256 balance = balanceOf(_address);

        AccountInfo[] memory accounts = new AccountInfo[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 _tokenId = tokenOfOwnerByIndex(_address, i);
            address gameOwner = ownerOf(_tokenId);
            address holder = holders[_tokenId];
            uint256 _passId = getGamePass(_tokenId);

            AccountInfo memory account = AccountInfo({
                tokenId: _tokenId,
                passId: _passId,
                owner: gameOwner,
                holder: holder
            });

            accounts[i] = account;
        }

        return accounts;
    }

    function setTokenIdCounter(uint256 num) public onlyOwner {
        _tokenIdCounter._value = num;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {   
        if (to != address(0) && userAccountUnique) {
            uint256 balance = balanceOf(to);
            require(balance < 1, "TownStory: The recipient account already exists");
        }

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

contract AccountHolder is ERC165, IERC721Receiver, IERC1155Receiver {
    TownStoryAccountUpgradeable private tsAccount;
    uint256 private tokenId;
    uint256 public version;

    constructor(TownStoryAccountUpgradeable _tsAccount, uint256 _tokenId) {
        tsAccount = _tsAccount;
        tokenId = _tokenId;
        version = 100;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function withdraw() public {
        require(tsAccount.ownerOf(tokenId) == msg.sender, "Permission denied");
        payable(msg.sender).transfer(address(this).balance);
    }
}