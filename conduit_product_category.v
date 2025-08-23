module peony

import veb

fn conduit_product_category_list(mut app App, mut ctx Context, ph ProductCategoryRetrieveParamsHygienised) veb.Result {
	return success(mut ctx)
}

fn conduit_product_category_create(mut app App, mut ctx Context, ph ProductCategoryRequestHygienised) veb.Result {
	return success(mut ctx)
}

fn conduit_product_category_get(mut app App, mut ctx Context, product_category_id_bin []u8) veb.Result {
	return success(mut ctx)
}

fn conduit_product_category_update(mut app App, mut ctx Context, product_category_id_bin []u8, ph ProductCategoryRequestHygienised) veb.Result {
	return success(mut ctx)
}

fn conduit_product_category_delete(mut app App, mut ctx Context, product_category_id_bin []u8) veb.Result {
	return success(mut ctx)
}
