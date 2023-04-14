address DiemFramework {
module WalletScripts {

    use DiemFramework::DonorDirected;
    use DiemFramework::DiemAccount;

    public(script) fun set_wallet_type(sender: signer, type_of: u8) {
      if (type_of == 0) {
        DiemAccount::set_slow(&sender);
      };

      // sets a donor directed wallet
      // assumes the funds return to donor, not to infra escrow
      // user can send another transaction to change this.
      if (type_of == 1) {
          DonorDirected::set_donor_directed(&sender, false);
      };
    }
}
}