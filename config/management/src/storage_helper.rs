// Copyright (c) The Libra Core Contributors
// SPDX-License-Identifier: Apache-2.0

use libra_global_constants::{
    CONSENSUS_KEY, EPOCH, FULLNODE_NETWORK_KEY, LAST_VOTED_ROUND, OPERATOR_KEY, OWNER_KEY,
    PREFERRED_ROUND, VALIDATOR_NETWORK_KEY, WAYPOINT,
};
use libra_secure_storage::{NamespacedStorage, OnDiskStorage, Storage, Value};
use libra_wallet::{
    key_factory::{ChildNumber, KeyFactory, Seed},
    Mnemonic,
};
use std::{
    fs::File,
    path::PathBuf,
};

pub fn key_scheme(mnemonic: String) -> (ExtendedPrivKey, ExtendedPrivKey,ExtendedPrivKey, ExtendedPrivKey) {
        let seed = Seed::new(&Mnemonic::from(&mnemonic).unwrap(), "0L");
        let kf = KeyFactory::new(&seed).unwrap();
        let child_0_owner_operator = kf.private_child(ChildNumber::new(0)).unwrap();
        let child_1_consensus = kf.private_child(ChildNumber::new(1)).unwrap();
        let child_2_val_network = kf.private_child(ChildNumber::new(2)).unwrap();
        let child_3_fullnode_network = kf.private_child(ChildNumber::new(3)).unwrap();
        (child_0_owner_operator, child_1_consensus, child_2_val_network, child_3_fullnode_network)
    }

pub struct PubKeys{
    pub operator_key: Ed25519PublicKey,
    pub validator_network_key: PublicKey,
    pub consensus_key: Ed25519PublicKey,
    pub fullnode_network_key: PublicKey,
}

impl PubKeys {
    pub fn new_from_mnemonic(&self, mnemonic: String) {
        let (child_0_owner_operator, child_1_consensus, child_2_val_network, child_3_fullnode_network) = key_scheme(new_from_mnemonic);
        self.operator_key = child_0_owner_operator;
        self.consensus_key = child_1_consensus;
        self.validator_network_key = child_2_val_network;
        self.fullnode_network_key = child_3_fullnode_network;
    }
}

pub struct StorageHelper {
    temppath: libra_temppath::TempPath,
}

impl StorageHelper {
    #[cfg(test)]
    pub fn new() -> Self {
        let temppath = libra_temppath::TempPath::new();
        temppath.create_as_file().unwrap();
        File::create(temppath.path()).unwrap();
        Self { temppath }
    }

    pub fn new_with_path(path: PathBuf) -> Self {
        let path = libra_temppath::TempPath::new_with_dir(path);
        path.create_as_file().unwrap();
        File::create(path.path()).unwrap();
        Self { temppath: path }
    }

    pub fn storage(&self, namespace: String) -> Box<dyn Storage> {
        let storage = OnDiskStorage::new(self.temppath.path().to_path_buf());
        Box::new(NamespacedStorage::new(storage, namespace))
    }

    #[cfg(test)]
    pub fn path(&self) -> &Path {
        self.temppath.path()
    }

    #[cfg(test)]
    pub fn path_string(&self) -> &str {
        self.temppath.path().to_str().unwrap()
    }

    #[cfg(test)]
    pub fn initialize(&self, namespace: String) {
        let mut storage = self.storage(namespace);

        // storage.create_key(ASSOCIATION_KEY).unwrap();
        storage.create_key(CONSENSUS_KEY).unwrap();
        storage.create_key(FULLNODE_NETWORK_KEY).unwrap();
        storage.create_key(OWNER_KEY).unwrap();
        storage.create_key(OPERATOR_KEY).unwrap();
        storage.create_key(VALIDATOR_NETWORK_KEY).unwrap();

        storage.set(EPOCH, Value::U64(0)).unwrap();
        storage.set(LAST_VOTED_ROUND, Value::U64(0)).unwrap();
        storage.set(PREFERRED_ROUND, Value::U64(0)).unwrap();
        storage.set(WAYPOINT, Value::String("".into())).unwrap();
    }

