#
define iis::manage_virtual_application($site_name, $site_path, $app_pool, $virtual_application_name = $title, $ensure = 'present') {
  validate_re($ensure, '^(present|installed|absent|purged)$', 'ensure must be one of \'present\', \'installed\', \'absent\', \'purged\'')

  if ($ensure in ['present','installed']) {
    iis::createpath { "${site_name}-${virtual_application_name}-${site_path}":
      site_path => $site_path,
    }

    exec { "CreateVirtualApplication-${site_name}-${virtual_application_name}" :
      command   => "Import-Module WebAdministration; New-WebApplication -Name ${virtual_application_name} -Site \"${site_name}\" -PhysicalPath \"${site_path}\" -ApplicationPool \"${app_pool}\"",
      onlyif    => "Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\${site_name}\") -and (Get-ChildItem \"IIS:\\Sites\\${site_name}\" | where {\$_.Schema.Name -eq 'Application' -and \$_.Name -eq '${virtual_application_name}'})) { exit 1 } else { exit 0 }",
      require   => [ Iis::Createpath["${site_name}-${virtual_application_name}-${site_path}"], Iis::Manage_site[$site_name] ],
      provider  => powershell,
      logoutput => true,
    }
  } else {
    exec { "DeleteVirtualApplication-${site_name}-${virtual_application_name}" :
      command   => "Import-Module WebAdministration; Remove-WebApplication -Name ${virtual_application_name} -Site \"${site_name}\"",
      onlyif    => "Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\${site_name}\") -and (Get-ChildItem \"IIS:\\Sites\\${site_name}\" | where {\$_.Schema.Name -eq 'Application' -and \$_.Name -eq '${virtual_application_name}'})) { exit 0 } else { exit 1 }",
      provider  => powershell,
      logoutput => true,
    }
  }
}
