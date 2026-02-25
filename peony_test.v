import peony

// deps
import json
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

fn (bp BlobProviderDummy) create(fd http.FileData) !peony.ProviderBlobFileData {
	if fd.filename == fail_key {
		return error('failed to create file, filename == ${fail_key}')
	}

	id := luuid.v2()
	return peony.ProviderBlobFileData{
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
	result := os.execute('docker run --rm --detach --name=${firebird_container_name} --env=FIREBIRD_ROOT_PASSWORD=${firebird_root_password} --env=FIREBIRD_USER=${firebird_user} --env=FIREBIRD_PASSWORD=${firebird_password} --env=FIREBIRD_DATABASE=${firebird_database} --env=FIREBIRD_DATABASE_DEFAULT_CHARSET=UTF8 --publish=${firebird_port}:3050 firebirdsql/firebird')
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
	result := os.execute('docker run --rm --detach --name=${redict_container_name} --publish=${redict_port}:6379 registry.redict.io/redict')
	if result.exit_code != 0 {
		return error(result.output)
	}
}

fn containers_are_ready() {
	mut firebird_is_loading := true
	mut redict_is_loading := true
	for firebird_is_loading || redict_is_loading {
		if firebird_is_loading {
			check := os.execute('echo "SELECT \'ALIVE\' FROM RDB\\\$DATABASE; quit;" | docker exec -i ${firebird_container_name} isql localhost:${firebird_database_path} -user ${firebird_user} -password ${firebird_password} -q')
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

	providers := peony.Providers{
		blob: new_provider_blob_dummy()
	}

	mut app := peony.new_peony_app(config, providers) or { panic(err) }
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
		request := http.new_request(http.Method.get, 'http://localhost:${port}/admin/auth',
			'')
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

fn response_is_ok(r http.Response) ! {
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
	v := r.header.get(http.CommonHeader.set_cookie)!
	return v.split(';')[0] // remove attributes
}

fn user_login() !string {
	response := do_post_request('/admin/auth', json.encode(peony.AuthRequest{
		email:    default_user_email
		password: default_user_password
	}))!
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
	expect(response.status_code == 401, 'Unathorized request should have been rejected, but it was not.')!
}

fn auth_middleware_allows_logins_and_logouts() ! {
	body := json.encode(peony.AuthRequest{
		email:    default_user_email
		password: default_user_password
	})
	mut response := do_post_request(endpoint_admin_auth, body)!
	response_is_ok(response)!

	cookie_value := extract_cookie_from_set_cookie(response)!

	response = do_authenticated_get_request(endpoint_admin_auth, cookie_value)!
	response_is_ok(response)!

	response = do_authenticated_delete_request(endpoint_admin_auth, cookie_value)!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_auth, cookie_value)!
	expect(response.status_code == 401, 'Expired session was accepted, but it should have not been.')!
}

fn admin_auth_returns_user_data(cookie_value string) ! {
	println('admin_auth_returns_user_data')
	response := do_authenticated_get_request(endpoint_admin_auth, cookie_value)!
	response_is_ok(response)!

	r := json.decode(peony.UserResponseEnvelope, response.body)!
	user := r.user
	expect(user.id != '', 'Returned empty user id')!
	expect(user.email == default_user_email, 'Unexpected user email: ${user.email}')!
	expect(user.handle != '', 'Unexpected user handle: ${user.handle}')!
	expect(user.role == peony.role_admin, 'Unexpected user role: ${user.role}')!
	// TODO test created_at is not zero https://github.com/vlang/v/issues/24765
}

fn admin_auth_rejects_login_when_already_logged_in(cookie_value string) ! {
	println('admin_auth_rejects_login_when_already_logged_in')
	response := do_authenticated_post_request('/admin/auth', cookie_value, json.encode(peony.AuthRequest{
		email:    default_user_email
		password: default_user_password
	}))!
	expect(response.status_code == 400, 'Logged in user was allowed to log in again')!
}

fn admin_users_list_users(cookie_value string) ! {
	println('admin_users_list_users')
	mut response := do_authenticated_get_request(endpoint_admin_users, cookie_value)!
	response_is_ok(response)!
	mut r := json.decode(peony.UserListResponseEnvelope, response.body)!
	expect(r.count != 0, 'Unexpected count: ${r.count}')!
	expect(r.users.len != 0, 'No users returned')!
	expect(r.offset == 0, 'Unexpected offset: ${r.offset}')!
	// expect(r.fetch == 0, 'TODO')

	mut default_user := peony.UserResponse{}
	mut found := false
	for i := 0; i < r.users.len; i++ {
		user := r.users[i]
		if user.email == default_user_email {
			default_user = user
			found = true
			break
		}
	}
	expect(found, 'Default user not found in response')!
	expect(default_user.id != '', 'Unexpected user id: ${default_user.id}')!
	expect(default_user.handle != '', 'Unexpected user handle: ${default_user.handle}')!
	expect(default_user.role == peony.role_admin, 'Unexpected user role: ${default_user.role}')!
}

// Verifies:
// Correctly create users
// Correctly delete users
// Correctly lists new users
// Correctly lists deleted users
fn admin_users_create_and_delete_user(cookie_value string) ! {
	println('admin_users_create_and_delete_user')
	mut response := do_authenticated_get_request(endpoint_admin_users, cookie_value)!
	mut r := json.decode(peony.UserListResponseEnvelope, response.body)!
	old_count := r.count
	old_users_len := r.users.len

	response = do_authenticated_post_request(endpoint_admin_users, cookie_value, json.encode(peony.UserCreateRequest{
		email: 'new_user@peony.com'
	}))!
	expect(response.status_code == 400, 'Invalid request was accepted.')!

	// TODO add all fields
	valid_new_user := peony.UserCreateRequest{
		email:    'new_user@peony.com'
		password: 'new user password'
	}
	response = do_authenticated_post_request(endpoint_admin_users, cookie_value, json.encode(valid_new_user))!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_users, cookie_value)!
	response_is_ok(response)!
	r = json.decode(peony.UserListResponseEnvelope, response.body)!
	expect(r.count == old_count + 1, 'Unexpected count. Count does not include new user')!
	expect(r.users.len == old_users_len + 1, 'Unexpected users.len. Count does not include new user')!

	mut new_user := peony.UserResponse{}
	mut found := false
	for i := 0; i < r.users.len; i++ {
		user := r.users[i]
		if user.email == valid_new_user.email {
			new_user = user
			found = true
			break
		}
	}
	expect(found, 'new user not found')!
	// TODO test all fields

	response = do_authenticated_delete_request('${endpoint_admin_users}/${new_user.id}',
		cookie_value)!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_users, cookie_value)!
	response_is_ok(response)!
	r = json.decode(peony.UserListResponseEnvelope, response.body)!
	expect(r.count == old_count, 'Unexpected count. Count includes deleted user')!
	expect(r.users.len == old_users_len, 'Unexpected users.len. Response includes deleted user')!
}

// TODO /admin/users/:user_id get, post, delete

// TODO offset and params
fn admin_locales_lists_locales(cookie_value string) ! {
	println('admin_locales')
	mut response := do_authenticated_get_request(endpoint_admin_locales, cookie_value)!
	response_is_ok(response)!
	r := json.decode(peony.LocaleResponseListEnvelope, response.body)!
	locale_codes_file := os.read_file('${os.getwd()}/migrations/seed-locale-codes.txt')!
	lines := locale_codes_file.split('\n')
	locale_codes := lines[..lines.len - 1] // remove last character \n (posix)
	expect(r.count == locale_codes.len, 'Count does not match amount of locales that should be in the db')!
	expect(r.offset == 0, 'Wrong page')!
	expect(r.fetch == peony.max_fetch, 'Maximum number of items fetched does not match max_fetch')!
}

// TODO create helper functions to:
// get a valid locale_id
// create a new region and get its id
// create a new stock location and get its id
// create a new sales channel and get its id
fn admin_store(cookie_value string) ! {
	println('admin_store')
	mut response := do_authenticated_get_request(endpoint_admin_store, cookie_value)!
	response_is_ok(response)!

	mut r := json.decode(peony.StoreResponseEnvelope, response.body)!
	mut store := r.store
	// TODO check values

	old_updated_at := store.updated_at

	new_store_name := luuid.v2()
	new_store_data := peony.StoreUpdateRequest{
		name: new_store_name
		// default_locale_id
		// default_region_id
		// default_stock_location_id
		// default_sales_channel_id
	}
	response = do_authenticated_post_request('${endpoint_admin_store}/${r.store.id}',
		cookie_value, json.encode(new_store_data))!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_store, cookie_value)!
	response_is_ok(response)!

	r = json.decode(peony.StoreResponseEnvelope, response.body)!
	store = r.store
	expect(store.name == new_store_name, 'Store name was not updated')!
	expect(store.updated_at != old_updated_at, 'store.updated_at was not updated')!
}

