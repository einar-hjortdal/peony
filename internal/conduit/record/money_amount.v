module record

import einar_hjortdal.firebird
import common

pub struct MoneyAmount {
pub:
	id          ID
	amount      i32
	is_original bool
}

pub fn (ma MoneyAmount) id() ID {
	return ma.id
}

pub struct VariantMoneyAmount {
	MoneyAmount
pub:
	variant_id    ID
	region_id     ID
	currency_code string // from region
	includes_tax  bool   // from region
}

pub fn variant_money_amount_retrieve(mut tx firebird.ClientTransaction, variant_ids []ID) ![]VariantMoneyAmount {
	data := tx.execute('SELECT
		ma.id,
		ma.amount,
		ma.is_original,
		ma.region_id,
		r.currency_code,
		r.includes_tax,
		vma.variant_id
		FROM money_amount ma
		LEFT JOIN region r
			ON ma.region_id = r.id
		LEFT JOIN variant_money_amount vma
			ON ma.id = vma.money_amount_id
		WHERE variant_id IN (${get_placeholders(variant_ids)})',
		...ids_bytes(variant_ids))!

	rows := data.rows()

	mut variant_money_amounts := []VariantMoneyAmount{len: rows.len}
	for i := 0; i < rows.len; i++ {
		v := rows[i].values()

		id_bin, _ := v[0].get_array_u8()!
		amount, _ := v[1].get_i32()!
		is_original, _ := v[2].get_bool()!
		region_id_bin, _ := v[3].get_array_u8()!
		currency_code, _ := v[4].get_string()!
		includes_tax, _ := v[5].get_bool()!
		variant_id_bin, _ := v[6].get_array_u8()!

		id := id_from_bytes(id_bin)!
		region_id := id_from_bytes(region_id_bin)!
		variant_id := id_from_bytes(variant_id_bin)!

		variant_money_amounts[i] = VariantMoneyAmount{
			id:            id
			amount:        amount
			region_id:     region_id
			is_original:   is_original
			currency_code: currency_code
			includes_tax:  includes_tax
			variant_id:    variant_id
		}
	}

	return variant_money_amounts
}

pub struct VariantMoneyAmountUpdateParams {
pub:
	variant_id      ID
	region_id       ID
	money_amount_id ID
	amount          i32
	is_original     ?bool
}

pub fn variant_money_amount_update(mut tx firebird.ClientTransaction, p []VariantMoneyAmountUpdateParams) ! {
	mut variant_ids_map := map[string]ID{}
	for i := 0; i < p.len; i++ {
		variant_id := p[i].variant_id
		variant_ids_map[variant_id.string()] = variant_id
	}
	variant_ids := variant_ids_map.values()

	// delete all related money amount first
	mut query := 'DELETE FROM money_amount
		WHERE id IN (
			SELECT money_amount_id
			FROM variant_money_amount
			WHERE variant_id IN (${get_placeholders(variant_ids)})
		)
		AND price_list_id IS NULL'

	tx.execute(query, ...ids_bytes(variant_ids))!

	mut n_params := 4
	mut src := []string{len: p.len}
	mut params := []firebird.Value{len: p.len * n_params, init: firebird.Null{}}
	for i := 0; i < p.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS id,
			CAST(? AS BINARY(16)) AS region_id,
			CAST(? AS BOOLEAN) AS is_original,
			CAST(? AS INTEGER) AS amount
			FROM RDB\$DATABASE'

		params[i * n_params] = p[i].money_amount_id.bytes()
		params[i * n_params + 1] = p[i].region_id.bytes()

		if is_original := p[i].is_original {
			params[i * n_params + 2] = is_original
		} else {
			params[i * n_params + 2] = common.money_amount_default_is_original
		}

		params[i * n_params + 3] = p[i].amount
	}

	query = 'INSERT INTO money_amount (id, region_id, is_original, amount) ${get_merge_source(src)}'

	tx.execute(query, ...params)!

	n_params = 2
	params = []firebird.Value{len: p.len * n_params, init: firebird.Null{}}
	for i := 0; i < p.len; i++ {
		src[i] = 'SELECT
			CAST(? AS BINARY(16)) AS variant_id,
			CAST(? AS BINARY(16)) AS money_amount_id
			FROM RDB\$DATABASE'

		params[i * n_params] = p[i].variant_id.bytes()
		params[i * n_params + 1] = p[i].money_amount_id.bytes()
	}

	query = 'INSERT INTO variant_money_amount (variant_id, money_amount_id)
		${get_merge_source(src)}'

	tx.execute(query, ...params)!
}
