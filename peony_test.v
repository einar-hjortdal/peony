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
	time.sleep(30 * time.second) // need to wait for app startup. TODO fix magic number
	return ch
}

fn stop_app(ch chan bool) {
	ch <- true
	time.sleep(5 * time.second) // wait for docker to stop containers. TODO fix magic number
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

fn do_authenticated_get_request(path string, cookie_value string) !http.Response {
	mut request := http.new_request(http.Method.get, build_url(path), '')
	request.add_header(http.CommonHeader.cookie, cookie_value)
	return request.do()!
}

fn response_is_ok(r http.Response) ! {
	if r.status_code != 200 {
		return error('status ${r.status_code} (${r.status_msg}): ${r.body}')
	}
}

fn extract_set_cookie(r http.Response) !string {
	v := r.header.get(http.CommonHeader.set_cookie)!
	return v.split(';')[0] // remove attributes
}

// TODO In order to be able to run multiple tests asynchronously:
// Check if port is in use or not, if in use, change all ports and try again.
// Use a more reliable technique than time.sleep to wait for things to be done.
fn test_peony() ! {
	ch := run_app()!
	defer {
		stop_app(ch)
	}

	// auth
	// middleware should reject unauthorized request
	mut response := do_get_request('/admin/auth')!
	assert response.status_code == 401

	// middleware should allow unauthenticated users to log in
	body := json.encode(AuthRequest{
		email:    test_default_user_email
		password: test_default_user_password
	})
	response = do_post_request('/admin/auth', body)!
	response_is_ok(response)!

	// middleware should allow authenticated requests
	cookie_value := extract_set_cookie(response)!
	response = do_authenticated_get_request('/admin/auth', cookie_value)!
	response_is_ok(response)!

	// list regions
	response = do_get_request('/store/regions')!
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
