
// /// Module: meme_coin
module meme_coin::meme_coin {
    use sui::tx_context::{TxContext};
    use sui::coin::{Self,Coin,TreasuryCap,CoinMetadata};
    use sui::object;
    use sui::url::Url;
    use sui::event;
    use sui::sui::{SUI};
    use std::option::{Self,Option};
    use std::string::{Self,String};
    use std::ascii::{Self,String as Ascii};
    public struct MEME_COIN has drop{}
 

    const DECIMAL:u8 = 9;
    const INIT_TOTAL_SUPPLY:u64 = 100_000_000_000_000_000;



    public struct CreateCurrencyEvent has copy,drop{
        metadata:ID,
        treasury:ID,
    }
    public struct CreateCoinEvent has copy,drop{
        symbol:Ascii,
        name:String,
        description:String,
        icon_url:Option<Url>,
        treasury:ID,
        metadata:ID,
        creator:address,
    }

    fun init(otw:MEME_COIN,ctx:&mut TxContext){
          let ( coin_cap, coin_metadata) = coin::create_currency(
            otw,
            DECIMAL,
            b"",
            b"",
            b"",
            option::none(),
            ctx
        );
        let event = CreateCurrencyEvent{
            metadata:object::id(&coin_metadata),
            treasury:object::id(&coin_cap),
        };
        transfer::public_share_object(coin_metadata);
        transfer::public_share_object(coin_cap);
        event::emit(event);
    }
    

    entry fun initial_coin(
        treasury:&TreasuryCap<MEME_COIN>,
        metadata:CoinMetadata<MEME_COIN>,
        symbol: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        icon_url: vector<u8>,
        creator:address,
    ){ 
        let mut metadata = metadata;
        let treasury_id = object::id(treasury);
        let metadata_id = object::id(&metadata);
        coin::update_symbol(treasury,&mut metadata,ascii::string(symbol));
        coin::update_name(treasury,&mut metadata,string::utf8(name));
        coin::update_description(treasury,&mut metadata,string::utf8(description));
        coin::update_icon_url(treasury,&mut metadata,ascii::string(icon_url));

        


        let event = CreateCoinEvent{
            symbol:coin::get_symbol(&metadata),
            name:coin::get_name(&metadata),
            description:coin::get_description(&metadata),
            icon_url:coin::get_icon_url(&metadata),
            treasury:treasury_id,
            metadata:metadata_id,
            creator,
        };
        transfer::public_freeze_object(metadata);
        event::emit(event);
    }

 

    
    //mint 시에 maker 의 초기물량을 정하고, 나머지 밈코인과 sui 를 상장시킨다. 


    entry fun mint_and_listing_dex(cap:&mut TreasuryCap<MEME_COIN>,sui_coin:Coin<SUI>,sender_amount:u64,ctx:&mut TxContext){
        let mut listing_meme_coin = coin::mint<MEME_COIN>(cap,INIT_TOTAL_SUPPLY,ctx);
        let sender_meme_coin = coin::split(&mut listing_meme_coin,sender_amount,ctx);
        transfer::public_transfer(sender_meme_coin,tx_context::sender(ctx));
        

        //Pool을 불러와야함.
        
    }

    
}

