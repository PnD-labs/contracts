module gmi::amm_utils{
    
    use gmi::amm_math;
    public fun get_amount_out(reserve_a:u64,reserve_b:u64,amount_in: u64,fee_denominator:u64,fee_numerator:u64, is_a_to_b: bool): u64 {
        if (is_a_to_b) {
            compute_amount_out(amount_in, reserve_a, reserve_b,fee_denominator,fee_numerator)
        } else {
            compute_amount_out(amount_in, reserve_b, reserve_a,fee_denominator,fee_numerator)
        }
    }
    
    public fun compute_amount_out(
        amount_in: u64,
        input_reserve: u64,
        output_reserve: u64,
        fee_denominator: u64,
        fee_numerator: u64
    ): u64 {
        let swap_amount = calculate_swap_amount_after_fee(fee_denominator,fee_numerator,amount_in);
        let k = amm_math::safe_mul_u64(input_reserve, output_reserve);
        let new_input_reserve = amm_math::safe_add_u64(input_reserve, swap_amount);
        let output_amount = amm_math::safe_div_u64(k, new_input_reserve);
        output_reserve - output_amount
    }

    public fun calculate_swap_amount_after_fee(fee_denominator:u64,fee_numerator:u64,amount_in:u64):u64{
        let fee = amm_math::safe_div_u64(amm_math::safe_mul_u64(amount_in,fee_denominator),fee_numerator);
        amount_in - fee
    }
}