#
define iis::manage_virtual_application($site_name, $site_path, $app_pool, $virtual_application_name = $title, $ensure = 'present') {
  include 'iis::param::powershell'

  validate_re($ensure, '^(present|installed|absent|purged)$', 'ensure must be one of \'present\', \'installed\', \'absent\', \'purged\'')

  if ($ensure in ['present','installed']) {
    iis::createpath { "${site_name}-${virtual_application_name}-${site_path}":
      site_path => $site_path
    }

    exec { "CreateVirtualApplication-${site_name}-${virtual_application_name}" :
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; New-WebApplication -Name ${virtual_application_name} -Site ${site_name} -PhysicalPath ${site_path} -ApplicationPool ${app_pool}\"",
      path      => "${iis::param::powershell::path};${::path}",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\Sites\\${site_name}\\${virtual_application_name}\\\")) { exit 1 } else { exit 0 }\"",
      require   => [ Iis::Createpath["${site_name}-${virtual_application_name}-${site_path}"], Iis::Manage_site[$site_name] ],
      logoutput => true,
    }        
    exec { "ConvertTo-WebApplication-${site_name}-${virtual_application_name}" :
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; ConvertTo-WebApplication \\\"IIS:\\Sites\\${site_name}\\${virtual_application_name}\\\"\"",
      path      => "${iis::param::powershell::path};${::path}",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Get-WebApplication -Name \\\"${virtual_application_name}\\\") -eq \$null ) { write-host \"yes\";exit 0 } else { write-host \"no\"; exit 1 }\"",
      require   => [ Iis::Createpath["${site_name}-${virtual_application_name}-${site_path}"], Iis::Manage_site[$site_name] ],
      logoutput => true,
      }	
  } else {
    exec { "DeleteVirtualApplication-${site_name}-${virtual_application_name}" :
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Remove-WebApplication -Name ${virtual_application_name} -Site ${site_name}\"",
      path      => "${iis::param::powershell::path};${::path}",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if(!(Test-Path \\\"IIS:\\Sites\\${site_name}\\${virtual_application_name}\\\")) { exit 1 } else { exit 0 }\"",
      logoutput => true,
    }
  }
}
