// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {AppStorage, Player, Lootbox, Rarity} from "./LibAppStorage.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {LibUtils} from "./Utils.sol";
import {GuildLootbox} from "../tokens/LootboxERC721.sol";

library LibLootbox {

    event OpenLootboxEvent(address player, uint256 lootboxId);

    function award(address playerAddress) internal returns (uint256 _lootboxId) {
        AppStorage storage s = LibDiamond.appStorage();
        _lootboxId = GuildLootbox(s.guildLootboxContract).mint(playerAddress);
        if (_lootboxId > 0) {
            // calc the rarity
            uint random = LibUtils.random(100);
            Rarity rarity = Rarity.common;
            for (uint8 i = 1; i < s.chanceByLootboxRarity.length; i++) {
                if (random <= s.chanceByLootboxRarity[i]) {
                    rarity = Rarity(i);
                }
            }
            // register the lootbox
            s.lootboxes[_lootboxId] = Lootbox(_lootboxId, block.timestamp, playerAddress, rarity);
            s.players[playerAddress].lootboxIds.push(_lootboxId);
            s.lootboxIdIndexes[playerAddress][_lootboxId] = s.players[playerAddress].lootboxIds.length - 1;
        }
    }

    /// @notice Open a lootbox
    /// @dev This function throws for queries about the zero address and non-existing players.
    /// @param playerAddress The player to query
    /// @param lootboxId The lootbox to open
    function open(address playerAddress, uint256 lootboxId) internal returns (bool) {
        AppStorage storage s = LibDiamond.appStorage();
        uint playerReward = (s.rewardFactorByLootboxRarity[uint8(s.lootboxes[lootboxId].rarity)] * (s.rewardMaticBalance / s.nPlayers)) / 100;
        (bool success, bytes memory data) = address(playerAddress).call{value : playerReward, gas : s.transferGasLimit}("");
        if (!success) {
            revert(string.concat("Error during send transaction: ", string(data)));
        }

        GuildLootbox(s.guildLootboxContract).burn(lootboxId);
        removeFromPlayer(playerAddress, lootboxId);
        s.rewardMaticBalance -= playerReward;
        s.totalMaticBalance -= playerReward;

        emit OpenLootboxEvent(playerAddress, lootboxId);
        return success;
    }

    function removeFromPlayer(address playerAddress, uint256 lootboxId) internal {
        AppStorage storage s = LibDiamond.appStorage();
        uint256 lootboxIndex = s.lootboxIdIndexes[playerAddress][lootboxId];
        uint256 lootboxLastIndex = s.players[playerAddress].lootboxIds.length - 1;
        if (lootboxIndex != lootboxLastIndex) {
            uint256 lastLootboxId = s.players[playerAddress].lootboxIds[lootboxLastIndex];
            s.players[playerAddress].lootboxIds[lootboxIndex] = lastLootboxId;
            s.lootboxIdIndexes[playerAddress][lastLootboxId] = lootboxIndex + 1;
        }
        s.players[playerAddress].lootboxIds.pop();
        delete s.lootboxIdIndexes[playerAddress][lootboxId];
        delete s.lootboxes[lootboxId];
    }
}
