pragma solidity ^0.4.23;

import "./ERC721BasicToken.sol";


contract contractOwner {
    address public contractOwner;

    constructor() public {
        contractOwner = msg.sender;
    }

    modifier onlyContractOwner {
        require(msg.sender == contractOwner);
        _;
    }

    function transferOwnership(address newOwner) onlyContractOwner public {
        contractOwner = newOwner;
    }
}

interface erc20TokenAdapter{
    function erc721TokenContractTransfer(address _from, address _to, uint _value) external;
}

contract CryptoBarons is ERC721BasicToken, contractOwner{
    
    struct BaronAsset{
        uint256 assetId;
        uint dateCreatedUnix;
    }
    
    struct TokenOrder{
        uint256 priceInBaronCoin;
        address owner;
    }
    
    address public erc20TokenContractAddress;

    uint256 constant private MAX_UINT256 = 2**256 - 1;

    BaronAsset[] public baronAssets;
    mapping (uint256 => TokenOrder) public tokenTransferOrders;
    
     constructor(address _erc20TokenContractAddress) public{
         erc20TokenContractAddress = _erc20TokenContractAddress;
    }
    
    function setERC20TokenContractAddress(address contractAddress)onlyContractOwner public {
        erc20TokenContractAddress = contractAddress;
    }
    
    function createBaronAsset(uint256 _tokenId)onlyContractOwner public {
        baronAssets.push(BaronAsset(_tokenId,now));
        _mint(msg.sender,_tokenId);
    }
    
     function bulkCreateBaronAsset(uint256[] _tokenIds)onlyContractOwner public {
         require(_tokenIds.length>0);
         for (uint256 i = 0; i < _tokenIds.length; i++) {
            baronAssets.push(BaronAsset(_tokenIds[i],now));
            
            _mint(msg.sender,_tokenIds[i]);
        }
    }
    
    function getTokenAtIndex(uint index)public view returns(uint256 _assetId, uint256 _dateCreatedUnix){
       BaronAsset asset =  baronAssets[index];
       _assetId = asset.assetId;
       _dateCreatedUnix = asset.dateCreatedUnix;
       return(_assetId,_dateCreatedUnix);
    }
    
    function getNumberOfAssetsCreated()public view returns(uint256 _length){
        _length = baronAssets.length;
        return _length;
    }
    
    function getAssets()public view returns(uint256[] _assetsIds, uint256[] _datesCreated){
        
        for(uint256 i =0; i < _assetsIds.length; i++ ){
            _assetsIds[i] = baronAssets[i].assetId;
            _datesCreated[i] = baronAssets[i].dateCreatedUnix;
        }
        return (_assetsIds,_datesCreated);
    }
    
    
    function bulkSafeTransferFrom(address[] _toAddresses,uint256[] _tokenIds)onlyContractOwner public{
          require(_toAddresses.length>0);
          require(_toAddresses.length == _tokenIds.length);
          
        for (uint256 i = 0; i < _toAddresses.length; i++) {
            require(_tokenIds[i] > 0 && _tokenIds[i]<MAX_UINT256);
            safeTransferFrom(msg.sender, _toAddresses[i], _tokenIds[i]);
        }          
        
    }
    
    function setTokenOrderListing(uint256 _tokenId, uint256 _price)canTransfer(_tokenId){
        tokenTransferOrders[_tokenId] = TokenOrder(_price,msg.sender);
    }
    
    function cancelTokenOrderListing(uint256 _tokenId, uint256 _price)canTransfer(_tokenId){
        tokenTransferOrders[_tokenId] = TokenOrder(0,0x0);
    }
    
    function tokenTransfer(uint256 _tokenId)
    {
      require(erc20TokenContractAddress!=0x0);
      erc20TokenAdapter erc20TokenContract = erc20TokenAdapter(erc20TokenContractAddress);
      TokenOrder tokenOrder =  tokenTransferOrders[_tokenId]; 
      require(tokenOrder.owner!=0x0);
      erc20TokenContract.erc721TokenContractTransfer(msg.sender,tokenOrder.owner,tokenOrder.priceInBaronCoin);
     
      //code that actually does the transfer of assetId
      tokenTransfer(tokenOrder.owner,msg.sender,_tokenId);
      
      tokenTransferOrders[_tokenId].owner = 0x0;
      tokenTransferOrders[_tokenId].priceInBaronCoin = 0;

    }
    
    function tokenTransfer(address _from, address _to,uint _tokenId)internal{
        require(_from != address(0));
        require(_to != address(0));
    
        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);
    
        emit Transfer(_from, _to, _tokenId);
    }
    
    
}