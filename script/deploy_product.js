const hre = require("hardhat");

async function main() {
  // Get the contract factories
  //   const [deployer] = await hre.ethers.getSigners();
  //   let deployer = "0x1640fc5781B960400b9B0cAE7Cd72b21B2E246e7";
  //   const WETH = await hre.ethers.getContractFactory("MockWETH");
  const OrderManagment = await hre.ethers.getContractFactory("OrderManagement");

  let liftiToken = "0xAbA8AB08D656C1829Be3795453758c2178131E56";

  const orderManagement = await OrderManagment.deploy(liftiToken);
  console.log("Order Management is Deployed To: ", orderManagement.target);

  // const Staking = await hre.ethers.getContractFactory("Profitmaxpresale");
  // const stake = await Staking.deploy(erc20.target);

  // console.log("Staking Contract deployed to:", stake.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});