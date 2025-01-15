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

contract MarketPlace {
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
        uint256 productId;
        uint256 quantity;
        uint256 price;
        uint256 fee;
        uint256 amountPaid;
        address buyer;
        OrderStatus OrderStatus;
    }

    struct Product {
        uint256 productId;
        uint256 quantity;
        uint256 price;
    }

    // Mapping to store orders: productId => Order
    mapping(uint256 => Order) public orders;
    address public paymentReceiver;
    uint256 public totalAmountReceived;
    address public feeAddress;
    uint256 public feePercentage;
    uint256 public totalFeeReceived;
    mapping(uint256 => bool) public productId;
    mapping(uint256 => Product) public products;
    mapping(address => bool) public isManager;

    event ProductListed(
        uint256 indexed productId,
        uint256 indexed productPrice,
        uint256 indexed quantity,
        address manager
    );
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
    event WithdrawToken(
        address indexed token,
        address indexed to,
        uint256 indexed amount
    );
    event UpdateProductQuantity(
        uint256 indexed productId,
        uint256 indexed _quantity
    );
    event UpdateProductPrice(uint256 productId, uint256 productPrice);
    event ToggleManager(address manager, bool isManager);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == owner || isManager[msg.sender], "Not authorized");
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

    // Order Created Admin
    function productListed(
        uint256 _productId,
        uint256 _productPrice,
        uint256 _quantity
    ) public onlyManager {
        require(!productId[_productId], "With this id already Exist");
        products[_productId] = Product(_productId, _quantity, _productPrice);
        productId[_productId] = true;
        emit ProductListed(_productId, _productPrice, _quantity, msg.sender);
    }
    // Purchase product by ID (price is managed in backend)
    function purchaseProduct(uint256 _productId, uint256 _quantity) external {
        require(
            products[_productId].quantity >= _quantity,
            "Product Not Found"
        );
        uint256 totalAmount = products[_productId].price * _quantity;
        uint256 fees = (totalAmount * feePercentage) / 1000;
        bool success = paymentToken.transferFrom(
            msg.sender,
            address(this),
            totalAmount + fees
        );
        require(success, "Payment failed");
        // Store the purchase details
        orders[_productId] = Order({
            productId: _productId,
            buyer: msg.sender,
            quantity: _quantity,
            price: products[_productId].price,
            fee: fees,
            amountPaid: totalAmount + fees,
            OrderStatus: OrderStatus.Pending
        });
        products[_productId].quantity -= _quantity;
        emit ProductPurchased(
            msg.sender,
            _productId,
            _quantity,
            products[_productId].price,
            fees,
            totalAmount,
            OrderStatus.Pending
        );
    }

    function shipProduct(uint256 _productId) external onlyManager {
        Order storage order = orders[_productId];
        require(
            order.OrderStatus == OrderStatus.Pending,
            "Invalid order status"
        );
        order.OrderStatus = OrderStatus.Shipped;
        paymentToken.transfer(paymentReceiver, order.amountPaid - order.fee);
        paymentToken.transfer(feeAddress, order.fee);
        totalFeeReceived += order.fee;
        totalAmountReceived += order.amountPaid;
        emit OrderShipped(msg.sender, _productId);
    }

    function canelOrder(uint256 _orderId) public {
        Order storage order = orders[_orderId];
        require(
            order.OrderStatus == OrderStatus.Pending,
            "Invalid order status"
        );
        require(order.buyer == msg.sender, "Not authorized");

        order.OrderStatus = OrderStatus.Cancelled;
        products[order.productId].quantity += order.quantity;
        paymentToken.transfer(order.buyer, order.amountPaid - order.fee);
        emit OrderCancelled(msg.sender, _orderId);
    }

    function returnOrder(uint256 _orderId) public {
        Order storage order = orders[_orderId];
        require(
            order.OrderStatus == OrderStatus.Shipped,
            "Invalid order status"
        );
        require(order.buyer == msg.sender, "Not authorized");

        order.OrderStatus = OrderStatus.Returned;
        emit OrderCancelled(msg.sender, _orderId);
    }

    function receiveReturn(uint256 _orderId) public onlyManager {
        Order storage order = orders[_orderId];
        require(
            order.OrderStatus == OrderStatus.Returned,
            "Invalid order status"
        );

        order.OrderStatus = OrderStatus.ReturnedReceived;
        paymentToken.transfer(order.buyer, order.amountPaid - order.fee);
        emit OrderCancelled(msg.sender, _orderId);
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

    function withdrawToken(
        address _token,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_token).transfer(_to, _amount);
        emit WithdrawToken(_token, _to, _amount);
    }

    function updateProductQuantity(
        uint256 _productId,
        uint256 _quantity
    ) public onlyManager {
        require(productId[_productId], "Product is not Exist");
        products[_productId].quantity += _quantity;
        emit UpdateProductQuantity(_productId, _quantity);
    }

    function updateProductPrice(
        uint256 _productId,
        uint256 _productPrice
    ) public onlyManager {
        require(productId[_productId], "Product is not Exist");
        products[_productId].price = _productPrice;
        emit UpdateProductPrice(_productId, _productPrice);
    }

    function toggleManager(address _manager) public onlyOwner {
        if (isManager[_manager]) {
            isManager[_manager] = false;
        }
        isManager[_manager] = true;
        emit ToggleManager(_manager, isManager[_manager]);
    }
}
