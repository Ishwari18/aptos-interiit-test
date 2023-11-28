
module RiskEngine {
    use std::P2P;
    use std::Account;
    use std::LibraCoin;
    use std::PriceOracle;
    use std::LibraAccount;
    use std::Event;
    use std::Base;
    use std::EventStore;
    use std::EventStore;
    use std::Transaction;
    use std::Signer;

    // Define the Account resource struct
     struct Account has key {
        open_orders: vector<Order>,
        open_positions: vector<OpenPosition>,
        position_history: vector<ClosedPosition>,
        available_margin: u64,
    }

    // Enum for OrderType
    enum OrderType {
        Market,
        Limit,
    }

    // Enum for OrderSide
    enum OrderSide {
        Buy,
        Sell,
    }

    // Resource to represent an Order
    resource struct Order {
        order_type: OrderType,
        order_side: OrderSide,
        asset: address,
        leverage: u64,
        margin: u64,
        price: u64,
        timestamp: u64,
    }

    // Resource to represent an OpenPosition
    resource struct OpenPosition {
        order_side: OrderSide,
        asset: address,
        leverage: u64,
        initial_margin: u64,
        maintainence_margin: u64,
        open_price: u64,
        timestamp: u64,
    }

    // Resource to represent a ClosedPosition
    resource struct ClosedPosition {
        order_side: OrderSide,
        asset: address,
        leverage: u64,
        open_price: u64,
        closed_price: u64,
        pnl: u64,
        timestamp: u64,
    }

    // Event for trade
    public event TradeEvent(address, address, u64, u64);

    // Public function to check order risk
    public fun checkOrderRisk(account: &mut Account, new_order: &Order) {
        let asset_exist = checkAssetPositionExists(&account.open_positions, new_order.asset);
        if !asset_exist {
            let margin = calculateMargin(new_order);
            if margin > account.available_margin {
                return false;
            }
        }
        return true;
    }

    // Internal function to calculate margin
    public fun calculateMargin(new_order: &Order): u64 {
        let initial_margin = new_order.margin;
        let position_size = new_order.margin * new_order.leverage;
        let asset_price = PriceOracle::get_price();
        let position_size_in_asset = asset_price / position_size;
        let maintainence_margin = ((15 * asset_price) / 100) * position_size_in_asset;
        return maintainence_margin + initial_margin;
    }

    // Internal function to check if an asset position exists
    public fun checkAssetPositionExists(positions: &vector<OpenPosition>, asset: address): bool {
        for opp_order in positions {
            if opp_order.asset == asset {
                return true;
            }
        }
        return false;
    }
}
