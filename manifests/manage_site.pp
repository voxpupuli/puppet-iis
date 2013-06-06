define iis::manage_site($site_path, $host_header, $app_pool, $site_name = $title, $port = '80', $ip_address = '*') {
  include 'iis::param::powershell'

  exec { "CreateSitePath-${site_path}":
    command   => "${iis::param::powershell::command} -Command \"New-Item-Path \\\"${site_path}\\\" -type directory\"",
    path      => "${iis::param::powershell::path};${::path}",
    onlyif    => "${iis::param::powershell::command} -Command \"if(Test-Path \\\"${site_path}\\\") { exit 1 } else { exit 0}\"",
    logoutput => true,
  }

  exec { "CreateSite-${site_name}" :
    command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; New-WebSite -Name ${site_name} -Port ${port} -IP ${ip_address} -HostHeader ${host_header} -PhysicalPath ${site_path} -ApplicationPool ${app_pool}\"",
    path      => "${iis::param::powershell::path};${::path}",
    onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\${site_name}\")) { exit 1 } else { exit 0 }\"",
    logoutput => true,
    require   => [ Exec["CreateSitePath-${site_path}"], iis::manage_app_pool[$app_pool] ],
  }
}
