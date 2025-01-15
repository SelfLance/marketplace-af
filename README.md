# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```

# Contract for Marketplace

      1- Product Purchase by Buyer
      2- Product Order Cancellation by Buyer
      3- Product Shipped by Owner
      4- Product Received Confirmation by Buyer
      5- Product Return by Buyer
      6- Product Return Received by Owner
      7- Platform Fee Setting by Owner (Max fee: 50%, Min fee: 0%)
      8- Change Payment Token Address (Owner Only)
      9- Change Fee Address (Owner Only)
      10- Manual Withdrawal of Funds (Lifti & Matic) by Owner
      11- Product Listing  By owner only
      12- Product Quantity update  By owner only
      13- Product Price Update By owner only

# Important Considerations

     1- Fee Calculation: If a fee is implemented (greater than 0%), it will be calculated and deducted from the buyer's account during purchase.

     2- Cancellation Fee Policy:
     Cancellation fees are non-refundable.
     Example: If a user buys 2 phones at 100 Lifti each (total: 200 Lifti) with a 2% fee, they pay 204 Lifti. If they cancel, they receive only 200 Lifti.

     4- Return Fee Policy: Return fees are also non-refundable.

     5- Separate Addresses: The contract will have separate addresses for:
     Receiving fees.
     Receiving product payments.
     Upon shipment, funds will be transferred to the respective accounts.

     6- Return Handling: If a buyer returns a shipment and the owner accepts the return, the owner is responsible for sending the equivalent amount of Lifti back to the contract for refund to the buyer.

# Marketplace Deployed on Amoy Testnet Polygon
     Successfully verified contract MarketPlace on the block explorer.
     https://amoy.polygonscan.com/address/0x64FCd3FaF15A46dE703552837105ac2915990A24#code

