// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './MockOracle.sol';

contract Exchange {
    enum OrderType {
        Limit,
        Market
    }

    struct Order {
        address trader;
        uint256 quantity;
        uint256 price;
        OrderType orderType;
    }

    mapping(bytes32 => Order) public buyLimitOrders;
    mapping(bytes32 => Order) public sellLimitOrders;
    mapping(bytes32 => Order) public marketOrders;

    bytes32[] public buyLimitOrderIds;
    bytes32[] public sellLimitOrderIds;
    bytes32[] public marketOrderIds;

    uint256 public orderCounter;

    event Trade(address indexed buyer, address indexed seller, uint256 quantity, uint256 price);

    // Address of the deployed MockOracle contract
    MockOracle public oracle;

    constructor(address _oracle) {
        oracle = MockOracle(_oracle);
    }

    function placeBuyLimitOrder(uint256 quantity, uint256 price) external {
        bytes32 orderId = keccak256(abi.encodePacked(orderCounter, msg.sender, block.timestamp));
        buyLimitOrders[orderId] = Order(msg.sender, quantity, price, OrderType.Limit);
        buyLimitOrderIds.push(orderId);
        orderCounter++;
    }

    function placeSellLimitOrder(uint256 quantity, uint256 price) external {
        bytes32 orderId = keccak256(abi.encodePacked(orderCounter, msg.sender, block.timestamp));
        sellLimitOrders[orderId] = Order(msg.sender, quantity, price, OrderType.Limit);
        sellLimitOrderIds.push(orderId);
        orderCounter++;
    }

    function placeMarketOrder(uint256 quantity, bool isBuyOrder) external {
        bytes32 orderId = keccak256(abi.encodePacked(orderCounter, msg.sender, block.timestamp));

         // Get the current price from the MockOracle contract
        uint256 currentPrice = oracle.getPrice();

        // Create a new market order with the retrieved price
        Order memory marketOrder = Order(msg.sender, quantity, currentPrice, OrderType.Market);

        if (isBuyOrder) {
            marketOrders[orderId] = marketOrder;
            marketOrderIds.push(orderId);
        } else {
            marketOrders[orderId] = marketOrder;
            marketOrderIds.push(orderId);
        }

        orderCounter++;
        matchOrders(orderId, isBuyOrder);
    }

    function matchOrders(bytes32 orderId, bool isBuyOrder) internal {
        Order storage marketOrder = marketOrders[orderId];
        mapping(bytes32 => Order) storage oppositeOrderBook = isBuyOrder ? sellLimitOrders : buyLimitOrders;
        bytes32[] storage oppositeOrderIds = isBuyOrder ? sellLimitOrderIds : buyLimitOrderIds;

        for (uint256 i = 0; i < oppositeOrderIds.length; i++) {
            bytes32 oppositeOrderId = oppositeOrderIds[i];

            if (oppositeOrderBook[oppositeOrderId].quantity > 0 &&
                (marketOrder.price >= oppositeOrderBook[oppositeOrderId].price)) {

                uint256 matchedQuantity = (marketOrder.quantity < oppositeOrderBook[oppositeOrderId].quantity)
                    ? marketOrder.quantity
                    : oppositeOrderBook[oppositeOrderId].quantity;

                emit Trade(
                    marketOrder.trader,
                    oppositeOrderBook[oppositeOrderId].trader,
                    matchedQuantity,
                    oppositeOrderBook[oppositeOrderId].price
                );

                marketOrder.quantity -= matchedQuantity;
                oppositeOrderBook[oppositeOrderId].quantity -= matchedQuantity;

                if (marketOrder.quantity == 0) {
                    delete marketOrders[orderId];
                    removeFromArray(marketOrderIds, orderId);
                }

                if (oppositeOrderBook[oppositeOrderId].quantity == 0) {
                    delete oppositeOrderBook[oppositeOrderId];
                    removeFromArray(oppositeOrderIds, oppositeOrderId);
                }

                if (marketOrder.quantity == 0) {
                    break;
                }
            }
        }
    }

    function removeFromArray(bytes32[] storage array, bytes32 value) internal {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                if (i != array.length - 1) {
                    array[i] = array[array.length - 1];
                }
                array.pop();
                break;
            }
        }
    }
}