// TODO test refuse to remove default locale
fn admin_store_updates_store_locales(cookie_value string) ! {
	println('admin_store_updates_store_locales')
	mut response := do_authenticated_get_request(endpoint_admin_store, cookie_value)!
	mut r := json.decode(peony.StoreResponseEnvelope, response.body)!
	old_store := r.store

	response = do_authenticated_get_request(endpoint_admin_locales, cookie_value)!
	r_2 := json.decode(peony.LocaleResponseListEnvelope, response.body)!
	locales := r_2.locales

	// get a random locale
	safe_max := peony.max_fetch - 1 // reserve 1
	random_index := rand.int_in_range(0, safe_max)!
	mut random_locale := locales[random_index]
	if random_locale.id == old_store.default_locale_id {
		random_locale = locales[random_index + 1] // safely add 1
	}

	new_locale_ids := [old_store.default_locale_id, random_locale.id]
	new_store_data := json.encode(peony.StoreUpdateRequest{
		locale_ids: new_locale_ids
	})
	response = do_authenticated_post_request('${endpoint_admin_store}/${old_store.id}',
		cookie_value, new_store_data)!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_store, cookie_value)!
	r = json.decode(peony.StoreResponseEnvelope, response.body)!
	new_store := r.store
	expect(new_store.locales.len == new_locale_ids.len, 'Locales array length does not match expectations')!

	restore_old_data := json.encode(peony.StoreUpdateRequest{
		locale_ids: [old_store.default_locale_id]
	})
	response = do_authenticated_post_request('${endpoint_admin_store}/${old_store.id}',
		cookie_value, restore_old_data)!
	response_is_ok(response)!
}

