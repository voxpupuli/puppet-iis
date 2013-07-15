define iis::manage_site($site_path, $app_pool, $host_header = '', $site_name = $title, $port = '80', $ip_address = '*') {
  include 'iis::param::powershell'

  iis::createpath { "${site_name}-${site_path}":
    site_path => $site_path
  }
  
  exec { "CreateSite-${site_name}" :
    command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; New-WebSite -Name \\\"${site_name}\\\" -Port ${port} -IP ${ip_address} -HostHeader \\\"${host_header}\\\" -PhysicalPath \\\"${site_path}\\\" -ApplicationPool \\\"${app_pool}\\\"\"",
    path      => "${iis::param::powershell::path};${::path}",
    onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\${site_name}\")) { exit 1 } else { exit 0 }\"",
    logoutput => true,
    require   => [ Iis::Createpath["${site_name}-${site_path}"], Iis::Manage_app_pool[$app_pool] ],
  }
}
