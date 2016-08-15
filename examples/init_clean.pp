# iis Basic example
# This is a basic example of configuration an app pool, website,
# application and virtual directory. This manifest cleans up
# if you've run puppet apply on initpp

# Remove the application
iis_application { 'MyWebApp' :
  ensure => absent,       # present|absent|started|stopped
  site   => 'MyWebSite',  # website created in iis_site
}

# Remove the virtual directory
iis_virtualdirectory { 'MyVirtualDirectory':
  ensure => absent,                     # present|absent
  site   => 'MyWebSite',                # website created in iis_site
  path   => 'c:\iis_example\virt_dir' , # path to physical directory
}

# Remove the website
iis_site { 'MyWebSite' :
  ensure      => absent,                    # present|absent|started|stopped
  path        => 'c:\iis_example',           # physical path
  app_pool    => 'MyAppPool',                # app pool created in iis_pool 
  host_header => 'www.puppetonwindows.com',  # primary hostname for the site
  ip          => '127.0.0.1',                # primary IP binding
  port        => '8081',                     # primary port binding
  #ssl         => true,                      # ssl flag (Win 2012/2016 only)
}

# Remove the application pool
iis_pool { 'MyAppPool' :
  ensure        => absent,       # present|absent|started|stopped
  runtime       => 'v2.0',        # v2.0 or v.4.0 for .NET runtime
  pipeline      => 'integrated',  # integrated|classic
  enable_32_bit => false,         # true|false
}

# Remove temp folders for our example
file { 'c:\iis_example\virt_dir' :
  ensure => absent,
  force  => true,
} ->
file { 'c:\iis_example' :
  ensure => absent,
  force  => true,
}