fn admin_categories_create_minimal_category(cookie_value string) ! {
	println('admin_categories_create_minimal_category')
	mut response := do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	response_is_ok(response)!
	mut r := json.decode(peony.CategoryResponseListEnvelope, response.body)!
	old_count := r.count
	old_categories_len := r.categories.len
	expected_count := old_count + 1
	expected_categories_len := old_categories_len + 1

	new_category_name := luuid.v2()
	new_category_data := json.encode(peony.CategoryCreateRequest{
		name: new_category_name
	})
	response = do_authenticated_post_request(endpoint_admin_categories, cookie_value,
		new_category_data)!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	r = json.decode(peony.CategoryResponseListEnvelope, response.body)!
	expect(r.count == expected_count, 'Count does not include newly created category: ${r.count}')!
	expect(r.offset == 0, 'Unexpected offset: ${r.offset}')!
	// expect(r.fetch == 0, 'TODO')
	expect(r.categories.len == expected_categories_len, 'Categories returned do not include newly created category: ${r.categories.len}')!

	mut category_to_delete := peony.CategoryResponse{}
	mut found := false
	for i := 0; i < r.categories.len; i++ {
		category := r.categories[i]
		if category.name == new_category_name {
			category_to_delete = category
			found = true
			break
		}
	}
	expect(found, 'Categories returned do not include newly created category')!

	response = do_authenticated_delete_request('${endpoint_admin_categories}/${category_to_delete.id}',
		cookie_value)!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	response_is_ok(response)!
	r = json.decode(peony.CategoryResponseListEnvelope, response.body)!
	expect(r.count == old_count, 'Count includes deleted category')!
	expect(r.offset == 0, 'Unexpected offset: ${r.offset}')!
	// expect(r.fetch == 0, 'TODO')
	expect(r.categories.len == old_categories_len, 'Categories returned include deleted category')!
}

fn admin_categories_create_complex_category(cookie_value string) ! {
	println('admin_categories_create_complex_category')
	mut response := do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	response_is_ok(response)!
	mut r := json.decode(peony.CategoryResponseListEnvelope, response.body)!
	old_count := r.count
	old_categories_len := r.categories.len
	expected_count := old_count + 1
	expected_categories_len := old_categories_len + 1

	name := luuid.v2()
	description := luuid.v2()
	handle := luuid.v2()
	is_internal := true
	is_active := false
	metadata := luuid.v2()
	seo_title := luuid.v2()
	seo_description := luuid.v2()
	category_data := json.encode(peony.CategoryCreateRequest{
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
	})
	response = do_authenticated_post_request(endpoint_admin_categories, cookie_value,
		category_data)!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	r = json.decode(peony.CategoryResponseListEnvelope, response.body)!
	expect(r.count == expected_count, 'Count does not include newly created category: ${r.count}')!
	expect(r.offset == 0, 'Unexpected offset: ${r.offset}')!
	// expect(r.fetch == 0, 'TODO')
	expect(r.categories.len == expected_categories_len, 'Categories returned do not include newly created category: ${r.categories.len}')!

	mut new_category := peony.CategoryResponse{}
	mut found := false
	for i := 0; i < r.categories.len; i++ {
		c := r.categories[i]
		if c.name == name {
			new_category = c
			found = true
			break
		}
	}
	expect(found, 'Categories returned do not include newly created category')!
	expect(new_category.id != '', 'Category is missing id')!
	expect(new_category.name == name, 'name does not match')!
	expect(new_category.description == description, 'description does not match')!
	expect(new_category.handle == handle, 'handle does not match')!
	expect(new_category.is_internal == is_internal, 'is_internal does not match')!
	expect(new_category.metadata == '"${metadata}"', 'metadata does not match')!
	expect(new_category.seo.title == seo_title, 'seo_title does not match')!
	expect(new_category.seo.description == seo_description, 'seo_description does not match')!

	response = do_authenticated_delete_request('${endpoint_admin_categories}/${new_category.id}',
		cookie_value)!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	response_is_ok(response)!
	r = json.decode(peony.CategoryResponseListEnvelope, response.body)!
	expect(r.count == old_count, 'Count includes deleted category')!
	expect(r.offset == 0, 'Unexpected offset: ${r.offset}')!
	// expect(r.fetch == 0, 'TODO')
	expect(r.categories.len == old_categories_len, 'Categories returned include deleted category')!
}

