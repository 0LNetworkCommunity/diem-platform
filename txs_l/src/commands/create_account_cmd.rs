//! `CreateAccount` subcommand

#![allow(clippy::never_loop)]

use abscissa_core::{Command, Options, Runnable};
use crate::{submit_tx::{submit_tx_, eval_tx_status}};
use crate::{test_tx_swarm::get_params_from_swarm};
use std::path::PathBuf;
use std::fs;
use libra_types::{transaction::{Script}};

/// `CreateAccount` subcommand
#[derive(Command, Debug, Default, Options)]
pub struct CreateAccountCmd {
    // todo: move to upper cmd
    #[options(help = "Path of account.json")]
    waypoint: Option<String>,

    #[options(help = "Path of account.json")]
    swarm: bool,

    #[options(help = "Path of account.json")]
    account_json_path: PathBuf,
}

pub fn create_user_account_script(
    account_json_path: &str // e.g. "~/account.json"
) -> Script {
    let file = fs::File::open(account_json_path)
        .expect("file should open read only");
    let json: serde_json::Value = serde_json::from_reader(file)
        .expect("file should be proper JSON");
    let block = json.get("block_zero")
        .expect("file should have block_zero and preimage key");

    let preimage = block
        .as_object().unwrap()
        .get("preimage").unwrap()
        .as_str().unwrap();
    
    let pre_hex = hex::decode(preimage).unwrap();

    let proof = block
        .as_object().unwrap()
        .get("proof").unwrap()
        .as_str().unwrap();
    
    let proof_hex = hex::decode(proof).unwrap();
    transaction_builder::encode_create_user_account_script(pre_hex, proof_hex)
}

impl Runnable for CreateAccountCmd {    

    fn run(&self) {
        if self.swarm {
            let swarm_path = PathBuf::from("./swarm_temp");
            let tx_params = get_params_from_swarm(swarm_path).unwrap();
        } else {
            get_params_from_command_line(self.waypoint);    // todo: waypoint is Option
        }
    
        let account_json = self.account_json_path.to_str().unwrap();
        match submit_tx_(
            &tx_params, 
            create_user_account_script(account_json)
        ) {
            Err(err) => { println!("{:?}", err) }
            Ok(res)  => {
                eval_tx_status(res);
            }
        }

    }
}