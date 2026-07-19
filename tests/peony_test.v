module tests

import peony
import peony.objects
import peony.providers

// deps
import json2
import net.http
import os
import rand
import time
import einar_hjortdal.luuid

const fail_key = 'fail'
const firebird_container_name = 'test_firebird_server'
const firebird_port = '3051'
const firebird_user = 'test_user'
const firebird_root_password = 'test_root_password'
const firebird_password = 'test_password'
const firebird_database = 'test_database.fdb'
const firebird_database_path = '/var/lib/firebird/data/${firebird_database}'
const firebird_url = 'firebird://${firebird_user}:${firebird_password}@localhost:${firebird_port}${firebird_database_path}'
const redict_container_name = 'test_redict_server'
const redict_port = '6380'
const redict_url = 'redict://@localhost:${redict_port}/0'
const session_secret = 'testSessionSecret'
const port = 12080
const default_user_email = 'info@peony.com'
const default_user_password = 'very-secret-password'

const endpoint_admin_auth = '/admin/auth'
const endpoint_admin_users = '/admin/users'
const endpoint_admin_locales = '/admin/locales'
const endpoint_admin_regions = '/admin/regions'
const endpoint_admin_store = '/admin/store'
const endpoint_admin_categories = '/admin/categories'
const endpoint_admin_products = '/admin/products'

// mock providers (each implementation requires its own independent tests)
struct BlobProviderDummy {}

fn new_provider_blob_dummy() &BlobProviderDummy {
	return &BlobProviderDummy{}
}

fn (bp BlobProviderDummy) create(fd http.FileData) !providers.BlobFileData {
	if fd.filename == fail_key {
		return error('failed to create file, filename == ${fail_key}')
	}

	id := luuid.v2()
	return providers.BlobFileData{
		id:  id
		url: 'https://BlobProvider.Dummy/${id}'
	}
}

fn (bp BlobProviderDummy) delete(id string) ! {
	if id == fail_key {
		return error('failed to delete file, filename == ${fail_key}')
	}
}

fn container_firebird_clean() {
	result := os.execute('docker stop ${firebird_container_name}')
	if result.exit_code != 0 {
		if result.output.contains('No such container') {
			return
		}
		eprintln(result.output)
	}
}

// Remember to `sudo usermod -aG docker $USER`
fn container_firebird_start() ! {
	container_firebird_clean() // kill container if already running
	result :=
		os.execute('docker run --rm --detach --name=${firebird_container_name} --env=FIREBIRD_ROOT_PASSWORD=${firebird_root_password} --env=FIREBIRD_USER=${firebird_user} --env=FIREBIRD_PASSWORD=${firebird_password} --env=FIREBIRD_DATABASE=${firebird_database} --env=FIREBIRD_DATABASE_DEFAULT_CHARSET=UTF8 --publish=${firebird_port}:3050 firebirdsql/firebird')
	if result.exit_code != 0 {
		return error(result.output)
	}
}

fn container_redict_clean() {
	result := os.execute('docker stop ${redict_container_name}')
	if result.exit_code != 0 {
		if result.output.contains('No such container') {
			return
		}
		eprintln(result.output)
	}
}

fn container_redict_start() ! {
	container_redict_clean() // kill container if already running
	result :=
		os.execute('docker run --rm --detach --name=${redict_container_name} --publish=${redict_port}:6379 registry.redict.io/redict')
	if result.exit_code != 0 {
		return error(result.output)
	}
}

fn containers_are_ready() {
	mut firebird_is_loading := true
	mut redict_is_loading := true
	for firebird_is_loading || redict_is_loading {
		if firebird_is_loading {
			check :=
				os.execute('echo "SELECT \'ALIVE\' FROM RDB\\\$DATABASE; quit;" | docker exec -i ${firebird_container_name} isql localhost:${firebird_database_path} -user ${firebird_user} -password ${firebird_password} -q')
			if check.output.contains('ALIVE') {
				firebird_is_loading = false
			}
		}

		if redict_is_loading {
			ping := os.execute('docker exec ${redict_container_name} redict-cli ping')
			if ping.output.contains('PONG') {
				redict_is_loading = false
			}
		}

		time.sleep(1 * time.second)
	}
	return
}

// Note: veb cannot be stopped, it has no shutdown functions: https://github.com/vlang/v/issues/25655
// Note: containers aren't stopped on panic
fn app_routine(ch chan bool) {
	config := peony.Config{
		debug:                 true
		firebird_url:          firebird_url
		redict_url:            redict_url
		port:                  port
		default_user_email:    default_user_email
		default_user_password: default_user_password
		session_secret:        session_secret
	}

	mut app := peony.new_peony_app(config, peony.Providers{
		blob: new_provider_blob_dummy()
	}) or { panic(err) }
	go app.run()
	_ := <-ch

	container_firebird_clean()
	container_redict_clean()
}

// starts a test app, when stopped it closes the containers.
fn run_app() !chan bool {
	container_firebird_start()!
	container_redict_start()!
	containers_are_ready()

	ch := chan bool{}
	go app_routine(ch)
	mut app_is_loading := true
	for app_is_loading {
		request := http.new_request(http.Method.get, 'http://localhost:${port}/admin/auth', '')
		if r := request.do() {
			app_is_loading = false
		}
		time.sleep(1 * time.second)
	}
	return ch
}

fn stop_app(ch chan bool) {
	ch <- true
}

fn build_url(s string) string {
	return 'http://localhost:${port}${s}'
}

// TODO handle params
// TODO handle headers
fn do_get_request(path string) !http.Response {
	request := http.new_request(http.Method.get, build_url(path), '')
	return request.do()!
}

fn do_post_request(path string, body string) !http.Response {
	request := http.new_request(http.Method.post, build_url(path), body)
	return request.do()!
}

fn do_authenticated_request(path string, cookie_value string, body string, method http.Method) !http.Response {
	mut request := http.new_request(method, build_url(path), body)
	segments := cookie_value.split('=')
	request.add_cookie(http.Cookie{
		name:  segments[0]
		value: segments[1]
	})
	return request.do()
}

fn do_authenticated_get_request(path string, cookie_value string) !http.Response {
	return do_authenticated_request(path, cookie_value, '', http.Method.get)
}

fn do_authenticated_get_request_with_params(path string, cookie_value string, params string) !http.Response {
	return do_authenticated_request(path, cookie_value, params, http.Method.get)
}

fn do_authenticated_post_request(path string, cookie_value string, body string) !http.Response {
	return do_authenticated_request(path, cookie_value, body, http.Method.post)
}

fn do_authenticated_delete_request(path string, cookie_value string) !http.Response {
	return do_authenticated_request(path, cookie_value, '', http.Method.delete)
}

fn is_ok(r http.Response) ! {
	if r.status_code != 200 {
		return error('status ${r.status_code} (${r.status_msg}): ${r.body}')
	}
}

fn is_created(r http.Response) ! {
	if r.status_code != 201 {
		return error('status ${r.status_code} (${r.status_msg}): ${r.body}')
	}
}

fn is_not_found(r http.Response) ! {
	if r.status_code != 404 {
		return error('status ${r.status_code} (${r.status_msg}): ${r.body}')
	}
}

fn extract_cookie_from_set_cookie(r http.Response) !string {
	v := r.header.get(http.CommonHeader.set_cookie) or { return error('no cookie was extracted') }
	return v.split(';')[0] // remove attributes
}

fn user_login() !string {
	response := do_post_request('/admin/auth', json2.encode(peony.AuthRequest{
		email:    default_user_email
		password: default_user_password
	},
		escape_unicode: true
	))!
	return extract_cookie_from_set_cookie(response)
}

fn user_logout(cookie_value string) ! {
	_ := do_authenticated_delete_request('/admin/auth', cookie_value)!
	return
}

fn admin_auth_wrapper(test_functions []fn (provided_cookie_value string) !) ! {
	cookie_value := user_login()!
	for i := 0; i < test_functions.len; i++ {
		test_function := test_functions[i]
		test_function(cookie_value)!
	}
	defer {
		user_logout(cookie_value) or {}
	}
}

fn expect(condition bool, error_message string) ! {
	if !condition {
		return error(error_message)
	}
}

fn auth_middleware_rejects_unauthorized() ! {
	response := do_get_request(endpoint_admin_auth)!
	expect(response.status_code == 401,
		'Unathorized request should have been rejected, but it was not.')!
}

fn auth_middleware_allows_logins_and_logouts() ! {
	body := json2.encode(peony.AuthRequest{
		email:    default_user_email
		password: default_user_password
	},
		escape_unicode: true
	)
	mut response := do_post_request(endpoint_admin_auth, body)!
	is_ok(response)!

	cookie_value := extract_cookie_from_set_cookie(response)!

	response = do_authenticated_get_request(endpoint_admin_auth, cookie_value)!
	is_ok(response)!

	response = do_authenticated_delete_request(endpoint_admin_auth, cookie_value)!
	is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_auth, cookie_value)!
	expect(response.status_code == 401,
		'Expired session was accepted, but it should have not been.')!
}

