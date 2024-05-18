module gmi::amm_swap {
    use sui::object::{Self, UID};
    use sui::coin::{Self, Coin};
    use sui::sui::{SUI};
    
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self,Balance};
    use sui::event::{Self};
    use sui::pay::{Self};
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
        meme_in_amount:u64,
        meme_out_amount:u64,
        sui_in_amount:u64,
        sui_out_amount:u64,
        reserve_meme:u64,
        reserve_sui:u64,
    }
    
    const ECoinInsufficient: u64 = 0;

    // Entry function to mint a new coin and initialize a liquidity pool
    entry public  fun init_pool<MemeCoin>(
        config: &Config,
        x:Coin<MemeCoin>,
        y: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        //@@balance check 
        
        let pool = make_pool(x,y, ctx);
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


    entry public fun sell_meme_coin<MemeCoin>(pool: &mut Pool<MemeCoin>, config: &Config, input_coin: Coin<MemeCoin>, ctx: &mut TxContext) {
        let swap_amount = input_coin.value();
        let (reserve_meme,reserve_sui) = pool.get_reserves();
        let (swap_fee_numerator,swap_fee_denominator) = amm_config::get_swap_fee(config);
    
        assert!(swap_amount > config.get_minimum_swap_amount(), ECoinInsufficient);
        
        let sui_coin_amount = amm_utils::get_amount_out(reserve_meme,reserve_sui,swap_amount, swap_fee_denominator,swap_fee_numerator, true);
        
        let sui_coin = coin::from_balance(pool.reserve_b.split(sui_coin_amount), ctx);
        
        pool.reserve_a.join(coin::into_balance(input_coin));
        pay::keep(sui_coin, ctx);
        event::emit(SwapEvent{
            sender: tx_context::sender(ctx),
            pool_id: object::id(pool),
            meme_in_amount:swap_amount,
            meme_out_amount:0,
            sui_in_amount:0,
            sui_out_amount:sui_coin_amount,
            reserve_meme,
            reserve_sui
        })
   
    }


    entry public fun buy_meme_coin<MemeCoin>(pool: &mut Pool<MemeCoin>, config: &Config, sui_coin: Coin<SUI>, ctx: &mut TxContext) {
        let sui_coin_amount = sui_coin.value();
        let (reserve_meme,reserve_sui) = pool.get_reserves();
        let (swap_fee_numerator,swap_fee_denominator) = amm_config::get_swap_fee(config);


        assert!(sui_coin_amount > config.get_minimum_swap_amount(), ECoinInsufficient);
        
        let meme_coin_amount =  amm_utils::get_amount_out(reserve_meme,reserve_sui,sui_coin_amount, swap_fee_denominator,swap_fee_numerator,false);
        
        let meme_coin = coin::from_balance(pool.reserve_b.split(meme_coin_amount), ctx);
        pool.reserve_b.join(coin::into_balance(sui_coin));
        pay::keep(meme_coin, ctx);
        event::emit(SwapEvent{
            sender: tx_context::sender(ctx),
            pool_id: object::id(pool),
            meme_in_amount:0,
            meme_out_amount:meme_coin_amount,
            sui_in_amount:sui_coin_amount,
            sui_out_amount:0,
            reserve_meme,
            reserve_sui,
        })
        
    }
    
    public fun get_reserves<MemeCoin>(pool: &Pool<MemeCoin>) : (u64,u64) {
        let reserve_meme = balance::value(&pool.reserve_a);
        let reserve_sui = balance::value(&pool.reserve_b);
        (reserve_meme,reserve_sui)
    }

}