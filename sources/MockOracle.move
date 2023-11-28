module MockOracle {

    // Function to get the price (returns a fixed value)
    public fun get_price(): u64 {
        return 10000;
    }
}
