import peony
import peony.providers

// deps
import os
import net.http
import time
import json
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

fn do_authenticated_post_request(path string, cookie_value string, body string) !http.Response {
	return do_authenticated_request(path, cookie_value, body, http.Method.post)
}

fn do_authenticated_delete_request(path string, cookie_value string) !http.Response {
	return do_authenticated_request(path, cookie_value, '', http.Method.delete)
}

fn response_is_ok(r http.Response) ! {
	assert r.status_code == 200, 'status ${r.status_code} (${r.status_msg}): ${r.body}'
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
	do_authenticated_delete_request('/admin/auth', cookie_value)!
}

struct RoutineData {
	channel      chan bool
	cookie_value string
}

fn get_routine_data() !RoutineData {
	return RoutineData{
		channel:      run_app()!
		cookie_value: user_login()!
	}
}

const routine_data = get_routine_data()! // runtime mem access error, doesn't happen in other setup

fn testsuite_begin() ! {
	// not needed for now, get_routine_data starts everything
}

fn testsuite_end() ! {
	stop_app(routine_data.channel)
}
