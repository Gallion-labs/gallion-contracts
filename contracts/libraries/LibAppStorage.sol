// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {LibDiamond} from "./LibDiamond.sol";
import {LibMeta} from "./LibMeta.sol";

struct AppStorage {
    bytes32 domainSeparator;
    address gallionLabs;
    address guildContract;
    address guildTokenContract;
    address guildLootboxContract;
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
        require(s.guildAdmins[LibMeta.msgSender()].createdAt > 0, "LibAppStorage: Only guild admins can call this function");
        _;
    }

    modifier playerExists(address player) {
        require(player != address(0), "LibAppStorage: Player address is not valid");
        require(s.players[player].createdAt > 0, "LibAppStorage: Player does not exist");
        _;
    }

    modifier playerNotExists(address player) {
        require(player != address(0), "LibAppStorage: Player address is not valid");
        require(!(s.players[player].createdAt > 0), "PlayerFacet: Player already exists");
        _;
    }

    modifier lootboxExists(uint256 lootbox) {
        require(s.lootboxes[lootbox].mintedAt > 0, "LibAppStorage: Lootbox does not exist");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyGallion() {
        require(LibMeta.msgSender() == s.gallionLabs, "LibAppStorage: Only Gallion can call this function");
        _;
    }
}