fn admin_auth_returns_user_data(cookie_value string) ! {
	println('admin_auth_returns_user_data')
	response := do_authenticated_get_request(endpoint_admin_auth, cookie_value)!
	is_ok(response)!

	r := json2.decode[peony.UserResponseEnvelope](response.body)!
	user := r.user
	expect(user.id != '', 'Returned empty user id')!
	expect(user.email == default_user_email.to_upper(), 'Unexpected user email: ${user.email}')!
	expect(user.handle != '', 'Unexpected user handle: ${user.handle}')!
	expect(user.role == objects.role_admin, 'Unexpected user role: ${user.role}')!
	// TODO test created_at is not zero https://github.com/vlang/v/issues/24765
}

fn admin_auth_rejects_login_when_already_logged_in(cookie_value string) ! {
	println('admin_auth_rejects_login_when_already_logged_in')
	response := do_authenticated_post_request('/admin/auth', cookie_value, json2.encode(peony.AuthRequest{
		email:    default_user_email
		password: default_user_password
	},
		escape_unicode: true
	))!
	expect(response.status_code == 400, 'Logged in user was allowed to log in again')!
}

fn admin_users_list_users(cookie_value string) ! {
	println('admin_users_list_users')
	mut response := do_authenticated_get_request(endpoint_admin_users, cookie_value)!
	is_ok(response)!
	mut r := json2.decode[peony.UserResponseListEnvelope](response.body)!
	expect(r.count != 0, 'Unexpected count: ${r.count}')!
	expect(r.users.len != 0, 'No users returned')!
	expect(r.offset == 0, 'Unexpected offset: ${r.offset}')!
	// expect(r.fetch == 0, 'TODO')

	mut default_user := peony.UserResponse{}
	mut found := false
	for i := 0; i < r.users.len; i++ {
		user := r.users[i]
		if user.email == default_user_email.to_upper() {
			default_user = user
			found = true
			break
		}
	}
	expect(found, 'Default user not found in response')!
	expect(default_user.id != '', 'Unexpected user id: ${default_user.id}')!
	expect(default_user.handle != '', 'Unexpected user handle: ${default_user.handle}')!
	expect(default_user.role == objects.role_admin, 'Unexpected user role: ${default_user.role}')!
}

// Verifies:
// Correctly create users
// Correctly delete users
// Correctly lists new users
// Correctly lists deleted users
fn admin_users_create_and_delete_user(cookie_value string) ! {
	println('admin_users_create_and_delete_user')
	mut response := do_authenticated_get_request(endpoint_admin_users, cookie_value)!
	mut r := json2.decode[peony.UserResponseListEnvelope](response.body)!
	old_count := r.count
	old_users_len := r.users.len

	response = do_authenticated_post_request(endpoint_admin_users, cookie_value, json2.encode(peony.UserCreateRequest{
		email: 'new_user@peony.com'
	},
		escape_unicode: true
	))!
	expect(response.status_code == 400, 'Invalid request was accepted.')!

	// TODO add all fields
	valid_new_user := peony.UserCreateRequest{
		email:    'new_user@peony.com'
		password: 'new user password'
	}
	response = do_authenticated_post_request(endpoint_admin_users, cookie_value, json2.encode(valid_new_user,
		escape_unicode: true
	))!
	is_created(response)!

	// TODO get new used directly instead of scanning all
	response = do_authenticated_get_request(endpoint_admin_users, cookie_value)!
	is_ok(response)!
	r = json2.decode[peony.UserResponseListEnvelope](response.body)!
	expect(r.count == old_count + 1, 'Unexpected count. Count does not include new user')!
	expect(r.users.len == old_users_len + 1,
		'Unexpected users.len. Count does not include new user')!

	mut new_user := peony.UserResponse{}
	mut found := false
	for i := 0; i < r.users.len; i++ {
		user := r.users[i]
		if user.email == valid_new_user.email.to_upper() {
			new_user = user
			found = true
			break
		}
	}
	expect(found, 'new user not found')!
	// TODO test all fields

	response = do_authenticated_delete_request('${endpoint_admin_users}/${new_user.id}',
		cookie_value)!
	is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_users, cookie_value)!
	is_ok(response)!
	r = json2.decode[peony.UserResponseListEnvelope](response.body)!
	expect(r.count == old_count, 'Unexpected count. Count includes deleted user')!
	expect(r.users.len == old_users_len, 'Unexpected users.len. Response includes deleted user')!
}

// TODO /admin/users/:user_id get, post, delete

// TODO offset and params
fn admin_locales_lists_locales(cookie_value string) ! {
	println('admin_locales')
	mut response := do_authenticated_get_request(endpoint_admin_locales, cookie_value)!
	is_ok(response)!
	r := json2.decode[peony.LocaleResponseListEnvelope](response.body)!
	locale_codes_file := os.read_file('${os.getwd()}/migrations/seed-locale-codes.txt')!
	lines := locale_codes_file.split('\n')
	locale_codes := lines[..lines.len - 1] // remove last character \n (posix)
	expect(r.count == locale_codes.len,
		'Count does not match amount of locales that should be in the db')!
	expect(r.offset == 0, 'Wrong page')!
	expect(r.fetch == objects.max_fetch, 'Maximum number of items fetched does not match max_fetch')!
}

// TODO create helper functions to:
// get a valid locale_id
// create a new region and get its id
// create a new stock location and get its id
// create a new sales channel and get its id
fn admin_store(cookie_value string) ! {
	println('admin_store')
	mut response := do_authenticated_get_request(endpoint_admin_store, cookie_value)!
	is_ok(response)!

	mut r := json2.decode[peony.StoreResponseEnvelope](response.body)!
	mut store := r.store

	old_updated_at := store.updated_at

	new_store_name := luuid.v2()
	new_store_data := peony.StoreUpdateRequest{
		name: new_store_name
		// default_locale_id
		// default_region_id
		// default_stock_location_id
		// default_sales_channel_id
	}
	time.sleep(1 * time.second) // for updated_at
	response = do_authenticated_post_request('${endpoint_admin_store}/${r.store.id}', cookie_value, json2.encode(new_store_data,
		escape_unicode: true
	))!
	is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_store, cookie_value)!
	is_ok(response)!

	r = json2.decode[peony.StoreResponseEnvelope](response.body)!
	store = r.store
	expect(store.name == new_store_name, 'Store name was not updated')!
	expect(store.updated_at != old_updated_at, 'store.updated_at was not updated')!
}

// TODO test refuse to remove default locale
fn admin_store_updates_store_locales(cookie_value string) ! {
	println('admin_store_updates_store_locales')
	mut response := do_authenticated_get_request(endpoint_admin_store, cookie_value)!
	mut r := json2.decode[peony.StoreResponseEnvelope](response.body)!
	old_store := r.store

	response = do_authenticated_get_request(endpoint_admin_locales, cookie_value)!
	r_2 := json2.decode[peony.LocaleResponseListEnvelope](response.body)!
	locales := r_2.locales

	// get a random locale
	safe_max := objects.max_fetch - 1 // reserve 1
	random_index := rand.int_in_range(0, safe_max)!
	mut random_locale := locales[random_index]
	if random_locale.id == old_store.default_locale_id {
		random_locale = locales[random_index + 1] // safely add 1
	}

	new_locale_ids := [old_store.default_locale_id, random_locale.id]
	new_store_data := json2.encode(peony.StoreUpdateRequest{
		locale_ids: new_locale_ids
	},
		escape_unicode: true
	)
	response = do_authenticated_post_request('${endpoint_admin_store}/${old_store.id}',
		cookie_value, new_store_data)!
	is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_store, cookie_value)!
	r = json2.decode[peony.StoreResponseEnvelope](response.body)!
	new_store := r.store
	expect(new_store.locales.len == new_locale_ids.len,
		'Locales array length does not match expectations')!

	restore_old_data := json2.encode(peony.StoreUpdateRequest{
		locale_ids: [old_store.default_locale_id]
	},
		escape_unicode: true
	)
	response = do_authenticated_post_request('${endpoint_admin_store}/${old_store.id}',
		cookie_value, restore_old_data)!
	is_ok(response)!
}

fn admin_categories_create_minimal_category(cookie_value string) ! {
	println('admin_categories_create_minimal_category')
	new_category_name := luuid.v2()
	new_category_data := json2.encode(peony.CategoryCreateRequest{
		name: new_category_name
	},
		escape_unicode: true
	)
	mut response := do_authenticated_post_request(endpoint_admin_categories, cookie_value,
		new_category_data)!
	is_created(response)!
	r := json2.decode[peony.CategoryResponseEnvelope](response.body)!
	created_category := r.category

	// TODO check created fields

	response = do_authenticated_delete_request('${endpoint_admin_categories}/${created_category.id}',
		cookie_value)!
	is_ok(response)!
}

