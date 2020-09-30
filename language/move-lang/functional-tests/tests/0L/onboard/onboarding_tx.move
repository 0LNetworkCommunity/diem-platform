//! account: bob, 10000000GAS
//! new-transaction
//! sender: bob
script {
use 0x0::VDF;
use 0x0::LibraAccount;
use 0x0::GAS;
use 0x0::Transaction;
use 0x0::MinerState;
use 0x0::ValidatorUniverse;
// use 0x0::Debug;

fun main(_sender: &signer) {
  // Scenario: Bob, an existing validator, is sending a transaction for Zoe, with a challenge and proof not yet submitted to the chain (in genesis).

  let challenge = x"b96f38d20be65ec68d5f509d56d35010298cfd27ba6301c76ae5527fc64610b6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006578706572696d656e74616c6400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050726f74657374732072616765206163726f737320746865206e6174696f6e";

  let solution = x"0042d302b909498aa0c352eb4b4addc589f950e30b4eb4e41a9afc31e38f0eddd5923bd3ffc3d8b7ce677c81b0ad3992839578d0f1973d308dfabf687bb19808bed4deaff726c56a2e3acbcbd134ecb76ab359235cdb1b45d53ee8f5c132a788177ffdb84f6c284702cff5a33ef93fa7ff9f1ec26628302a6702cf8bdded676188ac7abc5ba15bc690e7f41bd410867b3788b3bff3c754e3375724cf7434fda0b1f7fd6124e9770dd51eb1dde72924dc8f4b6362de1931e6b7435b344010fee759412a3e1c5e8b2815c3f4573d99b567ab076dbd9502e3cadedcb7f71e84489d97ad19cf82bdaf31f9e2ea8938b3898ef3cf8dce4242c9ffd15bb9d142eaf6df7effc11fbb6c09b6b18fc002a61f6eb409ba9d08712b4652c3a79ebc3de5dffc36a2164a76a566d5ff161158ea0c7f7261f2a8c28a5d3c034a0e6bc51a6f518f8521d8b59a8105ff0321b6a38b0ba2b0d338378f7f244060833982e572b41286d34695f1aa8ced7bd02e5d64991014b7589a0cf4c9a5375fd2ad9fed40b641838df1d46273c782262def768dfc0dda191dda999db7366f0832c6793a5b53beded6bf5dfd6b0bf9353c972cb3147e912a84d1b7e3a828afeca3d766fbe31f247c7ccc36759b4990076c8adca9c09219135d0509ef8d2e492355a14982adb9dbdc6fad82b2d81fac9001d84008ff96ad4359429bf8388d7aaf331ea17ec3412c6f939100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001";
  
  // Parse key and check
  let (parsed_address, _auth_key) = VDF::extract_address_from_challenge(&challenge);
  Transaction::assert(parsed_address == 0x298cfd27ba6301c76ae5527fc64610b6, 401);

  // let difficulty = 100u64;
  // let proof = MinerState::create_proof_blob(challenge, difficulty, solution);
  // MinerState::commit_state(sender, proof);

  LibraAccount::create_validator_account_with_vdf<GAS::T>(
    &challenge,
    &solution,
  );
  Transaction::assert(LibraAccount::is_certified<LibraAccount::ValidatorRole>(parsed_address), 402);

  let tower_height = MinerState::test_helper_get_miner_state(parsed_address);
  // Transaction::assert(state ==0, 403);
  // Debug::print(&state);
  Transaction::assert(tower_height ==0, 403);

  // TODO: add_validators lacks permissions.
  // ValidatorUniverse::add_validator(parsed_address);

  //Check the validator is in the validator universe.
  let weight =  ValidatorUniverse::get_validator_weight(parsed_address);
  Transaction::assert(weight == 1, 404);

  // // Check the account exists and the balance is 0
  Transaction::assert(LibraAccount::balance<GAS::T>(parsed_address) == 0, 405);
}
}
// check: EXECUTED
