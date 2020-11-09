//! MinerApp Config
//!
//! See instructions in `commands.rs` to specify the path to your
//! application's configuration file and/or command-line options
//! for specifying it.

use std::fs;

use byteorder::{LittleEndian, WriteBytesExt};
use libra_types::account_address::AccountAddress;
use serde::{Deserialize, Serialize};
use abscissa_core::path::{PathBuf};
use crate::delay::delay_difficulty;
use crate::submit_tx::TxParams;
// use libra_crypto::ValidCryptoMaterialStringExt;
use ajson;

/// MinerApp Configuration
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct MinerConfig {
    /// Workspace config
    pub workspace: Workspace,
    /// User Profile
    pub profile: Profile,
    /// Chain Info for all users
    pub chain_info: ChainInfo,
}

const AUTH_KEY_BYTES: usize = 32;
const CHAIN_ID_BYTES: usize = 64;
const STATEMENT_BYTES: usize = 1008;

impl MinerConfig {
    /// Gets the dynamic waypoint from libra node's key_store.json
    pub fn get_waypoint (&self) -> String {
    let file = fs::File::open(self.get_key_store_path())
        .expect("key_store.json not found.");
    let json: serde_json::Value = serde_json::from_reader(file)
        .expect("could not parse JSON in key_store.json");
    // let wp = json.get("Waypoint")
    // .expect("file should have Waypoint key");

    let name = ajson::get(&json.to_string(), "*waypoint.value.value").expect("could not find key: waypoint");
    name.to_string()
}


    /// Get configs from a running swarm instance.
    pub fn load_swarm_config(param: &TxParams) -> Self {
        let mut conf = MinerConfig::default();
        // Load profile config
        conf.profile.account = param.address;
        conf.profile.auth_key = param.auth_key.to_string();
        // conf.profile.operator_private_key = Some(param.keypair.private_key.to_encoded_string().unwrap());
        // Load chain info
        conf.chain_info.node = Some(param.url.to_string());
        conf
    }
    /// Format the config file data into a fixed byte structure for easy parsing in Move/other languages
    pub fn genesis_preimage(&self) -> Vec<u8> {
        let mut preimage: Vec<u8> = vec![];

        let mut padded_key_bytes = match hex::decode(self.profile.auth_key.clone()) {
            Err(x) => panic!("Invalid 0L Auth Key: {}", x),
            Ok(key_bytes) => {
                if key_bytes.len() != AUTH_KEY_BYTES {
                    panic!("Expected a {} byte 0L Auth Key. Got {} bytes", AUTH_KEY_BYTES, key_bytes.len());
                }
                key_bytes
            }
        };

        preimage.append(&mut padded_key_bytes);

        let mut padded_chain_id_bytes = {
            let mut chain_id_bytes = self.chain_info.chain_id.clone().into_bytes();

            match chain_id_bytes.len() {
                d if d > CHAIN_ID_BYTES => panic!(
                    "Chain Id is longer than {} bytes. Got {} bytes", CHAIN_ID_BYTES,
                    chain_id_bytes.len()
                ),
                d if d < CHAIN_ID_BYTES => {
                    let padding_length = CHAIN_ID_BYTES - chain_id_bytes.len() as usize;
                    let mut padding_bytes: Vec<u8> = vec![0; padding_length];
                    padding_bytes.append(&mut chain_id_bytes);
                    padding_bytes
                }
                d if d == CHAIN_ID_BYTES => chain_id_bytes,
                _ => unreachable!(),
            }
        };

        preimage.append(&mut padded_chain_id_bytes);

        preimage
            .write_u64::<LittleEndian>(delay_difficulty())
            .unwrap();

        // preimage
        //     .write_u64::<LittleEndian>(delay_difficulty())
        //     .unwrap();
        let mut padded_statements_bytes = {
            let mut statement_bytes = self.profile.statement.clone().into_bytes();

            match statement_bytes.len() {
                d if d > STATEMENT_BYTES => panic!(
                    "Chain Id is longer than 1008 bytes. Got {} bytes",
                    statement_bytes.len()
                ),
                d if d < STATEMENT_BYTES => {
                    let padding_length = STATEMENT_BYTES - statement_bytes.len() as usize;
                    let mut padding_bytes: Vec<u8> = vec![0; padding_length];
                    padding_bytes.append(&mut statement_bytes);
                    padding_bytes
                }
                d if d == STATEMENT_BYTES => statement_bytes,
                _ => unreachable!(),
            }
        };

        preimage.append(&mut padded_statements_bytes);

        assert_eq!(preimage.len(), (
            AUTH_KEY_BYTES // 0L Auth_Key
                + CHAIN_ID_BYTES // chain_id
                + 8 // iterations/difficulty
                + STATEMENT_BYTES
            // statement
        ), "Preimage is the incorrect byte length");
        return preimage;
    }
    /// Get where the block/proofs are stored.
    pub fn get_block_dir(&self)-> PathBuf {
        let mut home = self.workspace.miner_home.clone();
        home.push(&self.chain_info.block_dir);
        home
    }

