import { getSelectors, FacetCutAction } from './libraries/diamond';
import { ethers } from 'hardhat';
import { Address } from '../types';

// Comment to enable console output
/*console.log = () => {
};*/

async function deployTokenERC20(tokenName: string, tokenSymbol: string): Promise<Address> {
    // deploy Guild Token ERC20 contract
    const TokenERC20 = await ethers.getContractFactory('GuildToken');
    const token = await TokenERC20.deploy(tokenName, tokenSymbol);
    await token.deployed();
    return token.address;
}

async function deployLootboxERC721(tokenName: string, tokenSymbol: string): Promise<Address> {
    // deploy Lootbox ERC721 contract
    const LootboxERC721 = await ethers.getContractFactory('GuildLootbox');
    const lootbox = await LootboxERC721.deploy(tokenName, tokenSymbol);
    await lootbox.deployed();
    return lootbox.address;
}

async function deployDiamond(tokenERC20Address: Address, lootboxERC721Address: Address): Promise<Address> {
    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];

    // deploy DiamondCutFacet
    const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet');
    const diamondCutFacet = await DiamondCutFacet.deploy();
    await diamondCutFacet.deployed();
    // console.log('DiamondCutFacet deployed:', diamondCutFacet.address);

    // deploy Guild Diamond
    const GuildDiamond = await ethers.getContractFactory('GuildDiamond');
    const diamond = await GuildDiamond.deploy(contractOwner.address, diamondCutFacet.address);
    await diamond.deployed();
    // console.log('Diamond deployed:', diamond.address);

    // deploy DiamondInit
    // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
    // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
    const DiamondInit = await ethers.getContractFactory('DiamondInit');
    const diamondInit = await DiamondInit.deploy();
    await diamondInit.deployed();
    // console.log('DiamondInit deployed:', diamondInit.address);

    // deploy facets
    console.log('');
    console.log('Deploying facets');
    const FacetNames = [
        'DiamondLoupeFacet',
        'OwnershipFacet',
        'PlayerFacet',
        'LootboxFacet',
    ];
    const cut = [];
    for (const FacetName of FacetNames) {
        const Facet = await ethers.getContractFactory(FacetName);
        const facet = await Facet.deploy();
        await facet.deployed();
        // console.log(`${ FacetName } deployed: ${ facet.address }`);
        cut.push({
            facetAddress: facet.address,
            action: FacetCutAction.Add,
            functionSelectors: getSelectors(facet)
        });
    }

    // upgrade diamond with facets
    console.log('');
    // console.log('Diamond Cut:', cut);
    const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address);
    let tx;
    let receipt;
    // call to init function
    let functionCall = diamondInit.interface.encodeFunctionData('init', [
        {
            gallionLabs: accounts[9].address,
            guildAdmins: [accounts[2].address],
            guildTokenContract: tokenERC20Address,
            guildLootboxContract: lootboxERC721Address
        }
    ]);
    tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall);
    // console.log('Diamond cut tx: ', tx.hash);
    receipt = await tx.wait();
    if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${ tx.hash }`);
    }
    // console.log('Completed diamond cut');
    return diamond.address;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
/*if (require.main === module) {
    deployDiamond()
        .then(() => process.exit(0))
        .catch(error => {
            console.error(error);
            process.exit(1);
        });
}*/

export { deployDiamond, deployLootboxERC721, deployTokenERC20 };