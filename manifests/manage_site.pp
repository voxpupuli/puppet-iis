define iis::manage_site($site_path, $host_header = '', $app_pool, $site_name = $title, $port = '80', $ip_address = '*') {
  include 'iis::param::powershell'

  iis::createpath { "${site_name}-${site_path}":
    site_path => $site_path
  }
  
  $host_header_string = ''
  if $host_header != '' {
    $host_header_string = "-HostHeader ${host_header}"
  }

  exec { "CreateSite-${site_name}" :
    command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; New-WebSite -Name ${site_name} -Port ${port} -IP ${ip_address} ${host_header_string} -PhysicalPath ${site_path} -ApplicationPool ${app_pool}\"",
    path      => "${iis::param::powershell::path};${::path}",
    onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\${site_name}\")) { exit 1 } else { exit 0 }\"",
    logoutput => true,
    require   => [ iis::createpath["${site_name}-${site_path}"], iis::manage_app_pool[$app_pool] ],
  }
}