// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {AppStorage, Modifiers, Player, Lootbox, Rarity} from "../libraries/LibAppStorage.sol";
import {LibUtils} from "../libraries/Utils.sol";
import {GuildLootbox} from "../tokens/LootboxERC721.sol";
import {LibLootbox} from "../libraries/LibLootbox.sol";

contract LootboxFacet is Modifiers {

    /// @notice Query all details relating to a lootbox
    /// @dev This function throws for queries about non-existing lootbox.
    /// @param lootboxId The lootbox to query
    /// @return _lootbox The lootbox details
    function lootbox(uint256 lootboxId) public view lootboxExists(lootboxId) returns (Lootbox memory _lootbox) {
        _lootbox = s.lootboxes[lootboxId];
    }

    /// @notice Query all lootboxes owned by a player
    /// @dev This function throws for queries about the zero address and non-existing players.
    /// @param playerAddress The player to query for lootboxes
    /// @return _lootboxes The lootboxes owned by the player
    function list(address playerAddress) public view playerExists(playerAddress) returns (Lootbox[] memory _lootboxes) {
        uint256 length = s.players[playerAddress].lootboxIds.length;
        _lootboxes = new Lootbox[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 lootboxId = s.players[playerAddress].lootboxIds[i];
            if (s.lootboxes[lootboxId].owner == playerAddress) {
                _lootboxes[i] = (s.lootboxes[lootboxId]);
            }
        }
    }

    function award(address playerAddress) public playerExists(playerAddress) onlyGallion returns (uint256 _lootboxId) {
        _lootboxId = LibLootbox.award(playerAddress);
    }

    /// @notice Open a lootbox
    /// @dev This function throws for queries about the zero address and non-existing players.
    /// @param playerAddress The player to query
    /// @param lootboxId The lootbox to open
    function open(address playerAddress, uint256 lootboxId) external playerExists(playerAddress) onlyGallion returns (bool) {
        require(s.lootboxes[lootboxId].owner == playerAddress, "Player does not own this lootbox: ");
        return LibLootbox.open(playerAddress, lootboxId);
    }
}
