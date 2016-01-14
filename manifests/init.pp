#
class iis {
  iis::manage_app_pool {'www.internalapi.co.uk':
    enable_32_bit           => true,
    managed_runtime_version => 'v4.0',
  }

  iis::manage_site {'www.internalapi.co.uk':
    site_path   => 'C:\inetpub\wwwroot\test',
    port        => '80',
    ip_address  => '*',
    host_header => 'www.internalapi.co.uk',
    app_pool    => 'www.internalapi.co.uk',
  }

  iis::manage_virtual_application {'reviews':
    site_name => 'www.internalapi.co.uk',
    site_path => 'C:\inetpub\wwwroot\test',
    app_pool  => 'www.internalapi.co.uk',
  }
}
