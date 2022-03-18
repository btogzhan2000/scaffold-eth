pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract YourContract is ERC721,ERC721Enumerable, ERC721URIStorage, Ownable {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  uint256 public price;
  uint256 constant startingAt = 0.01 ether;

  mapping (bytes32 => bool) public forSale;
  mapping (bytes32 => bool) public forSecondarySale;
  mapping (bytes32 => uint256) public uriToTokenId;

  constructor(bytes32[] memory assetsForSale) public ERC721("YourContract", "YC") {
    for(uint256 i=0;i<assetsForSale.length;i++){
      forSale[assetsForSale[i]] = true;
      forSecondarySale[assetsForSale[i]] = false;
    }
    price = startingAt;
  }

  function _baseURI() internal pure override returns (string memory) {
    return "https://ipfs.io/ipfs/";
  }

  function mintItem(string memory tokenURI) public payable returns (uint256) {
    bytes32 uriHash = keccak256(abi.encodePacked(tokenURI));

    require(forSale[uriHash], "error");
    forSale[uriHash]=false;

    _tokenIds.increment();

    uint256 id = _tokenIds.current();
    _mint(msg.sender, id);
    _setTokenURI(id, tokenURI);

    uriToTokenId[uriHash] = id;
    return id;
  }

  function sellItem(string memory tokenURI) public returns (uint256) {
    bytes32 uriHash = keccak256(abi.encodePacked(tokenURI));

    require(!forSecondarySale[uriHash], "error");
    forSecondarySale[uriHash]=true;

    uint256 id = uriToTokenId[uriHash];

    emit Action(msg.sender, id, "sell item");

    return id;
  }

  function cancelSellItem(string memory tokenURI) public returns (uint256) {
    bytes32 uriHash = keccak256(abi.encodePacked(tokenURI));

    require(forSecondarySale[uriHash],"error");
    forSecondarySale[uriHash]=false;

    uint256 id = uriToTokenId[uriHash];

    emit Action(msg.sender, id, "cancel sell item");

    return id;
  }

  function buyItem(string memory tokenURI) public payable returns (uint256) {
    bytes32 uriHash = keccak256(abi.encodePacked(tokenURI));

    require(forSecondarySale[uriHash], "error");
    forSecondarySale[uriHash]=false;

    uint256 id = uriToTokenId[uriHash];
    address payable itemOwner = payable(ownerOf(id));

    _transfer(itemOwner, msg.sender, id);
    itemOwner.transfer(price);

    return id;
  }
  
  event Action(address sender, uint256 tokenId, string action);

// required default override functions (not my own code)
  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId)
      internal
      override(ERC721, ERC721URIStorage)
  {
      super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
      public
      view
      override(ERC721, ERC721URIStorage)
      returns (string memory)
  {
      return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }
}


