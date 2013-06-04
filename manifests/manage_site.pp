define iis::manage_site($site_path, $host_header, $app_pool, $site_name = $title, $port = '80', $ip_address = '*') {
  include 'param::powershell'

  file { "${host_header}-SitePath-${site_path}":
    path    => $site_path,
    ensure  => directory,
    require => iis::manage_app_pool[$site_name],
  }

  exec { "CreateSite-${site_name}" :
    command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; New-WebSite -Name ${site_name} -Port ${port} -IP ${ip_address} -HostHeader ${host_header} -PhysicalPath ${site_path} -ApplicationPool ${app_pool} \"",
    path      => "${iis::param::powershell::path};${::path}",
    onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\${site_name}\")) { exit 1 } else { exit 0 }\"",
    logoutput => true,
    require   => File["${host_header}-SitePath-${site_path}"],
  }
}
