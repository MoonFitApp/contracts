pragma solidity ^0.8.10;

abstract contract AdminControl {
    address public admin;
    address[] public _approvedAddress;
    mapping(address => bool) public _approvedOperators;

    event ChangeAdmin(address indexed _old, address indexed _new);
    event ApplyAdmin(address indexed _old, address indexed _new);

    function initAdminControl(address _admin) internal {
        require(_admin != address(0), "AdminControl: address(0)");
        admin = _admin;
        emit ChangeAdmin(address(0), _admin);
    }

    function withdrawTokenByOwner(uint256 amount) external onlyAdmin {
        require(address(this).balance > 0, "Contract balance is 0");
        require(address(this).balance >= amount, "Contract balance is insufficient");

        payable(admin).transfer(amount);
    }

    modifier onlyAdmin() {
        require(_msgSender() == admin, "AdminControl: not admin");
        _;
    }

    function changeAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "AdminControl: address(0)");
        admin = _admin;
        emit ChangeAdmin(admin, _admin);
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    // -------------- Approved --------------
    function setApprovedOperator(address operator, bool isApproved) external onlyAdmin {
        _setApprovedOperator(operator, isApproved);
    }

    function setApprovedOperators(address[] memory operators, bool isApproved) external onlyAdmin {
        for (uint256 i = 0; i < operators.length; i++) {
            _setApprovedOperator(operators[i], isApproved);
        }
    }

    function revokeAllApproved() external onlyAdmin {
        for (uint256 i = 0; i < _approvedAddress.length; i++) {
            _approvedOperators[_approvedAddress[i]] = false;
        }

        _approvedAddress = new address[](0);
    }

    function _setApprovedOperator(address operator, bool isApproved) internal virtual {
        require(operator != address(0), "Theo operator is the zero address");
        require(operator != address(this), "The operator is this contract address");
        require(operator != admin, "The operator is the admin's address");
        require(operator != _msgSender(), "The operator is the owner's address");
        _approvedOperators[operator] = isApproved;

        if (isApproved) {
            _approvedAddress.push(operator);
        }
    }

    modifier ownerOrApproved() {
        require(
            _adminOrApproved() == true,
            "Ownable: caller is not the admin or is approved"
        );
        _;
    }

    function _adminOrApproved() internal virtual returns (bool) {
        return _msgSender() == admin || _approvedOperators[_msgSender()] == true;
    }
}
