// In this test only alice mines.

//! account: alice, 1, 0, validator
//! account: bob, 1, 0, validator
//! account: carol, 1, 0, validator
//! account: dave, 1, 0, validator
//! account: eve, 1, 0, validator

// All nodes except Eve mined above threshold. 

//! new-transaction
//! sender: alice
script {
    use 0x0::Transaction::assert;
    use 0x0::MinerState;

    fun main(sender: &signer) {
        // Alice is the only one that can update her mining stats. Hence this first transaction.

        MinerState::test_helper_mock_mining(sender, 5);
        assert(MinerState::test_helper_get_count({{alice}}) == 5, 7357300101011000);
    }
}
//check: EXECUTED

//! new-transaction
//! sender: association
script {
    use 0x0::Vector;
    use 0x0::Transaction;
    use 0x0::NodeWeight;
    use 0x0::ValidatorUniverse;
    // use 0x0::Stats;
    use 0x0::MinerState;

    fun main(vm: &signer) {

        // Base Case: If validator universe vector length is less than the validator set size limit (N), return vector itself.
        // N equals to the vector length.

        //Check the size of the validator universe.
        let vec =  ValidatorUniverse::get_eligible_validators(vm);
        let len = Vector::length<address>(&vec);
        Transaction::assert(len == 5, 7357140102011000);

        MinerState::reconfig(vm);

        // This is the base case: check case of the validator set limit being less than universe size.
        let top_n_is_under = NodeWeight::top_n_accounts(vm, 3);
        Transaction::assert(Vector::length<address>(&top_n_is_under) == 3, 7357140102021000);

        // Check eve is NOT in that list.
        Transaction::assert(Vector::contains<address>(&top_n_is_under, &{{eve}}) != true, 7357140102031000);
        Transaction::assert(Vector::contains<address>(&top_n_is_equal, &{{alice}}), 7357140102051000);
        // case of querying the full validator universe.
        let top_n_is_equal = NodeWeight::top_n_accounts(vm, len);
        // One of the nodes did not vote, so they will be excluded from list.

        Transaction::assert(Vector::length<address>(&top_n_is_equal) == len, 7357140102041000);

        // Check eve IS on that list.
        Transaction::assert(Vector::contains<address>(&top_n_is_equal, &{{eve}}), 7357140102051000);
        
        // case of querying a larger n than the validator universe.
        // Check if we ask for a larger set we also get 
        let top_n_is_over = NodeWeight::top_n_accounts(vm, 9);
        Transaction::assert(Vector::length<address>(&top_n_is_over) == len, 7357140102061000);

        // Check eve IS on that list.
        Transaction::assert(Vector::contains<address>(&top_n_is_equal, &{{eve}}), 7357140102051000);

    }
}
// check: EXECUTED