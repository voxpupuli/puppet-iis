define iis::manage_binding($site_name, $protocol, $port, $host_header = '', $ip_address = '*', $certificate_name = '') {
  include 'iis::param::powershell'

  if ! ($protocol in [ 'http', 'https', 'net.tcp', 'net.pipe', 'netmsmq', 'msmq.formatname' ]) {
    fail('valid protocols \'http\', \'https\', \'net.tcp\', \'net.pipe\', \'netmsmq\', \'msmq.formatname\'')
  }

  validate_string($site_name)
  validate_re($site_name,['^(.)+$'], 'site_name must not be empty')

  if ! ($ip_address == '*') {
    validate_re($ip_address, ['^([0-9]){1,3}\.([0-9]){1,3}\.([0-9]){1,3}\.([0-9]){1,3}$'], "\"${ip_address}\" is not a valid ip address")
  }

  exec { "ManageBinding-${title}":
    path      => "${iis::param::powershell::path};${::path}",
    command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; New-WebBinding -Name \\\"${site_name}\\\" -Port ${port} -Protocol \\\"${protocol}\\\" -HostHeader \\\"${host_header}\\\" -IPAddress \\\"${ip_address}\\\"\"",
    onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if (Get-WebBinding -Name \\\"${site_name}\\\" -Port ${port} -Protocol \\\"${protocol}\\\" -HostHeader \\\"${host_header}\\\" -IPAddress \\\"${ip_address}\\\" | Where-Object {\$_.bindingInformation -eq \\\"${ip_address}:${port}:${host_header}\\\"}) { exit 1 } else { exit 0 }\"",
    logoutput => true,
    require   => Iis::Manage_site[$site_name],
  }

  if ($protocol == 'https') {
    validate_re($certificate_name, ['^(.)+$'], 'certificate_name required for https bindings')
    if ($ip_address == '*' or $ip_address == '0.0.0.0') {
      fail("https bindings require a valid ip_address")
    }

    exec { "Attach-Certificate-${title}":
      path      => "${iis::param::powershell::path};${::path}",
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; New-Item \\\"IIS:\\SslBindings\\${ip_address}!${port}\\\" (Get-ChildItem cert:\\ -Recurse | Where-Object {\$_.FriendlyName -match ${certificate_name} } | Select-Object -First 1)\"",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if(Get-ChildItem cert:\\ -Recurse | Where-Object {\$_.FriendlyName -match ${certificate_name} } | Select-Object -First 1) { exit 1 } else { exit 0 }\"",
      require   => Exec["ManageBinding-${title}"],
      logoutput => true,
    }
  }
}

