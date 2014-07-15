#
define iis::manage_site_state($site_name, $ensure = 'running') {
  include 'iis::param::powershell'

  validate_re($ensure, '^(running|true|stopped|false)$', 'ensure must be one of \'running\', \'true\', \'stopped\', \'false\'')

  if ($ensure in ['running','true']) {
    exec { "StartSite-${site_name}":
      path      => "${iis::param::powershell::path};${::path}",
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Start-Website -Name \\\"${site_name}\\\"\"",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Get-Item \\\"IIS:\\Sites\\${site_name}\\\").state -eq \\\"started\\\") { exit 1 }\"",
      logoutput => true,
      require   => Exec["CreateSite-${site_name}"],
    }
  } else {
    exec { "StopSite-${site_name}":
      path      => "${iis::param::powershell::path};${::path}",
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Stop-Website -Name \\\"${site_name}\\\"\"",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Get-Item \\\"IIS:\\Sites\\${site_name}\\\").state -eq \\\"stopped\\\") { exit 1 }\"",
      logoutput => true,
    }
  }
}