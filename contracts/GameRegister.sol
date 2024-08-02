// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./AccountUpgradeable.sol";

contract TownStoryGameRegister is AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    address private signer;
    address private _owner;
    TownStoryAccountUpgradeable tsAccount;
    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");

    uint256 public mintPrice;
    mapping(address => bool) private created;
    mapping(bytes32 => bool) public executed;

    event CreateAccountMinted(address indexed sender, uint256 indexed accountId, address indexed accountHolder);

    constructor(TownStoryAccountUpgradeable _account, address _signer, address _minter) {
        tsAccount = _account;
        signer = _signer;
        _owner = msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SERVER_ROLE, _minter);
    }

    modifier _notContract() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "Contract is not allowed");
        require(msg.sender == tx.origin, "Proxy contract is not allowed");
        _;
    }

    function createAccount(uint256 limit) external nonReentrant _notContract onlyRole(DEFAULT_ADMIN_ROLE) payable {
        address user = _msgSender();

        uint256 balance = tsAccount.balanceOf(user);
        require(balance < limit, "TownStory: The recipient account already exists");

        require(
            mintPrice <= msg.value,
            "TownStory: Not enough value sent"
        );

        (uint256 tokenId, address holder) = tsAccount.createAccount(user);

        emit CreateAccountMinted(user, tokenId, holder);
    }

    function gameCreateAccount(address user, uint256 limit) external onlyRole(SERVER_ROLE) {
        uint256 balance = tsAccount.balanceOf(user);
        require(balance < limit, "TownStory: The recipient account already exists");

        (uint256 tokenId, address holder) = tsAccount.createAccount(user);
        emit CreateAccountMinted(user, tokenId, holder);
    }

    function createAccountSign(
        bytes memory signature,
        uint256 passId,
        uint deadline
    ) external nonReentrant _notContract payable {
        require(deadline >= block.timestamp, "TownStory: Deadline Passed");

        address user = _msgSender();
        bytes32 txHash = keccak256(abi.encode(_msgSender(), passId, deadline));

        require(!executed[txHash], "TownStory: Tx Executed");
        require(verify(txHash, signature), "TownStory: Unauthorised");
        executed[txHash] = true;

        require(
            msg.value >= mintPrice,
            "TownStory: Not enough value sent"
        );

        (uint256 tokenId, address holder) = tsAccount.createAccount(user);

        AccountInfo memory accountInfo = tsAccount.accountInfoById(tokenId);
        require(accountInfo.owner == _msgSender(), "TownStory: You do not own this account");

        if (passId > 0) {
            uint256[] memory accountIds = new uint256[](1);
            accountIds[0] = tokenId;

            uint256[] memory passIds = new uint256[](1);
            passIds[0] = passId;

            tsAccount.bindGamePass(accountIds, passIds);
        }

        emit CreateAccountMinted(user, tokenId, holder);
    }


    function syncSignatureMint(
        uint256 deadline,
        uint256[][] memory mintIds,
        uint256[][] memory mintAmounts,
        int256 tokens
    ) private view returns(bytes32) {
        return keccak256(abi.encode(tokens, mintIds, mintAmounts, _msgSender(), deadline));
    }

    function verify(bytes32 hash, bytes memory signature) private view returns (bool) {
        bytes32 ethSignedHash = hash.toEthSignedMessageHash();
        return ethSignedHash.recover(signature) == signer;
    }

    // Setting
    function setMintPrice(uint256 _price) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPrice = _price;
    }

    function transferSigner(address _signer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = _signer;
    }

    function destroy() public onlyRole(DEFAULT_ADMIN_ROLE) payable {
        address payable owner = payable(address(_owner));
        selfdestruct(owner);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}