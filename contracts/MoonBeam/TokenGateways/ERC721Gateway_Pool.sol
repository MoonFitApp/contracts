// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../_bases/ERC721Gateways/ERC721Gateway.sol";

interface IERC721_SafeTransfer {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract ERC721Gateway_Pool is ERC721Gateway {
    function _swapOut(uint256 tokenId)
        internal
        virtual
        override
        returns (bool)
    {
        super._swapOut(tokenId);
        IERC721_SafeTransfer(token).safeTransferFrom(msg.sender, address(this), tokenId);

        return true;
    }

    function _swapIn(
        uint256 tokenId,
        address receiver,
        bytes memory extraData
    ) internal override returns (bool) {
        super._swapIn(tokenId, receiver, extraData);
        IERC721_SafeTransfer(token).safeTransferFrom(address(this), receiver, tokenId);

        return true;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
