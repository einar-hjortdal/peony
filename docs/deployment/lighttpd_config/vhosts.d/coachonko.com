$HTTP["scheme"] == "http" {

  $HTTP["host"] == "www.coachonko.com" {
    # If the requested URL is for the ACME challenge
    $HTTP["url"] =~ "^/.well-known/acme-challenge/" {
      alias.url += ("/.well-known/acme-challenge/" => "/var/www/kadaknath/")
    }
    # Else redirect to https non-www
    else {
      url.redirect = ( "" => "https://coachonko.com${url.path}${qsa}" )
    }
  }

  $HTTP["host"] == "coachonko.com" {
    # If the requested URL is for the ACME challenge
    $HTTP["url"] =~ "^/.well-known/acme-challenge/" {
      alias.url += ("/.well-known/acme-challenge/" => "/var/www/kadaknath/")
    }
    # Else redirect to https
    else {
      url.redirect = ("" => "https://${url.authority}${url.path}${qsa}")
    }
  }
}

$HTTP["scheme"] == "https" {

  $HTTP["host"] == "www.coachonko.com" {
    # If the requested URL is for the ACME challenge
    $HTTP["url"] =~ "^/.well-known/acme-challenge/" {
      alias.url += ("/.well-known/acme-challenge/" => "/var/www/kadaknath/")
    }
    # Else redirect to non-www
    else {
      url.redirect = ( "" => "https://coachonko.com${url.path}${qsa}" )
    }

    ssl.pemfile = "/etc/pki/www/certs/coachonko.com.pem"
    ssl.privkey = "/etc/pki/www/private/coachonko.com.key"
    #ssl.stapling-file = "/etc/pki/www/misc/coachonko.com.ocsp"
  }

  $HTTP["host"] == "coachonko.com" {
    # If the requested URL is for the ACME challenge
    # Serve the content managed by the ACME client
    #
    $HTTP["url"] =~ "^/.well-known/acme-challenge/" {
      alias.url += ("/.well-known/acme-challenge/" => "/var/www/kadaknath/")
    }
    # Reverse proxy to storefront frontend
    else {
      proxy.server = ( "" => (( "host" => "127.0.0.1", "port" => 29200 )))
    }

    ssl.pemfile = "/etc/pki/www/certs/coachonko.com.pem"
    ssl.privkey = "/etc/pki/www/private/coachonko.com.key"
    #ssl.stapling-file = "/etc/pki/www/misc/coachonko.com.ocsp"

    ## use separate access/error log files
    accesslog.filename = log_root + "/coachonko.com/access.log"
    server.errorlog = log_root + "/coachonko.com/error.log"
  }
}