fn admin_categories_create_complex_category(cookie_value string) ! {
	println('admin_categories_create_complex_category')
	name := luuid.v2()
	description := luuid.v2()
	handle := luuid.v2()
	is_internal := true
	is_active := false
	metadata := luuid.v2()
	seo_title := luuid.v2()
	seo_description := luuid.v2()
	category_data := json2.encode(peony.CategoryCreateRequest{
		name:        name
		description: description
		handle:      handle
		is_internal: is_internal
		is_active:   is_active
		metadata:    metadata
		seo:         peony.SEORequest{
			title:       seo_title
			description: seo_description
		}
	},
		escape_unicode: true
	)
	mut response := do_authenticated_post_request(endpoint_admin_categories, cookie_value,
		category_data)!
	is_created(response)!
	r := json2.decode[peony.CategoryResponseEnvelope](response.body)!
	new_category := r.category
	nc_description := unwrap_or_error(new_category.description, 'category description missing')!
	nc_metadata := unwrap_or_error(new_category.metadata, 'category metadata missing')!
	nc_seo_title := unwrap_or_error(new_category.seo.title, 'category seo title missing')!
	nc_seo_description := unwrap_or_error(new_category.seo.description,
		'category seo description missing')!

	expect(new_category.id != '', 'Category is missing id')!
	expect(new_category.name == name, 'name does not match')!
	expect(nc_description == description, 'description does not match')!
	expect(new_category.handle == handle, 'handle does not match')!
	expect(new_category.is_internal == is_internal, 'is_internal does not match')!
	expect(nc_metadata == '"${metadata}"', 'metadata does not match')!
	expect(nc_seo_title == seo_title, 'seo_title does not match')!
	expect(nc_seo_description == seo_description, 'seo_description does not match')!

	response = do_authenticated_delete_request('${endpoint_admin_categories}/${new_category.id}',
		cookie_value)!
	is_ok(response)!
}

fn admin_categories_updates_category(cookie_value string) ! {
	println('admin_categories_updates_category')
	new_category_name := luuid.v2()
	new_category_data := json2.encode(peony.CategoryCreateRequest{
		name: new_category_name
	},
		escape_unicode: true
	)
	mut response := do_authenticated_post_request(endpoint_admin_categories, cookie_value,
		new_category_data)!
	response = do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	mut r := json2.decode[peony.CategoryResponseListEnvelope](response.body)!

	mut new_category := peony.CategoryResponse{}
	for i := 0; i < r.categories.len; i++ {
		category := r.categories[i]
		if category.name == new_category_name {
			new_category = category
			break
		}
	}

	new_name := luuid.v2()
	new_description := luuid.v2()
	new_handle := luuid.v2()
	new_is_internal := !new_category.is_internal
	new_is_active := !new_category.is_active
	new_metadata := luuid.v2()
	updated_category_data := json2.encode(peony.CategoryUpdateRequest{
		name:        new_name
		description: new_description
		handle:      new_handle
		is_internal: new_is_internal
		is_active:   new_is_active
		metadata:    new_metadata
	},
		escape_unicode: true
	)
	time.sleep(1 * time.second) // needed to check updated_at
	response = do_authenticated_post_request('${endpoint_admin_categories}/${new_category.id}',
		cookie_value, updated_category_data)!
	is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	r = json2.decode[peony.CategoryResponseListEnvelope](response.body)!
	mut updated_category := peony.CategoryResponse{}
	for i := 0; i < r.categories.len; i++ {
		category := r.categories[i]
		if category.id == new_category.id {
			updated_category = category
			break
		}
	}

	uc_description := unwrap_or_error(updated_category.description, 'category description missing')!
	uc_metadata := unwrap_or_error(updated_category.metadata, 'category metadata missing')!
	// TODO update seo

	expect(updated_category.updated_at > new_category.updated_at,
		'updated_at field was not updated')!
	expect(updated_category.name == new_name, 'name does not match')!
	expect(uc_description == new_description, 'description does not match')!
	expect(updated_category.handle == new_handle, 'handle does not match')!
	expect(updated_category.is_internal == new_is_internal, 'is_internal does not match')!
	expect(updated_category.is_active == new_is_active, 'is_internal does not match')!
	expect(uc_metadata == '"${new_metadata}"', 'metadata does not match')!

	response = do_authenticated_delete_request('${endpoint_admin_categories}/${new_category.id}',
		cookie_value)!
}

fn admin_categories_create_rejects_bad_requests(cookie_value string) ! {
	println('admin_categories_create_rejects_bad_requests')
	new_category_data := peony.CategoryCreateRequest{}
	response := do_authenticated_post_request(endpoint_admin_categories, cookie_value, json2.encode(new_category_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422, 'Category was created despite having no name')!
}

// Verifies:
// Correctly create minimal product (only title provided)
// Correctly delete product
// Correctly lists new product
// Correctly lists deleted product
fn admin_products_create_minimal_product(cookie_value string) ! {
	println('admin_products_create_minimal_product')
	new_product_title := luuid.v2()
	new_product_data := peony.ProductCreateRequest{
		title: new_product_title
	}
	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	is_created(response)!
	r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	created_product := r.product

	response = do_authenticated_delete_request('${endpoint_admin_products}/${created_product.id}',
		cookie_value)!
	is_ok(response)!

	response = do_authenticated_get_request('${endpoint_admin_products}/${created_product.id}',
		cookie_value)!
	is_not_found(response)!
}

fn admin_products_create_complex_product(cookie_value string) ! {
	println('admin_products_create_complex_product')
	title := luuid.v2()
	subtitle := luuid.v2()
	description := luuid.v2()
	handle := luuid.v2()
	status := objects.product_status_draft
	discountable := true
	metadata := luuid.v2()
	seo_title := luuid.v2()
	seo_description := luuid.v2()
	thumbnail := 1 // expecting the new product's thumbail to be equal to image_1
	image_0_url := luuid.v2()
	image_0_alt := luuid.v2()
	image_1_url := luuid.v2()
	image_1_alt := luuid.v2()
	new_product_data := peony.ProductCreateRequest{
		title:        title
		subtitle:     subtitle
		description:  description
		handle:       handle
		status:       status
		discountable: discountable
		metadata:     metadata
		seo:          peony.SEORequest{
			title:       seo_title
			description: seo_description
		}
		thumbnail:    1
		images:       [
			peony.ImageCreateRequest{
				url: image_0_url
				alt: image_0_alt
			},
			peony.ImageCreateRequest{
				url: image_1_url
				alt: image_1_alt
			},
		]
	}
	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	is_created(response)!
	r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	created_product := r.product

	image_0 := created_product.images[0]
	image_1 := created_product.images[1]

	np_subtitle := unwrap_or_error(created_product.subtitle, 'product subtitle missing')!
	np_description := unwrap_or_error(created_product.description, 'product description missing')!
	np_metadata := unwrap_or_error(created_product.metadata, 'product metadata missing')!
	np_seo_title := unwrap_or_error(created_product.seo.title, 'product seo title missing')!
	np_seo_description := unwrap_or_error(created_product.seo.description,
		'product seo description missing')!
	np_thumnail_alt := unwrap_or_error(created_product.thumbnail.alt,
		'product thumnail alt missing')!
	np_i0_alt := unwrap_or_error(image_0.alt, 'product image 0 alt missing')!
	np_i1_alt := unwrap_or_error(image_0.alt, 'product image 1 alt missing')!

	expect(created_product.id != '', 'Product is missing id')!
	expect(created_product.title == title, 'title does not match')!
	expect(np_subtitle == subtitle, 'subtitle does not match')!
	expect(np_description == description, 'description does not match')!
	expect(created_product.status == status, 'status does not match')!
	expect(created_product.discountable == discountable, 'discountable does not match')!
	expect(np_metadata == '"${metadata}"', 'metadata does not match')!
	expect(np_seo_title == seo_title, 'seo_title does not match')!
	expect(np_seo_description == seo_description, 'seo_description does not match')!
	expect(created_product.thumbnail.id != '', 'thumbnail is missing id')!
	expect(created_product.thumbnail.url == image_1_url, 'thumbnail url does not match')!
	expect(np_thumnail_alt == image_1_alt, 'thumbnail alt does not match')!
	expect(created_product.images.len == 2, 'Missing images')!
	expect(image_0.url == image_0_url, 'image_0_url does not match')!
	expect(np_i0_alt == image_0_alt, 'image_0_alt does not match')!
	expect(image_1.url == image_1_url, 'image_1_url does not match')!
	expect(np_i1_alt == image_1_alt, 'image_1_alt does not match')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${created_product.id}',
		cookie_value)!
	is_ok(response)!
}