    /// Get where node key_store.json stored.
    pub fn get_key_store_path(&self)-> PathBuf {
        let mut home = self.workspace.miner_home.clone();
        home.push("key_store.json");
        home
    }

    // /// Get where the backlog.json are stored.
    // pub fn get_local_backlog_path(&self)-> PathBuf {
    //     let mut home = self.workspace.home.clone();
    //     home.push("backlog.json");
    //     home
    // }
}

/// Default configuration settings.
///
/// Note: if your needs are as simple as below, you can
/// use `#[derive(Default)]` on MinerConfig instead.
impl Default for MinerConfig {
    fn default() -> Self {
        Self {
            workspace: Workspace::default(),
            profile: Profile::default(),
            chain_info: ChainInfo::default(),
        }
    }
}

/// Information about the Chain to mined for
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Workspace {
    /// home directory of miner
    pub miner_home: PathBuf,
    /// home directory of the libra node, may be the same as miner.
    pub node_home: PathBuf,
}

impl Default for Workspace {
    fn default() -> Self {
        Self{
            miner_home: PathBuf::from("~/.0L/miner"),
            node_home: PathBuf::from("~/.0L/node")
        }
    }
}

/// Information about the Chain to mined for
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct ChainInfo {
    /// Chain that this work is being committed to
    pub chain_id: String,
    /// Directory to store blocks in
    pub block_dir: String,
    /// Node URL and and port to submit transactions. Defaults to localhost:8080
    pub node: Option<String>,
    /// Waypoint for last epoch which the node is syncing from.
    pub base_waypoint: Option<String>,
}

// TODO: These defaults serving as test fixtures.
impl Default for ChainInfo {
    fn default() -> Self {
        Self {
            chain_id: "experimental".to_owned(),
            block_dir: "blocks".to_owned(),
            // Mock Waypoint. Miner complains without.
            base_waypoint: None,
            node: Some("http://localhost:8080".to_owned()),
        }
    }
}
/// Miner profile to commit this work chain to a particular identity
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Profile {
    ///The 0L account for the Miner and prospective validator. This is derived from auth_key
    pub account: AccountAddress,

    ///Miner Authorization Key for 0L Blockchain. Note: not the same as public key, nor account.
    pub auth_key: String,

    // ///The 0L private_key for signing transactions.
    // pub operator_private_key: Option<String>,

    /// ip address of the miner. May be different from transaction URL.
    pub ip: Option<String>,

    ///An opportunity for the Miner to write a message on their genesis block.
    pub statement: String,
}

impl Default for Profile {
    fn default() -> Self {
        Self {
            auth_key: "".to_owned(),
            account: AccountAddress::from_hex_literal("0x0").unwrap(),
            ip: Some("0.0.0.0".to_owned()),
            statement: "Protests rage across the nation".to_owned(),
        }
    }
}
