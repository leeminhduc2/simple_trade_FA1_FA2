/// Source code : https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/move-examples/fungible_asset/fa_coin/sources/FACoin.move#L147
/// A 2-in-1 module that combines managed_fungible_asset and coin_example into one module that when deployed, the
/// deployer will be creating a new managed fungible asset with the hardcoded supply config, name, symbol, and decimals.
/// The address of the asset can be obtained via get_metadata(). As a simple version, it only deals with primary stores.
module leeminhduc2::fa_coin {
    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata, FungibleAsset};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::function_info;
    use aptos_framework::dispatchable_fungible_asset;
    use std::error;
    use std::signer;
    use std::string::{Self, utf8};
    use std::option;

    /// Only fungible asset metadata owner can make changes.
    const ENOT_OWNER: u64 = 1;
    /// The FA coin is paused.
    const EPAUSED: u64 = 2;

    const ASSET_SYMBOL: vector<u8> = b"FA1";
    const ASSET_SYMBOL2: vector<u8> = b"FA2";

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Hold refs to control the minting, transfer and burning of fungible assets.
    struct ManagedFungibleAsset has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Hold refs to control the minting, transfer and burning of fungible assets.
    struct ManagedFungibleAsset2 has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Global state to pause the FA coin.
    /// OPTIONAL
    struct State has key {
        paused: bool,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Global state to pause the FA coin.
    /// OPTIONAL
    struct State2 has key {
        paused: bool,
    }

    /// Initialize metadata object and store the refs.
    // :!:>initialize
    fun init_module(admin: &signer) {
        assert!(signer::address_of(admin) == @leeminhduc2, error::permission_denied(ENOT_OWNER));
        let constructor_ref = &object::create_named_object(admin, ASSET_SYMBOL);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(),
            utf8(b"FA1 Coin"), /* name */
            utf8(ASSET_SYMBOL), /* symbol */
            8, /* decimals */
            utf8(b"http://example.com/favicon.ico"), /* icon */
            utf8(b"http://example.com"), /* project */
        );

        // Create mint/burn/transfer refs to allow creator to manage the fungible asset.
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);
        move_to(
            &metadata_object_signer,
            ManagedFungibleAsset { mint_ref, transfer_ref, burn_ref }
        ); // <:!:initialize

        // Create a global state to pause the FA coin and move to Metadata object.
        move_to(
            &metadata_object_signer,
            State { paused: false, }
        );

        
    }

    /// Initialize metadata object and store the refs.
    // :!:>initialize
    fun init_module2(admin: &signer) {
        assert!(signer::address_of(admin) == @leeminhduc2, error::permission_denied(ENOT_OWNER));
        let constructor_ref = &object::create_named_object(admin, ASSET_SYMBOL2);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(),
            utf8(b"FA2 Coin"), /* name */
            utf8(ASSET_SYMBOL2), /* symbol */
            8, /* decimals */
            utf8(b"http://example.com/favicon.ico"), /* icon */
            utf8(b"http://example.com"), /* project */
        );

        // Create mint/burn/transfer refs to allow creator to manage the fungible asset.
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);
        move_to(
            &metadata_object_signer,
            ManagedFungibleAsset2 { mint_ref, transfer_ref, burn_ref }
        ); // <:!:initialize

        // Create a global state to pause the FA coin and move to Metadata object.
        move_to(
            &metadata_object_signer,
            State2 { paused: false, }
        );

        
    }

    #[view]
    /// Return the address of the managed fungible asset that's created when this module is deployed.
    public fun get_metadata(): Object<Metadata> {
        let asset_address = object::create_object_address(&@leeminhduc2, ASSET_SYMBOL);
        object::address_to_object<Metadata>(asset_address)
    }

    #[view]
    /// Return the address of the managed fungible asset that's created when this module is deployed.
    public fun get_metadata2(): Object<Metadata> {
        let asset_address = object::create_object_address(&@leeminhduc2, ASSET_SYMBOL2);
        object::address_to_object<Metadata>(asset_address)
    }

    /// Deposit function override to ensure that the account is not denylisted and the FA coin is not paused.
    /// OPTIONAL
    public fun deposit<T: key>(
        store: Object<T>,
        fa: FungibleAsset,
        transfer_ref: &TransferRef,
    ) acquires State {
        assert_not_paused();
        fungible_asset::deposit_with_ref(transfer_ref, store, fa);
    }

    /// Deposit function override to ensure that the account is not denylisted and the FA coin is not paused.
    /// OPTIONAL
    public fun deposit2<T: key>(
        store: Object<T>,
        fa: FungibleAsset,
        transfer_ref: &TransferRef,
    ) acquires State2 {
        assert_not_paused2();
        fungible_asset::deposit_with_ref(transfer_ref, store, fa);
    }

    /// Withdraw function override to ensure that the account is not denylisted and the FA coin is not paused.
    /// OPTIONAL
    public fun withdraw<T: key>(
        store: Object<T>,
        amount: u64,
        transfer_ref: &TransferRef,
    ): FungibleAsset acquires State {
        assert_not_paused();
        fungible_asset::withdraw_with_ref(transfer_ref, store, amount)
    }

    /// Withdraw function override to ensure that the account is not denylisted and the FA coin is not paused.
    /// OPTIONAL
    public fun withdraw2<T: key>(
        store: Object<T>,
        amount: u64,
        transfer_ref: &TransferRef,
    ): FungibleAsset acquires State2 {
        assert_not_paused2();
        fungible_asset::withdraw_with_ref(transfer_ref, store, amount)
    }

    // :!:>mint
    /// Mint as the owner of metadata object.
    public entry fun mint(admin: &signer, to: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let managed_fungible_asset = authorized_borrow_refs(admin, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = fungible_asset::mint(&managed_fungible_asset.mint_ref, amount);
        fungible_asset::deposit_with_ref(&managed_fungible_asset.transfer_ref, to_wallet, fa);
    }// <:!:mint

    // :!:>mint
    /// Mint as the owner of metadata object.
    public entry fun mint2(admin: &signer, to: address, amount: u64) acquires ManagedFungibleAsset2 {
        let asset = get_metadata2();
        let managed_fungible_asset = authorized_borrow_refs2(admin, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = fungible_asset::mint(&managed_fungible_asset.mint_ref, amount);
        fungible_asset::deposit_with_ref(&managed_fungible_asset.transfer_ref, to_wallet, fa);
    }// <:!:mint

    /// Transfer as the owner of metadata object ignoring `frozen` field.
    public entry fun transfer(admin: &signer, from: address, to: address, amount: u64) acquires ManagedFungibleAsset, State {
        let asset = get_metadata();
        let transfer_ref = &authorized_borrow_refs(admin, asset).transfer_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = withdraw(from_wallet, amount, transfer_ref);
        deposit(to_wallet, fa, transfer_ref);
    }

    /// Transfer as the owner of metadata object ignoring `frozen` field.
    public entry fun transfer2(admin: &signer, from: address, to: address, amount: u64) acquires ManagedFungibleAsset2, State2 {
        let asset = get_metadata2();
        let transfer_ref = &authorized_borrow_refs2(admin, asset).transfer_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = withdraw2(from_wallet, amount, transfer_ref);
        deposit2(to_wallet, fa, transfer_ref);
    }

    /// Burn fungible assets as the owner of metadata object.
    public entry fun burn(admin: &signer, from: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let burn_ref = &authorized_borrow_refs(admin, asset).burn_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        fungible_asset::burn_from(burn_ref, from_wallet, amount);
    }

    /// Burn fungible assets as the owner of metadata object.
    public entry fun burn2(admin: &signer, from: address, amount: u64) acquires ManagedFungibleAsset2 {
        let asset = get_metadata2();
        let burn_ref = &authorized_borrow_refs2(admin, asset).burn_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        fungible_asset::burn_from(burn_ref, from_wallet, amount);
    }

    /// Pause or unpause the transfer of FA coin. This checks that the caller is the pauser.
    public entry fun set_pause(pauser: &signer, paused: bool) acquires State {
        let asset = get_metadata();
        assert!(object::is_owner(asset, signer::address_of(pauser)), error::permission_denied(ENOT_OWNER));
        let state = borrow_global_mut<State>(object::create_object_address(&@leeminhduc2, ASSET_SYMBOL));
        if (state.paused == paused) { return };
        state.paused = paused;
    }

    /// Pause or unpause the transfer of FA coin. This checks that the caller is the pauser.
    public entry fun set_pause2(pauser: &signer, paused: bool) acquires State2 {
        let asset = get_metadata2();
        assert!(object::is_owner(asset, signer::address_of(pauser)), error::permission_denied(ENOT_OWNER));
        let state = borrow_global_mut<State2>(object::create_object_address(&@leeminhduc2, ASSET_SYMBOL2));
        if (state.paused == paused) { return };
        state.paused = paused;
    }

    /// Assert that the FA coin is not paused.
    /// OPTIONAL
    fun assert_not_paused() acquires State {
        let state = borrow_global<State>(object::create_object_address(&@leeminhduc2, ASSET_SYMBOL));
        assert!(!state.paused, EPAUSED);
    }

    /// Assert that the FA coin is not paused.
    /// OPTIONAL
    fun assert_not_paused2() acquires State2 {
        let state = borrow_global<State2>(object::create_object_address(&@leeminhduc2, ASSET_SYMBOL2));
        assert!(!state.paused, EPAUSED);
    }

    /// Borrow the immutable reference of the refs of `metadata`.
    /// This validates that the signer is the metadata object's owner.
    inline fun authorized_borrow_refs(
        owner: &signer,
        asset: Object<Metadata>,
    ): &ManagedFungibleAsset acquires ManagedFungibleAsset {
        assert!(object::is_owner(asset, signer::address_of(owner)), error::permission_denied(ENOT_OWNER));
        borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
    }

    /// Borrow the immutable reference of the refs of `metadata`.
    /// This validates that the signer is the metadata object's owner.
    inline fun authorized_borrow_refs2(
        owner: &signer,
        asset: Object<Metadata>,
    ): &ManagedFungibleAsset2 acquires ManagedFungibleAsset2 {
        assert!(object::is_owner(asset, signer::address_of(owner)), error::permission_denied(ENOT_OWNER));
        borrow_global<ManagedFungibleAsset2>(object::object_address(&asset))
    }

    public entry fun trade_FA1_to_FA2(admin : &signer, user : address, amount : u64) acquires ManagedFungibleAsset, ManagedFungibleAsset2 { 
        burn(admin, user,amount);
        mint2(admin,user,amount);
    }

    public entry fun trade_FA2_to_FA1(admin : &signer, user : address, amount : u64) acquires ManagedFungibleAsset, ManagedFungibleAsset2 { 
        burn2(admin, user,amount);
        mint(admin,user,amount);
    }

    #[test(admin = @leeminhduc2,user = @0xCAFE)]  
    fun test_trade(admin : &signer, user : address) acquires ManagedFungibleAsset, ManagedFungibleAsset2 {
        init_module(admin);
        init_module2(admin);
        mint(admin,user,1000);
        trade_FA1_to_FA2(admin,user,1000);
        let asset = get_metadata();
        let asset2 = get_metadata2();
        let admin_addr =signer::address_of(admin);
         let admin_wallet = primary_fungible_store::ensure_primary_store_exists(admin_addr, asset);
         let user_wallet = primary_fungible_store::ensure_primary_store_exists(user, asset2);
         assert!(fungible_asset::balance(admin_wallet) == 0,1);
         assert!(fungible_asset::balance(user_wallet) == 1000,2);
    
        
    }

    
}