fn handles_unique_product_handles(cookie_value string) ! {
	println('handles_unique_product_handles')
	//  create product with no specified handle
	mut new_product_title := luuid.v2()
	mut new_product_data := peony.ProductCreateRequest{
		title: new_product_title
	}
	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	is_created(response)!
	mut r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	mut created_product := r.product

	expect(created_product.handle == created_product.title,
		'product created with no explicit handle has a handle that does not match title')!
	response = do_authenticated_delete_request('${endpoint_admin_products}/${created_product.id}',
		cookie_value)!

	// create product with specified handle
	new_product_title = luuid.v2()
	mut new_product_handle := luuid.v2()
	new_product_data = peony.ProductCreateRequest{
		title:  new_product_title
		handle: new_product_handle
	}
	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	is_created(response)!
	r = json2.decode[peony.ProductResponseEnvelope](response.body)!
	created_product = r.product
	expect(created_product.handle == new_product_handle,
		'product created with explicit handle has a handle that does not match the given handle')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${created_product.id}',
		cookie_value)!

	// TODO create product with no specified handle and already existing
	// TODO create product with specified handle and already existing
}

fn creates_product_with_one_option(cookie_value string) ! {
	println('creates_product_with_one_option')
	new_product_title := luuid.v2()

	mut new_product_data := peony.ProductCreateRequest{
		title:   new_product_title
		options: []peony.ProductOptionCreateRequest{}
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422, 'Product was created with explicitly no options')!

	new_product_data = peony.ProductCreateRequest{
		title:   new_product_title
		options: [peony.ProductOptionCreateRequest{}]
	}

	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422, 'Product was created with one option without title')!

	new_option_title := luuid.v2()
	new_product_data = peony.ProductCreateRequest{
		title:   new_product_title
		options: [
			peony.ProductOptionCreateRequest{
				title: new_option_title
			},
		]
	}

	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422, 'Product was created with one option without values')!

	new_product_data = peony.ProductCreateRequest{
		title:   new_product_title
		options: [
			peony.ProductOptionCreateRequest{
				title:  new_option_title
				values: []peony.ProductOptionValueCreateRequest{}
			},
		]
	}

	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422,
		'Product was created with one option with explicitly no values')!

	new_value_name := luuid.v2()
	new_product_data = peony.ProductCreateRequest{
		title:   new_product_title
		options: [
			peony.ProductOptionCreateRequest{
				title:  new_option_title
				values: [
					peony.ProductOptionValueCreateRequest{
						name: new_value_name
					},
				]
			},
		]
	}

	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422, 'Product was created with one option but no variants')!

	new_product_data = peony.ProductCreateRequest{
		title:    new_product_title
		options:  [
			peony.ProductOptionCreateRequest{
				title:  new_option_title
				values: [
					peony.ProductOptionValueCreateRequest{
						name: new_value_name
					},
				]
			},
		]
		variants: []peony.ProductVariantCreateRequest{}
	}

	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422, 'Product was created with explicitly no variants')!

	new_product_data = peony.ProductCreateRequest{
		title:    new_product_title
		options:  [
			peony.ProductOptionCreateRequest{
				title:  new_option_title
				values: [
					peony.ProductOptionValueCreateRequest{
						name: new_value_name
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: []i32{}
			},
		]
	}

	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422,
		'Product was created with one variant with explicitly no option values')!

	new_product_data = peony.ProductCreateRequest{
		title:    new_product_title
		options:  [
			peony.ProductOptionCreateRequest{
				title:  new_option_title
				values: [
					peony.ProductOptionValueCreateRequest{
						name: new_value_name
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(0), 1]
			},
		]
	}

	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422,
		'Product was created with option_values referencing too many options')!

	new_product_data = peony.ProductCreateRequest{
		title:    new_product_title
		options:  [
			peony.ProductOptionCreateRequest{
				title:  new_option_title
				values: [
					peony.ProductOptionValueCreateRequest{
						name: new_value_name
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(1)]
			},
		]
	}

	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422,
		'Product was created with option_values referencing non-existing options')!

	new_product_data = peony.ProductCreateRequest{
		title:    new_product_title
		options:  [
			peony.ProductOptionCreateRequest{
				title:  new_option_title
				values: [
					peony.ProductOptionValueCreateRequest{
						name: new_value_name
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(0)]
			},
		]
	}

	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	is_created(response)!

	r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	product := r.product
	options := product.options
	expect(options.len == 1,
		'Product contains unexpected number of options: expected 1, got ${options.len}')!

	option := options[0]
	expect(option.title == new_option_title, 'Created option has the wrong title.')!

	values := option.values
	expect(values.len == 1,
		'Created option has unexpected number of values: expected 1, got ${values.len}')!

	value := values[0]
	expect(value.name == new_value_name, 'Created value has the wrong name')!

	variants := product.variants
	expect(variants.len == 1, 'Product contains unexpected number of variants')!

	variant := variants[0]
	option_values := variant.option_values
	expect(option_values.len == 1, 'Variant references too many values')!

	option_value := option_values[0]
	expect(option_value.option_id == option.id, 'Variant references wrong option')!
	expect(option_value.id == value.id, 'Variant references wrong value')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}',
		cookie_value)!
	is_ok(response)!
}

fn creates_product_without_options_with_variant(cookie_value string) ! {
	println('creates_product_without_options_with_variant')
	new_product_data := peony.ProductCreateRequest{
		title:    luuid.v2()
		variants: [
			peony.ProductVariantCreateRequest{
				title:    luuid.v2()
				ean:      rand.ascii(peony.max_length_ean)
				upc:      rand.ascii(peony.max_length_upc)
				barcode:  rand.ascii(peony.max_length_barcode)
				metadata: '{"everyone":"applied","golden":false,"plane":[false,true,true,false,{"caught":"bag","send":false,"play":170874771,"lips":"factory","rapidly":997234369,"greater":true},-1230624692],"doll":true,"crew":false,"held":81753149.38483429}'
			},
		]
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	is_created(response)!

	r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	product := r.product

	variants := product.variants
	expect(variants.len == 1,
		'Product contains unexpected number of variants: expected 1, got ${variants.len}')!

	variant := variants[0]
	v_title := unwrap_or_error(variant.title, 'variant title missing')!
	v_ean := unwrap_or_error(variant.ean, 'variant ean missing')!
	v_upc := unwrap_or_error(variant.upc, 'variant upc missing')!
	v_barcode := unwrap_or_error(variant.barcode, 'variant barcode missing')!
	v_metadata := unwrap_or_error(variant.metadata, 'variant metadata missing')!

	expect(v_title != '', 'Variant title was not set')! // TODO check identical
	expect(v_ean != '', 'Variant ean was not set')! // TODO check identical
	expect(v_upc != '', 'Variant upc was not set')! // TODO check identical
	expect(v_barcode != '', 'Variant barcode was not set')! // TODO check identical
	expect(v_metadata != '', 'Variant metadata was not set')! // TODO check identical

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}',
		cookie_value)!
	is_ok(response)!
}

fn creates_product_with_one_option_and_many_variants(cookie_value string) ! {
	println('creates_product_with_one_option_and_many_variants')
	new_product_data := peony.ProductCreateRequest{
		title:    luuid.v2()
		options:  [
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(0)]
			},
			peony.ProductVariantCreateRequest{
				option_values: [i32(1)]
			},
		]
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	is_created(response)!

	r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	product := r.product
	options := product.options
	expect(options.len == 1,
		'Product contains unexpected number of options: expected 1, got ${options.len}')!

	variants := product.variants
	expect(variants.len == 2,
		'Product contains unexpected number of variants: expected 2, got ${variants.len}')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}',
		cookie_value)!
	is_ok(response)!
}

fn creates_product_with_many_options_and_one_variant(cookie_value string) ! {
	println('creates_product_with_many_options')
	new_product_data := peony.ProductCreateRequest{
		title:    luuid.v2()
		options:  [
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(0), 1]
			},
		]
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	is_created(response)!

	r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	product := r.product
	options := product.options
	expect(options.len == 2,
		'Product contains unexpected number of options: expected 2, got ${options.len}')!

	variants := product.variants
	expect(variants.len == 1,
		'Product contains unexpected number of variants: expected 1, got ${variants.len}')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}',
		cookie_value)!
	is_ok(response)!
}

fn creates_product_with_variant_image(cookie_value string) ! {
	println('creates_product_with_variant_image')
	new_product_data := peony.ProductCreateRequest{
		title:    luuid.v2()
		images:   [
			peony.ImageCreateRequest{
				url: rand.ascii(63)
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				image: 0
			},
		]
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	is_created(response)!

	r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	product := r.product
	images := product.images
	expect(images.len == 1,
		'Product created with an unexpected number of images. Expected 1, got ${images.len}')!

	variants := product.variants
	expect(variants.len == 1,
		'Product created with an unexpected number of variants. Expected 1, got ${variants.len}')!

	image := images[0]
	variant := variants[0]
	v_image_id := unwrap_or_error(variant.image_id, 'variant image id mising')!
	expect(image.id == v_image_id, 'variant image_id does not match the expected image id')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}',
		cookie_value)!
	is_ok(response)!
}

