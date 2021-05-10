//! `items`
use std::str;
use serde::{Deserialize, Serialize};

use crate::mgmt::management::NodeMode;
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
/// Healthcheck summary items
pub struct Items {
  /// node configs created
  pub configs_exist: bool,
  /// are there db files
  pub db_files_exist: bool,
  /// is the db boostrapped
  // TODO: Change the name to db_bootstrapped, requires changes to web.
  pub db_restored: bool,
  /// account created
  pub account_created: bool,
  /// node running
  pub node_running: bool,
  /// miner running
  pub miner_running: bool,
  /// web serving
  pub web_running: bool,
  /// node mode
  pub node_mode: Option<NodeMode>,
  /// is the blockchain in sync with upstream
  pub is_synced: bool,
  /// how far behind is the node
  pub sync_delay: i64,
  /// is in the validator set
  pub validator_set: bool,
}

impl Default for Items {
  fn default() -> Self {
    Self {
      configs_exist: false,
      db_restored: false,
      account_created: false,
      node_running: false,
      miner_running: false,
      is_synced: false,
      sync_delay: 0,
      validator_set: false,
      db_files_exist: false,
      web_running: false,
      node_mode: None,
    }
  }
}

impl Items {
  /// Get new object
  pub fn new(is_synced: bool) -> Self {
    Self {
      is_synced,
      ..Self::default()
    }
  }
}