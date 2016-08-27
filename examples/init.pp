# iis Basic example
# This is a basic example of configuration an app pool, website,
# application and virtual directory.

# Create temp folder for our example
file { 'c:\iisexample' : ensure => directory } ->
file { 'c:\iisexample\virtdir': ensure => directory}

# Create an application pool
iis_pool { 'MyAppPool' :
  ensure        => started,       # present|absent|started|stopped
  runtime       => 'v2.0',        # v2.0 or v.4.0 for .NET runtime
  pipeline      => 'integrated',  # integrated|classic
  enable_32_bit => false,         # true|false
}

# Create a website
iis_site { 'MyWebSite' :
  ensure      => started,                    # present|absent|started|stopped
  path        => 'c:\iisexample',           # physical path
  app_pool    => 'MyAppPool',                # app pool created in iis_pool 
  host_header => 'www.puppetonwindows.com',  # primary hostname for the site
  ip          => '127.0.0.1',                # primary IP binding
  port        => '8081',                     # primary port binding
  #ssl         => true,                      # ssl flag (Win 2012/2016 only)
} 

# Create an application
iis_application { 'MyWebApp' :
  ensure => present,        # present|absent|started|stopped
  site   => 'MyWebSite',    # website created in iis_site
  path   => 'c:\iisexample',
} 

# Create a virtual directory
iis_virtualdirectory { 'MyVirtualDirectory':
  ensure => present,                    # present|absent
  site   => 'MyWebSite',                # website created in iis_site
  path   => 'c:\iisexample\virtdir' , # path to physical directory
}

# Create a binding
iis_binding { '172.0.0.1:8082:myawesomewebsite.com' : 
  ensure      => present,
  site_name   => 'MyWebSite',
  ip_address  => '127.0.0.1',
  port        => '8082',
  host_header => 'myawesomewebsite.com',
  protocol    => 'http',
}