fn updates_product_with_variant_image(cookie_value string) ! {
	println('updates_product_with_variant_image')
	product_data := peony.ProductCreateRequest{
		title:    luuid.v2()
		images:   [
			peony.ImageCreateRequest{
				url: rand.ascii(63)
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				image: 0
			},
		]
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(product_data,
		escape_unicode: true
	))!
	is_created(response)!

	mut r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	mut product := r.product
	expect(product.images.len == 1,
		'Product created with an unexpected number of images. Expected 1, got ${product.images.len}')!

	expect(product.variants.len == 1,
		'Product created with an unexpected number of variants. Expected 1, got ${product.variants.len}')!

	mut image := product.images[0]
	mut variant := product.variants[0]

	new_product_data := peony.ProductUpdateRequest{
		title:    luuid.v2()
		images:   [
			peony.ProductImageUpdateRequest{
				url: rand.ascii(63)
			},
			peony.ProductImageUpdateRequest{
				id: image.id
			},
		]
		variants: [
			peony.ProductVariantUpdateRequest{
				id:    variant.id
				image: 0
			},
		]
	}

	response = do_authenticated_post_request('${endpoint_admin_products}/${product.id}',
		cookie_value, json2.encode(new_product_data, escape_unicode: true))!
	is_ok(response)!
	r = json2.decode[peony.ProductResponseEnvelope](response.body)!
	product = r.product

	expect(product.images.len == 2,
		'Product created with an unexpected number of images. Expected 2, got ${product.images.len}')!
	expect(product.variants.len == 1,
		'Product created with an unexpected number of variants. Expected 1, got ${product.variants.len}')!

	variant = product.variants[0]
	new_image_id := product.images[0].id
	v_image_id := unwrap_or_error(variant.image_id, 'variant image id mising')!
	expect(new_image_id == v_image_id, 'Updated variant references wrong image')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}',
		cookie_value)!
	is_ok(response)!
}

fn updates_product_replaces_default_variant(cookie_value string) ! {
	println('updates_product_replaces_default_variant')
	product_data := peony.ProductCreateRequest{
		title:    luuid.v2()
		variants: [
			peony.ProductVariantCreateRequest{},
		]
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(product_data,
		escape_unicode: true
	))!
	is_created(response)!
	mut r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	mut product := r.product
	old_variant_id := product.variants[0].id

	new_product_data := peony.ProductUpdateRequest{
		title:    luuid.v2()
		variants: [
			// no old variant => delete old variant
			peony.ProductVariantUpdateRequest{
				// no variant id => create new variant
			},
		]
	}

	response = do_authenticated_post_request('${endpoint_admin_products}/${product.id}',
		cookie_value, json2.encode(new_product_data, escape_unicode: true))!
	is_ok(response)!
	r = json2.decode[peony.ProductResponseEnvelope](response.body)!
	product = r.product

	expect(product.variants.len == 1,
		'Product updated with an unexpected number of variants. Expected 1, got ${product.variants.len}')!
	new_variant_id := product.variants[0].id
	expect(old_variant_id != new_variant_id,
		'Old variant was not deleted, the new variant shares its same id.')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}',
		cookie_value)!
	is_ok(response)!
}

fn creates_a_variant(cookie_value string) ! {
	println('creates_a_variant')
	image_0_url := luuid.v2()
	product_data := peony.ProductCreateRequest{
		title:    luuid.v2()
		images:   [
			peony.ImageCreateRequest{
				url: image_0_url
			},
			peony.ImageCreateRequest{
				url: luuid.v2()
			},
		]
		options:  [
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(0)]
			},
		]
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(product_data,
		escape_unicode: true
	))!
	is_created(response)!
	pr := json2.decode[peony.ProductResponseEnvelope](response.body)!
	product := pr.product
	expect(product.options.len == 1,
		'Unexpected number of options: expected 1, got ${product.options.len}')!
	expect(product.images.len == 2,
		'Unexpected number of images: expected 1, got ${product.images.len}')!

	image_0 := product.images[0]
	expect(image_0.url == image_0_url, 'Image at rank 0 does not match expected url')!

	option := product.options[0]
	expect(option.values.len == 2,
		'Unexpected number of option_value: expected 2, got ${option.values.len}')!

	value_1 := option.values[1]
	expect(value_1.value_rank == 1,
		'Unexpected value_rank for value at index 1: expected 1, got ${value_1.value_rank}')!

	title := luuid.v2()
	ean := rand.ascii(peony.max_length_ean)
	upc := rand.ascii(peony.max_length_upc)
	barcode := rand.ascii(peony.max_length_barcode)
	variant_data := peony.VariantCreateRequest{
		title:    title
		ean:      ean
		upc:      upc
		barcode:  barcode
		image_id: image_0.id
		// inventory_item:
		option_value_ids: [value_1.id]
		// metadata:
		// regional_prices:
	}
	response = do_authenticated_post_request('${endpoint_admin_products}/${product.id}/variants',
		cookie_value, json2.encode(variant_data, escape_unicode: true))!
	is_created(response)!
	vr := json2.decode[peony.VariantResponseEnvelope](response.body)!
	variant := vr.variant

	v_title := unwrap_or_error(variant.title, 'variant title mising')!
	v_ean := unwrap_or_error(variant.ean, 'variant ean mising')!
	v_upc := unwrap_or_error(variant.upc, 'variant upc mising')!
	v_barcode := unwrap_or_error(variant.barcode, 'variant barcode mising')!
	expect(v_title == title, 'Variant title does not match: expected ${title}, got ${v_title}')!
	expect(v_ean == ean, 'Variant ean does not match: expected ${ean}, got ${v_ean}')!
	expect(v_upc == upc, 'Variant upc does not match: expected ${upc}, got ${v_upc}')!
	expect(v_barcode == barcode,
		'Variant barcode does not match: expected ${barcode}, got ${v_barcode}')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}',
		cookie_value)!
	is_ok(response)!
}

fn updates_a_variant(cookie_value string) ! {
	println('updates_a_variant')
	product_data := peony.ProductCreateRequest{
		title:    luuid.v2()
		images:   [
			peony.ImageCreateRequest{
				url: luuid.v2()
			},
			peony.ImageCreateRequest{
				url: luuid.v2()
			},
		]
		options:  [
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(0)]
				image:         0
			},
		]
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(product_data,
		escape_unicode: true
	))!
	is_created(response)!
	pr := json2.decode[peony.ProductResponseEnvelope](response.body)!
	product := pr.product
	expect(product.variants.len == 1,
		'Unexpected number of variants: expected 1, got ${product.variants.len}')!
	expect(product.images.len == 2,
		'Unexpected number of images: expected 2, got ${product.images.len}')!
	expect(product.options.len == 1,
		'Unexpected number of options: expected 1, got ${product.options.len}')!

	default_variant := product.variants[0]
	image_1 := product.images[1]
	option := product.options[0]
	expect(option.values.len == 2,
		'Unexpected number of option_value: expected 2, got ${option.values.len}')!

	value_1 := option.values[1]
	expect(value_1.value_rank == 1,
		'Unexpected value_rank for value at index 1: expected 1, got ${value_1.value_rank}')!

	title := luuid.v2()
	ean := rand.ascii(peony.max_length_ean)
	upc := rand.ascii(peony.max_length_upc)
	barcode := rand.ascii(peony.max_length_barcode)
	variant_data := peony.VariantUpdateRequest{
		title:    title
		ean:      ean
		upc:      upc
		barcode:  barcode
		image_id: image_1.id
		// inventory_item:
		option_value_ids: [value_1.id]
		// metadata:
		// regional_prices:
	}
	response = do_authenticated_post_request('${endpoint_admin_products}/${product.id}/variants/${default_variant.id}',
		cookie_value, json2.encode(variant_data, escape_unicode: true))!
	is_ok(response)!
	vr := json2.decode[peony.VariantResponseEnvelope](response.body)!
	variant := vr.variant

	v_title := unwrap_or_error(variant.title, 'variant title mising')!
	v_ean := unwrap_or_error(variant.ean, 'variant ean mising')!
	v_upc := unwrap_or_error(variant.upc, 'variant upc mising')!
	v_barcode := unwrap_or_error(variant.barcode, 'variant barcode mising')!
	v_image_id := unwrap_or_error(variant.image_id, 'variant image_id mising')!

	expect(v_title == title, 'Variant title does not match: expected ${title}, got ${v_title}')!
	expect(v_ean == ean, 'Variant ean does not match: expected ${ean}, got ${v_ean}')!
	expect(v_upc == upc, 'Variant upc does not match: expected ${upc}, got ${v_upc}')!
	expect(v_barcode == barcode,
		'Variant barcode does not match: expected ${barcode}, got ${v_barcode}')!
	expect(v_image_id == image_1.id, 'Variant image_id does not match')!
	expect(variant.option_values.len == 1,
		'Unexpected number of option_values: expected 1, got ${variant.option_values.len}')!

	option_value := variant.option_values[0]
	expect(option_value.id == value_1.id, 'option_value id does not match')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}',
		cookie_value)!
	is_ok(response)!
}

