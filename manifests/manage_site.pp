#
define iis::manage_site($site_path, $app_pool, $host_header = '', $site_name = $title, $port = '80', $ip_address = '*', $ensure = 'present', $ssl = 'false') {
  include 'iis::param::powershell'

  validate_re($ensure, '^(present|installed|absent|purged)$', 'ensure must be one of \'present\', \'installed\', \'absent\', \'purged\'')
  validate_re($ssl, '^(false|true)$', 'sll must be one of \'true\' or \'false\'')

  if ($ensure in ['present','installed']) {
    iis::createpath { "${site_name}-${site_path}":
      site_path => $site_path
    }

    $cmdSiteExists = "Test-Path \\\"IIS:\\Sites\\${site_name}\\\""

    $createSwitches = ["-Name \\\"${site_name}\\\"",
          "-Port ${port} -IP ${ip_address}",
          "-HostHeader \\\"${host_header}\\\"",
          "-PhysicalPath \\\"${site_path}\\\"",
          "-ApplicationPool \\\"${app_pool}\\\"",
          "-Ssl:$${ssl}"]

    $switches = join($createSwitches,' ')
    exec { "CreateSite-${site_name}" :
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; \$id = (Get-WebSite | foreach {\$_.id} | sort -Descending | select -first 1) + 1; New-WebSite ${switches} -ID \$id \"",
      path      => "${iis::param::powershell::path};${::path}",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((${$cmdSiteExists})) { exit 1 } else { exit 0 }\"",
      logoutput => true,
      require   => [ Iis::Createpath["${site_name}-${site_path}"], Iis::Manage_app_pool[$app_pool] ],
    }

    exec { "UpdateSite-PhysicalPath-${site_name}":
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\Sites\\${site_name}\\\" -Name physicalPath -Value \\\"${site_path}\\\"\"",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((${$cmdSiteExists}) -eq \$false) { exit 1 } if ((Get-ItemProperty \\\"IIS:\\Sites\\${site_name}\\\" physicalPath) -eq \\\"${site_path}\\\") { exit 1 } else { exit 0 }\"",
      path      => "${iis::param::powershell::path};${::path}",
      logoutput => true,
      before    => Exec["CreateSite-${site_name}"],
    }

    exec { "UpdateSite-ApplicationPool-${site_name}":
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\Sites\\${site_name}\\\" -Name applicationPool -Value \\\"${app_pool}\\\"\"",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((${$cmdSiteExists}) -eq \$false) { exit 1 } if((Get-ItemProperty \\\"IIS:\\Sites\\${site_name}\\\" applicationPool) -eq \\\"${app_pool}\\\") { exit 1 } else { exit 0 }\"",
      path      => "${iis::param::powershell::path};${::path}",
      logoutput => true,
      before    => Exec["CreateSite-${site_name}"],
    }
  } else {
    exec { "DeleteSite-${site_name}" :
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Remove-WebSite -Name \\\"${site_name}\\\"\"",
      path      => "${iis::param::powershell::path};${::path}",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if(!(Test-Path \\\"IIS:\\Sites\\${site_name}\\\")) { exit 1 } else { exit 0 }\"",
      logoutput => true,
    }
  }
}
