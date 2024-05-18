
/// Module: memefactory
module gmi::coin_factory {
    use sui::tx_context::{TxContext};
    use sui::coin::{Self,Coin,TreasuryCap};
    use sui::balance::{Self,Balance};
    use sui::sui::{SUI};
    use sui::transfer::{Self};
    use sui::url::{Self,Url};
    use sui::object::{Self,UID,ID};
    use sui::event::{Self};
    use sui::pay;
    use gmi::amm_config::{Self,Config};
    // friend gmi::amm_swap;
    
    public struct AdminCap has key{
        id:UID,
        admin:address,
        fee_balance:Balance<SUI>,
    }

    public struct MemeCoin has drop{}
 
    public struct InitEvent has copy,drop{
        admin_cap_id:ID,
    }

    public struct CreateCoinEvent has copy,drop{
        symbol:vector<u8>,
        name:vector<u8>,
        description:vector<u8>,
        // icon_url:Url,
        coin_cap_id:ID,
        coin_metadata_id:ID,
        creator:address,
    }

    public struct BurnCoinEvent has copy,drop{
        coin_cap_id:ID,
        amount:u64
    }

    

    fun init(ctx:&mut TxContext){
        let admin_cap = AdminCap{
            id:object::new(ctx),
            admin:tx_context::sender(ctx),
            fee_balance:balance::zero()
        };
        let admin_cap_id = object::id(&admin_cap);
        transfer::share_object(admin_cap);
        event::emit(InitEvent{
            admin_cap_id
        });
    }

    
    public(package) fun create_coin(
        config:&Config,
        symbol: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        // icon_url: Option<vector<u8>>,
        ctx: &mut TxContext
    ):Coin<MemeCoin> {
        
        // // 코인과 메타데이터를 생성합니다.
        // let (mut coin_cap, coin_metadata) = coin::create_currency(
        //     MemeCoin{},
        //     config.get_mint_decimal(),
        //     symbol,
        //     name,
        //     description,
        //     option::some(url::new_unsafe_from_bytes(icon_url)),
        //     ctx
        // );
         let (mut coin_cap, coin_metadata) = coin::create_currency(
            MemeCoin{},
            config.get_mint_decimal(),
            symbol,
            name,
            description,
            option::none(),
            ctx
        );

        let coin = mint(&mut coin_cap,config.get_mint_total_supply(), ctx);
        // 코인 생성 이벤트를 발행합니다.
        let coin_cap_id = object::id(&coin_cap);
        let coin_metadata_id = object::id(&coin_metadata);
    
        transfer::public_freeze_object(coin_metadata);

        transfer::public_share_object(coin_cap);

        event::emit(CreateCoinEvent {
            symbol,
            name,
            description,
            // icon_url: url::new_unsafe_from_bytes(icon_url),
            coin_cap_id,
            coin_metadata_id,
            creator:tx_context::sender(ctx)
        });
        coin
    }

    fun mint(cap:&mut TreasuryCap<MemeCoin>,amount:u64,ctx:&mut TxContext):Coin<MemeCoin>{
        coin::mint<MemeCoin>(cap,amount,ctx)
    }
    public(package) fun add_fee_balance(admin_cap:&mut AdminCap,balance:Balance<SUI>){
        balance::join(&mut admin_cap.fee_balance,balance);
    }
    entry public fun burn(cap:&mut TreasuryCap<MemeCoin>,token:Coin<MemeCoin>){
        let amount = coin::value(&token);
        
        balance::decrease_supply(coin::supply_mut(cap),coin::into_balance(token));
        //@@ burn event 추가
        event::emit(BurnCoinEvent{
            coin_cap_id:object::id(cap),
            amount
        });
    }

    entry public fun claim_fee(admin_cap: &mut AdminCap,ctx: &mut TxContext) {
        let amount = admin_cap.fee_balance.value();
        let fee_coin = coin::from_balance(admin_cap.fee_balance.split(amount),ctx);
        pay::keep(fee_coin, ctx);
    }

    //transfer 랑 merge 랑 split 있어야함?

}

