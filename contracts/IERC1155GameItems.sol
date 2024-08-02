// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155GameItems {
    function gameMintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function gameBurnBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function gameBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function gameSetApproval(
        address owner,
        address operator,
        bool approved
    ) external;

    function isNftLocked(uint256 _id) external view returns (bool);

    function isNftLockedBatch(uint256[] memory _ids) external view returns (bool, bool[] memory);

    function lockedTransferId() external view returns (uint256[] memory);
}