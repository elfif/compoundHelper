import { Contract } from "ethers";
import { ethers, network } from "hardhat";
import { checkBalances } from "./checkBalances";
import { getImpersonatedSigner } from "./checkBalances";
import ierc20Abi from '../artifacts/contracts/interfaces/IERC20.sol/IERC20.json'

export async function compoundHelper() {
  const _alchemicaTokens: [
    [string, string],
    [string, string],
    [string, string],
    [string, string],
    [string, string]
  ] = [
    [
      "0x403E967b044d4Be25170310157cB1A4Bf10bdD0f",
      "0xfEC232CC6F0F3aEb2f81B2787A9bc9F6fc72EA5C"
    ],[
      "0x44A6e0BE76e1D9620A7F76588e4509fE4fa8E8C8",
      "0x641CA8d96b01Db1E14a5fBa16bc1e5e508A45f2B"
    ],[
      "0x6a3E7C3c6EF65Ee26975b12293cA1AAD7e1dAeD2",
      "0xC765ECA0Ad3fd27779d36d18E32552Bd7e26Fd7b",
    ],[
      "0x42E5E06EF5b90Fe15F853F59299Fc96259209c5C",
      "0xBFad162775EBfB9988db3F24ef28CA6Bc2fB92f0",
    ],[
      "0x3801c3b3b5c98f88a9c9005966aa96aa440b9afc",  
      "0xb0E35478a389dD20050D66a67FB761678af99678" 
    ]
  ];

  const _quickswapRouter = "0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff";
  const ghst = "0x385eeac5cb85a38a9a07a70c73e0a3271cfb54a7";
  const farm = "0x1fE64677Ab1397e20A1211AFae2758570fEa1B8c"
    
  const signer = await getImpersonatedSigner()
    
  //const Helper = await ethers.getContractFactory("contracts/LiquidityHelper.sol:LiquidityHelper", signer);
  const Helper = await ethers.getContractFactory("cache/solpp-generated-contracts/LiquidityHelper.sol:LiquidityHelper", signer);
  const helper = await Helper.deploy(
    _alchemicaTokens,
    _quickswapRouter,
    ghst,
    farm
  );

  await helper.deployed();
  console.log("Liquidity Helper deployed to", helper.address);
   
  const data = await helper.getAllBalances()
  console.log("balance", await signer.getAddress())
  console.log(data);

  const ghstContract = new Contract(ghst, ierc20Abi.abi, signer)
  let ghstBalance = await ghstContract.balanceOf(await signer.getAddress())
  console.log("ghstBalance", ghstBalance)

  for (const tokenPairs of _alchemicaTokens) {
    for (const token of tokenPairs) {
      const contract = new Contract(token, ierc20Abi.abi, signer)
      const data = await contract.approve(helper.address, ethers.constants.MaxInt256)
      // console.log("Approve", token, data)
      await data.wait();
      // console.log("wait approve", awaitData)
      const checkData = await contract.allowance(await signer.getAddress(), helper.address);
      console.log("allowance", checkData)
    }
  }

  const data2 = await helper.removeFromLp([ 1,1,1,1,1 ], 1);
  console.log("response removeFromLp", data2)

  const data3 = await helper.getAllBalances()
  console.log(data3)

  ghstBalance = await ghstContract.balanceOf(await signer.getAddress())
  console.log("ghstBalance", ghstBalance)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  compoundHelper()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}