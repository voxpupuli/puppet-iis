#This is manifest is all custom code
define iis::manage_virtual_directory($site_name, $site_path, $dir_account, $dir_password, $virtual_directory_name = $title, $ensure = 'present') {
  include 'iis::param::powershell'

  validate_re($ensure, '^(present|installed|absent|purged)$', 'ensure must be one of \'present\', \'installed\', \'absent\', \'purged\'')
  
  if ($ensure in ['present','installed']) {
 
    exec { "CreateVirtualDirectory-${site_name}-${virtual_directory_name}" :
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; New-WebVirtualDirectory -Site ${site_name} -Name ${virtual_directory_name} -PhysicalPath ${site_path} \"",
      path      => "${iis::param::powershell::path};${::path}",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Get-WebVirtualDirectory -Site ${site_name}) -eq \$null ) { write-host \"yes\";exit 0 } else { write-host \"no\"; exit 1 }\"",
      require   => [ Iis::Manage_site[$site_name] ],
      notify => Exec ["processmodelusername-${dir_account}"],
      logoutput => true,
    }                                                                                                    
    exec { "processmodelusername-${dir_account}" :
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\Sites\\${site_name}\\${virtual_directory_name}\\\" username ${$dir_account}\"",
      path      => "${iis::param::powershell::path};${::path}",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\Sites\\${site_name}\\${virtual_directory_name}\\\" username).Value.CompareTo('${$dir_account}') -eq 0) { exit 1 } else { exit 0 }\"",
      refreshonly => true,
      logoutput => true,
      notify => Exec ["processmodelpassword-${dir_password}"]
      }
    exec { "processmodelpassword-${dir_password}" :
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\Sites\\${site_name}\\${virtual_directory_name}\\\" password ${dir_password}\"",
      path      => "${iis::param::powershell::path};${::path}",
      require   => Exec["processmodelusername-${dir_account}"],
      refreshonly => true,
      logoutput => true,
    }
  } else {
    exec { "DeleteVirtualDirectory-${site_name}-${virtual_directory_name}" :
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Remove-WebVirtualDirectory -Site ${site_name}\"",
      path      => "${iis::param::powershell::path};${::path}",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if(!(Test-Path \\\"IIS:\\Sites\\${site_name}\\${virtual_directory_name}\\\")) { exit 1 } else { exit 0 }\"",
      logoutput => true,
    }
          
        
  }
}

