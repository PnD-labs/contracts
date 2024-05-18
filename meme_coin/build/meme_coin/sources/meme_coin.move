
// /// Module: meme_coin
module meme_coin::meme_coin {
    use sui::tx_context::TxContext;
    use sui::coin::{Self,Coin,TreasuryCap,CoinMetadata};
    use std::string;
    use std::ascii;
    public struct MEME_COIN has drop{}
    

    fun init(otw:MEME_COIN,ctx:&mut TxContext){
          let ( coin_cap, coin_metadata) = coin::create_currency(
            otw,
            9,
            b"",
            b"",
            b"",
            option::none(),
            ctx
        );

        // transfer::public_freeze_object(coin_metadata);
        // transfer::public_share_object(coin_metadata);
        transfer::public_transfer(coin_metadata,tx_context::sender(ctx));
        transfer::public_share_object(coin_cap);
    }

    entry fun update_metadata(
        treasury:&TreasuryCap<MEME_COIN>,
        metadata:&mut CoinMetadata<MEME_COIN>,
        symbol: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        icon_url: vector<u8>
    ){
        
        coin::update_symbol(treasury,metadata,ascii::string(symbol));
        coin::update_name(treasury,metadata,string::utf8(name));
        coin::update_description(treasury,metadata,string::utf8(description));
        coin::update_icon_url(treasury,metadata,ascii::string(icon_url));

    }
    entry fun freeze_metadata(metadata:CoinMetadata<MEME_COIN>){
        transfer::public_freeze_object(metadata);
    }

    

    entry fun mint(cap:&mut TreasuryCap<MEME_COIN>,amount:u64,ctx:&mut TxContext){
        let coin = coin::mint<MEME_COIN>(cap,amount,ctx);
        transfer::public_transfer(coin,tx_context::sender(ctx));
    }
}

