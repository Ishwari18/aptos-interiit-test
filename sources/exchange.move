module DecentralizedExchange {
     use std::P2P;
     use std::Account;
     use std::LibraCoin;
     use std::PriceOracle;
     use std::LibraAccount;
     use std::Event;
     use std::Base;
     use std::EventStore;
     use std::Transaction;
     use std::Signer;
     
     struct Order has key {
        address: address,
        quantity: u64,
        price: u64,
        order_type: u8,
    }

     struct ExchangeData {
        BuyLimitOrders: vector<Order>,
        SellLimitOrders: vector<Order>,
        MarketOrders: vector<Order>,
        OrderTypes: vector<u8>,
        OrderCounter: u64,
    }

    // Initialize the exchange data
    public fun init() {
        let data: &mut ExchangeData;
        data.BuyLimitOrders = vector::empty<Order>();
        data.SellLimitOrders = vector::empty<Order>();
        data.MarketOrders = vector::empty<Order>();
        data.OrderTypes = vector::empty<u8>();
        data.OrderCounter = 0;
    }

    public fun placeBuyLimitOrder(sender: address, quantity: u64, price: u64, order_type: u8) acquires DecentralizedExchange {
        let order_id = OrderCounter;
        let new_order = Order {
            address: sender,
            quantity: quantity,
            price: price,
            order_type: order_type
        };
        BuyLimitOrders.push(order_id, new_order);
        OrderCounter = OrderCounter + 1;
    }

    public fun placeSellLimitOrder(sender: address, quantity: u64, price: u64, order_type: u8) acquires DecentralizedExchange {
        let order_id = OrderCounter;
        let new_order = Order {
            address: sender,
            quantity: quantity,
            price: price,
            order_type: order_type
        };
        SellLimitOrders.push(order_id, new_order);
        OrderCounter = OrderCounter + 1;
    }

    public fun placeMarketOrder(sender: address, quantity: u64, is_buy_order: bool) acquires DecentralizedExchange {
        let order_id = OrderCounter;
        let current_price = PriceOracle.get_price();
        let market_order = Order {
            address: sender,
            quantity: quantity,
            price: current_price,
            order_type: 2 // Market order type
        };
        MarketOrders.push(order_id, market_order);
        OrderCounter = OrderCounter + 1;
        matchOrders(order_id, is_buy_order);
    }

    public fun matchOrders(order_id: u64, is_buy_order: bool) acquires DecentralizedExchange {
        let market_order = MarketOrders.get(order_id);
        let opposite_order_book = if (is_buy_order) { SellLimitOrders } else { BuyLimitOrders };
        let opposite_order_ids = if (is_buy_order) { SellLimitOrders.keys() } else { BuyLimitOrders.keys() };

        for opp_order_id in &opposite_order_ids {
            let opposite_order = opposite_order_book.get(opp_order_id);
            if (opposite_order.quantity > 0 &&
                (market_order.price >= opposite_order.price)) {
                let matched_quantity = if (market_order.quantity < opposite_order.quantity) {
                    market_order.quantity
                } else {
                    opposite_order.quantity
                };
                
                market_order.quantity = market_order.quantity - matched_quantity;
                opposite_order.quantity = opposite_order.quantity - matched_quantity;
                if (market_order.quantity == 0) {
                    MarketOrders.remove(order_id);
                }
                if (opposite_order.quantity == 0) {
                    opposite_order_book.remove(opp_order_id);
                }
                if (market_order.quantity == 0) {
                    break;
                }
            }
        }
    }
}