fn deletes_a_variant(cookie_value string) ! {
	println('deletes_a_variant')
	product_data := peony.ProductCreateRequest{
		title:    luuid.v2()
		options:  [
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(0)]
			},
			peony.ProductVariantCreateRequest{
				option_values: [i32(1)]
			},
		]
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(product_data,
		escape_unicode: true
	))!
	is_created(response)!
	pr := json2.decode[peony.ProductResponseEnvelope](response.body)!
	product := pr.product
	expect(product.variants.len == 2,
		'Unexpected number of variants: expected 1, got ${product.variants.len}')!

	variant_0 := product.variants[0]
	variant_1 := product.variants[1]

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}/variants/${variant_0.id}',
		cookie_value)!
	is_ok(response)!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}/variants/${variant_1.id}',
		cookie_value)!
	expect(response.status_code == 400, 'Deleted last variant')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}',
		cookie_value)!
	is_ok(response)!
}

fn creates_product_with_variant_with_regional_prices(cookie_value string) ! {
	println('creates_product_with_regional_prices')
	mut response := do_authenticated_get_request(endpoint_admin_regions, cookie_value)!
	regions_list := json2.decode[peony.RegionResponseListEnvelope](response.body)!
	regions := regions_list.regions

	mut regional_prices := map[string]peony.VariantPriceRequest{}
	for i := 0; i < regions.len; i++ {
		region := regions[i]
		regional_prices[region.id] = peony.VariantPriceRequest{
			base_price:     rand.i32_in_range(0, max_i32)!
			original_price: rand.i32_in_range(0, max_i32)!
		}
	}

	new_product_data := peony.ProductCreateRequest{
		title:    luuid.v2()
		variants: [
			peony.ProductVariantCreateRequest{
				regional_prices: regional_prices
			},
		]
	}

	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	is_created(response)!

	r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	product := r.product
	variants := product.variants
	expect(variants.len == 1,
		'Product contains unexpected number of variants: expected 1, got ${variants.len}')!

	variant := variants[0]
	expect(variant.regional_prices.len == regions.len,
		'Variant contains unexpected number of regional prices, expected ${regions.len}, got ${variant.regional_prices.len}')!

	region_ids := variant.regional_prices.keys()
	for i := 0; i < region_ids.len; i++ {
		region_id := region_ids[i]
		base_expected := regional_prices[region_id].base_price
		base_received := variant.regional_prices[region_id].base_price
		expect(base_expected == base_received,
			'regional base_price does not match: expected ${base_expected}, received ${base_received}')!

		if original_expected := regional_prices[region_id].original_price {
			original_received := variant.regional_prices[region_id].original_price
			expect(original_expected == original_received,
				'regional base_price does not match: expected ${original_expected}, received ${original_received}')!
		}
	}

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}',
		cookie_value)!
	is_ok(response)!
}

fn refuses_product_creation_with_variants_with_same_values(cookie_value string) ! {
	println('refuses_product_creation_with_one_option_and_many_variants_with_same_values')
	// 1 option, 1 value, 2 variants
	mut new_product_data := peony.ProductCreateRequest{
		title:    luuid.v2()
		options:  [
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(0)]
			},
			peony.ProductVariantCreateRequest{
				option_values: [i32(0)]
			},
		]
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422,
		'Product was created with 1 option, 1 value and 2 variants with the same values')!

	// 1 option, 2 values, 2 variants
	new_product_data = peony.ProductCreateRequest{
		title:    luuid.v2()
		options:  [
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(1)]
			},
			peony.ProductVariantCreateRequest{
				option_values: [i32(1)]
			},
		]
	}

	// 2 options, 1 value each, 2 variants
	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422,
		'Product was created with 1 option, 2 value and 2 variants with the same values')!

	new_product_data = peony.ProductCreateRequest{
		title:    luuid.v2()
		options:  [
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(0), 0]
			},
			peony.ProductVariantCreateRequest{
				option_values: [i32(0), 0]
			},
		]
	}

	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422,
		'Product was created with 2 options, 1 value each and 2 variants with the same values')!

	// 2 options, 2 values each, 2 variants
	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422,
		'Product was created with 1 option, 2 value and 2 variants with the same values')!

	new_product_data = peony.ProductCreateRequest{
		title:    luuid.v2()
		options:  [
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(1), 0]
			},
			peony.ProductVariantCreateRequest{
				option_values: [i32(1), 0]
			},
		]
	}

	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422,
		'Product was created with 2 options, 1 value each and 2 variants with the same values')!
}

fn admin_products_updates_product(cookie_value string) ! {
	println('admin_products_updates_product')
	title := luuid.v2()
	original_product_data := peony.ProductCreateRequest{
		title: title
	}
	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(original_product_data,
		escape_unicode: true
	))!
	mut r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	new_product := r.product

	new_title := luuid.v2()
	new_subtitle := luuid.v2()
	new_description := luuid.v2()
	new_handle := luuid.v2()
	new_is_giftcard := true
	new_status := objects.product_status_published
	new_discountable := false
	new_metadata := luuid.v2()
	new_seo_title := luuid.v2()
	new_seo_description := luuid.v2()
	updated_product_data := json2.encode(peony.ProductUpdateRequest{
		title:        new_title
		subtitle:     new_subtitle
		description:  new_description
		handle:       new_handle
		is_giftcard:  new_is_giftcard
		status:       new_status
		discountable: new_discountable
		metadata:     new_metadata
		seo:          peony.SEORequest{
			title:       new_seo_title
			description: new_seo_description
		}
	},
		escape_unicode: true
	)
	time.sleep(1 * time.second) // needed to check updated_at
	response = do_authenticated_post_request('${endpoint_admin_products}/${new_product.id}',
		cookie_value, updated_product_data)!
	is_ok(response)!
	r = json2.decode[peony.ProductResponseEnvelope](response.body)!
	updated_product := r.product

	up_subtitle := unwrap_or_error(updated_product.subtitle, 'product subtitle mising')!
	up_description := unwrap_or_error(updated_product.description, 'product description mising')!
	up_metadata := unwrap_or_error(updated_product.metadata, 'product metadata mising')!
	up_seo_title := unwrap_or_error(updated_product.seo.title, 'product seo title mising')!
	up_seo_description := unwrap_or_error(updated_product.seo.description,
		'product seo desciption mising')!

	expect(updated_product.id != '', 'Product is missing id')!
	expect(updated_product.updated_at > new_product.updated_at, 'updated_at field was not updated')!
	expect(updated_product.title == new_title, 'title does not match')!
	expect(up_subtitle == new_subtitle, 'subtitle does not match')!
	expect(up_description == new_description, 'description does not match')!
	expect(updated_product.status == new_status, 'status does not match')!
	expect(updated_product.discountable == new_discountable, 'discountable does not match')!
	expect(up_metadata == '"${new_metadata}"', 'metadata does not match')!
	expect(up_seo_title == new_seo_title, 'seo_title does not match')!
	expect(up_seo_description == new_seo_description, 'seo_description does not match')!
}

fn admin_products_create_rejects_bad_requests(cookie_value string) ! {
	println('admin_products_create_rejects_bad_requests')
	mut new_product_data := peony.ProductCreateRequest{}
	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422, 'Product was created despite having no title')!

	new_product_data = peony.ProductCreateRequest{
		title: ''
	}
	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	expect(response.status_code == 422, 'Product was created despite request having empty title')!
}

fn updates_product_options_ranking(cookie_value string) ! {
	println('updates_product_options_ranking')
	mut new_product_data := peony.ProductCreateRequest{
		title:    luuid.v2()
		options:  [
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(0), 0]
			},
		]
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	is_created(response)!

	mut r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	mut product := r.product
	old_options := product.options
	expect(old_options.len == 2,
		'Product contains unexpected number of options: expected 2, got ${old_options.len}')!

	old_option_0 := old_options[0]
	old_option_1 := old_options[1]

	updated_product_data := peony.ProductUpdateRequest{
		options: [
			peony.ProductOptionUpdateRequest{
				id: old_option_1.id
			},
			peony.ProductOptionUpdateRequest{
				id: old_option_0.id
			},
		]
	}

	response = do_authenticated_post_request('${endpoint_admin_products}/${product.id}',
		cookie_value, json2.encode(updated_product_data, escape_unicode: true))!
	is_ok(response)!

	r = json2.decode[peony.ProductResponseEnvelope](response.body)!
	product = r.product
	new_options := product.options
	expect(new_options.len == 2,
		'Product contains unexpected number of options: expected 2, got ${new_options.len}')!

	new_option_0 := new_options[0]
	new_option_1 := new_options[1]
	expect(new_option_0.id == old_option_1.id, 'Option ranking was not updated')!
	expect(new_option_1.id == old_option_0.id, 'Option ranking was not updated')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}',
		cookie_value)!
	is_ok(response)!
}

