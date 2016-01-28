#
define iis::manage_site(
  $ensure      = 'present',
  $site_name   = $title,
  $site_path   = '',
  $app_pool    = '',
  $host_header = '',
  $ip_address  = '*',
  $port        = '80',
  $ssl         = false
  ) {
  validate_re($ensure, '^(present|installed|absent|purged)$', 'ensure must be one of \'present\', \'installed\', \'absent\', \'purged\'')
  validate_bool($ssl)

  if $ensure in ['present','installed'] {
    validate_absolute_path($site_path)

    iis::createpath { "${site_name}-${site_path}":
      site_path => $site_path,
    }

    $cmd_site_exists = "Test-Path \"IIS:\\Sites\\${site_name}\""

    $create_switches = ["-Name \"${site_name}\"",
          "-Port ${port} -IP ${ip_address}",
          "-HostHeader \"${host_header}\"",
          "-PhysicalPath \"${site_path}\"",
          "-ApplicationPool \"${app_pool}\"",
          "-Ssl:$${ssl}"]

    $switches = join($create_switches,' ')
    exec { "CreateSite-${site_name}" :
      command   => "Import-Module WebAdministration; \$id = (Get-WebSite | foreach {\$_.id} | sort -Descending | select -first 1) + 1; New-WebSite ${switches} -ID \$id",
      onlyif    => "Import-Module WebAdministration; if((${$cmd_site_exists})) { exit 1 } else { exit 0 }",
      provider  => 'powershell',
      path      => $::path,
      logoutput => true,
      require   => [ Iis::Createpath["${site_name}-${site_path}"], Iis::Manage_app_pool[$app_pool] ],
    }

    exec { "UpdateSite-PhysicalPath-${site_name}":
      command   => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\Sites\\${site_name}\" -Name physicalPath -Value \"${site_path}\"",
      onlyif    => "Import-Module WebAdministration; if((${$cmd_site_exists}) -eq \$false) { exit 1 } if ((Get-ItemProperty \"IIS:\\Sites\\${site_name}\" physicalPath) -eq \"${site_path}\") { exit 1 } else { exit 0 }",
      provider  => 'powershell',
      path      => $::path,
      logoutput => true,
      before    => Exec["CreateSite-${site_name}"],
    }

    exec { "UpdateSite-ApplicationPool-${site_name}":
      command   => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\Sites\\${site_name}\" -Name applicationPool -Value \"${app_pool}\"",
      onlyif    => "Import-Module WebAdministration; if((${$cmd_site_exists}) -eq \$false) { exit 1 } if((Get-ItemProperty \"IIS:\\Sites\\${site_name}\" applicationPool) -eq \"${app_pool}\") { exit 1 } else { exit 0 }",
      provider  => 'powershell',
      path      => $::path,
      logoutput => true,
      before    => Exec["CreateSite-${site_name}"],
    }
  } else {
    exec { "DeleteSite-${site_name}" :
      command   => "Import-Module WebAdministration; Remove-WebSite -Name \"${site_name}\"",
      onlyif    => "Import-Module WebAdministration; if(!(Test-Path \"IIS:\\Sites\\${site_name}\")) { exit 1 } else { exit 0 }",
      provider  => 'powershell',
      path      => $::path,
      logoutput => true,
    }
  }
}
