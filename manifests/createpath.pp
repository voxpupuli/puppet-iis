#
define iis::createpath($site_path = undef) {
  if $site_path == undef {
    fail('site_path is undefined')
  }

  if ! defined(Exec["Create-Path-${title}"]) {
    exec { "Create-Path-${title}":
      command   => "New-Item -path \"${site_path}\" -type directory",
      onlyif    => "if(Test-Path \"${site_path}\") { exit 1 } else { exit 0 }",
      provider  => powershell,
      logoutput => true,
    }
  }
}
