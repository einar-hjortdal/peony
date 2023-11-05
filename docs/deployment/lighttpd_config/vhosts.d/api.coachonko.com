$HTTP["scheme"] == "http" {

  $HTTP["host"] == "api.coachonko.com" {
    # If the requested URL is for the ACME challenge
    $HTTP["url"] =~ "^/.well-known/acme-challenge/" {
      alias.url += ("/.well-known/acme-challenge/" => "/var/www/kadaknath/")
    }
    # Else redirect to https
    else {
      url.redirect = ( "" => "https://api.coachonko.com${url.path}${qsa}" )
    }
  }
}

$HTTP["scheme"] == "https" {

  $HTTP["host"] == "api.coachonko.com" {
    # If the requested URL is for the ACME challenge
    $HTTP["url"] =~ "^/.well-known/acme-challenge/" {
      alias.url += ("/.well-known/acme-challenge/" => "/var/www/kadaknath/")
    }

    ssl.pemfile = "/etc/pki/www/certs/api.coachonko.com.pem"
    ssl.privkey = "/etc/pki/www/private/api.coachonko.com.key"
    #ssl.stapling-file = "/etc/pki/www/misc/api.coachonko.com.ocsp"
  }

  $HTTP["host"] == "api.coachonko.com" {
    # If the requested URL is for the ACME challenge
    # Serve the content managed by the ACME client
    #
    $HTTP["url"] =~ "^/.well-known/acme-challenge/" {
      alias.url += ("/.well-known/acme-challenge/" => "/var/www/kadaknath/")
    }
    # Reverse proxy to peony
    else {
      proxy.server = ( "" => (( "host" => "127.0.0.1", "port" => 29000 )))
    }

    ssl.pemfile = "/etc/pki/www/certs/api.coachonko.com.pem"
    ssl.privkey = "/etc/pki/www/private/api.coachonko.com.key"
    #ssl.stapling-file = "/etc/pki/www/misc/api.coachonko.com.ocsp"

    ## use separate access/error log files
    accesslog.filename = log_root + "/api.coachonko.com/access.log"
    server.errorlog = log_root + "/api.coachonko.com/error.log"
  }
}
