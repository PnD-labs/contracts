module gmi::amm_swap {
    use sui::object::{Self, UID};
    use sui::coin::{Self, Coin};
    use sui::sui::{SUI};
    
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self,Balance};
    use sui::event::{Self};
    use sui::pay::{Self};
    use gmi::coin_factory::{Self,AdminCap};
    use gmi::amm_config::{Self,Config};
    use gmi::amm_math::{Self};
    use gmi::amm_utils::{Self};
    //@@gmi pool is don't have lp token
    public struct Pool<phantom MemeCoin> has key {
        id: UID,
        reserve_a: Balance<MemeCoin>,
        reserve_b: Balance<SUI>,
        //Locked if pool is $69K or more.
        lock:bool,
    }

    //@@ Event
    public struct MakePoolEvent has copy,drop{
        sender:address,
        pool_id:ID,
        
    }

    public struct SwapEvent has copy,drop{
        sender:address,
        pool_id:ID,
        amount_a_in:u64,
        amount_a_out:u64,
        amount_b_in:u64,
        amount_b_out:u64,
        reserve_a:u64,
        reserve_b:u64,
    }
    
    const ECoinInsufficient: u64 = 0;

    // Entry function to mint a new coin and initialize a liquidity pool
    entry public  fun mint_input_coin_init_pool(
        admin_cap:&mut AdminCap,
        config: &Config,
        sui_token: Coin<SUI>,
        symbol: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        // icon_url: vector<u8>,
        ctx: &mut TxContext
    ) {
        let mut sui_token = sui_token;
        // Split the SUI token based on the mint fee specified in the config

        let mint_fee = coin::split(&mut sui_token, amm_config::get_mint_fee(config), ctx);
        coin_factory::add_fee_balance(admin_cap,mint_fee.into_balance());       
        
        let meme_coin = coin_factory::create_coin(config,symbol, name, description, ctx);
        let pool = make_pool(meme_coin,sui_token, ctx);
        let pool_id = object::id(&pool);

        transfer::share_object(pool);
        event::emit(MakePoolEvent {
            sender: tx_context::sender(ctx),
            pool_id,
        })
    }

    fun make_pool<MemeCoin>(
        meme_coin: Coin<MemeCoin>,
        sui_token: Coin<SUI>,
        ctx: &mut TxContext
    ):Pool<MemeCoin>{
        let pool = Pool<MemeCoin>{
            id: object::new(ctx),
            reserve_a: coin::into_balance(meme_coin),
            reserve_b: coin::into_balance(sui_token),
            lock:false,
        };
        pool
    }


    entry public fun swap_coinA_to_coinB<MemeCoin>(pool: &mut Pool<MemeCoin>, config: &Config, input_coin: Coin<MemeCoin>, ctx: &mut TxContext) {
        let swap_amount = input_coin.value();
        let (reserve_a,reserve_b) = pool.get_reserves();
        let (swap_fee_numerator,swap_fee_denominator) = amm_config::get_swap_fee(config);
    
        assert!(swap_amount > config.get_minimum_swap_amount(), ECoinInsufficient);
        
        let out_amount = amm_utils::get_amount_out(reserve_a,reserve_b,swap_amount, swap_fee_denominator,swap_fee_numerator, true);
        
        let out_coin = coin::from_balance(pool.reserve_b.split(out_amount), ctx);
        
        pool.reserve_a.join(coin::into_balance(input_coin));
        pay::keep(out_coin, ctx);
        event::emit(SwapEvent {
            sender: tx_context::sender(ctx),
            pool_id: object::id(pool),
            amount_a_in:swap_amount,
            amount_a_out:0,
            amount_b_in:0,
            amount_b_out:out_amount,
            reserve_a,
            reserve_b,
        });
    }


    entry public fun swap_coinB_to_coinA<MemeCoin>(pool: &mut Pool<MemeCoin>, config: &Config, input_coin: Coin<SUI>, ctx: &mut TxContext) {
        let swap_amount = input_coin.value();
        let (reserve_a,reserve_b) = pool.get_reserves();
        let (swap_fee_numerator,swap_fee_denominator) = amm_config::get_swap_fee(config);


        assert!(swap_amount > config.get_minimum_swap_amount(), ECoinInsufficient);
        
        let out_amount =  amm_utils::get_amount_out(reserve_a,reserve_b,swap_amount, swap_fee_denominator,swap_fee_numerator,false);
        
        let out_coin = coin::from_balance(pool.reserve_b.split(out_amount), ctx);
        pool.reserve_b.join(coin::into_balance(input_coin));
        pay::keep(out_coin, ctx);
        event::emit(SwapEvent {
            sender: tx_context::sender(ctx),
            pool_id: object::id(pool),
            amount_a_in:0,
            amount_a_out:out_amount,
            amount_b_in:swap_amount,
            amount_b_out:0,
            reserve_a,
            reserve_b,
        });
    }
    
    public fun get_reserves<MemeCoin>(pool: &Pool<MemeCoin>) : (u64,u64) {
        let reserve_a = balance::value(&pool.reserve_a);
        let reserve_b = balance::value(&pool.reserve_b);
        (reserve_a,reserve_b)
    }

}
