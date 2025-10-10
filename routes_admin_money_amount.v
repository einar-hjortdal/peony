module peony

import veb

// updates a money_amount
@['/admin/money_amount/:money_amount_id'; post]
pub fn (mut app App) admin_money_amount_update(mut ctx Context, money_amount_id string) veb.Result {
	return ctx.json('TODO')
}
