// Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libs/MerkleProof.sol";


contract MintPassNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Strings for string;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURIExtended;

    mapping(address => bool) private _mintedList;
    bytes32 public _rootHash;
    bool public _isActive = true;

    constructor(bytes32 rootHash) ERC721("MoonFit Mint Pass", "MFMP") {
        _rootHash = rootHash;
    }

    function mintNFT(bytes32[] calldata _path) external returns (uint256){
        require(_isActive, 'Mint Pass: Mint round is not active');
        // Merkle Proof Verify
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_path, _rootHash, hash), "Mint Pass: You is not in whitelist");
        require(_mintedList[msg.sender] != true, "Mint Pass: You already minted a mint pass before");

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        //        _setTokenURI(newItemId, _tokenURI_);
        _mintedList[msg.sender] = true;

        return newItemId;
    }

    function burnNFT(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIExtended = baseURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If item does not have tokenURI and contract has base URI, concatenate the tokenID to the baseURI.
        if (bytes(base).length > 0 && bytes(_tokenURI).length == 0) {
            return string(abi.encodePacked(base, tokenId.toString(), ".json"));
        }
        // Other cases, return tokenURI
        return _tokenURI;
    }

    function latestTokenId() public view returns (uint256) {
        return _tokenIds.current();
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner returns (uint256) {
        _setTokenURI(tokenId, _tokenURI);
        return tokenId;
    }

    //    function withdrawNFT(uint256 tokenId, string memory _tokenURI, address receiver) external onlyOwner returns (uint256) {
    //        _setTokenURI(tokenId, _tokenURI);
    //        safeTransferFrom(_msgSender(), receiver, tokenId);
    //        return tokenId;
    //    }

    // Others functions

    function setMerkleRoot(bytes32 rootHash) external onlyOwner {
        require(rootHash != bytes32(0), "Private Sale: Root hash is the zero bytes32");
        _rootHash = rootHash;
    }

    function setIsActive(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

}
