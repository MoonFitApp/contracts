// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//
interface IMoonFitERC721 is IERC721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function mintNFT(address recipient, string memory _tokenURI_) external returns (uint256);

    function mintNFT(address recipient) external returns (uint256);
}

contract MasterContract is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, UUPSUpgradeable, IERC721Receiver {
    address payable private _wallet;
    mapping(address => bool) private _approvedOperators;
    address[] private _approvedAddress;
    bool private _isMaintenance;
    bool private _isDepositMaintenance;

    event NewDepositERC721(address contractId, address owner, uint256 tokenId, string transactionKey, uint blockTime);
    event NewDepositERC20(address contractId, address owner, uint256 value, string transactionKey, uint blockTime);
    event NewDepositBaseToken(address owner, uint256 value, string transactionKey, uint blockTime);

    event NewWithdrawERC721(address contractId, address owner, uint256 tokenId, string transactionKey, uint blockTime);
    event NewWithdrawERC20(address contractId, address owner, uint256 value, string transactionKey, uint blockTime);
    event NewWithdrawBaseToken(address owner, uint256 value, string transactionKey, uint blockTime);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address wallet) initializer public {
        require(wallet != address(0), "wallet is the zero address");
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _wallet = payable(wallet);
        _isMaintenance = false;
    }

    // Deposits
    function depositERC721(address contractId, uint256 tokenId, string memory transactionKey) public nonReentrant payable {
        _validateDeposit();
        _validateERC721Address(contractId);

        _depositERC721(_msgSender(), contractId, tokenId, transactionKey);
    }

    function depositMultipleERC721(address contractId, uint256[] memory tokenIds, string[] memory transactionKeys) public nonReentrant payable {
        _validateDeposit();
        _validateERC721Address(contractId);
        require(tokenIds.length == transactionKeys.length, "Parameters is invalid");
        address owner = _msgSender();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _depositERC721(owner, contractId, tokenIds[i], transactionKeys[i]);
        }
    }

    function _depositERC721(address owner, address contractId, uint256 tokenId, string memory transactionKey) internal virtual {
        IMoonFitERC721 moonFitNFT = IMoonFitERC721(contractId);
        _validateTransactionKey(transactionKey);
        require(moonFitNFT.ownerOf(tokenId) == owner, "Caller is not token owner");

        moonFitNFT.transferFrom(owner, address(this), tokenId);
        emit NewDepositERC721(contractId, owner, tokenId, transactionKey, block.timestamp);
    }

    function depositERC20(address contractId, uint256 amount, string memory transactionKey) public nonReentrant payable {
        _validateDeposit();
        _validateERC20Address(contractId);
        _validateTransactionKey(transactionKey);
        IERC20 moonFitToken = IERC20(contractId);

        address owner = _msgSender();
        uint256 allowance = moonFitToken.allowance(owner, address(this));
        require(allowance >= amount, "ERC20: insufficient allowance");
        require(moonFitToken.balanceOf(owner) >= amount, "ERC20: transfer amount exceeds balance");

        moonFitToken.transferFrom(owner, address(this), amount);

        emit NewDepositERC20(contractId, owner, amount, transactionKey, block.timestamp);
    }

    function depositBaseToken(uint amount, string memory transactionKey) public nonReentrant payable {
        _validateDeposit();
        require(amount == msg.value, "Amount is invalid");
        _validateTransactionKey(transactionKey);

        emit NewDepositBaseToken(msg.sender, amount, transactionKey, block.timestamp);
    }

    //-------------- Withdrawal --------------
    function withdrawERC721(address contractId, address toAddress, uint256 tokenId, string memory transactionKey) external nonReentrant ownerOrApproved {
        _withdrawERC721(contractId, toAddress, tokenId, transactionKey);
    }

    function withdrawERC20(address contractId, address toAddress, uint256 amount, string memory transactionKey) external nonReentrant ownerOrApproved {
        _withdrawERC20(contractId, toAddress, amount, transactionKey);
    }

    function withdrawBaseToken(address toAddress, uint amount, string memory transactionKey) external nonReentrant ownerOrApproved {
        _withdrawBaseToken(toAddress, amount, transactionKey);
    }

    function withdrawMultipleERC721(address contractId, address[] memory toAddress, uint256[] memory tokenIds, string[] memory transactionKeys) external nonReentrant ownerOrApproved {
        require(toAddress.length == tokenIds.length && toAddress.length == transactionKeys.length, "Parameters is invalid");

        for (uint256 index = 0; index < toAddress.length; index++) {
            _withdrawERC721(contractId, toAddress[index], tokenIds[index], transactionKeys[index]);
        }
    }

    function withdrawMultipleERC20(address contractId, address[] memory toAddress, uint256[] memory amounts, string[] memory transactionKeys) external nonReentrant ownerOrApproved {
        require(toAddress.length == amounts.length && toAddress.length == transactionKeys.length, "Parameters is invalid");

        for (uint256 index = 0; index < toAddress.length; index++) {
            _withdrawERC20(contractId, toAddress[index], amounts[index], transactionKeys[index]);
        }
    }

    function withdrawMultipleBaseToken(address[] memory toAddress, uint256[] memory amounts, string[] memory transactionKeys) external nonReentrant ownerOrApproved {
        require(toAddress.length == amounts.length && toAddress.length == transactionKeys.length, "Parameters is invalid");

        for (uint256 index = 0; index < toAddress.length; index++) {
            _withdrawBaseToken(toAddress[index], amounts[index], transactionKeys[index]);
        }
    }

    function _withdrawERC721(address contractId, address toAddress, uint256 tokenId, string memory transactionKey) internal virtual {
        _validateContractMaintainer();
        _validateERC721Address(contractId);
        _validateTransactionKey(transactionKey);
        IMoonFitERC721 moonFitNFT = IMoonFitERC721(contractId);
        require(moonFitNFT.ownerOf(tokenId) == address(this), "Contract is not token owner");

        moonFitNFT.transferFrom(address(this), toAddress, tokenId);
        emit NewWithdrawERC721(contractId, toAddress, tokenId, transactionKey, block.timestamp);
    }

    function _withdrawERC20(address contractId, address toAddress, uint256 amount, string memory transactionKey) internal virtual {
        _validateContractMaintainer();
        _validateERC20Address(contractId);
        IERC20 moonFitNFT = IERC20(contractId);
        require(moonFitNFT.balanceOf(address(this)) >= amount, "Insufficient token");
        require(amount > 0, "Amount is zero");

        moonFitNFT.transfer(toAddress, amount);
        emit NewWithdrawERC20(contractId, toAddress, amount, transactionKey, block.timestamp);
    }

    function _withdrawBaseToken(address toAddress, uint amount, string memory transactionKey) internal virtual {
        _validateContractMaintainer();
        require(getContractBalance() >= amount, "Insufficient token");
        require(amount > 0, "Amount is zero");
        payable(toAddress).transfer(amount);

        emit NewWithdrawBaseToken(toAddress, amount, transactionKey, block.timestamp);
    }

    //-------------- Mint --------------
    function mintMultipleERC721(address contractId, address[] memory toAddress, string[] memory transactionKeys, string[] memory tokenUris) external nonReentrant ownerOrApproved {
        _validateContractMaintainer();
        _validateERC721Address(contractId);
        IMoonFitERC721 moonFitNFT = IMoonFitERC721(contractId);

        for (uint256 i = 0; i < toAddress.length; i++) {
            _mintERC721(moonFitNFT, toAddress[i], transactionKeys[i], tokenUris[i]);
        }
    }

    function _mintERC721(IMoonFitERC721 moonFitNFT, address toAddress, string memory transactionKey, string memory tokenUri) internal virtual {
        _validateContractMaintainer();
        _validateTransactionKey(transactionKey);
        uint256 tokenId;

        if (_stringLength(tokenUri) == 0) {
            tokenId = moonFitNFT.mintNFT(toAddress);
        } else {
            tokenId = moonFitNFT.mintNFT(toAddress, tokenUri);
        }

        emit NewWithdrawERC721(address(moonFitNFT), toAddress, tokenId, transactionKey, block.timestamp);
    }

    //-------------- Validate --------------
    function _validateERC721Address(address contractId) internal pure {
        _validateContract(contractId);
    }

    function _validateERC20Address(address contractId) internal pure {
        _validateContract(contractId);
    }

    function _validateContract(address contractId) private pure {
        require(contractId != address(0), "Contract address is the zero address");
    }

    function _validateTransactionKey(string memory transactionKey) private pure {
        require(_stringLength(transactionKey) != 0, "Transaction key is required");
    }

    function _validateContractMaintainer() private view {
        require(_isMaintenance == false, "Contract under maintenance");
    }

    function _validateDeposit() private view {
        _validateContractMaintainer();
        require(_isDepositMaintenance == false, "Contract under maintenance");
    }

    // -------------- Helper --------------

    function _stringLength(string memory text) private pure returns (uint256) {
        bytes memory strBytes = bytes(text);

        return strBytes.length;
    }

    function getTokenIdsERC721(address contractId, address owner, uint256 fromIndex, uint256 toIndex) public view returns (uint256[] memory) {
        _validateERC721Address(contractId);
        IMoonFitERC721 moonFitNFT = IMoonFitERC721(contractId);
        uint256 balance = moonFitNFT.balanceOf(owner);

        if (balance == 0) {
            return new uint256[](0);
        }

        if (toIndex >= balance) {
            toIndex = balance - 1;
        }


        uint256 length = toIndex - fromIndex + 1;
        uint256[] memory data = new uint256[](length);
        uint256 tmpIndex;

        for (uint256 index = fromIndex; index <= toIndex; index++) {
            data[tmpIndex] = moonFitNFT.tokenOfOwnerByIndex(owner, index);
            tmpIndex++;
        }

        return data;
    }

    // -------------- Withdraw by owner --------------
    function withdrawTokenByOwner() external ownerOrApproved {
        require(address(this).balance > 0, "Contract balance is 0 GLMR");
        payable(_wallet).transfer(address(this).balance);
    }

    //-------------- Maintenance --------------
    function setContractMaintenance(bool status) external onlyOwner {
        _isMaintenance = status;
    }

    function setDepositMaintenance(bool status) external onlyOwner {
        _isDepositMaintenance = status;
    }

    // -------------- Approved --------------
    function setApprovedOperator(address operator, bool isApproved) external onlyOwner {
        _setApprovedOperator(operator, isApproved);
    }

    function setApprovedOperators(address[] memory operators, bool isApproved) external onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            _setApprovedOperator(operators[i], isApproved);
        }
    }

    function revokeAllApproved() external onlyOwner {
        for (uint256 i = 0; i < _approvedAddress.length; i++) {
            _approvedOperators[_approvedAddress[i]]  = false;
        }

        _approvedAddress = new address[](0);
    }

    function _setApprovedOperator(address operator, bool isApproved) internal virtual {
        require(operator != address(0), "Theo operator is the zero address");
        require(operator != address(this), "The operator is this contract address");
        require(operator != _wallet, "The operator is the owner's address");
        require(operator != _msgSender(), "The operator is the owner's address");
        _approvedOperators[operator] = isApproved;

        if (isApproved) {
            _approvedAddress.push(operator);
        }
    }

    modifier ownerOrApproved() {
        require(
            owner() == _msgSender() || _approvedOperators[_msgSender()] == true,
            "Ownable: caller is not the owner or is approved"
        );
        _;
    }

    //-------------- Balance --------------
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //-------------- Other --------------
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}
}