fn updates_variants_ranking(cookie_value string) ! {
	println('updates_variants_ranking')
	mut new_product_data := peony.ProductCreateRequest{
		title:    luuid.v2()
		options:  [
			peony.ProductOptionCreateRequest{
				title:  luuid.v2()
				values: [
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
					peony.ProductOptionValueCreateRequest{
						name: luuid.v2()
					},
				]
			},
		]
		variants: [
			peony.ProductVariantCreateRequest{
				option_values: [i32(0)]
			},
			peony.ProductVariantCreateRequest{
				option_values: [i32(1)]
			},
		]
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(new_product_data,
		escape_unicode: true
	))!
	is_created(response)!

	mut r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	mut product := r.product
	old_variants := product.variants
	expect(old_variants.len == 2,
		'Product contains unexpected number of variants: expected 2, got ${old_variants.len}')!

	variant_0_id := old_variants[0].id
	variant_1_id := old_variants[1].id

	updated_product_data := peony.ProductUpdateRequest{
		variants: [
			peony.ProductVariantUpdateRequest{
				id: variant_1_id
			},
			peony.ProductVariantUpdateRequest{
				id: variant_0_id
			},
		]
	}

	response = do_authenticated_post_request('${endpoint_admin_products}/${product.id}',
		cookie_value, json2.encode(updated_product_data, escape_unicode: true))!
	is_ok(response)!

	r = json2.decode[peony.ProductResponseEnvelope](response.body)!
	product = r.product
	new_variants := product.variants
	expect(new_variants.len == 2,
		'Product contains unexpected number of variants: expected 2, got ${new_variants.len}')!

	new_variant_0_id := new_variants[0].id
	new_variant_1_id := new_variants[1].id
	expect(new_variant_0_id == variant_1_id, 'Variant ranking was not updated')!
	expect(new_variant_1_id == variant_0_id, 'Variant ranking was not updated')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product.id}',
		cookie_value)!
	is_ok(response)!
}

fn add_random_locales(cookie_value string, locales_amount i32) ![]peony.LocaleResponse {
	mut response := do_authenticated_get_request(endpoint_admin_store, cookie_value)!
	r := json2.decode[peony.StoreResponseEnvelope](response.body)!
	store := r.store
	default_locale_id := store.default_locale_id

	response = do_authenticated_get_request(endpoint_admin_locales, cookie_value)!
	r_2 := json2.decode[peony.LocaleResponseListEnvelope](response.body)!
	available_locales := r_2.locales

	mut locales := []peony.LocaleResponse{len: locales_amount}
	mut new_locale_ids := []string{len: locales_amount + 1}
	// TODO check locales_amount is not a crazy number (negative, insane large...)

	// reserve number of locales and one for default locale if encountered
	safe_max := objects.max_fetch - locales_amount - 1
	if safe_max < 0 {
		return error('Not enough locales to pick ${locales_amount}')
	}

	random_index := rand.int_in_range(0, safe_max)!

	mut default_found := false
	for i := 0; i < locales_amount; i++ {
		mut new_locale := available_locales[random_index + i]
		if !default_found && new_locale.id == default_locale_id {
			default_found = true
		}

		if default_found {
			new_locale = available_locales[random_index + i + 1]
		}

		locales[i] = new_locale
		new_locale_ids[i] = new_locale.id
	}
	new_locale_ids[locales_amount] = default_locale_id // add default

	new_store_data := json2.encode(peony.StoreUpdateRequest{
		locale_ids: new_locale_ids
	},
		escape_unicode: true
	)
	response = do_authenticated_post_request('${endpoint_admin_store}/${store.id}', cookie_value,
		new_store_data)!
	is_ok(response)!
	return locales
}

fn remove_secondary_locales(cookie_value string) ! {
	mut response := do_authenticated_get_request(endpoint_admin_store, cookie_value)!
	r := json2.decode[peony.StoreResponseEnvelope](response.body)!
	store := r.store
	default_locale_id := store.default_locale_id

	new_store_data := json2.encode(peony.StoreUpdateRequest{
		locale_ids: [default_locale_id]
	},
		escape_unicode: true
	)
	response = do_authenticated_post_request('${endpoint_admin_store}/${store.id}', cookie_value,
		new_store_data)!
	is_ok(response)!
}

fn get_random_image_create_request(secondary_locales []peony.LocaleResponse) peony.ImageCreateRequest {
	mut translations := map[string]peony.ImageTranslationRequest{}
	if secondary_locales.len > 0 {
		for i := 0; i < secondary_locales.len; i++ {
			locale := secondary_locales[i]
			translations[locale.id] = peony.ImageTranslationRequest{
				alt: luuid.v2()
			}
		}
	}

	return peony.ImageCreateRequest{
		url:          luuid.v2()
		alt:          luuid.v2()
		translations: translations
	}
}

fn admin_products_handles_product_images(cookie_value string) ! {
	println('admin_products_updates_product_images')
	title := luuid.v2()
	secondary_locales := add_random_locales(cookie_value, 2)!
	n_images := 3
	mut images := []peony.ImageCreateRequest{len: n_images}
	for i := 0; i < n_images; i++ {
		images[i] = get_random_image_create_request(secondary_locales)
	}
	original_product_data := peony.ProductCreateRequest{
		title:  title
		images: images
	}
	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(original_product_data,
		escape_unicode: true
	))!
	is_created(response)!
	mut r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	new_product := r.product

	expect(new_product.images.len == n_images, 'number of images created does not match')!
	new_thumbnail := new_product.thumbnail
	expect(new_thumbnail.id == new_product.images[0].id, 'thumbnail is the wrong image')!

	for i := 0; i < new_product.images.len; i++ {
		requested_image := images[i]
		new_image := new_product.images[i]

		expect(new_image.id != '', 'image id is missing')!
		expect(new_image.url == requested_image.url, 'image_1 url does not match')!

		ni_alt := unwrap_or_error(new_image.alt, 'image alt missing')!
		if alt := requested_image.alt {
			expect(ni_alt == alt, 'image_1 alt does not match')!
		}

		// verify all requested translations were created
		if requested_image_translations := requested_image.translations {
			expect(new_image.translations.len == requested_image_translations.len,
				'image ${i} translations differ in number')!
			for j := 0; j < secondary_locales.len; j++ {
				locale := secondary_locales[j]
				expect(locale.id in new_image.translations,
					'secondary locale not found in image ${i} translations')!
			}
		}
	}

	// update sorting order
	mut images_update := [
		peony.ProductImageUpdateRequest{
			id: new_product.images[2].id
		},
		peony.ProductImageUpdateRequest{
			id: new_product.images[0].id
		},
		peony.ProductImageUpdateRequest{
			id: new_product.images[1].id
		},
	]
	mut product_update := peony.ProductUpdateRequest{
		images: images_update
	}

	response = do_authenticated_post_request('${endpoint_admin_products}/${new_product.id}',
		cookie_value, json2.encode(product_update, escape_unicode: true))!
	is_ok(response)!
	r = json2.decode[peony.ProductResponseEnvelope](response.body)!
	updated_product := r.product
	updated_images := updated_product.images
	expect(updated_images.len == images_update.len, 'images are an unexpected number')!
	for i := 0; i < images_update.len; i++ {
		if expected_id := images_update[i].id {
			expect(updated_images[i].id == expected_id, 'image sorting order is wrong')!
		}
	}
	// TODO check no data is lost

	// update image alt and translations
	// update sorting order and remove one image
	// update sorting order and add one image
	// update sorting order plus one alt and translation
}

