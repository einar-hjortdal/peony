module peony

import providers
import einar_hjortdal.firebird
import einar_hjortdal.luuid
import internal.common
import internal.errors
import internal.conduit.record

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
mut:
	id       common.ID
	instance ?&providers.NotificationProvider
}

// maps channels to providers
type NotificationProviderRegistry = map[string]NotificationProviderRegistryEntry

struct Providers {
mut:
	blob         ?&BlobProviderEntry
	notification ?NotificationProviderRegistry
	// tax &providers.TaxProvider
	// payment []&providers.PaymentProvider
	// fulfillment []&providers.FulfillmentProvider
}

fn (p ProvidersConfig) get_blob_provider_entry() ?&BlobProviderEntry {
	blob_factory := p.blob_factory or { return none }
	return &BlobProviderEntry{
		factory: blob_factory
	}
}

fn (p ProvidersConfig) validate_notification() ! {
	configs := p.notification or { return }
	for _, config in configs {
		if config.name.trim_space() == '' {
			return common.config_error('notification provider name cannot be an empty string')
		}

		if config.channels.len == 0 {
			return common.config_error('at least one notification channel name is required')
		}

		for _, channel in config.channels {
			if channel.trim_space() == '' {
				return common.config_error('notification channel name cannot be an empty string')
			}
		}
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
	existing_providers := record.notification_provider_retrieve(mut tx)!
	existing_channels := record.notification_channel_retrieve(mut tx)!

	mut existing_provider_map := map[string]record.NotificationProvider{}
	for p in existing_providers {
		existing_provider_map[p.name] = p
	}

	mut existing_channel_map := map[string]record.NotificationChannel{}
	for c in existing_channels {
		existing_channel_map[c.name] = c
	}

	// deduplicate
	mut provider_name_to_channel := map[string]string{}
	for channel_name, entry in r {
		provider_name_to_channel[entry.config.name] = channel_name
	}

	// process providers
	// initialize array with capacity r.len (at most one provider per channel, at most one channel per entry)
	mut to_create_providers := []record.NotificationProviderCreateParams{len: 0, cap: r.len}
	mut to_install := []common.ID{len: 0, cap: r.len}
	mut to_uninstall := []common.ID{len: 0, cap: existing_providers.len}
	mut provider_name_to_id := map[string]common.ID{}

	for provider_name, _ in provider_name_to_channel {
		if existing := existing_provider_map[provider_name] {
			provider_name_to_id[provider_name] = existing.id
			if !existing.is_installed {
				to_install << existing.id
			}
		} else {
			new_id := common.new_id(mut gen)
			provider_name_to_id[provider_name] = new_id
			to_create_providers << record.NotificationProviderCreateParams{
				id:           new_id
				name:         provider_name
				is_installed: true
			}
		}
	}

	for existing in existing_providers {
		if existing.name !in provider_name_to_channel && existing.is_installed {
			to_uninstall << existing.id
		}
	}

	if to_create_providers.len > 0 {
		record.notification_provider_create(mut tx, to_create_providers)!
	}

	if to_install.len > 0 {
		record.notification_provider_install(mut tx, to_install)!
	}

	if to_uninstall.len > 0 {
		record.notification_provider_uninstall(mut tx, to_uninstall)!
	}

	// process channels
	mut to_create_channels := []record.NotificationChannelCreateParams{len: 0, cap: r.len}
	mut to_update_channels := []record.NotificationChannelUpdateParams{len: 0, cap: r.len}

	for channel_name, mut entry in r {
		provider_id := provider_name_to_id[entry.config.name]
		if existing := existing_channel_map[channel_name] {
			to_update_channels << record.NotificationChannelUpdateParams{
				id:          existing.id
				provider_id: provider_id
			}
			entry.id = existing.id
		} else {
			new_id := common.new_id(mut gen)
			to_create_channels << record.NotificationChannelCreateParams{
				id:          new_id
				name:        channel_name
				provider_id: provider_id
			}
			entry.id = new_id
		}
	}

	if to_create_channels.len > 0 {
		record.notification_channel_create(mut tx, to_create_channels)!
	}
	if to_update_channels.len > 0 {
		record.notification_channel_update(mut tx, to_update_channels)!
	}

	record.notification_channel_disable_unserved(mut tx)!
}

fn (mut app App) init_providers() ! {
	app.with_commit(fn [mut app] (mut tx firebird.ClientTransaction) !common.Empty {
		if mut notification := app.providers.notification {
			notification.init(mut tx, mut app.luuid_generator)!
		} else {
			record.notification_provider_uninstall_all(mut tx)!
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

fn (mut app App) get_blob_provider_instance() !&providers.BlobProvider {
	mut entry := app.providers.blob or {
		return errors.internal('No blob provider is installed', 'app.providers.blob is none')
	}

	instance := entry.instance or {
		new_instance := entry.factory() or {
			return errors.internal('Failed to get new blob provider instance', err.msg())
		}
		entry.instance = new_instance
		return new_instance
	}

	return instance
}
