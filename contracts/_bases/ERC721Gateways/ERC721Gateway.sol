// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./AdminControl.sol";

interface IERC721Gateway {
    function token() external view returns (address);

    function SwapOut(
        uint256 tokenId,
        address receiver,
        uint256 toChainID
    ) external payable returns (uint256 swapOutSeq);
}

abstract contract ERC721Gateway is IERC721Gateway, AdminControl {
    address private _initiator;
    bool public initialized = false;
    mapping(address => uint256[]) public _swapInLocked;

    event LogSwapOut(
        uint256 tokenId,
        address sender,
        address receiver,
        uint256 toChainID,
        uint256 swapOutSeq
    );

    constructor() {
        _initiator = msg.sender;
    }

    address public token;
    uint256 public swapOutFee;
    uint256 public swapOutSeq;

    function initERC721Gateway(address token_, address admin) public {
        require(_initiator == msg.sender && !initialized, "_initiator != msg.sender && initialized == false");
        initAdminControl(admin);
        initialized = true;
        token = token_;
    }

    function _checkSwapInBySwapOutSeq(address fromContract, uint256 _swapOutSeq) internal virtual returns (bool){
        for (uint256 i=0; i < _swapInLocked[fromContract].length; i++) {
            if (_swapOutSeq == _swapInLocked[fromContract][i]) {
                return true;
            }
        }

        return false;
    }

    function _swapOut(
        uint256 tokenId
    ) internal virtual returns (bool) {
        require(msg.value >= swapOutFee, "Fee insufficient");

        return true;
    }

    function _swapIn(
        uint256 tokenId,
        address receiver,
        bytes memory extraMsg
    ) internal virtual returns (bool) {
        (bytes32 txhash, address from, uint256 fromChainID, uint256 _swapOutSeq, address fromContract, ) = abi.decode(extraMsg, (bytes32, address, uint256, uint256, address, string));
        require(txhash != bytes32(0), "TxHash is empty");
        require(from != address(0), "Address is empty");
        require(fromContract != address(0), "Address is empty");
        require(fromChainID != 0, "ChainId is invalid");
        require(_swapOutSeq > 0, "SwapOutSeq is invalid");
        require(_checkSwapInBySwapOutSeq(fromContract, _swapOutSeq) == false, "Swapped in in another transaction");

        _swapInLocked[fromContract].push(_swapOutSeq);

        return true;
    }

    function MoonFitSwapIn(
        uint256 tokenId,
        address receiver,
        bytes memory extraMsg
    ) payable external ownerOrApproved returns (bool) {
        return _swapIn(tokenId, receiver, extraMsg);
    }

    function MoonFitSwapOut(
        uint256 tokenId,
        address receiver,
        uint256 destChainID
    ) external payable returns (uint256) {
        bool ok = _swapOut(tokenId);
        require(ok, "Swap out failed");

        swapOutSeq++;
        emit LogSwapOut(
            tokenId,
            msg.sender,
            receiver,
            destChainID,
            swapOutSeq
        );

        return swapOutSeq;
    }
}