fn admin_handles_category_translations(cookie_value string) ! {
	println('admin_handles_category_translations')
	secondary_locales := add_random_locales(cookie_value, 2)!
	secondary_locale_1 := secondary_locales[0]
	secondary_locale_2 := secondary_locales[1]

	category_name := luuid.v2()
	category_description := luuid.v2()
	category_translation_1_name := luuid.v2()
	category_translation_1_description := luuid.v2()
	category_translation_2_name := luuid.v2()
	category_translation_2_description := luuid.v2()
	category_seo_title := luuid.v2()
	category_seo_description := luuid.v2()
	category_seo_translation_1_title := luuid.v2()
	category_seo_translation_1_description := luuid.v2()
	category_seo_translation_2_title := luuid.v2()
	category_seo_translation_2_description := luuid.v2()
	category_data := json2.encode(peony.CategoryCreateRequest{
		name:         category_name
		description:  category_description
		translations: {
			secondary_locale_1.id: peony.CategoryTranslationRequest{
				name:        category_translation_1_name
				description: category_translation_1_description
			}
			secondary_locale_2.id: peony.CategoryTranslationRequest{
				name:        category_translation_2_name
				description: category_translation_2_description
			}
		}
		seo:          peony.SEORequest{
			title:        category_seo_title
			description:  category_seo_description
			translations: {
				secondary_locale_1.id: peony.SEOTranslationRequest{
					title:       category_seo_translation_1_title
					description: category_seo_translation_1_description
				}
				secondary_locale_2.id: peony.SEOTranslationRequest{
					title:       category_seo_translation_2_title
					description: category_seo_translation_2_description
				}
			}
		}
	},
		escape_unicode: true
	)
	mut response := do_authenticated_post_request(endpoint_admin_categories, cookie_value,
		category_data)!
	is_created(response)!
	mut decoded := json2.decode[peony.CategoryResponseEnvelope](response.body)!
	new_category := decoded.category

	translations := new_category.translations or { return error('translations missing') }
	seo_translations := new_category.seo.translations or {
		return error('seo translations missiong')
	}

	translation_1 := translations[secondary_locale_1.id]
	translation_2 := translations[secondary_locale_2.id]
	seo_translation_1 := seo_translations[secondary_locale_1.id]
	seo_translation_2 := seo_translations[secondary_locale_2.id]
	st1_title := unwrap_or_error(seo_translation_1.title, 'seo title missing')!
	st1_description := unwrap_or_error(seo_translation_1.description, 'seo description missing')!
	st2_title := unwrap_or_error(seo_translation_2.title, 'seo title missing')!
	st2_description := unwrap_or_error(seo_translation_2.description, 'seo description missing')!

	expect(translation_1.name == category_translation_1_name,
		'category translation 1 title does not match')!
	expect(translation_1.description == category_translation_1_description,
		'category translation 1 description does not match')!
	expect(translation_2.name == category_translation_2_name,
		'category translation 2 title does not match')!
	expect(translation_2.description == category_translation_2_description,
		'category translation 2 description does not match')!
	expect(st1_title == category_seo_translation_1_title, 'seo translation 1 title does not match')!
	expect(st1_description == category_seo_translation_1_description,
		'seo translation 1 description does not match')!
	expect(st2_title == category_seo_translation_2_title, 'seo translation 2 title does not match')!
	expect(st2_description == category_seo_translation_2_description,
		'seo translation 2 description does not match')!

	new_category_data := json2.encode(peony.CategoryUpdateRequest{
		translations: map[string]peony.CategoryTranslationRequest{}
		seo:          peony.SEORequest{
			title:        category_seo_title
			description:  category_seo_description
			translations: map[string]peony.SEOTranslationRequest{}
		}
	},
		escape_unicode: true
	)
	response = do_authenticated_post_request('${endpoint_admin_categories}/${new_category.id}',
		cookie_value, new_category_data)!
	is_ok(response)!
	decoded = json2.decode[peony.CategoryResponseEnvelope](response.body)!
	updated_category := decoded.category
	expect(updated_category.translations == none, 'translations were not deleted')!
	expect(updated_category.seo.translations == none, 'seo translations were not deleted')!

	response = do_authenticated_delete_request('${endpoint_admin_categories}/${new_category.id}',
		cookie_value)!

	remove_secondary_locales(cookie_value)!
}

fn admin_handles_product_translations(cookie_value string) ! {
	println('admin_handles_product_translations')
	secondary_locales := add_random_locales(cookie_value, 2)!
	secondary_locale_1 := secondary_locales[0]
	secondary_locale_2 := secondary_locales[1]

	product_title := luuid.v2()
	product_subtitle := luuid.v2()
	product_description := luuid.v2()
	product_translation_1_title := luuid.v2()
	product_translation_1_subtitle := luuid.v2()
	product_translation_1_description := luuid.v2()
	product_translation_2_title := luuid.v2()
	product_translation_2_subtitle := luuid.v2()
	product_translation_2_description := luuid.v2()
	product_seo_title := luuid.v2()
	product_seo_description := luuid.v2()
	product_seo_translation_1_title := luuid.v2()
	product_seo_translation_1_description := luuid.v2()
	product_seo_translation_2_title := luuid.v2()
	product_seo_translation_2_description := luuid.v2()
	product_data := peony.ProductCreateRequest{
		title:        product_title
		subtitle:     product_subtitle
		description:  product_description
		translations: {
			secondary_locale_1.id: peony.ProductTranslationRequest{
				title:       product_translation_1_title
				subtitle:    product_translation_1_subtitle
				description: product_translation_1_description
			}
			secondary_locale_2.id: peony.ProductTranslationRequest{
				title:       product_translation_2_title
				subtitle:    product_translation_2_subtitle
				description: product_translation_2_description
			}
		}
		seo:          peony.SEORequest{
			title:        product_seo_title
			description:  product_seo_description
			translations: {
				secondary_locale_1.id: peony.SEOTranslationRequest{
					title:       product_seo_translation_1_title
					description: product_seo_translation_1_description
				}
				secondary_locale_2.id: peony.SEOTranslationRequest{
					title:       product_seo_translation_2_title
					description: product_seo_translation_2_description
				}
			}
		}
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value, json2.encode(product_data,
		escape_unicode: true
	))!
	is_created(response)!
	r := json2.decode[peony.ProductResponseEnvelope](response.body)!
	new_product := r.product

	translations := new_product.translations or { return error('translations missing') }
	seo_translations := new_product.translations or { return error('seo translations missing') }

	product_translation_1 := translations[secondary_locale_1.id]
	product_translation_2 := translations[secondary_locale_2.id]
	seo_translation_1 := seo_translations[secondary_locale_1.id]
	seo_translation_2 := seo_translations[secondary_locale_2.id]
	st1_title := unwrap_or_error(seo_translation_1.title, 'seo title missing')!
	st1_description := unwrap_or_error(seo_translation_1.description, 'seo description missing')!
	st2_title := unwrap_or_error(seo_translation_2.title, 'seo title missing')!
	st2_description := unwrap_or_error(seo_translation_2.description, 'seo description missing')!

	expect(product_translation_1.title == product_translation_1_title,
		'product translation 1 title does not match')!
	expect(product_translation_1.subtitle == product_translation_1_subtitle,
		'product translation 1 subtitle does not match')!
	expect(product_translation_1.description == product_translation_1_description,
		'product translation 1 description does not match')!
	expect(product_translation_2.title == product_translation_2_title,
		'product translation 2 title does not match')!
	expect(product_translation_2.subtitle == product_translation_2_subtitle,
		'product translation 2 subtitle does not match')!
	expect(product_translation_2.description == product_translation_2_description,
		'product translation 2 description does not match')!
	expect(st1_title == product_seo_translation_1_title, 'seo translation 1 title does not match')!
	expect(st1_description == product_seo_translation_1_description,
		'seo translation 1 description does not match')!
	expect(st2_title == product_seo_translation_2_title, 'seo translation 2 title does not match')!
	expect(st2_description == product_seo_translation_2_description,
		'seo translation 2 description does not match')!

	// Product
	// product_data = peony.ProductCreateRequest{
	// 	translations: [
	// 		peony.ProductTranslationRequest{

	// 		}
	// 	]
	// 	seo:          peony.SEORequest{
	// 		translations: []
	// 	}
	// }

	response = do_authenticated_delete_request('${endpoint_admin_products}/${new_product.id}',
		cookie_value)!
	remove_secondary_locales(cookie_value)!
}

fn store_regions() ! {
	println('store_regions')
	// list regions
	mut response := do_get_request('/store/regions')!
	is_ok(response)!
	regions := json2.decode[peony.RegionResponseListEnvelope](response.body)!
	default_region := regions.regions[0]
	default_region_id := default_region.id
	// TODO check all expected fields are populated
	// TODO taxes

	// get region by id
	response = do_get_request('/store/regions/${default_region_id}')!
	is_ok(response)!
}

fn test_peony() ! {
	ch := run_app()!
	defer {
		stop_app(ch)
	}

	// auth middleware must be tested before everything else
	auth_middleware_rejects_unauthorized()!
	auth_middleware_allows_logins_and_logouts()!

	admin_auth_wrapper([
		admin_auth_returns_user_data,
		admin_auth_rejects_login_when_already_logged_in,
		admin_users_list_users,
		admin_users_create_and_delete_user,
		admin_locales_lists_locales,
		// admin_regions,
		admin_store,
		admin_store_updates_store_locales,
		admin_categories_create_minimal_category,
		admin_categories_create_complex_category,
		admin_categories_updates_category,
		admin_handles_category_translations,
		// TODO test category parent
		admin_products_create_minimal_product,
		admin_products_create_complex_product,
		admin_products_updates_product,
		admin_products_create_rejects_bad_requests,
		// TODO test list products contains new products
		// TODO test list products does not contain deleted products
		admin_products_handles_product_images,
		admin_handles_product_translations,
		handles_unique_product_handles,
		creates_product_with_one_option,
		creates_product_without_options_with_variant,
		creates_product_with_one_option_and_many_variants,
		creates_product_with_many_options_and_one_variant,
		refuses_product_creation_with_variants_with_same_values,
		creates_product_with_variant_with_regional_prices,
		updates_product_options_ranking,
		updates_variants_ranking,
		creates_product_with_variant_image,
		updates_product_with_variant_image,
		updates_product_replaces_default_variant,
		creates_a_variant,
		updates_a_variant,
		deletes_a_variant,
		// /admin/product/:product_id images update (empty array, re-arrnaged array, complex mix)
		// /admin/product/:product_id variants create, update (ranking too)
		//
		// no variant money_amount provided sets default to 0 for all regions
		// refuse empty variant money_amount array
		// refuse arrays with more than 2 base_price or original_price per region
		//
		// TODO image endpoints
		// TODO options and values
		// TODO inventory item endpoints
		// TODO stock location endpoints
		// TODO inventory level endpoints
		//
	])!

	store_regions()!
}
