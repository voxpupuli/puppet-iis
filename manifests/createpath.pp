#
define iis::createpath($site_path = undef) {
  include 'iis::param::powershell'

  if $site_path == undef {
    fail('site_path is undefined')
  }

  if ! defined(Exec["Create-Path-${title}"]) {
    exec { "Create-Path-${title}":
      command   => "${iis::param::powershell::command} -Command \"New-Item -path \\\"${site_path}\\\" -type directory\"",
      path      => "${iis::param::powershell::path};${::path}",
      onlyif    => "${iis::param::powershell::command} -Command \"if(Test-Path \\\"${site_path}\\\") { exit 1 } else { exit 0 }\"",
      logoutput => true,
    }
  }
}