fn admin_categories_updates_category(cookie_value string) ! {
	println('admin_categories_updates_category')
	new_category_name := luuid.v2()
	new_category_data := json.encode(peony.CategoryCreateRequest{
		name: new_category_name
	})
	mut response := do_authenticated_post_request(endpoint_admin_categories, cookie_value,
		new_category_data)!
	response = do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	mut r := json.decode(peony.CategoryResponseListEnvelope, response.body)!

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
	updated_category_data := json.encode(peony.CategoryUpdateRequest{
		name:        new_name
		description: new_description
		handle:      new_handle
		is_internal: new_is_internal
		is_active:   new_is_active
		metadata:    new_metadata
	})
	time.sleep(1 * time.second) // needed to check updated_at
	response = do_authenticated_post_request('${endpoint_admin_categories}/${new_category.id}',
		cookie_value, updated_category_data)!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	r = json.decode(peony.CategoryResponseListEnvelope, response.body)!
	mut updated_category := peony.CategoryResponse{}
	for i := 0; i < r.categories.len; i++ {
		category := r.categories[i]
		if category.id == new_category.id {
			updated_category = category
			break
		}
	}

	expect(updated_category.updated_at > new_category.updated_at, 'updated_at field was not updated')!
	expect(updated_category.name == new_name, 'name does not match')!
	expect(updated_category.description == new_description, 'description does not match')!
	expect(updated_category.handle == new_handle, 'handle does not match')!
	expect(updated_category.is_internal == new_is_internal, 'is_internal does not match')!
	expect(updated_category.is_active == new_is_active, 'is_internal does not match')!
	expect(updated_category.metadata == '"${new_metadata}"', 'metadata does not match')!

	response = do_authenticated_delete_request('${endpoint_admin_categories}/${new_category.id}',
		cookie_value)!
}

fn admin_categories_create_rejects_bad_requests(cookie_value string) ! {
	println('admin_categories_create_rejects_bad_requests')
	new_category_data := peony.CategoryCreateRequest{}
	response := do_authenticated_post_request(endpoint_admin_categories, cookie_value,
		json.encode(new_category_data))!
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
	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value,
		json.encode(new_product_data))!
	is_created(response)!
	r := json.decode(peony.ProductResponseEnvelope, response.body)!
	created_product := r.product

	response = do_authenticated_delete_request('${endpoint_admin_products}/${created_product.id}',
		cookie_value)!
	response_is_ok(response)!

	response = do_authenticated_get_request('${endpoint_admin_products}/${created_product.id}',
		cookie_value)!
	is_not_found(response)!
}

fn admin_products_create_complex_product(cookie_value string) ! {
	println('admin_products_create_complex_product')
	mut response := do_authenticated_get_request(endpoint_admin_products, cookie_value)!
	response_is_ok(response)!
	mut r := json.decode(peony.ProductResponseListEnvelope, response.body)!
	old_count := r.count
	old_products_len := r.products.len
	expected_count := old_count + 1
	expected_products_len := old_products_len + 1

	title := luuid.v2()
	subtitle := luuid.v2()
	description := luuid.v2()
	handle := luuid.v2()
	status := peony.product_status_draft
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
	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json.encode(new_product_data))!
	is_created(response)!

	response = do_authenticated_get_request(endpoint_admin_products, cookie_value)!
	response_is_ok(response)!
	r = json.decode(peony.ProductResponseListEnvelope, response.body)!
	expect(r.count == expected_count, 'Count does not include the newly created product')!
	expect(r.products.len == expected_products_len, 'Products returned do not include the newly created product: same length.')!

	mut new_product := peony.ProductResponse{}
	mut found := false
	for i := 0; i < r.products.len; i++ {
		product := r.products[i]
		if product.handle == handle {
			new_product = product
			found = true
			break
		}
	}
	expect(found, 'Products returned do not include the newly created product: product not found.')!
	expect(new_product.id != '', 'Product is missing id')!
	expect(new_product.title == title, 'title does not match')!
	expect(new_product.subtitle == subtitle, 'subtitle does not match')!
	expect(new_product.description == description, 'description does not match')!
	expect(new_product.status == status, 'status does not match')!
	expect(new_product.discountable == discountable, 'discountable does not match')!
	expect(new_product.metadata == '"${metadata}"', 'metadata does not match')!
	expect(new_product.seo.title == seo_title, 'seo_title does not match')!
	expect(new_product.seo.description == seo_description, 'seo_description does not match')!
	expect(new_product.thumbnail.id != '', 'thumbnail is missing id')!
	expect(new_product.thumbnail.url == image_1_url, 'thumbnail url does not match')!
	expect(new_product.thumbnail.alt == image_1_alt, 'thumbnail alt does not match')!
	expect(new_product.images.len == 2, 'Missing images')!
	image_0 := new_product.images[0]
	image_1 := new_product.images[1]
	expect(image_0.url == image_0_url, 'image_0_url does not match')!
	expect(image_0.alt == image_0_alt, 'image_0_alt does not match')!
	expect(image_1.url == image_1_url, 'image_1_url does not match')!
	expect(image_1.alt == image_1_alt, 'image_1_alt does not match')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${new_product.id}',
		cookie_value)!
	response_is_ok(response)!
}

