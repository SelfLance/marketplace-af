const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('ProductPayment', function () {
  let ProductPayment;
  let productPayment;
  let owner;
  let buyer;
  let paymentReceiver;
  let feeAddress;
  let mockToken;

  const productId = 1;
  const productPrice = 100;
  const quantity = 2;
  const feePercentage = 20;

  beforeEach(async function () {
    [owner, buyer, paymentReceiver, feeAddress, user1, user2] = await ethers.getSigners();

    const MockToken = await ethers.getContractFactory('MockToken'); 
      mockToken = await MockToken.deploy();
      console.log("Mock Token is Deployed: ", mockToken.target)
      mockToken.mint( buyer.address,"100000000000")

    ProductPayment = await ethers.getContractFactory('ProductPayment');
    productPayment = await ProductPayment.deploy(mockToken.target, feeAddress.address, feePercentage);
  });

  it('should purchase product successfully', async function () {
      // Approve the contract to spend buyer's tokens
      let fee = (productPrice * quantity * feePercentage) / 1000;
      await mockToken.connect(buyer).approve(productPayment.target, (productPrice * quantity) + fee);
      console.log("Mock Balance of Buyer: ", await mockToken.balanceOf(buyer.address))

    // Purchase the product
    await productPayment.connect(buyer).purchaseProduct(productId, productPrice, quantity);

    // Check order details
    const order = await productPayment.orders(productId);
    expect(order.buyer).to.equal(buyer.address);
    expect(order.quantity).to.equal(quantity);
    expect(order.price).to.equal(productPrice);
    // Calculate expected fee
    const expectedFee = (productPrice * quantity * feePercentage) / 1000;
    expect(order.fee).to.equal(expectedFee);
    expect(order.amountPaid).to.equal((productPrice * quantity) + expectedFee);
    expect(order.OrderStatus).to.equal(0); // OrderStatus.Pending

    // Check token balance of the contract
    const contractBalance = await mockToken.balanceOf(productPayment.target);
    expect(contractBalance).to.equal((productPrice * quantity) + expectedFee);
  });

  it('should ship product successfully', async function () {
    // Purchase product (call testPurchaseProduct for setup)
      // await this.testPurchaseProduct();
      let fee = (productPrice * quantity * feePercentage) / 1000;
      await mockToken.connect(buyer).approve(productPayment.target, (productPrice * quantity) + fee);
      console.log("Mock Balance of Buyer: ", await mockToken.balanceOf(buyer.address))

    // Purchase the product
    await productPayment.connect(buyer).purchaseProduct(productId, productPrice, quantity);

    // Ship the product
    await productPayment.connect(owner).shipProduct(productId);

    // Check order status
    const order = await productPayment.orders(productId);
    expect(order.OrderStatus).to.equal(2); // OrderStatus.Shipped

    // Check payment received
    expect(await productPayment.totalAmountReceived()).to.equal(order.amountPaid);

    // Check token balance of payment receiver
    const receiverBalance = await mockToken.balanceOf(paymentReceiver.address);
    expect(receiverBalance).to.equal(0);
  });

  it('should cancel order successfully', async function () {
    // Purchase product (call testPurchaseProduct for setup)
      // await this.testPurchaseProduct();
      let fee = (productPrice * quantity * feePercentage) / 1000;
      await mockToken.connect(buyer).approve(productPayment.target, (productPrice * quantity) + fee);
      console.log("Mock Balance of Buyer: ", await mockToken.balanceOf(buyer.address))

    const buyerBalanceBefo = await mockToken.balanceOf(buyer.address);

    // Purchase the product
    await productPayment.connect(buyer).purchaseProduct(productId, productPrice, quantity);

    // Cancel the order
    await productPayment.connect(buyer).canelOrder(productId);

    // Check order status
    const order = await productPayment.orders(productId);
    expect(order.OrderStatus).to.equal(4); // OrderStatus.Cancelled

    // Check buyer's token balance
    const buyerBalance = await mockToken.balanceOf(buyer.address);
    expect(buyerBalance).to.equal(buyerBalanceBefo - order.fee); // Refunded amount - fee
  });

  it('should return order successfully', async function () {
    // Purchase and ship product
      // await this.testPurchaseProduct();
      let fee = (productPrice * quantity * feePercentage) / 1000;
      await mockToken.connect(buyer).approve(productPayment.target, (productPrice * quantity) + fee);

    // Purchase the product
    await productPayment.connect(buyer).purchaseProduct(productId, productPrice, quantity);
    await productPayment.connect(owner).shipProduct(productId);

    // Return the order
    await productPayment.connect(buyer).returnOrder(productId);

    // Check order status
    const order = await productPayment.orders(productId);
    expect(order.OrderStatus).to.equal(5); // OrderStatus.Returned
  });

  it('should receive returned product successfully', async function () {
    // Purchase, ship, and return product
      // await this.testPurchaseProduct();
      let fee = (productPrice * quantity * feePercentage) / 1000;
      let balanceBuyerBef = await mockToken.balanceOf(buyer.address); 
      await mockToken.connect(buyer).approve(productPayment.target, (productPrice * quantity) + fee);
      await productPayment.connect(buyer).purchaseProduct(productId, productPrice, quantity);

    await productPayment.connect(owner).shipProduct(productId);
    await productPayment.connect(buyer).returnOrder(productId);
    mockToken.mint(productPayment.target, "1000000")

    // Receive the returned product
    await productPayment.connect(owner).receiveReturn(productId);
      
    // Check order status
    const order = await productPayment.orders(productId);
    expect(order.OrderStatus).to.equal(6); // OrderStatus.ReturnedReceived

    // Check owner's token balance (refunded amount - fee)
    const buyerBalance = await mockToken.balanceOf(buyer.address); 
    expect(buyerBalance).to.equal(balanceBuyerBef  - order.fee );
  });

  it('should update token successfully', async function () {
    const NewMockToken = await ethers.getContractFactory('MockToken');
    const newMockToken = await NewMockToken.deploy();

    // Update the token address
    await productPayment.connect(owner).updateToken(newMockToken.target);

    // Check the updated token address
    expect(await productPayment.paymentToken()).to.equal(newMockToken.target);
  });

  it('should change payment receiver successfully', async function () {
    // Change the payment receiver
    await productPayment.connect(owner).changePaymentReceiver(paymentReceiver.address);

    // Check the updated payment receiver
    expect(await productPayment.paymentReceiver()).to.equal(paymentReceiver.address);
  });

  it('should change owner successfully', async function () {
    // Change the owner
    await productPayment.connect(owner).changeOwner(paymentReceiver.address);

    // Check the updated owner
    expect(await productPayment.owner()).to.equal(paymentReceiver.address);
  });

  it('should change fee address successfully', async function () {
    // Change the fee address
    await productPayment.connect(owner).changeFeeAddress(feeAddress.address);

    // Check the updated fee address
    expect(await productPayment.feeAddress()).to.equal(feeAddress.address);
  });

  it('should change fee percentage successfully', async function () {
    // Change the fee percentage
    const newFeePercentage = 10;
    await productPayment.connect(owner).changeFeePercentage(newFeePercentage);

    // Check the updated fee percentage
    expect(await productPayment.feePercentage()).to.equal(newFeePercentage);
  });
    
    it.only('should transfer token to contract successfully', async function () {
       await  mockToken.mint(owner.address, "1000");
        await    mockToken.connect(owner).transfer(user1.address, "200")
       await mockToken.connect(owner).transfer(productPayment.target, "200")
        console.log("Balance of Contract is :", await mockToken.balanceOf(productPayment.target))     
    })

    it.only('should Withdrawl token from contract successfully', async function () {
        await  mockToken.mint(owner.address, "1000");
         await    mockToken.connect(owner).transfer(user1.address, "200")
        await mockToken.connect(owner).transfer(productPayment.target, "200")
        console.log("Balance of Contract is :", await mockToken.balanceOf(productPayment.target))     
        
        await productPayment.connect(owner).withdrawToken(mockToken.target, user2.address, 100)
        expect(await mockToken.balanceOf(productPayment.target)).to.equal("100")
        await expect(productPayment.connect(user2).withdrawToken(mockToken.target, user2.address, 100)).to.be.revertedWith("Not authorized")

     })

  // ... Add test cases for withdrawMatic and withdrawToken ... 
});