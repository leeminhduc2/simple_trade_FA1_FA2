module leeminhduc2::simple_trade_example {
    use std::error;
    use std::option;
    use std::signer;
    use std::string::utf8;

    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata, FungibleAsset};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::resource_account;
    use aptos_framework::account;

    /// Only fungible asset metadata owner can make changes.
    const ENOT_OWNER: u64 = 1;
    /// The FA coin is paused.
    const EPAUSED: u64 = 2;

    const ASSET_SYMBOL: vector<u8> = b"FA";

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Hold refs to control the minting, transfer and burning of fungible assets.
    struct ManagedFungibleAsset has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef,
    }

    struct ModuleData has key {
        // Storing the signer capability here, so the module can programmatically sign for transactions
        admin_cap: SignerCapability,
    }

    fun init_module(admin : &signer) {
        // Retrieve the resource signer's signer capability and store it within the `ModuleData`.
        // Note that by calling `resource_account::retrieve_resource_account_cap` to retrieve the resource account's signer capability,
        // we rotate th resource account's authentication key to 0 and give up our control over the resource account. Before calling this function,
        // the resource account has the same authentication key as the source account so we had control over the resource account.
        let admin_cap = resource_account::retrieve_resource_account_cap(admin, @source_account);

        // Store the token data id and the resource account's signer capability within the module, so we can programmatically
        // sign for transactions in the `mint_event_ticket()` function.
        move_to(admin, ModuleData {
            admin_cap,
        });

    }

    // Register a new fungible asset named "name" and create a primary fungible store along with a KOL creator stake pool.
    fun register_stake_pool(admin: &signer, name: vector<u8>) {
        let constructor_ref = &object::create_named_object(admin, name);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(),
            utf8(name), /* name */
            utf8(ASSET_SYMBOL), /* symbol */
            8, /* decimals */
            utf8(b"http://example.com/favicon.ico"), /* icon */
            utf8(b"http://example.com"), /* project */
        );

        // Create mint/burn/transfer refs to allow user to manage the fungible asset.
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);
        move_to(
            &metadata_object_signer,
            ManagedFungibleAsset { mint_ref, transfer_ref, burn_ref }
        );
    }

    // Register a new fungible asset named "name" and create a primary fungible store
    public fun register(user : &signer, name : vector<u8>) acquires ModuleData {
        register_stake_pool(&get_resource_signer(), name);
        let asset = get_metadata(name);
        primary_fungible_store::ensure_primary_store_exists(signer::address_of(user), asset);
    }

    fun get_resource_signer() : signer acquires ModuleData {
        let module_data = borrow_global_mut<ModuleData>(@leeminhduc2);
        // Create a signer of the resource account from the signer capability stored in this module.
        // Using a resource account and storing its signer capability within the module allows the module to programmatically
        // sign transactions on behalf of the module.
        account::create_signer_with_capability(&module_data.admin_cap)
    }

    #[view]
    public fun get_metadata(name : vector<u8>) : Object<Metadata> {
        let asset_address = object::create_object_address(&@leeminhduc2, name);
        object::address_to_object<Metadata>(asset_address)
    }


    // :!:>mint
    /// Mint as the owner of metadata object.
    fun mint(name : vector<u8>, to : address, amount: u64) acquires ManagedFungibleAsset, ModuleData {
        let asset = get_metadata(name);
        let managed_fungible_asset = authorized_borrow_refs(&get_resource_signer(), asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = fungible_asset::mint(&managed_fungible_asset.mint_ref, amount);
        fungible_asset::deposit(to_wallet, fa);
    }// <:!:mint

    /// Transfer specific types of token between users
    public entry fun transfer(from: &signer, to: address, name : vector<u8>, amount: u64) {
        let from_address = signer::address_of(from);
        let asset = get_metadata(name);
        let from_wallet = primary_fungible_store::primary_store(from_address, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = fungible_asset::withdraw(from,from_wallet, amount);
        fungible_asset::deposit(to_wallet, fa);
    }

    /// Borrow the immutable reference of the refs of `metadata `.
    /// This validates that the signer is the metadata object's owner.
    inline fun authorized_borrow_refs(
        owner: &signer,
        asset: Object<Metadata>,
    ): &ManagedFungibleAsset acquires ManagedFungibleAsset {
        assert!(object::is_owner(asset, signer::address_of(owner)), error::permission_denied(ENOT_OWNER));
        borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
    }

    public entry fun trade(from : &signer, asset_from_name : vector<u8>, asset_to_name : vector<u8>, amount: u64) acquires ModuleData, ManagedFungibleAsset {
        transfer(from, @leeminhduc2, asset_from_name, amount);
        mint(asset_to_name, signer::address_of(from), amount);
    }

    #[test(user1 = @0xCAFE, user2 = @0xBEEF)]
    fun test_trade(user1 : &signer, user2 : &signer) acquires ModuleData, ManagedFungibleAsset {
        let user1_coin_name = b"KOL1";
        let user2_coin_name = b"KOL2";
        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);


        register(user1, user1_coin_name);
        register(user2, user2_coin_name);

        let metadata1 = get_metadata(user1_coin_name);
        let metadata2 = get_metadata(user2_coin_name);

        mint(user1_coin_name, user1_address, 1000);
        mint(user2_coin_name, user2_address, 500);

        trade(user1, user1_coin_name, user2_coin_name, 100);

        let user1_fa1_wallet = primary_fungible_store::primary_store(user1_address, metadata1);
        let user1_fa2_wallet = primary_fungible_store::primary_store(user1_address, metadata2);
        let user2_fa1_wallet = primary_fungible_store::primary_store(user2_address, metadata1);
        let user2_fa2_wallet = primary_fungible_store::primary_store(user2_address, metadata2);

        assert!(fungible_asset::balance(user1_fa1_wallet) == 900,1);
        assert!(fungible_asset::balance(user1_fa2_wallet) == 100,2);
        assert!(fungible_asset::balance(user2_fa1_wallet) == 100,3);
        assert!(fungible_asset::balance(user2_fa2_wallet) == 400,4);

    }

}