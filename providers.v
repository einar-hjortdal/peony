module peony

import providers
import einar_hjortdal.firebird
import einar_hjortdal.luuid
import internal.common

// Providers are services used by peony.
// BlobProvider stores and serves files such as product images, videos, etc.
// NotificationProvider allows peony to send email, sms...
// PaymentProvider enables peony to receive payments, issue refunds, etc.
// FulfillmentProvider enables peony to schedule shipments, book returns, etc.
pub struct ProvidersConfig {
pub:
	blob_factory ?fn () !&providers.BlobProvider
	notification ?[]providers.NotificationProviderConfig
}

struct BlobProviderEntry {
	factory fn () !&providers.BlobProvider @[required]
mut:
	instance ?&providers.BlobProvider
}

struct NotificationProviderRegistryEntry {
	config providers.NotificationProviderConfig
	id     common.ID
mut:
	instance ?&providers.NotificationProvider
}

// maps channels to providers
type NotificationProviderRegistry = map[string]NotificationProviderRegistryEntry

struct Providers {
mut:
	blob         ?BlobProviderEntry
	notification ?NotificationProviderRegistry
	// tax &providers.TaxProvider
	// payment []&providers.PaymentProvider
	// fulfillment []&providers.FulfillmentProvider
}

fn validate_notification_provider_config(c providers.NotificationProviderConfig) ! {
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

fn (p ProvidersConfig) get_blob_provider_entry() ?BlobProviderEntry {
	blob_factory := p.blob_factory or { return none }
	return BlobProviderEntry{
		factory: blob_factory
	}
}

fn (p ProvidersConfig) validate_notification() ! {
	configs := p.notification or { return }
	for _, config in configs {
		validate_notification_provider_config(config)!
	}
}

fn (p ProvidersConfig) get_notification_provider_registry() ?NotificationProviderRegistry {
	configs := p.notification or { return none }
	mut res := NotificationProviderRegistry{}
	for _, config in configs {
		channels := config.channels
		for _, channel in channels {
			res[channel] = NotificationProviderRegistryEntry{
				config: config
			}
		}
	}
	return res
}

fn (p ProvidersConfig) get_providers() !&Providers {
	p.validate_notification()!
	return &Providers{
		blob:         p.get_blob_provider_entry()
		notification: p.get_notification_provider_registry()
	}
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

fn (mut r NotificationProviderRegistry) init(
	mut tx firebird.ClientTransaction,
	mut gen luuid.Generator) ! {
	for channel_name, provider in r {
		provider_name := provider.config.name
		// TODO lookup database: get id, set is_installed, update updated_at if needed...
		// merge than select?
		tx.execute('')! // suppress
		println(channel_name) // suppress
		println(provider_name) // suppress
		common.new_id(mut gen) // suppress
	}
}

fn (mut app App) init_providers() ! {
	_ := app.with_commit(fn [mut app] (mut tx firebird.ClientTransaction) !common.Empty {
		if mut notification := app.providers.notification {
			notification.init(mut tx, mut app.luuid_generator)!
		}
		return common.Empty{}
	})!
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
