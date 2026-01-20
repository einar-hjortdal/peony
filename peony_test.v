module peony

import os
import net.http
import time
import einar_hjortdal.luuid
import json

const test_fail_key = 'fail'
const test_firebird_container_name = 'test_firebird_server'
const test_firebird_port = '3051'
const test_firebird_user = 'test_user'
const test_firebird_root_password = 'test_root_password'
const test_firebird_password = 'test_password'
const test_firebird_database = 'test_database.fdb'
const test_firebird_database_path = '/var/lib/firebird/data/${test_firebird_database}'
const test_firebird_url = 'firebird://${test_firebird_user}:${test_firebird_password}@localhost:${test_firebird_port}${test_firebird_database_path}'
const test_redict_container_name = 'test_redict_server'
const test_redict_port = '6380'
const test_redict_url = 'redict://@localhost:${test_redict_port}/0'
const test_session_secret = 'testSessionSecret'
const test_port = 12080
const test_default_user_email = 'info@peony.com'
const test_default_user_password = 'very-secret-password'

const endpoint_admin_auth = '/admin/auth'
const endpoint_admin_users = '/admin/users'
const endpoint_admin_categories = '/admin/categories'
const endpoint_admin_products = '/admin/products'

// mock providers (each implementation requires its own independent tests)
struct BlobProviderDummy {}

fn new_provider_blob_dummy() &BlobProviderDummy {
	return &BlobProviderDummy{}
}

fn (bp BlobProviderDummy) create(fd http.FileData) !ProviderBlobFileData {
	if fd.filename == test_fail_key {
		return error('failed to create file, filename == ${test_fail_key}')
	}

	id := luuid.v2()
	return ProviderBlobFileData{
		id:  id
		url: 'https://BlobProvider.Dummy/${id}'
	}
}

fn (bp BlobProviderDummy) delete(id string) ! {
	if id == test_fail_key {
		return error('failed to delete file, filename == ${test_fail_key}')
	}
}

fn container_firebird_clean() {
	result := os.execute('docker stop ${test_firebird_container_name}')
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
	result := os.execute('docker run --rm --detach --name=${test_firebird_container_name} --env=FIREBIRD_ROOT_PASSWORD=${test_firebird_root_password} --env=FIREBIRD_USER=${test_firebird_user} --env=FIREBIRD_PASSWORD=${test_firebird_password} --env=FIREBIRD_DATABASE=${test_firebird_database} --env=FIREBIRD_DATABASE_DEFAULT_CHARSET=UTF8 --publish=${test_firebird_port}:3050 firebirdsql/firebird')
	if result.exit_code != 0 {
		return error(result.output)
	}
}

fn container_redict_clean() {
	result := os.execute('docker stop ${test_redict_container_name}')
	if result.exit_code != 0 {
		if result.output.contains('No such container') {
			return
		}
		eprintln(result.output)
	}
}

fn container_redict_start() ! {
	container_redict_clean() // kill container if already running
	result := os.execute('docker run --rm --detach --name=${test_redict_container_name} --publish=${test_redict_port}:6379 registry.redict.io/redict')
	if result.exit_code != 0 {
		return error(result.output)
	}
}

