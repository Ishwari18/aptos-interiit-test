// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './MockOracle.sol';

contract RiskEngine {

    MockOracle oracle;
    
    struct Account {
        Order[] openOrders;
        OpenPosition[] openPositions;
        ClosedPosition[] positionHistory;
        uint256 availableMargin;
    }

    enum OrderType {
        Market,
        Limit
    }

    enum OrderSide {
        Buy,
        Sell
    }

    struct Order {
        OrderType orderType;
        OrderSide oderSide;
        address asset;
        uint256 leverage;
        uint256 margin;
        uint256 price;
        uint256 timestamp;
    }

    struct OpenPosition {
        OrderSide orderSide;
        address asset;
        uint256 leverage;
        uint256 initialMargin;
        uint256 maintainenceMargin;
        uint256 openPrice;
        uint256 timpestamp;
    }

    struct ClosedPosition {
        OrderSide orderSide;
        address asset;
        uint256 leverage;
        uint256 openPrice;
        uint256 closedPrice;
        uint256 pnl;
        uint256 timpestamp;
    }

    constructor(address _oracle) {
        oracle = MockOracle(_oracle);
    }

   function orderRisk(Account memory _account, Order memory _newOrder) private view returns(bool) {

    // 1. Check that the asset exists or not
    address _asset = _newOrder.asset;
    bool _assetExist = _checkAssetPositionExists(_account.openPositions, _asset);

    if (!_assetExist) {
        // if no -> If the required margin of a new position
        uint256 _margin = _calculateMargin(_newOrder);
        if (_margin > _account.availableMargin) {
            return false;
        }
        return true;
    } else {
        
        return  true;
    }
    
}


    function _calculateMargin(Order memory _newOrder) internal view returns(uint256 margin) {
        // Total margin = Margin used + Security margin
        //                  (Initil margin) (Maintainence margin)

        // maintainence margin = (15% of price)* order size in asset
        uint256 _initialMarign = _newOrder.margin;
        uint256 _positionSize = _newOrder.margin * _newOrder.leverage;
        uint256 _assetPrice = oracle.getPrice();
        uint256 _positionSizeInAsset = _assetPrice/_positionSize;
        uint256 _maintainenceMargin = ((15*_assetPrice)/100 )* _positionSizeInAsset;
        margin = _maintainenceMargin + _initialMarign;
    }

    function _checkAssetPositionExists(OpenPosition[] memory _positions, address _asset) internal pure returns(bool){
        for (uint256 i = 0; i<=_positions.length; i++){
            if(_positions[i].asset == _asset){
                return true;
            }
        }
        return false;
    }


} 