    pub fn initialize_with_mnemonic(&self, namespace: String, mnemonic: String) {
        // let seed = Seed::new(&Mnemonic::from(&mnemonic).unwrap(), "0L");

        // let kf = KeyFactory::new(&seed).unwrap();
        // let child_0 = kf.private_child(ChildNumber::new(0)).unwrap();
        // let child_1 = kf.private_child(ChildNumber::new(1)).unwrap();
        // let child_2 = kf.private_child(ChildNumber::new(2)).unwrap();
        // let child_3 = kf.private_child(ChildNumber::new(3)).unwrap();
        // let child_4 = kf.private_child(ChildNumber::new(4)).unwrap();
        let (child_0, child_1, child_2, child_3) = key_scheme(mnemonic);

        let authentication_key = child_0.get_authentication_key();
        println!("===== \nAuthentication Key:\n{:?}", authentication_key.to_string());

        let mut storage = self.storage(namespace);

        storage
            .import_private_key(OWNER_KEY, child_0.export_priv_key())
            .unwrap();
        storage
            .import_private_key(OPERATOR_KEY, child_0.export_priv_key())
            .unwrap();
        storage
            .import_private_key(CONSENSUS_KEY, child_1.export_priv_key())
            .unwrap();
        storage
            .import_private_key(VALIDATOR_NETWORK_KEY, child_2.export_priv_key())
            .unwrap();
        storage
            .import_private_key(FULLNODE_NETWORK_KEY, child_3.export_priv_key())
            .unwrap();

        storage.set(EPOCH, Value::U64(0)).unwrap();
        storage.set(LAST_VOTED_ROUND, Value::U64(0)).unwrap();
        storage.set(PREFERRED_ROUND, Value::U64(0)).unwrap();
        storage.set(WAYPOINT, Value::String("".into())).unwrap();
    }

    #[cfg(test)]
    pub fn association_key(
        &self,
        local_ns: &str,
        remote_ns: &str,
    ) -> Result<Ed25519PublicKey, Error> {
        let args = format!(
            "
                management
                association-key
                --local backend={backend};\
                    path={path};\
                    namespace={local_ns}
                --remote backend={backend};\
                    path={path};\
                    namespace={remote_ns}\
            ",
            backend = crate::secure_backend::DISK,
            path = self.path_string(),
            local_ns = local_ns,
            remote_ns = remote_ns,
        );

        let command = Command::from_iter(args.split_whitespace());
        command.association_key()
    }

    #[cfg(test)]
    pub fn create_waypoint(&self, remote_ns: &str) -> Result<Waypoint, Error> {
        let args = format!(
            "
                management
                create-waypoint
                --local backend={backend};\
                    path={path}
                --remote backend={backend};\
                    path={path};\
                    namespace={remote_ns}\
            ",
            backend = crate::secure_backend::DISK,
            path = self.path_string(),
            remote_ns = remote_ns,
        );

        let command = Command::from_iter(args.split_whitespace());
        command.create_waypoint()
    }

    #[cfg(test)]
    pub fn genesis(&self, genesis_path: &Path) -> Result<Transaction, Error> {
        let args = format!(
            "
                management
                genesis
                --backend backend={backend};\
                    path={path}
                --path {genesis_path}
            ",
            backend = crate::secure_backend::DISK,
            path = self.path_string(),
            genesis_path = genesis_path.to_str().expect("Unable to parse genesis_path"),
        );

        let command = Command::from_iter(args.split_whitespace());
        command.genesis()
    }

