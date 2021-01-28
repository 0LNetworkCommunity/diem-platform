script {
  use 0x1::AutoPay;
  use 0x1::Signer;
  fun autopay_create_instruction(
    sender: &signer,
    payee: address,
    end_epoch: u64,
    percentage: u64,
  ) {
    let account = Signer::address_of(sender);
    assert(AutoPay::is_enabled(account), 0);
    AutoPay::create_instruction(
      sender, 
      payee,
      end_epoch,
      percentage,
    );
  }
}