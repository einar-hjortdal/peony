$HTTP["scheme"] == "http" {

  $HTTP["host"] == "admin.coachonko.com" {
    # If the requested URL is for the ACME challenge
    $HTTP["url"] =~ "^/.well-known/acme-challenge/" {
      alias.url += ("/.well-known/acme-challenge/" => "/var/www/kadaknath/")
    }
    # Else redirect to https
    else {
      url.redirect = ( "" => "https://admin.coachonko.com${url.path}${qsa}" )
    }
  }
}

$HTTP["scheme"] == "https" {

  $HTTP["host"] == "admin.coachonko.com" {
    # If the requested URL is for the ACME challenge
    $HTTP["url"] =~ "^/.well-known/acme-challenge/" {
      alias.url += ("/.well-known/acme-challenge/" => "/var/www/kadaknath/")
    }

    ssl.pemfile = "/etc/pki/www/certs/admin.coachonko.com.pem"
    ssl.privkey = "/etc/pki/www/private/admin.coachonko.com.key"
    #ssl.stapling-file = "/etc/pki/www/misc/admin.coachonko.com.ocsp"
  }

  $HTTP["host"] == "admin.coachonko.com" {
    # If the requested URL is for the ACME challenge
    # Serve the content managed by the ACME client
    #
    $HTTP["url"] =~ "^/.well-known/acme-challenge/" {
      alias.url += ("/.well-known/acme-challenge/" => "/var/www/kadaknath/")
    }
    # Reverse proxy to admin frontend
    else {
      proxy.server = ( "" => (( "host" => "127.0.0.1", "port" => 29100 )))
    }

    ssl.pemfile = "/etc/pki/www/certs/admin.coachonko.com.pem"
    ssl.privkey = "/etc/pki/www/private/admin.coachonko.com.key"
    #ssl.stapling-file = "/etc/pki/www/misc/admin.coachonko.com.ocsp"

    ## use separate access/error log files
    accesslog.filename = log_root + "/admin.coachonko.com/access.log"
    server.errorlog = log_root + "/admin.coachonko.com/error.log"
  }
}
