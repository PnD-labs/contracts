module gmi::amm_math{
    const EInvalidAddParam:u64 = 0;
    const EInvalidDivParam:u64 = 1;
    public fun safe_mul_u64(x: u64, y: u64): u64 {
        ((x as u128) * (y as u128) as u64)
    }
     public fun safe_add_u64(a: u64, b: u64): u64 {
        let sum = a + b;
        assert!(sum >= a && sum >= b, EInvalidAddParam);
        sum
    }

    public fun safe_div_u64(a: u64, b: u64): u64 {
        assert!(b > 0, EInvalidDivParam);
        let quotient = a / b;
        quotient
    }

}
