module models

// vlib
import arrays
import db.mysql as v_mysql
import strconv
// local
import data.mysql

// TODO when requested with a query, fetch more data:
// location
// default_currency
// currencies
// sales_channels
// sales_channels
// payment_providers
// fulfillment_providers
pub struct Store {
pub mut:
	id                  string
	created_at          string [json: 'createdAt']
	updated_at          string [json: 'updatedAt']
	name                string
	default_locale_code string [json: 'defaultLocaleCode']
	// default_location_id // references ? table
	default_currency_code string [json: 'defaultCurrencyCode']
	// default_currency // Currency references currency table
	// currencies                []Currency // references currency table
	swap_link_template        string [json: 'swapLinkTemplate']
	payment_link_template     string [json: 'paymentLinkTemplate']
	invite_link_template      string [json: 'inviteLinkTemplate']
	default_stock_location_id int    [json: 'defaultStockLocationId']
	// stock_locations // references stock_location table
	default_sales_channel_id int [json: 'defaultSalesChannelId']
	// sales_channels // references ? table
	// payment_providers // references ? table
	// fulfillment_providers // references ? table
	metadata string [raw]
}

// TODO use StoreWriteable
// TODO make Store immutable

pub fn (store Store) create(mut mysql_conn v_mysql.DB) ! {
	query := 'INSERT INTO "store" ("id") VALUES (UUID_TO_BIN(?, 0))'
	mysql.prep_n_exec(mut mysql_conn, 'stmt', query, store.id)!
}

pub fn (store Store) update(mut mysql_conn v_mysql.DB) ! {
	// TODO also check that updated fields are not the same as the ones already set
	// how to do that? Either pass the new store as parameter or fetch the store by id and compare.
	mut query_columns := []string{}
	mut vars := []mysql.Param{}

	// 	currencies

	if store.name != '' {
		query_columns = arrays.concat(query_columns, 'name')
		vars = arrays.concat(vars, mysql.Param(store.name))
	}
	if store.default_locale_code != '' {
		query_columns = arrays.concat(query_columns, 'default_locale_code')
		vars = arrays.concat(vars, mysql.Param(store.default_locale_code))
	}
	if store.default_currency_code != '' {
		query_columns = arrays.concat(query_columns, 'default_currency_code')
		vars = arrays.concat(vars, mysql.Param(store.default_currency_code))
	}
	if store.swap_link_template != '' {
		query_columns = arrays.concat(query_columns, 'swap_link_template')
		vars = arrays.concat(vars, mysql.Param(store.swap_link_template))
	}
	if store.payment_link_template != '' {
		query_columns = arrays.concat(query_columns, 'payment_link_template')
		vars = arrays.concat(vars, mysql.Param(store.payment_link_template))
	}
	if store.invite_link_template != '' {
		query_columns = arrays.concat(query_columns, 'invite_link_template')
		vars = arrays.concat(vars, mysql.Param(store.invite_link_template))
	}
	// if store.currencies != '' {
	// 	query_columns = arrays.concat(query_columns, 'currencies')
	// 	vars = arrays.concat(vars, mysql.Param(store.currencies))
	// }
	if store.metadata != '' {
		query_columns = arrays.concat(query_columns, 'metadata')
		vars = arrays.concat(vars, mysql.Param(store.metadata))
	}
	// TODO add updated_at time.now()

	columns_with_question_marks := mysql.columns_with_question_marks(query_columns)

	query := 'UPDATE "store" SET ${columns_with_question_marks} WHERE "id" = ${store.id}' // TODO pass store.id also
	mysql.prep_n_exec(mut mysql_conn, 'stmt', query, ...vars)!
}

pub fn store_retrieve(mut mysql_conn v_mysql.DB) !Store {
	query_columns := ['created_at', 'updated_at', 'name', 'default_locale_code',
		'default_currency_code', 'swap_link_template', 'invite_link_template',
		'default_stock_location_id', 'default_sales_channel_id', 'metadata']
	query := 'SELECT BIN_TO_UUID("id"), ${mysql.columns(query_columns)} from "store"'
	res := mysql_conn.real_query(query)!
	// In the store table there is only one row, index will always be 0.
	row := res.rows()[0].vals

	mut store := Store{}
	// Result columns are in the same order as the SELECT statement
	store.id = row[0]
	store.created_at = row[1]
	store.updated_at = row[2]
	store.name = row[3]
	store.default_locale_code = row[4]
	store.default_currency_code = row[5]
	store.swap_link_template = row[6]
	store.invite_link_template = row[7]
	store.default_stock_location_id = strconv.atoi(row[8]) or { 0 }
	store.default_sales_channel_id = strconv.atoi(row[9]) or { 0 }
	store.metadata = row[10]

	return store
}
