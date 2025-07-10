module main

import net.http
import veb

fn conduit_products_get(mut app App, mut ctx Context, p RetrieveProductParams) veb.Result {
	internal_products, count := app.retrieve_products(p) or {
		ctx.res.set_status(http.Status.internal_server_error)
		return ctx.json(new_peony_error('Failed to retrieve products data', err.msg()))
	}

	// TODO build PriceContext, get customer_id from ctx if customer is logged in
	// this is when variant prices should be calculated and injected in response

	mut external_products := []ProductResponse{len: internal_products.len}
	for i := 0; i < internal_products.len; i++ {
		external_products[i] = format_product_response(internal_products[i]) or {
			ctx.res.set_status(http.Status.internal_server_error)
			return ctx.json(new_peony_error('Failed to format response', err.msg()))
		}
	}

	r := ListResponse{
		items:  external_products
		count:  count
		offset: get_offset_amount(p.offset)
		fetch:  get_fetch_amount(p.fetch)
	}

	return ctx.json(r)
}
