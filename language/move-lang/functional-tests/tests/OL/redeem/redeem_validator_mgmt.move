// Temporary tests for non-public methods written for OL. 
// Not to be executed once code is merged with OLv3

// Initialize Redeem Module
//! new-transaction
//! sender: config
script {
use 0x0::Redeem;
fun main(s: &signer) {
    Redeem::initialize(s);
}
}
// check: EXECUTED

// // Adding new validator epoch info
// //! new-transaction
// //! sender: association
// script{
// use 0x0::Redeem;
// fun main() {
//     // Borrow validator universe for modification
//     Redeem::add_validator(0xDEADBEEF);
//     Redeem::add_validator(0xDEADBEEF);
// }
// }
// // check: EXECUTED

// // Updating existing validator epoch info
// //! new-transaction
// //! sender: association
// script{
// use 0x0::Redeem;
// fun main() {
//     // Borrow validator universe for modification
//     Redeem::add_validator(0xDEADBEEF);
//     Redeem::update_validator_test(0xDEADBEEF);
//     Redeem::update_validator_test(0xDEADDEAD);
// }
// }
// // check: EXECUTED
    
