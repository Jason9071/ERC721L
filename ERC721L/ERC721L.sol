// SPDX-License-Identifier: MIT
// creator : Jason Siauw
// contact : jasonsiauw90712223@gmail.com

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ERC721L is ERC721A, Ownable{
    using SafeMath for uint256 ;

    struct voteToWithdraw{
        bool allowToRequestToWithdraw ;
        bool requestingWithdraw ;
        uint256 passRate ;
        uint percentage ;
        uint256 timeLock ;
        mapping( uint256 => bool ) isVoted ;
        uint256 vote ;
    }

    voteToWithdraw public vtw;
    //bytes32 public merkleRoot;
    uint256 public maxSupply; 
    uint256 public price; 

    constructor( 
        //bytes32 merkleRoot_,
        //uint256 price_,
        //uint256 maxSupply_
     ) ERC721A("ERC721L", "Lock", "ipfs://test/") {
        //merkleRoot = merkleRoot_;
        //price = price_;
        price = 0.3 ether;
        maxSupply = 3333;
        vtw.allowToRequestToWithdraw = true ;
        vtw.requestingWithdraw = false ;
        vtw.passRate = 65 ;
        vtw.percentage = 0 ;
        vtw.timeLock = 0 ;
        vtw.vote = 0 ;
    }

    function mint(uint256 quantity) external payable {
        require( msg.value * quantity >= price ,"ERC721L: no enough ether");
        _safeMint(msg.sender, quantity);
    }

    /*
    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function isWhitelist(address adr, bytes32[] calldata proof, bytes32 root) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf(adr));
    }

    function setTokenURI(string memory newTokenURI) external onlyOwner {
        _setTokenURI(newTokenURI);
    }
    */

    function requestToWithdraw( uint percentage ) external onlyOwner {
        require(address(this).balance > 0, "ERC721L: insufficient balance");
        require(vtw.allowToRequestToWithdraw, "ERC721L: not allowed to request withdraw");
        require(percentage > 1, "ERC721L: percentage must be bigger then 0");
        require(percentage < 101, "ERC721L: percentage must be smaller then 101");
        vtw.allowToRequestToWithdraw = false;
        vtw.requestingWithdraw = true;
        vtw.percentage = percentage ;

        if ( percentage <= 10 ) {
            vtw.timeLock = block.timestamp + 3 days ; 
        }
        else if ( percentage >= 11 && percentage <= 50 ) {
            vtw.timeLock = block.timestamp + 14 days ; 
        }
        else if ( percentage > 50 ) {
            vtw.timeLock = block.timestamp + 30 days ;
        }
    }

    function vote( uint256 tokenId ) external {
        require(vtw.requestingWithdraw, "ERC721L: no withdraw request applied");
        require(vtw.timeLock > block.timestamp, "ERC721L: voting is over now");
        require( ownerOf(tokenId) == msg.sender , "ERC721L: you are not the token owner");
        require( !vtw.isVoted[tokenId] , "ERC721L: this token already voted");

        vtw.isVoted[tokenId] = true ;
        vtw.vote++ ;
    }

    function pass() internal view returns( bool ) {
        uint256 passVotes = _totalMinted().div(100).mul(65) ;
        if ( vtw.vote >= passVotes )
            return false ;
        return true;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "ERC721L: insufficient balance");
        require(vtw.requestingWithdraw, "ERC721L: no withdraw request applied");
        require(vtw.timeLock < block.timestamp, "ERC721L: waitting holder to vote");
        
        if ( pass() )
            payable(owner()).transfer(address(this).balance.div(100).mul(vtw.percentage));

        // reset all the info //
        vtw.allowToRequestToWithdraw = true ;
        vtw.requestingWithdraw = false ;
        vtw.passRate = 65 ;
        vtw.percentage = 0 ;
        vtw.timeLock = 0 ;
        vtw.vote = 0 ;
        // reset all the info //
    }

    function voteInfo() external view returns( bool, bool, uint, uint, uint256, uint256 ) {
        return ( 
            vtw.allowToRequestToWithdraw,
            vtw.requestingWithdraw,
            vtw.passRate,
            vtw.percentage,
            vtw.timeLock,
            vtw.vote
        );
    }
}