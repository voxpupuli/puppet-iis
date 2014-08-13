define iis::manage_virtual_directory($site_name, $directory, $path) {
  include 'iis::param::powershell'

    exec { "WebConfiguration-create-${site_name}-${directory}" :
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; New-Item 'IIS:\Sites\\${site_name}\\${directory}' -type VirtualDirectory -PhysicalPath ${path} \"",
      path      => "${iis::param::powershell::path};${::path}",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if(Test-Path -Path 'IIS:\Sites\\${site_name}\\${directory}') { exit 1 } else { exit 0 } \"",
      logoutput => true,
    }

    exec { "WebConfiguration-edit-${site_name}-${directory}" :
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Set-ItemProperty 'IIS:\Sites\\${site_name}\\${directory}' -Name PhysicalPath -Value '${path}' \"",
      path      => "${iis::param::powershell::path};${::path}",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Get-ItemProperty 'IIS:\Sites\\${site_name}\\${directory}' -Name PhysicalPath).value -eq '${path}') { exit 1 } else { exit 0 }\"",
      logoutput => true,
      require   => Exec["WebConfiguration-create-${site_name}-${directory}"]
    }
}


