// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {LibDiamond} from "./LibDiamond.sol";
import {LibMeta} from "./LibMeta.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct AppStorage {
    bytes32 domainSeparator;
    address gallionLabs;
    address guildContract;
    GuildToken guildToken;
    LootboxToken lootboxToken;
    uint totalMaticBalance;
    uint rewardMaticBalance;
    uint8 rewardRatioFromIncome; // From 1 to 100 (%)
    uint[] chanceByLootboxRarity; // From 1 to 100 (%)
    uint[] rewardFactorByLootboxRarity; // From 1 to 100 (%)
    mapping(address => Admin) guildAdmins;
    mapping(address => Player) players;
    mapping(uint256 => Lootbox) lootboxes;
    mapping(uint16 => Rarity) lootboxDropLevels;
    mapping(address => mapping(uint256 => uint256)) lootboxIdIndexes; // Lootbox indexes by player & lootbox id
    uint32 transferGasLimit;
    uint nPlayers;
}

struct GuildToken {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
}

struct LootboxToken {
    string name;
    string symbol;
    Counters.Counter tokenIds;
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
    mapping(address => mapping(uint256 => uint256)) ownedTokens;
    mapping(uint256 => uint256) ownedTokensIndex;
    uint256[] allTokens;
    mapping(uint256 => uint256) allTokensIndex;
}

struct Admin {
    uint createdAt;
}

struct Player {
    uint createdAt;
    uint16 level;
    uint256[] lootboxIds;
}

struct Lootbox {
    uint256 id;
    uint mintedAt;
    address owner;
    Rarity rarity;
}

enum Rarity {
    common,
    rare,
    epic,
    legendary
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyGuildAdmin() {
        require(s.guildAdmins[LibMeta.msgSender()].createdAt > 0, "NOT_ALLOWED: Only guild admins can call this function");
        _;
    }

    modifier playerExists(address player) {
        require(player != address(0), "NOT_ALLOWED: Player address is not valid");
        require(s.players[player].createdAt > 0, "NOT_ALLOWED: Player does not exist");
        _;
    }

    modifier playerNotExists(address player) {
        require(player != address(0), "NOT_ALLOWED: Player address is not valid");
        require(!(s.players[player].createdAt > 0), "NOT_ALLOWED: Player already exists");
        _;
    }

    modifier lootboxExists(uint256 lootbox) {
        require(s.lootboxes[lootbox].mintedAt > 0, "NOT_ALLOWED: Lootbox does not exist");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyGallion() {
        require(LibMeta.msgSender() == s.gallionLabs, "NOT_ALLOWED: Only Gallion can call this function");
        _;
    }

    modifier protectedCall() {
        LibDiamond.enforceIsContractOwner();
        require(LibMeta.msgSender() == address(this),
            "NOT_ALLOWED: Only Owner or this contract can call this function");
        _;
    }
}