fn handles_unique_product_handles(cookie_value string) ! {
	println('handles_unique_product_handles')
	//  create product with no specified handle
	mut new_product_title := luuid.v2()
	mut new_product_data := peony.ProductCreateRequest{
		title: new_product_title
	}
	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value,
		json.encode(new_product_data))!
	response = do_authenticated_get_request(endpoint_admin_products, cookie_value)!
	mut r := json.decode(peony.ProductResponseListEnvelope, response.body)!
	mut created_product := peony.ProductResponse{}
	mut found := false
	for i := 0; i < r.products.len; i++ {
		product := r.products[i]
		if product.title == new_product_title {
			created_product = product
			found = true
			break
		}
	}
	expect(created_product.handle == created_product.title, 'product created with no explicit handle has a handle that does not match title')!
	response = do_authenticated_delete_request('${endpoint_admin_products}/${created_product.id}',
		cookie_value)!

	// create product with specified handle
	new_product_title = luuid.v2()
	mut new_product_handle := luuid.v2()
	new_product_data = peony.ProductCreateRequest{
		title:  new_product_title
		handle: new_product_handle
	}
	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json.encode(new_product_data))!
	response = do_authenticated_get_request(endpoint_admin_products, cookie_value)!
	r = json.decode(peony.ProductResponseListEnvelope, response.body)!
	created_product = peony.ProductResponse{}
	found = false
	for i := 0; i < r.products.len; i++ {
		product := r.products[i]
		if product.handle == new_product_handle {
			created_product = product
			found = true
			break
		}
	}
	expect(found, 'Created product has unexpected handle')!

	// TODO create product with no specified handle and already existing
	// TODO create product with specified handle and already existing
}

fn creates_product_with_options_and_values(cookie_value string) ! {
	// checkbox marks logic was written to handle case, test must be written.
	// [x] TODO reject create a product with one option and no values
	// [ ] TODO create a product with one option, one value and no explicit variants
	// [ ] TODO create a product with 2 options and 2 values for each option, and no explicit variants
	// [ ] TODO create a product with 2 options and 2 values for each option, and 3 explicit variants
}

fn creates_product_with_variants(cookie_value string) ! {
	println('creates_product_with_variants')
	// TODO create a product with no options but with variant data
	// TODO create a product with one option and 2 values, 2 variants
}

fn refuses_variant_with_same_values(cookie_value string) ! {
	println('refuses_variant_with_same_values')
	// TODO create one product with 2 variants with same values
	// TODO first create a product with a variant, then update the product with a variant with same values
}

fn admin_products_updates_product(cookie_value string) ! {
	println('admin_products_updates_product')
	title := luuid.v2()
	original_product_data := peony.ProductCreateRequest{
		title: title
	}
	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value,
		json.encode(original_product_data))!

	response = do_authenticated_get_request(endpoint_admin_products, cookie_value)!
	mut r := json.decode(peony.ProductResponseListEnvelope, response.body)!

	mut new_product := peony.ProductResponse{}
	for i := 0; i < r.products.len; i++ {
		product := r.products[i]
		if product.title == title {
			new_product = product
			break
		}
	}
	new_product_id := new_product.id

	new_title := luuid.v2()
	new_subtitle := luuid.v2()
	new_description := luuid.v2()
	new_handle := luuid.v2()
	new_is_giftcard := true
	new_status := peony.product_status_published
	new_discountable := false
	new_metadata := luuid.v2()
	new_seo_title := luuid.v2()
	new_seo_description := luuid.v2()
	updated_product_data := json.encode(peony.ProductUpdateRequest{
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
	})
	time.sleep(1 * time.second) // needed to check updated_at
	response = do_authenticated_post_request('${endpoint_admin_products}/${new_product.id}',
		cookie_value, updated_product_data)!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_products, cookie_value)!
	r = json.decode(peony.ProductResponseListEnvelope, response.body)!
	mut updated_product := peony.ProductResponse{}
	for i := 0; i < r.products.len; i++ {
		product := r.products[i]
		if product.id == new_product.id {
			updated_product = product
			break
		}
	}

	expect(updated_product.id != '', 'Product is missing id')!
	expect(updated_product.updated_at > new_product.updated_at, 'updated_at field was not updated')!
	expect(updated_product.title == new_title, 'title does not match')!
	expect(updated_product.subtitle == new_subtitle, 'subtitle does not match')!
	expect(updated_product.description == new_description, 'description does not match')!
	expect(updated_product.status == new_status, 'status does not match')!
	expect(updated_product.discountable == new_discountable, 'discountable does not match')!
	expect(updated_product.metadata == '"${new_metadata}"', 'metadata does not match')!
	expect(updated_product.seo.title == new_seo_title, 'seo_title does not match')!
	expect(updated_product.seo.description == new_seo_description, 'seo_description does not match')!
}

