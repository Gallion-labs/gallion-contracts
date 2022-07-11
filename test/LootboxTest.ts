import { ethers } from 'hardhat';
import { Address } from '../types';
import { DiamondCutFacet, DiamondLoupeFacet, GuildDiamond, LootboxFacet, PlayerFacet } from '../typechain-types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { PlayerStructOutput } from '../typechain-types/contracts/facets/PlayerFacet';
import { LootboxStructOutput } from '../typechain-types/contracts/facets/LootboxFacet';
import { GuildLootbox } from '../typechain-types';
import { deployTokenERC20 } from '../scripts/deployForTests';
import { expect } from 'chai';

const { deployDiamond, deployLootboxERC721 } = require('../scripts/deployForTests.ts');
const { assert } = require('chai');

const Account = {
    Owner: 0,
    NewOwner: 1,
    Admin1: 2,
    Admin2: 3,
    Player1: 4,
    Player2: 5,
    Gallion: 9
};

describe('Lootbox Facet test', async function () {
    let accounts: SignerWithAddress[] = [];
    let diamondAddress: Address;
    let tokenAddress: Address;
    let lootboxAddress: Address;
    let guildContract: GuildDiamond;
    let diamondCutFacet: DiamondCutFacet;
    let diamondLoupeFacet: DiamondLoupeFacet;
    let playerFacet: PlayerFacet;
    let lootboxFacet: LootboxFacet;

    before(async function () {
        accounts = await ethers.getSigners();
        tokenAddress = await deployTokenERC20('Mayari Coin', 'MAYA');
        lootboxAddress = await deployLootboxERC721('Mayari Lootbox', 'MLT');
        diamondAddress = await deployDiamond(tokenAddress, lootboxAddress);
        guildContract = (await ethers.getContractAt('GuildDiamond', diamondAddress) as GuildDiamond);
        diamondCutFacet = (await ethers.getContractAt('DiamondCutFacet', diamondAddress) as DiamondCutFacet);
        diamondLoupeFacet = (await ethers.getContractAt('DiamondLoupeFacet', diamondAddress) as DiamondLoupeFacet);
        playerFacet = (await ethers.getContractAt('PlayerFacet', diamondAddress) as PlayerFacet);
        lootboxFacet = (await ethers.getContractAt('LootboxFacet', diamondAddress) as LootboxFacet);
        // Create player 1
        await playerFacet
            .connect(accounts[Account.Admin1])
            .addPlayer(accounts[Account.Player1].address);
    });

    it('should transfer ownership of Lootbox ERC721 contract to the player facet', async () => {
        const lootboxContract: GuildLootbox = (await ethers.getContractAt('GuildLootbox', lootboxAddress) as GuildLootbox);
        await lootboxContract.transferOwnership(accounts[Account.Gallion].address);
        assert.equal(await lootboxContract.owner(), accounts[Account.Gallion].address);
    });

    it('should mint a lootbox for player 1', async () => {
        const playerFacet: PlayerFacet = (await ethers.getContractAt('PlayerFacet', diamondAddress) as PlayerFacet);
        await lootboxFacet
            .connect(accounts[Account.Gallion])
            .award(accounts[Account.Player1].address);
        const player: PlayerStructOutput = await playerFacet
            .connect(accounts[Account.Gallion])
            .player(accounts[Account.Player1].address);
        expect(player.lootboxIds).to.have.length(1);
    });

    it('should get the first lootbox of player 1', async () => {
        const playerFacet: PlayerFacet = (await ethers.getContractAt('PlayerFacet', diamondAddress) as PlayerFacet);
        const player: PlayerStructOutput = await playerFacet
            .connect(accounts[Account.Gallion])
            .player(accounts[Account.Player1].address);
        assert.exists(player.createdAt, 'Player does not exist');
        const lootbox: LootboxStructOutput = await lootboxFacet
            .connect(accounts[Account.Gallion])
            .lootbox(player.lootboxIds[0]);
        assert.exists(lootbox.mintedAt, 'Lootbox does not exist');
    });

    it('should open the first lootbox of player 1', async () => {
        const playerFacet: PlayerFacet = (await ethers.getContractAt('PlayerFacet', diamondAddress) as PlayerFacet);
        const player1Address = accounts[Account.Player1].address;
        let player: PlayerStructOutput = await playerFacet
            .connect(accounts[Account.Gallion])
            .player(player1Address);
        assert.exists(player.createdAt, 'Player does not exist');
        const lootboxIdToOpen = player.lootboxIds[0];
        let lootbox: LootboxStructOutput = await lootboxFacet
            .connect(accounts[Account.Gallion])
            .lootbox(lootboxIdToOpen);
        assert.exists(lootbox.mintedAt, 'Lootbox does not exist');
        await lootboxFacet
            .connect(accounts[Account.Gallion])
            .open(player1Address, lootboxIdToOpen);
        const playerLootboxes = await lootboxFacet
            .connect(accounts[Account.Gallion])
            .list(player1Address);
        expect(playerLootboxes).to.have.length(0, 'Player lootboxes from LootboxFacet should be empty');
        player = await playerFacet
            .connect(accounts[Account.Gallion])
            .player(player1Address);
        expect(player.lootboxIds).to.have.length(0, 'Player lootboxes from PlayerFacet should be empty');
    });
});
