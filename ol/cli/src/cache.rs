//! `cache`
use crate::{
    check::items::Items,
    mgmt::management::HostProcess,
    node::{account::OwnerAccountView, chain_view::ChainView, states::HostState},
};
use anyhow::Error;
use serde::{Deserialize, Serialize};
use std::{
    fs::rename,
    fs::{self, File},
    io::Write,
    path::PathBuf,
    process::exit,
};

/// caching database name, to be appended to node_home
pub const MONITOR_DB_PATH: &str = "/tmp/0L/monitor_db";

/// filename for monitor cache
pub const CACHE_JSON_NAME: &str = "monitor_cache.json";

/// filename for temp monitor cache
pub const CACHE_TEMP_NAME: &str = "monitor_cache.temp";

/// format for storing node data to json
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Vitals {
    /// healthcheck items
    pub items: Items,
    /// owner account state
    pub account_view: OwnerAccountView,
    /// chain metadata
    pub chain_view: Option<ChainView>,
    /// the node process
    pub node_proc: Option<HostProcess>,
    /// the miner process
    pub miner_proc: Option<HostProcess>,
    /// the monitor process
    pub monitor_proc: Option<HostProcess>,
    /// state of the host for state machine
    pub host_state: HostState,
}

impl Vitals {
    /// reach the json cache
    pub fn read_json(node_home: &PathBuf) -> Result<Vitals, Error> {
        let cache_path = get_cache_path(node_home);
        let file = match fs::File::open(cache_path) {
            Ok(f) => f,
            Err(e) => return Err(e)
        };
        match serde_json::from_reader(file) {
            Ok(value) => value,
            Err(e) => Err(e)
        }
    }

    /// write json cache
    pub fn write_json(&self, node_home: &PathBuf) -> Result<(), Error> {
        let serialized = serde_json::to_vec(&self)?;

        // uses temporary file to avoid listeners reading partial content
        let temp_path = node_home.join(CACHE_TEMP_NAME);
        let mut file = File::create(&temp_path)?;
        file.write_all(&serialized)?;

        // after writing temporary file renames and overwrite to cache file
        let cache_path = get_cache_path(node_home);
        match rename(temp_path, cache_path) {
            Ok(_) => Ok(()),
            Err(e) => {
                println!("Could not rename json: \nError {}", e);
                exit(1)
            },
        }
    }
}

/// Get cache path
fn get_cache_path(dir: &PathBuf) -> PathBuf {
    dir.join(CACHE_JSON_NAME)
}