fn admin_products_create_rejects_bad_requests(cookie_value string) ! {
	println('admin_products_create_rejects_bad_requests')
	mut new_product_data := peony.ProductCreateRequest{}
	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value,
		json.encode(new_product_data))!
	expect(response.status_code == 422, 'Product was created despite having no title')!

	new_product_data = peony.ProductCreateRequest{
		title: ''
	}
	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json.encode(new_product_data))!
	expect(response.status_code == 422, 'Product was created despite request having empty title')!
}

fn get_category_translation(locale_id string, r peony.CategoryResponse) !peony.CategoryTranslationResponse {
	for i := 0; i < r.translations.len; i++ {
		t := r.translations[i]
		if t.locale_id == locale_id {
			return t
		}
	}
	return error('seo translation not found')
}

fn get_product_translation(locale_id string, r peony.ProductResponse) !peony.ProductTranslationResponse {
	for i := 0; i < r.translations.len; i++ {
		t := r.translations[i]
		if t.locale_id == locale_id {
			return t
		}
	}
	return error('seo translation not found')
}

fn get_seo_translation(locale_id string, r peony.SEOResponse) !peony.SEOTranslationResponse {
	for i := 0; i < r.translations.len; i++ {
		t := r.translations[i]
		if t.locale_id == locale_id {
			return t
		}
	}
	return error('seo translation not found')
}

fn add_random_locales(cookie_value string, locales_amount i32) ![]peony.LocaleResponse {
	mut response := do_authenticated_get_request(endpoint_admin_store, cookie_value)!
	r := json.decode(peony.StoreResponseEnvelope, response.body)!
	store := r.store
	default_locale_id := store.default_locale_id

	response = do_authenticated_get_request(endpoint_admin_locales, cookie_value)!
	r_2 := json.decode(peony.LocaleResponseListEnvelope, response.body)!
	available_locales := r_2.locales

	mut locales := []peony.LocaleResponse{len: locales_amount}
	mut new_locale_ids := []string{len: locales_amount + 1}
	// TODO check locales_amount is not a crazy number (negative, insane large...)

	// reserve number of locales and one for default locale if encountered
	safe_max := peony.max_fetch - locales_amount - 1
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

	new_store_data := json.encode(peony.StoreUpdateRequest{
		locale_ids: new_locale_ids
	})
	response = do_authenticated_post_request('${endpoint_admin_store}/${store.id}', cookie_value,
		new_store_data)!
	response_is_ok(response)!
	return locales
}

fn remove_secondary_locales(cookie_value string) ! {
	mut response := do_authenticated_get_request(endpoint_admin_store, cookie_value)!
	r := json.decode(peony.StoreResponseEnvelope, response.body)!
	store := r.store
	default_locale_id := store.default_locale_id

	new_store_data := json.encode(peony.StoreUpdateRequest{
		locale_ids: [default_locale_id]
	})
	response = do_authenticated_post_request('${endpoint_admin_store}/${store.id}', cookie_value,
		new_store_data)!
	response_is_ok(response)!
}

