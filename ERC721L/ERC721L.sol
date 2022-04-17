// SPDX-License-Identifier: MIT
// creator : Jason Siauw
// contact : jasonsiauw90712223@gmail.com

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ERC721L is ERC721A, Ownable{
    constructor( 
        bytes32 merkleRoot_
     ) ERC721A("ERC721L", "Lock", "ipfs:///") {
        merkleRoot = merkleRoot_;
        vtw.allowToRequestToWithdraw = true ;
        vtw.requestingWithdraw = false ;
        vtw.percentage = 0 ;
        vtw.timeLock = 0 ;
    }

    struct voteToWithdraw{
        bool allowToRequestToWithdraw ;
        bool requestingWithdraw ;
        uint percentage ;
        uint256 timeLock ;
        mapping( uint256 => bool ) vote ;
    }

    voteToWithdraw public vtw;
    bytes32 public merkleRoot;
    uint256 public price = 0.1 ether ; 
    function mint(address to, uint256 quantity) internal {
        _safeMint(to, quantity);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function isWhitelist(address adr, bytes32[] calldata proof, bytes32 root) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf(adr));
    }

    function setTokenURI(string memory newTokenURI) external onlyOwner {
        _setTokenURI(newTokenURI);
    }

    function requestToWithdraw( uint percentage ) public onlyOwner {
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


    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "ERC721L: insufficient balance");
        require(vtw.requestingWithdraw, "ERC721L: no withdraw request applied");
        require(vtw.timeLock < block.timestamp, "ERC721L: waitting holder to vote");

        
        payable(msg.sender).transfer(address(this).balance);

    }
    
}