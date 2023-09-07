// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../_bases/ERC721Gateways/ERC721Gateway.sol";

interface IERC721_MintBurn {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(address account, uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}

contract ERC721Gateway_MintBurn is ERC721Gateway {
    function _swapOut(uint256 tokenId)
        internal
        virtual
        override
        returns (bool)
    {
        require(IERC721_MintBurn(token).ownerOf(tokenId) == msg.sender, "not allowed");
        super._swapOut(tokenId);
        IERC721_MintBurn(token).burn(tokenId);

        return true;
    }

    function _swapIn(
        uint256 tokenId,
        address receiver,
        bytes memory extraData
    ) internal override returns (bool) {
        super._swapIn(tokenId, receiver, extraData);
        IERC721_MintBurn(token).mint(receiver, tokenId);

        return true;
    }
}
