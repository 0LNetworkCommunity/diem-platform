// This test is to check if new epoch is triggered at end of 15 blocks.
// Here EPOCH-LENGTH = 15 Blocks.
// TO DO: Genesis function call to have 15 round epochs.
// NOTE: This test will fail in test-net and Production, only for Debug - due to epoch length.

// NOTE: We are creating 5 validators.
//! account: alice, 1000000, 0, validator
//! account: bob, 1000000, 0, validator
//! account: charlie, 1000000, 0, validator
//! account: diana, 1000000, 0, validator
//! account: eustance, 1000000, 0, validator
//! account: vivian, 1000000, 0, validator

//! block-prologue
//! proposer: vivian
//! block-time: 1

//! block-prologue
//! proposer: vivian
//! block-time: 2

//! block-prologue
//! proposer: vivian
//! block-time: 3

//! block-prologue
//! proposer: vivian
//! block-time: 4

//! block-prologue
//! proposer: vivian
//! block-time: 5

//! block-prologue
//! proposer: vivian
//! block-time: 6

//! block-prologue
//! proposer: vivian
//! block-time: 7

//! block-prologue
//! proposer: vivian
//! block-time: 8

//! block-prologue
//! proposer: vivian
//! block-time: 9

//! block-prologue
//! proposer: vivian
//! block-time: 10

//! block-prologue
//! proposer: vivian
//! block-time: 11

//! block-prologue
//! proposer: vivian
//! block-time: 12

//! block-prologue
//! proposer: vivian
//! block-time: 13

//! block-prologue
//! proposer: vivian
//! block-time: 14

//! block-prologue
//! proposer: vivian
//! block-time: 15
//! round: 15

// check: NewEpochEvent

//! new-transaction
//! sender: association
script {
  use 0x0::LibraBlock;
  use 0x0::Debug;
  use 0x0::Transaction;
  use 0x0::Subsidy;
  fun main(signer: &signer) {
    let block_height =  LibraBlock::get_current_block_height(); //borrow_global<BlockMetadata>(0xA550C18);
    Debug::print(&0x000000000013370000001);
    Debug::print(&block_height);
    Transaction::assert(block_height == 15, 98);

    let subsidy_units = Subsidy::calculate_Subsidy(signer, 1, 15);
    Debug::print(&subsidy_units);
    // Debug::print(&burn_units);

    }
}
// check: EXECUTED