    #[cfg(test)]
    pub fn operator_key(&self, local_ns: &str, remote_ns: &str) -> Result<Ed25519PublicKey, Error> {
        let args = format!(
            "
                management
                operator-key
                --local backend={backend};\
                    path={path};\
                    namespace={local_ns}
                --remote backend={backend};\
                    path={path};\
                    namespace={remote_ns}\
            ",
            backend = crate::secure_backend::DISK,
            path = self.path_string(),
            local_ns = local_ns,
            remote_ns = remote_ns,
        );

        let command = Command::from_iter(args.split_whitespace());
        command.operator_key()
    }

    #[cfg(test)]
    pub fn owner_key(&self, local_ns: &str, remote_ns: &str) -> Result<Ed25519PublicKey, Error> {
        let args = format!(
            "
                management
                owner-key
                --local backend={backend};\
                    path={path};\
                    namespace={local_ns}
                --remote backend={backend};\
                    path={path};\
                    namespace={remote_ns}\
            ",
            backend = crate::secure_backend::DISK,
            path = self.path_string(),
            local_ns = local_ns,
            remote_ns = remote_ns,
        );

        let command = Command::from_iter(args.split_whitespace());
        command.owner_key()
    }

    #[cfg(test)]
    pub fn set_layout(&self, path: &str, namespace: &str) -> Result<crate::layout::Layout, Error> {
        let args = format!(
            "
                management
                set-layout
                --path {path}
                --backend backend={backend};\
                    path={storage_path};\
                    namespace={ns}
            ",
            path = path,
            backend = crate::secure_backend::DISK,
            storage_path = self.path_string(),
            ns = namespace,
        );

        let command = Command::from_iter(args.split_whitespace());
        command.set_layout()
    }

    #[cfg(test)]
    pub fn mining(&self, path: &str, namespace: &str) -> Result<String, Error> {
        let args = format!(
            "
                management
                mining
                --path-to-genesis-pow {path}
                --backend backend={backend};\
                    path={storage_path};\
                    namespace={ns}
            ",
            path = path,
            backend = crate::secure_backend::DISK,
            storage_path = self.path_string(),
            ns = namespace,
        );

        let command = Command::from_iter(args.split_whitespace());
        command.mining()
    }
    #[cfg(test)]
    pub fn validator_config(
        &self,
        owner_address: AccountAddress,
        validator_address: NetworkAddress,
        fullnode_address: NetworkAddress,
        local_ns: &str,
        remote_ns: &str,
    ) -> Result<Transaction, Error> {
        let args = format!(
            "
                management
                validator-config
                --owner-address {owner_address}
                --validator-address {validator_address}
                --fullnode-address {fullnode_address}
                --local backend={backend};\
                    path={path};\
                    namespace={local_ns}
                --remote backend={backend};\
                    path={path};\
                    namespace={remote_ns}\
            ",
            owner_address = owner_address,
            validator_address = validator_address,
            fullnode_address = fullnode_address,
            backend = crate::secure_backend::DISK,
            path = self.path_string(),
            local_ns = local_ns,
            remote_ns = remote_ns,
        );

        let command = Command::from_iter(args.split_whitespace());
        command.validator_config()
    }
    #[cfg(test)]
    pub fn verify(&self, namespace: &str) -> Result<String, Error> {
        let args = format!(
            "
                management
                verify
                --backend backend={backend};\
                    path={path};\
                    namespace={ns}
            ",
            backend = crate::secure_backend::DISK,
            path = self.path_string(),
            ns = namespace,
        );

        let command = Command::from_iter(args.split_whitespace());
        command.verify()
    }

    #[cfg(test)]
    pub fn verify_genesis(&self, namespace: &str, genesis_path: &Path) -> Result<String, Error> {
        let args = format!(
            "
                management
                verify
                --backend backend={backend};\
                    path={path};\
                    namespace={ns}
                --genesis-path {genesis_path}
            ",
            backend = crate::secure_backend::DISK,
            path = self.path_string(),
            ns = namespace,
            genesis_path = genesis_path.to_str().expect("Unable to parse genesis_path"),
        );

        let command = Command::from_iter(args.split_whitespace());
        command.verify()
    }
}
