//! account: dummy-prevents-genesis-reload, 100000 ,0, validator

//! new-transaction
script{
use 0x1::VDF;
// use 0x1::Debug;
fun main() {

  // this tests the happy case, that a proof is submitted with all three correct parameters.

  let challenge: vector<u8>;
  let difficulty: u64;
  let solution: vector<u8>;
  let re: bool;

  difficulty = 100;
  challenge = x"cb7f5980bed306ab05817ed345dd2dd0fff1d6c28e8288479eac78cf2eda7922000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304c20746573746e65746400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050726f74657374732072616765206163726f737320746865206e6174696f6e";
  // Generate solutions with cd ./verfiable_delay/vdf-cli && cargo run -- -l=4096 aa 100
  // the -l=4096 is important because this is the security paramater of 0L miner.
  solution = x"0011a9a21f9b26934d21e10aa46fc1c030f2c68168d9148fc21b8ac475c5167b8ef859313bf9bb00e2b0b4a8aed14f95d817be8c0707a77d9039e9fd0c0c89a8e50d38ba88b2afc69966220ce966688ccdcde0910509e5ff3a68ca448caa82674d28a3f1f769cb330b01dd9dccfd155a022f3fd656ccc268ff3d07616aad0341b0fff58151d52a003b254ac18acc9941dce45e74653c38c80914eb93790dbc854295392b2218defcc9b6b7a6a6d15d43e02a341f1a09d3a0004383fe3e243439f6148f4d79b9a8b94a3ed4f93e71b293e61ff8d13348ad7082b19e21c92dea68b71af9c88f37d4cf9fc38b1efb178745735917afbae78d221ce9231e2824dbd52185000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001";

  re = VDF::verify(&challenge, &difficulty, &solution);
  // Debug::print<bool>(&re);
  assert(move re == true, 1);
}
}