fn containers_are_ready() {
	mut firebird_is_loading := true
	mut redict_is_loading := true
	for firebird_is_loading || redict_is_loading {
		if firebird_is_loading {
			check := os.execute('echo "SELECT \'ALIVE\' FROM RDB\\\$DATABASE; quit;" | docker exec -i ${test_firebird_container_name} isql localhost:${test_firebird_database_path} -user ${test_firebird_user} -password ${test_firebird_password} -q')
			if check.output.contains('ALIVE') {
				firebird_is_loading = false
			}
		}

		if redict_is_loading {
			ping := os.execute('docker exec ${test_redict_container_name} redict-cli ping')
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
	config := Config{
		debug:                 true
		firebird_url:          test_firebird_url
		redict_url:            test_redict_url
		port:                  test_port
		default_user_email:    test_default_user_email
		default_user_password: test_default_user_password
		session_secret:        test_session_secret
	}

	providers := Providers{
		blob: new_provider_blob_dummy()
	}

	mut app := new_peony_app(config, providers) or { panic(err) }
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
		request := http.new_request(http.Method.get, 'http://localhost:${test_port}/admin/auth',
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
	return 'http://localhost:${test_port}${s}'
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

fn extract_cookie_from_set_cookie(r http.Response) !string {
	v := r.header.get(http.CommonHeader.set_cookie)!
	return v.split(';')[0] // remove attributes
}

fn user_login() !string {
	response := do_post_request('/admin/auth', json.encode(AuthRequest{
		email:    test_default_user_email
		password: test_default_user_password
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
	body := json.encode(AuthRequest{
		email:    test_default_user_email
		password: test_default_user_password
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
	response := do_authenticated_get_request(endpoint_admin_auth, cookie_value)!
	response_is_ok(response)!

	r := json.decode(UserResponseEnvelope, response.body)!
	user := r.user
	expect(user.id != '', 'Returned empty user id')!
	expect(user.email == test_default_user_email, 'Unexpected user email: ${user.email}')!
	expect(user.handle != '', 'Unexpected user handle: ${user.handle}')!
	expect(user.role == role_admin, 'Unexpected user role: ${user.role}')!
	// TODO test created_at is not zero https://github.com/vlang/v/issues/24765
}

fn admin_users_list_users(cookie_value string) ! {
	mut response := do_authenticated_get_request(endpoint_admin_users, cookie_value)!
	response_is_ok(response)!
	mut r := json.decode(UserListResponseEnvelope, response.body)!
	expect(r.count != 0, 'Unexpected count: ${r.count}')!
	expect(r.users.len != 0, 'No users returned')!
	expect(r.offset == 0, 'Unexpected offset: ${r.offset}')!
	// expect(r.fetch == 0, 'TODO')

	mut default_user := UserResponse{}
	mut found := false
	for i := 0; i < r.users.len; i++ {
		user := r.users[i]
		if user.email == test_default_user_email {
			default_user = user
			found = true
			break
		}
	}
	expect(found, 'Default user not found in response')!
	expect(default_user.id != '', 'Unexpected user id: ${default_user.id}')!
	expect(default_user.handle != '', 'Unexpected user handle: ${default_user.handle}')!
	expect(default_user.role == role_admin, 'Unexpected user role: ${default_user.role}')!
}

// Verifies:
// Correctly create users
// Correctly delete users
// Correctly lists new users
// Correctly lists deleted users
fn admin_users_create_and_delete_user(cookie_value string) ! {
	mut response := do_authenticated_get_request(endpoint_admin_users, cookie_value)!
	mut r := json.decode(UserListResponseEnvelope, response.body)!
	old_count := r.count
	old_users_len := r.users.len

	response = do_authenticated_post_request(endpoint_admin_users, cookie_value, json.encode(UserCreateRequest{
		email: 'new_user@peony.com'
	}))!
	expect(response.status_code == 400, 'Invalid request was accepted.')!

	// TODO add all fields
	valid_new_user := UserCreateRequest{
		email:    'new_user@peony.com'
		password: 'new user password'
	}
	response = do_authenticated_post_request(endpoint_admin_users, cookie_value, json.encode(valid_new_user))!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_users, cookie_value)!
	response_is_ok(response)!
	r = json.decode(UserListResponseEnvelope, response.body)!
	expect(r.count == old_count + 1, 'Unexpected count. Count does not include new user')!
	expect(r.users.len == old_users_len + 1, 'Unexpected users.len. Count does not include new user')!

	mut new_user := UserResponse{}
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
	r = json.decode(UserListResponseEnvelope, response.body)!
	expect(r.count == old_count, 'Unexpected count. Count includes deleted user')!
	expect(r.users.len == old_users_len, 'Unexpected users.len. Response includes deleted user')!
}

// TODO /admin/users/:user_id get, post, delete

// TODO create helper functions to:
// get a valid locale_id
// create a new region and get its id
// create a new stock location and get its id
// create a new sales channel and get its id
fn admin_store(cookie_value string) ! {
	endpoint := '/admin/store'
	mut response := do_authenticated_get_request(endpoint, cookie_value)!
	response_is_ok(response)!

	mut r := json.decode(StoreResponseEnvelope, response.body)!
	mut store := r.store
	// TODO check values

	old_updated_at := store.updated_at

	new_store_name := luuid.v2()
	new_store_data := StoreUpdateRequest{
		name: new_store_name
		// default_locale_id
		// default_region_id
		// default_stock_location_id
		// default_sales_channel_id
		// locale_ids
	}
	response = do_authenticated_post_request('${endpoint}/${r.store.id}', cookie_value,
		json.encode(new_store_data))!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint, cookie_value)!
	response_is_ok(response)!

	r = json.decode(StoreResponseEnvelope, response.body)!
	store = r.store
	expect(store.name == new_store_name, 'Store name was not updated')!
	expect(store.updated_at != old_updated_at, 'store.updated_at was not updated')!
}

fn admin_categories_create_minimal_category(cookie_value string) ! {
	mut response := do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	response_is_ok(response)!
	mut r := json.decode(CategoryResponseListEnvelope, response.body)!
	old_count := r.count
	old_categories_len := r.categories.len
	expected_count := old_count + 1
	expected_categoriess_len := old_categories_len + 1

	name := luuid.v2()
	new_category_data := CategoryCreateRequest{
		name: name
	}
	response = do_authenticated_post_request(endpoint_admin_categories, cookie_value,
		json.encode(new_category_data))!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_categories, cookie_value)!
	response_is_ok(response)!
	r = json.decode(CategoryResponseListEnvelope, response.body)!

	expect(r.count == expected_count, 'Count does not include newly created category: ${r.count}')!
	expect(r.offset == 0, 'Unexpected offset: ${r.offset}')!
	// expect(r.fetch == 0, 'TODO')
	expect(r.categories.len == expected_categoriess_len, 'Categories returned do not include newly created category: ${r.categories.len}')!

	mut new_category := CategoryResponse{}
	mut found := false
	for i := 0; i < r.categories.len; i++ {
		category := r.categories[i]
		if category.name == name {
			new_category = category
			found = true
			break
		}
	}
	expect(found, 'Categories returned do not include newly created category')!

	response = do_authenticated_delete_request('${endpoint_admin_categories}/${new_category.id}',
		cookie_value)!
	response_is_ok(response)!
}

fn admin_categories_create_rejects_bad_requests(cookie_value string) ! {
	new_category_data := CategoryCreateRequest{}
	response := do_authenticated_post_request(endpoint_admin_categories, cookie_value,
		json.encode(new_category_data))!
	expect(response.status_code == 400, 'Category was created despite having no name')!
}

// Verifies:
// Correctly create minimal product (only title provided)
// Correctly delete product
// Correctly lists new product
// Correctly lists deleted product
fn admin_products_create_minimal_product(cookie_value string) ! {
	mut response := do_authenticated_get_request(endpoint_admin_products, cookie_value)!
	response_is_ok(response)!
	mut r := json.decode(ProductResponseListEnvelope, response.body)!
	old_count := r.count
	old_products_len := r.products.len
	expected_count := old_count + 1
	expected_products_len := old_products_len + 1

	new_product_title := luuid.v2()
	new_product_data := ProductCreateRequest{
		title: new_product_title
	}
	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json.encode(new_product_data))!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_products, cookie_value)!
	response_is_ok(response)!
	r = json.decode(ProductResponseListEnvelope, response.body)!
	expect(r.count == expected_count, 'Count does not include newly created product: ${r.count}')!
	expect(r.offset == 0, 'Unexpected offset: ${r.offset}')!
	// expect(r.fetch == 0, 'TODO')
	expect(r.products.len == expected_products_len, 'Products returned do not include newly created product: ${r.products.len}')!

	mut product_to_delete := ProductResponse{}
	mut found := false
	for i := 0; i < r.products.len; i++ {
		product := r.products[i]
		if product.title == new_product_title {
			product_to_delete = product
			found = true
			break
		}
	}
	expect(found, 'Products returned do not include newly created product')!

	response = do_authenticated_delete_request('${endpoint_admin_products}/${product_to_delete.id}',
		cookie_value)!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_products, cookie_value)!
	response_is_ok(response)!
	r = json.decode(ProductResponseListEnvelope, response.body)!
	expect(r.count == old_count, 'Count includes deleted product')!
	expect(r.offset == 0, 'Unexpected offset: ${r.offset}')!
	// expect(r.fetch == 0, 'TODO')
	expect(r.products.len == old_products_len, 'Products returned include deleted product')!
}

fn admin_products_create_complex_product(cookie_value string) ! {
	mut response := do_authenticated_get_request(endpoint_admin_products, cookie_value)!
	response_is_ok(response)!
	mut r := json.decode(ProductResponseListEnvelope, response.body)!
	old_count := r.count
	old_products_len := r.products.len
	expected_count := old_count + 1
	expected_products_len := old_products_len + 1

	title := luuid.v2()
	subtitle := luuid.v2()
	description := luuid.v2()
	handle := luuid.v2()
	status := product_status_draft
	discountable := true
	metadata := luuid.v2()
	seo_title := luuid.v2()
	seo_description := luuid.v2()
	thumbnail := 1 // expecting the new product's thumbail to be equal to image_1
	image_0_url := luuid.v2()
	image_0_alt := luuid.v2()
	image_1_url := luuid.v2()
	image_1_alt := luuid.v2()
	new_product_data := ProductCreateRequest{
		title:        title
		subtitle:     subtitle
		description:  description
		handle:       handle
		status:       status
		discountable: discountable
		metadata:     metadata
		seo:          SEOUpdateRequest{
			title:       seo_title
			description: seo_description
		}
		thumbnail:    1
		images:       [
			ImageRequest{
				url: image_0_url
				alt: image_0_alt
			},
			ImageRequest{
				url: image_1_url
				alt: image_1_alt
			},
		]
	}
	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json.encode(new_product_data))!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint_admin_products, cookie_value)!
	response_is_ok(response)!
	r = json.decode(ProductResponseListEnvelope, response.body)!
	expect(r.count == expected_count, 'Count does not include the newly created product')!
	expect(r.products.len == expected_products_len, 'Products returned do not include the newly created product: same length.')!

	mut new_product := ProductResponse{}
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

fn admin_products_create_rejects_bad_requests(cookie_value string) ! {
	mut new_product_data := ProductCreateRequest{}
	mut response := do_authenticated_post_request(endpoint_admin_products, cookie_value,
		json.encode(new_product_data))!
	expect(response.status_code == 400, 'Product was created despite having no title')!

	new_product_data = ProductCreateRequest{
		title: ''
	}
	response = do_authenticated_post_request(endpoint_admin_products, cookie_value, json.encode(new_product_data))!
	expect(response.status_code == 400, 'Product was created despite request having empty title')!
}

fn store_regions() ! {
	// list regions
	mut response := do_get_request('/store/regions')!
	response_is_ok(response)!
	regions := json.decode(RegionResponseListEnvelope, response.body)!
	default_region := regions.regions[0]
	default_region_id := default_region.id
	// TODO check all expected fields are populated
	// TODO taxes

	// get region by id
	response = do_get_request('/store/regions/${default_region_id}')!
	response_is_ok(response)!
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
		admin_users_list_users,
		admin_users_create_and_delete_user,
		admin_store,
		admin_categories_create_minimal_category,
		admin_products_create_minimal_product,
		admin_products_create_complex_product,
		admin_products_create_rejects_bad_requests,
		// TODO test SEO. When update, delete all current data and insert new data.
	])!

	store_regions()!
}
