//! account: alice, 1000000, 0, validator
//! account: bob, 1000000, 0

//! new-transaction
//! sender: diemroot
//! execute-as: bob
script {
  
  use 0x1::Ancestry;
  use 0x1::Vector;
  use 0x1::Signer;

  fun main(alice: signer, bob: signer) {

    Ancestry::init(&alice, &bob);
    let tree = Ancestry::get_tree(Signer::address_of(&alice));

    assert(Vector::contains<address>(&tree, &Signer::address_of(&bob)), 7357001);

  }
}
// check: EXECUTED
