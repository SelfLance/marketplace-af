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
        uint256 fee;
        uint256 amountPaid;
        OrderStatus OrderStatus;
    }

    // Mapping to store orders: productId => Order
    mapping(uint256 => Order) public orders;
    address public paymentReceiver;
    uint256 public totalAmountReceived;
    address public feeAddress;
    uint256 public feePercentage;

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
        uint256 fees,
        uint256 totalAmount,
        OrderStatus indexed orderStatus
    );

    event OrderShipped(address indexed buyer, uint256 indexed productId);
    event OrderCancelled(address indexed buyer, uint256 indexed productId);
    event TokenUpdated(address newToken);
    event PaymentReceiverChanged(address newReceiver);
    event OwnerChanged(address newOwner);
    event ChangeFeeAddress(address newFeeAddress);
    event ChangeFeePercentage(uint256 newFeePercentage);
    event WithdrawMatic(address indexed to, uint256 indexed amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(
        address _tokenAddress,
        address _feeAddress,
        uint256 _feePercentage
    ) {
        owner = msg.sender;
        paymentReceiver = msg.sender;
        feePercentage = _feePercentage;
        feeAddress = _feeAddress;
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
        bool success = paymentToken.transferFrom(
            msg.sender,
            address(this),
            totalAmount
        );
        require(success, "Payment failed");
        uint256 fees = (totalAmount * feePercentage) / 100;
        // Store the purchase details
        orders[productId] = Order({
            buyer: msg.sender,
            quantity: quantity,
            price: productPrice,
            fee: fees,
            amountPaid: totalAmount + fees,
            OrderStatus: OrderStatus.Pending
        });

        emit ProductPurchased(
            msg.sender,
            productId,
            quantity,
            productPrice,
            fees,
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
        paymentToken.transfer(paymentReceiver, order.amountPaid);
        totalAmountReceived += order.amountPaid;
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
        paymentToken.transfer(order.buyer, order.amountPaid - order.fee);
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
        paymentToken.transfer(owner, order.amountPaid - order.fee);
        emit OrderCancelled(msg.sender, orderId);
    }
    // Update token address (optional for owner)
    function updateToken(address _newToken) external onlyOwner {
        paymentToken = IERC20(_newToken);
        emit TokenUpdated(_newToken);
    }

    function changePaymentReceiver(address _newReceiver) external onlyOwner {
        paymentReceiver = _newReceiver;
        emit PaymentReceiverChanged(_newReceiver);
    }
    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
    function changeFeeAddress(address _newFeeAddress) external onlyOwner {
        feeAddress = _newFeeAddress;
        emit ChangeFeeAddress(_newFeeAddress);
    }
    function changeFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 500, "Invalid fee percentage");
        feePercentage = _newFeePercentage;
        emit ChangeFeePercentage(_newFeePercentage);
    }
    function withdrawMatic(uint256 _amount, address _to) public onlyOwner {
        payable(_to).transfer(_amount);
        emit WithdrawMatic(_to, _amount);
    }
}
