// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { AppStorage, Rarity, Modifiers } from "../libraries/LibAppStorage.sol";

contract RulesFacet is Modifiers {

    /// @notice Define levels on which a player will win a lootbox
    /// @param moduloLevels list of modulo levels on which a player will win a lootbox
    /// @param lootboxRarity rarity of the lootbox
    function setLootboxDropLevels(uint16[] memory moduloLevels, Rarity[] memory lootboxRarity) external onlyGuildAdmin {
        require(moduloLevels.length == lootboxRarity.length, "Levels and rewards must have the same length");
        uint lastModuloLevel = 0;
        for (uint i = 0; i < moduloLevels.length; i++) {
            uint16 moduloLevel = moduloLevels[i];
            Rarity lootboxType = lootboxRarity[i];
            require(moduloLevel > lastModuloLevel, "Modulo levels must be passed in ascending order");

            if (lootboxType == Rarity.common) {
                s.lootboxDropLevels[moduloLevel] = Rarity.common;
            } else if (lootboxType == Rarity.rare) {
                s.lootboxDropLevels[moduloLevel] = Rarity.rare;
            } else if (lootboxType == Rarity.epic) {
                s.lootboxDropLevels[moduloLevel] = Rarity.epic;
            } else if (lootboxType == Rarity.legendary) {
                s.lootboxDropLevels[moduloLevel] = Rarity.legendary;
            } else {
                revert("Invalid lootbox rarity");
            }
        }
    }
}