fn get_random_image_create_request(secondary_locales []peony.LocaleResponse) peony.ImageCreateRequest {
	mut translations := []peony.ImageTranslationRequest{len: secondary_locales.len}
	if secondary_locales.len > 0 {
		for i := 0; i < secondary_locales.len; i++ {
			l := secondary_locales[i]
			translations[i] = peony.ImageTranslationRequest{
				locale_id: l.id
				alt:       luuid.v2()
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
	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value,
		json.encode(original_product_data))!
	is_created(response)!

	response = do_authenticated_get_request(endpoint_admin_products, cookie_value)!
	mut r := json.decode(peony.ProductResponseListEnvelope, response.body)!

	mut new_product := peony.ProductResponse{}
	for i := 0; i < r.products.len; i++ {
		product := r.products[i]
		if product.title == title {
			new_product = product
			break
		}
	}

	product_id := new_product.id
	expect(new_product.images.len == n_images, 'number of images created does not match')!
	new_thumbnail := new_product.thumbnail
	expect(new_thumbnail.id == new_product.images[0].id, 'thumbnail is the wrong image')!

	for i := 0; i < new_product.images.len; i++ {
		requested_image := images[i]
		new_image := new_product.images[i]

		expect(new_image.id != '', 'image id is missing')!
		expect(new_image.url == requested_image.url, 'image_1 url does not match')!

		if alt := requested_image.alt {
			expect(new_image.alt == alt, 'image_1 alt does not match')!
		}

		// verify all requested translations were created
		if requested_image_translations := requested_image.translations {
			expect(new_image.translations.len == requested_image_translations.len, 'image ${i} translations differ in number')!
			for j := 0; j < secondary_locales.len; j++ {
				locale := secondary_locales[j]
				mut found := false
				for k := 0; k < new_image.translations.len; k++ {
					translation := new_image.translations[k]
					if translation.locale_id == locale.id {
						found = true
						break
					}
				}
				expect(found, 'secondary locale not found in image ${i} translations')!
			}
		}
	}

	// update sorting order
	mut images_update := [
		peony.ImageUpdateRequest{
			id: new_product.images[2].id
		},
		peony.ImageUpdateRequest{
			id: new_product.images[0].id
		},
		peony.ImageUpdateRequest{
			id: new_product.images[1].id
		},
	]
	mut product_update := peony.ProductUpdateRequest{
		images: images_update
	}

	response = do_authenticated_post_request('${endpoint_admin_products}/${product_id}',
		cookie_value, json.encode(product_update))!
	response_is_ok(response)!

	response = do_authenticated_get_request('${endpoint_admin_products}/${product_id}',
		cookie_value)!
	mut r_by_id := json.decode(peony.ProductResponseEnvelope, response.body)!
	updated_product := r_by_id.product
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
	category_data := json.encode(peony.CategoryCreateRequest{
		name:         category_name
		description:  category_description
		translations: [
			peony.CategoryTranslationRequest{
				locale_id:   secondary_locale_1.id
				name:        category_translation_1_name
				description: category_translation_1_description
			},
			peony.CategoryTranslationRequest{
				locale_id:   secondary_locale_2.id
				name:        category_translation_2_name
				description: category_translation_2_description
			},
		]
		seo:          peony.SEORequest{
			title:        category_seo_title
			description:  category_seo_description
			translations: [
				peony.SEOTranslationRequest{
					locale_id:   secondary_locale_1.id
					title:       category_seo_translation_1_title
					description: category_seo_translation_1_description
				},
				peony.SEOTranslationRequest{
					locale_id:   secondary_locale_2.id
					title:       category_seo_translation_2_title
					description: category_seo_translation_2_description
				},
			]
		}
	})
	mut response := do_authenticated_post_request(endpoint_admin_categories, cookie_value,
		category_data)!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	mut category_r := json.decode(peony.CategoryResponseListEnvelope, response.body)!
	categories := category_r.categories
	mut new_category := peony.CategoryResponse{}
	for i := 0; i < categories.len; i++ {
		category := categories[i]
		if category.name == category_name {
			new_category = category
			break
		}
	}

	category_translation_1 := get_category_translation(secondary_locale_1.id, new_category)!
	category_translation_2 := get_category_translation(secondary_locale_2.id, new_category)!
	mut seo_translation_1 := get_seo_translation(secondary_locale_1.id, new_category.seo)!
	mut seo_translation_2 := get_seo_translation(secondary_locale_2.id, new_category.seo)!
	expect(category_translation_1.name == category_translation_1_name, 'category translation 1 title does not match')!
	expect(category_translation_1.description == category_translation_1_description, 'category translation 1 description does not match')!
	expect(category_translation_2.name == category_translation_2_name, 'category translation 2 title does not match')!
	expect(category_translation_2.description == category_translation_2_description, 'category translation 2 description does not match')!
	expect(seo_translation_1.title == category_seo_translation_1_title, 'seo translation 1 title does not match')!
	expect(seo_translation_1.description == category_seo_translation_1_description, 'seo translation 1 description does not match')!
	expect(seo_translation_2.title == category_seo_translation_2_title, 'seo translation 2 title does not match')!
	expect(seo_translation_2.description == category_seo_translation_2_description, 'seo translation 2 description does not match')!

	new_category_data := json.encode(peony.CategoryUpdateRequest{
		translations: []peony.CategoryTranslationRequest{}
		seo:          peony.SEORequest{
			title:        category_seo_title
			description:  category_seo_description
			translations: []peony.SEOTranslationRequest{}
		}
	})
	response = do_authenticated_post_request('${endpoint_admin_categories}/${new_category.id}',
		cookie_value, new_category_data)!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	category_r = json.decode(peony.CategoryResponseListEnvelope, response.body)!

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
		translations: [
			peony.ProductTranslationRequest{
				locale_id:   secondary_locale_1.id
				title:       product_translation_1_title
				subtitle:    product_translation_1_subtitle
				description: product_translation_1_description
			},
			peony.ProductTranslationRequest{
				locale_id:   secondary_locale_2.id
				title:       product_translation_2_title
				subtitle:    product_translation_2_subtitle
				description: product_translation_2_description
			},
		]
		seo:          peony.SEORequest{
			title:        product_seo_title
			description:  product_seo_description
			translations: [
				peony.SEOTranslationRequest{
					locale_id:   secondary_locale_1.id
					title:       product_seo_translation_1_title
					description: product_seo_translation_1_description
				},
				peony.SEOTranslationRequest{
					locale_id:   secondary_locale_2.id
					title:       product_seo_translation_2_title
					description: product_seo_translation_2_description
				},
			]
		}
	}

	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value,
		json.encode(product_data))!
	is_created(response)!
	response = do_authenticated_get_request(endpoint_admin_products, cookie_value)!
	product_r := json.decode(peony.ProductResponseListEnvelope, response.body)!
	mut new_product := peony.ProductResponse{}
	for i := 0; i < product_r.products.len; i++ {
		product := product_r.products[i]
		if product.title == product_title {
			new_product = product
			break
		}
	}

	product_translation_1 := get_product_translation(secondary_locale_1.id, new_product)!
	product_translation_2 := get_product_translation(secondary_locale_2.id, new_product)!
	seo_translation_1 := get_seo_translation(secondary_locale_1.id, new_product.seo)!
	seo_translation_2 := get_seo_translation(secondary_locale_2.id, new_product.seo)!
	expect(product_translation_1.title == product_translation_1_title, 'product translation 1 title does not match')!
	expect(product_translation_1.subtitle == product_translation_1_subtitle, 'product translation 1 subtitle does not match')!
	expect(product_translation_1.description == product_translation_1_description, 'product translation 1 description does not match')!
	expect(product_translation_2.title == product_translation_2_title, 'product translation 2 title does not match')!
	expect(product_translation_2.subtitle == product_translation_2_subtitle, 'product translation 2 subtitle does not match')!
	expect(product_translation_2.description == product_translation_2_description, 'product translation 2 description does not match')!
	expect(seo_translation_1.title == product_seo_translation_1_title, 'seo translation 1 title does not match')!
	expect(seo_translation_1.description == product_seo_translation_1_description, 'seo translation 1 description does not match')!
	expect(seo_translation_2.title == product_seo_translation_2_title, 'seo translation 2 title does not match')!
	expect(seo_translation_2.description == product_seo_translation_2_description, 'seo translation 2 description does not match')!

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
	response_is_ok(response)!
	regions := json.decode(peony.RegionResponseListEnvelope, response.body)!
	default_region := regions.regions[0]
	default_region_id := default_region.id
	// TODO check all expected fields are populated
	// TODO taxes

	// get region by id
	response = do_get_request('/store/regions/${default_region_id}')!
	response_is_ok(response)!
}

