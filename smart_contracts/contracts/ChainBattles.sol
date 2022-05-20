//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "hardhat/console.sol";

contract ChainBattles is ERC721URIStorage {
 
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    uint randNonce = 0;
    uint MAX_SPEED = 100;
    uint MAX_STRENGTH = 100;

    struct Characteristics {
        uint level;
        uint speed;
        uint strength;
        uint life;
        uint lastBattleGround;
    }

    mapping(uint256 => Characteristics) public tokenIdToLevels;

    constructor() ERC721("ChainBattles", "CBTLS") {}

    function generateCharacter(uint256 tokenId) public view returns (string memory){

        Characteristics memory characteristics = getCharacteristics(tokenId);

        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
            '<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>',
            '<rect width="100%" height="100%" fill="black" />',
            '<text x="50%" y="20%" class="base" dominant-baseline="middle" text-anchor="middle">Warrior</text>',
            '<text x="50%" y="30%" class="base" dominant-baseline="middle" text-anchor="middle">Levels: ', characteristics.level.toString(), '</text>',
            '<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">Speed: ', characteristics.speed.toString(), '</text>',
            '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">Strength: ', characteristics.strength.toString(), '</text>',
            '<text x="50%" y="60%" class="base" dominant-baseline="middle" text-anchor="middle">Life: ', characteristics.life.toString(), '</text>',
            '<text x="50%" y="70%" class="base" dominant-baseline="middle" text-anchor="middle">Last Battle Ground: ', characteristics.lastBattleGround.toString(), '</text>',
            '</svg>'
        );

        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svg)
            )
        );
    }

    function getCharacteristics(uint256 tokenId) public view returns (Characteristics memory) {
        Characteristics memory characteristics   = tokenIdToLevels[tokenId];
        return characteristics;
    }

    function getTokenURI(uint256 tokenId) public view returns(string memory) {
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Chain Battles #' , tokenId.toString(), '",', 
                '"description": "Battles on Chain",', 
                '"image": "', generateCharacter(tokenId), '"',                
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,", 
                Base64.encode(dataURI)
            )
        );
    }

    function mint() public {
        tokenIds.increment();
        uint256 newItemId = tokenIds.current();
        _safeMint(msg.sender, newItemId);
        tokenIdToLevels[newItemId] = Characteristics(0, 1, 1, 3, block.number);
        _setTokenURI(newItemId, getTokenURI(newItemId));
    }

    function play(uint256 tokenId) public {
        require(_exists(tokenId), "Pleaes use an exisiting Token");
        require(ownerOf(tokenId) == msg.sender, "You must own this token to train it");

        Characteristics memory characteristics = tokenIdToLevels[tokenId];

        require(characteristics.life > 0, "You should have life to play the game");
        
        bool shouldIncreaseLevel  = randMod(100) >=50 ? true: false;
        bool lifeLost  = randMod(100) >=50 ? true: false;
        uint newSpeed  = randMod(100);
        uint newStrength  = randMod(100);

        if (shouldIncreaseLevel) {
            characteristics.level++;                    
        } 
        if (lifeLost) {
            characteristics.life--;                    
        }

        characteristics.speed = setSpeedOrStrength(characteristics.speed, newSpeed, newSpeed % 2 == 0, MAX_SPEED);
        characteristics.strength = setSpeedOrStrength(characteristics.strength, newStrength, newStrength % 2 == 0, MAX_STRENGTH);
        characteristics.lastBattleGround = block.number;

        tokenIdToLevels[tokenId] = characteristics;
        _setTokenURI(tokenId, getTokenURI(tokenId));
    }

    function randMod(uint _modulus) private returns(uint) {
        randNonce++;
        uint rand = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus;
        return rand;
    }

    function setSpeedOrStrength(uint current, 
                                uint incrementOrDecrement, 
                                bool increase, 
                                uint maxValue) private pure returns (uint speedOrStrength) {
        if (increase) {
            speedOrStrength = current + incrementOrDecrement;
            speedOrStrength = speedOrStrength > maxValue ? maxValue : speedOrStrength;
        } else {
            speedOrStrength = (current > incrementOrDecrement) ? (current - incrementOrDecrement) : 1;

        }
    }
}