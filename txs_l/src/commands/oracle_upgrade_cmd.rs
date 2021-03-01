//! `OracleUpgrade` subcommand

#![allow(clippy::never_loop)]

use abscissa_core::{Command, Options, Runnable};
use crate::{submit_tx::{submit_tx_, eval_tx_status}};
use crate::{test_tx_swarm::get_params_from_swarm};
use std::path::PathBuf;
use std::fs;
use std::io::prelude::*;
use libra_types::{transaction::{Script}};

/// `OracleUpgrade` subcommand
#[derive(Command, Debug, Default, Options)]
pub struct OracleUpgradeCmd {
    #[options(help = "Path of upgrade file")]
    upgrade_file_path: PathBuf,
}

pub fn oracle_tx_script(
    upgrade_file_path: &str // e.g. "../libra/fixtures/upgrade_payload/foo_stdlib.mv"
) -> Script {
    let mut file = fs::File::open(upgrade_file_path)
        .expect("file should open read only");
    let mut buffer = Vec::new();
    file.read_to_end(&mut buffer).expect("failed to read the file");

    let id = 1; // upgrade is oracle #1
    transaction_builder::encode_ol_oracle_tx_script(id, buffer)
}

impl Runnable for OracleUpgradeCmd {    

    fn run(&self) {
        let swarm_path = PathBuf::from("./swarm_temp");
        let tx_params = get_params_from_swarm(swarm_path).unwrap();
    
        let upgrade_file = self.upgrade_file_path.to_str().unwrap();
        match submit_tx_(
            &tx_params, 
            oracle_tx_script(upgrade_file)
        ) {
            Err(err) => { println!("{:?}", err) }
            Ok(res)  => {
                eval_tx_status(res);
            }
        }

    }
}
