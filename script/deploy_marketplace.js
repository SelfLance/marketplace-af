const hre = require("hardhat");

async function main() {

  const MarketPlace = await hre.ethers.getContractFactory("MarketPlace");

    let liftiToken = "0xAbA8AB08D656C1829Be3795453758c2178131E56";
    let feeAddress = "0xC6C385dfe722557591f8e2e0297Ad06F2C083A2B"
    let feePercentage = 20;// Two percent

  const marketPlace = await MarketPlace.deploy(liftiToken, feeAddress, feePercentage);
  console.log("Market Place is Deployed To: ", marketPlace.target);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});