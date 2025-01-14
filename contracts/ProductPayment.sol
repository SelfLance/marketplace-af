// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ProductPayment {
    address public owner;
    IERC20 public paymentToken;
    enum OrderStatus {
        Pending,
        Confirmed,
        Shipped,
        Delivered,
        Cancelled,
        Returned,
        ReturnedReceived
    }
    struct Order {
        address buyer;
        uint256 quantity;
        uint256 price;
        uint256 amountPaid;
        OrderStatus OrderStatus;
    }

    // Mapping to store orders: productId => Order
    mapping(uint256 => Order) public orders;

    event ProductPurchased(
        address indexed buyer,
        uint256 indexed productId,
        uint256 amount
    );
    event ProductPurchased(
        address indexed buyer,
        uint256 productId,
        uint256 quantity,
        uint256 productPrice,
        uint256 totalAmount,
        OrderStatus indexed orderStatus
    );

    event OrderShipped(address indexed buyer, uint256 indexed productId);
    event OrderCancelled(address indexed buyer, uint256 indexed productId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        paymentToken = IERC20(_tokenAddress);
    }

    // Purchase product by ID (price is managed in backend)
    function purchaseProduct(
        uint256 productId,
        uint256 productPrice,
        uint256 quantity
    ) external {
        require(productPrice > 0, "Invalid product price");
        uint256 totalAmount = productPrice * quantity;
        // Transfer ERC-20 tokens from buyer to owner
        bool success = paymentToken.transferFrom(
            msg.sender,
            address(this),
            totalAmount
        );

        require(success, "Payment failed");
        // Store the purchase details
        orders[productId] = Order({
            buyer: msg.sender,
            quantity: quantity,
            price: productPrice,
            amountPaid: totalAmount,
            OrderStatus: OrderStatus.Pending
        });

        emit ProductPurchased(
            msg.sender,
            productId,
            quantity,
            productPrice,
            totalAmount,
            OrderStatus.Pending
        );
    }

    function shipProduct(uint256 productId) external onlyOwner {
        Order storage order = orders[productId];
        require(
            order.OrderStatus == OrderStatus.Pending,
            "Invalid order status"
        );
        order.OrderStatus = OrderStatus.Shipped;
        paymentToken.transfer(owner, order.amountPaid);
        emit OrderShipped(msg.sender, productId);
    }

    function canelOrder(uint256 orderId) public {
        Order storage order = orders[orderId];
        require(
            order.OrderStatus == OrderStatus.Pending,
            "Invalid order status"
        );
        require(order.buyer == msg.sender, "Not authorized");

        order.OrderStatus = OrderStatus.Cancelled;
        paymentToken.transfer(order.buyer, order.amountPaid);
        emit OrderCancelled(msg.sender, orderId);
    }

    function returnOrder(uint256 orderId) public {
        Order storage order = orders[orderId];
        require(
            order.OrderStatus == OrderStatus.Shipped,
            "Invalid order status"
        );
        require(order.buyer == msg.sender, "Not authorized");

        order.OrderStatus = OrderStatus.Returned;
        // paymentToken.transfer(order.buyer, order.amountPaid);
        emit OrderCancelled(msg.sender, orderId);
    }

    function receiveReturn(uint256 orderId) public onlyOwner {
        Order storage order = orders[orderId];
        require(
            order.OrderStatus == OrderStatus.Returned,
            "Invalid order status"
        );

        order.OrderStatus = OrderStatus.ReturnedReceived;
        paymentToken.transfer(owner, order.amountPaid);
        emit OrderCancelled(msg.sender, orderId);
    }

    // Update token address (optional for owner)
    function updateToken(address _newToken) external onlyOwner {
        paymentToken = IERC20(_newToken);
    }
}
