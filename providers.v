module peony

import providers
import einar_hjortdal.firebird
import internal.common

struct Providers {
mut:
	blob         ?&providers.BlobProvider
	notification ?NotificationProviderRegistry
	// tax &providers.TaxProvider
	// payment []&providers.PaymentProvider
	// fulfillment []&providers.FulfillmentProvider
}

struct NotificationProviderRegistryEntry {
	config providers.NotificationProviderConfig
	id     common.ID
mut:
	instance ?&providers.NotificationProvider
}

type NotificationProviderRegistry = map[string]NotificationProviderRegistryEntry

fn verify_notification_provider_config(c providers.NotificationProviderConfig) ! {
	if c.name.trim_space() == '' {
		return common.config_error('name is required')
	}

	if c.channels.len == 0 {
		return common.config_error('at least one channel name is required')
	}

	for _, channel in c.channels {
		if channel.trim_space() == '' {
			return common.config_error('channel is an empty string')
		}
	}
}

// used at app startup
fn new_notification_provider_registry(
	mut tx firebird.ClientTransaction,
	configs []providers.NotificationProviderConfig) !NotificationProviderRegistry {
	mut res := NotificationProviderRegistry{}
	for _, config in configs {
		verify_notification_provider_config(config)!

		// TODO lookup database: get id, set is_installed, update updated_at if needed...
		// merge than select?

		channels := config.channels
		for _, channel in channels {
			res[channel] = NotificationProviderRegistryEntry{
				config: config
			}
		}
	}
	return res
}

// returns a reference to a providers struct
fn get_providers(p ProvidersConfig) !&Providers {
	return &Providers{}
}

fn (r NotificationProviderRegistry) send(notification providers.NotificationData) !providers.NotificationResult {
	c := notification.channel
	mut e := r[c] or { return error('No notification provider exists for channel `${c}`') }
	mut instance := e.instance or {
		new_instance := e.config.factory()!
		new_instance
	}

	return instance.send(notification)!
}

fn (mut app App) init_providers(p ProvidersConfig) ! {
	app.providers.blob = p.blob_factory()!

	app.providers.notification = new_notification_provider_registry(mut tx, p.notification)!
}

// TODO
// list of event const strings
//     - password reset
//     - customer create/update/delete
//     - shipment create
//     - delivery create
//     - invite create/accept/delete/send
//     - order create/update/cancel/complete
//     - return request/receive
//     - exchange create/receive
// TODO job queue with redict streams
