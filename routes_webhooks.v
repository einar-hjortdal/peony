module peony

import veb

@['/webhooks/payment/:provider_code'; post]
fn (mut app App) webhook_payment(mut ctx Context, provider_code string) veb.Result {
	// WIP
	// We use many payment providers. We want to make sure that one peony instance may have 2 or more instances of the same provider, with different configurations.
	// We can use a manually-chosen provider code to tell which instance is needed. This code has to be unique across provider instances.
	// TODO is this enough?
	return ctx.handle_ok(provider_code)
}
