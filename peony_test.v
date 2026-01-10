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
const test_port = 8081
const test_default_user_email = 'info@peony.com'
const test_default_user_password = 'very-secret-password'

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
		if _ := request.do() {
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
	request.add_header(http.CommonHeader.cookie, cookie_value)
	return request.do()
}

fn do_authenticated_get_request(path string, cookie_value string) !http.Response {
	return do_authenticated_request(path, cookie_value, '', http.Method.get)
}

fn do_authenticated_post_request(path string, cookie_value string, body string) !http.Response {
	return do_authenticated_request(path, cookie_value, body, http.Method.get)
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

fn authenticated_wrapper(suite fn (provided_cookie_value string) !) ! {
	cookie_value := user_login()!
	suite(cookie_value)!
	defer {
		user_logout(cookie_value) or {}
	}
}

fn admin_auth() ! {
	endpoint := '/admin/auth'
	// middleware should reject unauthorized request
	mut response := do_get_request(endpoint)!
	if response.status_code != 401 {
		return error('Unathorized request should have been rejected, but it was not.')
	}

	// middleware should allow unauthenticated users to log in
	body := json.encode(AuthRequest{
		email:    test_default_user_email
		password: test_default_user_password
	})
	response = do_post_request(endpoint, body)!
	response_is_ok(response)!

	// middleware should allow authenticated requests
	cookie_value := extract_cookie_from_set_cookie(response)!
	response = do_authenticated_get_request(endpoint, cookie_value)!
	response_is_ok(response)!

	response = do_authenticated_delete_request(endpoint, cookie_value)!
	response_is_ok(response)!

	response = do_authenticated_get_request(endpoint, cookie_value)!
	if response.status_code != 401 {
		return error('Expired session was accepted, but it shouldn have not been.')
	}
}

fn admin_users(cookie_value string) ! {
	endpoint := '/admin/users'
	mut response := do_authenticated_get_request(endpoint, cookie_value)!
	response_is_ok(response)!
	mut r := json.decode(UserListResponseEnvelope, response.body)!
	if r.count != 1 {
		return error('Unexpected count: ${r.count}')
	}

	if r.users.len != 1 {
		return error('Unexpected number of users: ${r.users.len}')
	}

	if r.offset != 0 {
		return error('Unexpected offset: ${r.offset}')
	}

	if r.fetch != 0 {
		println('TODO decide default fetch amount and apply everywhere')
	}

	user := r.users[0]
	// TODO check fields are as expected

	response = do_authenticated_post_request(endpoint, cookie_value, json.encode(UserCreateRequest{
		email: 'new_user@peony.com'
	}))!
	if response.status_code != 400 {
		return error('Invalid request was accepted.')
	}

	valid_new_user := UserCreateRequest{
		email:    'new_user@peony.com'
		password: 'new user password'
	}
	response = do_authenticated_post_request(endpoint, cookie_value, json.encode(valid_new_user))!
	response_is_ok(response)!

	// TODO /admin/users/:user_id get, post, delete
}

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

	new_store_data := StoreUpdateRequest{
		name: 'new store name'
		// default_locale_id
		// default_region_id
		// default_stock_location_id
		// default_sales_channel_id
		// locale_ids
	}
	response = do_authenticated_post_request('${endpoint}/:${r.store.id}', cookie_value,
		json.encode(new_store_data))!
	response_is_ok(response)!
	r = json.decode(StoreResponseEnvelope, response.body)!
	if r.store.name != new_store_data.name {
		return error('Store name was not updated: expected ${new_store_data.name}, got ${r.store.name}')
	}
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

	admin_auth()!
	authenticated_wrapper(admin_users)!

	store_regions()!
}