fn testsuite_begin() ! {
	// TODO make this start services and auth
	// problem: need to share channel and cookie with rest of tests

	// ch := run_app()!
	// cookie_value := user_login()!
}

fn testsuite_end() ! {
	// TODO make this stop services
	// problem: need to have access to channel

	// stop_app(ch)
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
		// TODO test store update updated_at
		admin_categories_create_minimal_category,
		admin_categories_create_complex_category,
		admin_categories_updates_category,
		admin_handles_category_translations,
		// TODO test category parent
		admin_products_create_minimal_product,
		admin_products_create_complex_product,
		admin_products_updates_product,
		admin_products_create_rejects_bad_requests,
		admin_products_handles_product_images,
		admin_handles_product_translations,
		handles_unique_product_handles,
		creates_product_with_options_and_values,
		creates_product_with_variants,
		refuses_variant_with_same_values,
		// /admin/product/:product_id images update (empty array, re-arrnaged array, complex mix)
		// /admin/product/:product_id variants create, update (ranking too)
		//
		// no variant money_amount provided sets default to 0 for all regions
		// refuse empty variant money_amount array
		// refuse arrays with more than 2 base_price or original_price per region
		//
		//
		// TODO options and values
		// TODO variants endpoints
		// TODO inventory item endpoints
		// TODO stock location endpoints
		// TODO inventory level endpoints
		//
	])!

	store_regions()!
}
