$HTTP["scheme"] == "http" {

  $HTTP["host"] == "garage.coachonko.com" {
    # If the requested URL is for the ACME challenge
    $HTTP["url"] =~ "^/.well-known/acme-challenge/" {
      alias.url += ("/.well-known/acme-challenge/" => "/var/www/kadaknath/")
    }
    # Else redirect to https
    else {
      url.redirect = ( "" => "https://garage.coachonko.com${url.path}${qsa}" )
    }
  }
}

$HTTP["scheme"] == "https" {

  $HTTP["host"] == "garage.coachonko.com" {
    # If the requested URL is for the ACME challenge
    $HTTP["url"] =~ "^/.well-known/acme-challenge/" {
      alias.url += ("/.well-known/acme-challenge/" => "/var/www/kadaknath/")
    }

    ssl.pemfile = "/etc/pki/www/certs/garage.coachonko.com.pem"
    ssl.privkey = "/etc/pki/www/private/garage.coachonko.com.key"
    #ssl.stapling-file = "/etc/pki/www/misc/garage.coachonko.com.ocsp"
  }

  $HTTP["host"] == "garage.coachonko.com" {
    # If the requested URL is for the ACME challenge
    # Serve the content managed by the ACME client
    #
    $HTTP["url"] =~ "^/.well-known/acme-challenge/" {
      alias.url += ("/.well-known/acme-challenge/" => "/var/www/kadaknath/")
    }
    # Reverse proxy to Garage
    else {
      proxy.server = ( "" => (( "host" => "127.0.0.1", "port" => 29500 )))
    }

    ssl.pemfile = "/etc/pki/www/certs/garage.coachonko.com.pem"
    ssl.privkey = "/etc/pki/www/private/garage.coachonko.com.key"
    #ssl.stapling-file = "/etc/pki/www/misc/garage.coachonko.com.ocsp"

    ## use separate access/error log files
    accesslog.filename = log_root + "/garage.coachonko.com/access.log"
    server.errorlog = log_root + "/garage.coachonko.com/error.log"
  }
}
