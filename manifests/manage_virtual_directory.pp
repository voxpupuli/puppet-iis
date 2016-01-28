define iis::manage_virtual_directory($site_name, $directory, $path) {

  exec { "VirtualDirectory-create-${site_name}-${directory}" :
    command   => "Import-Module WebAdministration; New-Item 'IIS:\\Sites\\${site_name}\\${directory}' -type VirtualDirectory -PhysicalPath '${path}' ",
    onlyif    => "Import-Module WebAdministration; if(Test-Path -Path 'IIS:\\Sites\\${site_name}\\${directory}') { exit 1 } else { exit 0 } ",
    logoutput => true,
    provider  => powershell,
  }

  exec { "VirtualDirectory-edit-${site_name}-${directory}" :
    command   => "Import-Module WebAdministration; Set-ItemProperty 'IIS:\\Sites\\${site_name}\\${directory}' -Name PhysicalPath -Value '${path}' ",
    onlyif    => "Import-Module WebAdministration; if((Get-ItemProperty 'IIS:\\Sites\\${site_name}\\${directory}' -Name PhysicalPath).value -eq '${path}') { exit 1 } else { exit 0 }",
    logoutput => true,
    provider  => powershell,
    require   => Exec["VirtualDirectory-create-${site_name}-${directory}"],
  }
}
