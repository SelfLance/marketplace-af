// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ProductPayment {
    address public owner;
    IERC20 public paymentToken;

    struct Order {
        address buyer;
        uint256 amountPaid;
        bool isConfirmed;
    }

    // Mapping to store orders: productId => Order
    mapping(uint256 => Order) public orders;

    event ProductPurchased(
        address indexed buyer,
        uint256 indexed productId,
        uint256 amount
    );
    event ProductConfirmed(address indexed buyer, uint256 indexed productId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        paymentToken = IERC20(_tokenAddress);
    }

    // Purchase product by ID (price is managed in backend)
    function purchaseProduct(uint256 productId, uint256 productPrice) external {
        require(productPrice > 0, "Invalid product price");
        require(
            orders[productId].buyer == address(0),
            "Product already purchased"
        );

        // Transfer ERC-20 tokens from buyer to owner
        bool success = paymentToken.transferFrom(
            msg.sender,
            owner,
            productPrice
        );
        require(success, "Payment failed");

        // Store the purchase details
        orders[productId] = Order({
            buyer: msg.sender,
            amountPaid: productPrice,
            isConfirmed: false
        });

        emit ProductPurchased(msg.sender, productId, productPrice);
    }

    // Buyer confirms product receipt
    function confirmProductReceived(uint256 productId) external {
        Order storage order = orders[productId];
        require(order.buyer == msg.sender, "Not the buyer");
        require(!order.isConfirmed, "Already confirmed");

        order.isConfirmed = true;
        emit ProductConfirmed(msg.sender, productId);
    }

    // Update token address (optional for owner)
    function updateToken(address _newToken) external onlyOwner {
        paymentToken = IERC20(_newToken);
    }
}
