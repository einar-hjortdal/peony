module main

// variant prices and taxes must be calculated at the application level utilizing a context
// variant_id + quantity

// this context is made of:
// cart_id?: string;
// customer_id?: string;
// region_id?: string;
// quantity?: number;
// currency_code?: string;
// include_discount_prices?: boolean;
// tax_rates?: TaxServiceRate[];
// ignore_cache?: boolean;
//
