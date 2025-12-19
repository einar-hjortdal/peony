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
const test_firebird_url = 'firebird://${test_firebird_user}:${test_firebird_password}@localhost:${test_firebird_port}/var/lib/firebird/data/${test_firebird_database}'
const test_redict_container_name = 'test_redict_server'
const test_redict_port = '6380'
const test_redict_url = 'redict://@localhost:${test_redict_port}/0'
const test_session_secret = 'testSessionSecret'
const test_peony_port = '8081'
const test_peony_email = 'info@peony.com'
const test_peony_password = 'very-secret-password'

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

// Remember to `sudo usermod -aG docker $USER`
fn container_firebird_start() ! {
	result := os.execute('docker run --rm --detach --name=${test_firebird_container_name} --env=FIREBIRD_ROOT_PASSWORD=${test_firebird_root_password} --env=FIREBIRD_USER=${test_firebird_user} --env=FIREBIRD_PASSWORD=${test_firebird_password} --env=FIREBIRD_DATABASE=${test_firebird_database} --env=FIREBIRD_DATABASE_DEFAULT_CHARSET=UTF8 --publish=${test_firebird_port}:3050 firebirdsql/firebird')
	if result.exit_code != 0 {
		return error(result.output)
	}
}

fn container_firebird_clean() {
	result := os.execute('docker stop ${test_firebird_container_name}')
	if result.exit_code != 0 {
		eprintln(result.output)
	}
}

fn container_redict_start() ! {
	result := os.execute('docker run --rm --detach --name=${test_redict_container_name} --publish=${test_redict_port}:6379 registry.redict.io/redict')
	if result.exit_code != 0 {
		return error(result.output)
	}
}

fn container_redict_clean() {
	result := os.execute('docker stop ${test_redict_container_name}')
	if result.exit_code != 0 {
		eprintln(result.output)
	}
}

// Note: veb cannot be stopped, it has no shutdown functions: https://github.com/vlang/v/issues/25655
// Note: containers aren't stopped on panic
fn app_routine(ch chan bool) {
	mut app := new_peony_app(Providers{
		blob_provider: new_provider_blob_dummy()
	})
	go app.run()
	_ := <-ch

	container_firebird_clean()
	container_redict_clean()
}

// starts a test app, when stopped it closes the containers.
fn run_app() !chan bool {
	os.setenv(env_firebird_url, test_firebird_url, true)
	os.setenv(env_redict_url, test_redict_url, true)
	os.setenv(env_session_secret, test_session_secret, true)
	os.setenv(env_port, test_peony_port, true)
	os.setenv(env_email, test_peony_email, true)
	os.setenv(env_password, test_peony_password, true)

	container_firebird_start()!
	container_redict_start()!
	time.sleep(5 * time.second) // need to wait for cotnainers startup. TODO fix magic number

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
	return 'http://localhost:${test_peony_port}${s}'
}

// TODO handle params
fn do_get_request(path string) !http.Response {
	request := http.new_request(http.Method.get, build_url(path), '') // TODO error 111 (rejected)
	return request.do()!
}

fn check_response(r http.Response) ! {
	if r.status_code != 200 {
		return error('status ${r.status_code} (${r.status_msg}): ${r.body}')
	}
}

// TODO In order to be able to run multiple tests asynchronously:
// Check if port is in use or not, if in use, change all ports and try again.
// Use a more reliable technique than time.sleep to wait for things to be done.
fn test_peony() ! {
	ch := run_app()!
	defer {
		stop_app(ch)
	}

	// list regions
	mut response := do_get_request('/store/regions')!
	check_response(response)!
	regions := json.decode(RegionResponseListEnvelope, response.body)!
	default_region := regions.regions[0]
	default_region_id := default_region.id
	// TODO check all expected fields are populated
	// TODO taxes

	// get region by id
	response = do_get_request('/store/regions/${default_region_id}')!
	check_response(response)!
}
