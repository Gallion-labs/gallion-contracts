// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {AppStorage, Modifiers, Player} from "../libraries/LibAppStorage.sol";
import {LibLootbox} from "../libraries/LibLootbox.sol";

contract PlayerFacet is Modifiers {
    event LevelUpEvent(address player, uint16 level);

    /// @notice Query all details relating to a player
    /// @dev This function throws for queries about the zero address and non-existing players.
    /// @param playerAddress The player to query
    /// @return _player The player's details
    function player(address playerAddress) public view playerExists(playerAddress) returns (Player memory _player) {
        _player = s.players[playerAddress];
    }

    /// @notice Add a player
    /// @dev This function throws for queries about the zero address and already existing players.
    /// @param playerAddress Address of the player to add
    function addPlayer(address playerAddress) external onlyGuildAdmin playerNotExists(playerAddress) {
        s.players[playerAddress] = Player(block.timestamp, 0, new uint256[](0));
        s.nPlayers++;
    }

    /// @notice Level-up a player
    /// @dev This function throws for queries about the zero address and non-existing players.
    /// @param playerAddress Address of the player to level-up
    function levelUp(address playerAddress) external onlyGallion playerExists(playerAddress) {
        s.players[playerAddress].level++;
        LibLootbox.award(playerAddress);
    }

    /// @notice Remove a player
    /// @dev This function throws for queries about the zero address and non-existing players.
    /// @param playerAddress Address of the player to remove
    function removePlayer(address playerAddress) external onlyGuildAdmin playerExists(playerAddress) {
        delete s.players[playerAddress];
    }
}
