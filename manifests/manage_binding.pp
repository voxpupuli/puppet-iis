define iis::manage_binding($site_name, $protocol, $port, $host_header = '', $ip_address = '*', $certificate_name = '', $ensure = 'present') {
  include 'iis::param::powershell'

  if ! ($protocol in [ 'http', 'https', 'net.tcp', 'net.pipe', 'netmsmq', 'msmq.formatname' ]) {
    fail('valid protocols \'http\', \'https\', \'net.tcp\', \'net.pipe\', \'netmsmq\', \'msmq.formatname\'')
  }

  validate_string($site_name)
  validate_re($site_name,['^(.)+$'], 'site_name must not be empty')
  validate_re($ensure, '^(present|installed|absent|purged)$', 'ensure must be one of \'present\', \'installed\', \'absent\', \'purged\'')

  if ! ($ip_address == '*') {
    validate_re($ip_address, ['^([0-9]){1,3}\.([0-9]){1,3}\.([0-9]){1,3}\.([0-9]){1,3}$'], "\"${ip_address}\" is not a valid ip address")
  }

  if ($ensure in ['present','installed']) {
    exec { "CreateBinding-${title}":
      path      => "${iis::param::powershell::path};${::path}",
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; New-WebBinding -Name \\\"${site_name}\\\" -Port ${port} -Protocol \\\"${protocol}\\\" -HostHeader \\\"${host_header}\\\" -IPAddress \\\"${ip_address}\\\"\"",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if (Get-WebBinding -Name \\\"${site_name}\\\" -Port ${port} -Protocol \\\"${protocol}\\\" -HostHeader \\\"${host_header}\\\" -IPAddress \\\"${ip_address}\\\" | Where-Object {\$_.bindingInformation -eq \\\"${ip_address}:${port}:${host_header}\\\"}) { exit 1 } else { exit 0 }\"",
      logoutput => true,
      require   => Iis::Manage_site[$site_name],
    }

    if ($protocol == 'https') {
      validate_re($certificate_name, ['^(.)+$'], 'certificate_name required for https bindings')
      if ($ip_address == '*' or $ip_address == '0.0.0.0') {
        fail('https bindings require a valid ip_address')
      }

      exec { "Attach-Certificate-${title}":
        path      => "${iis::param::powershell::path};${::path}",
        command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; New-Item \\\"IIS:\\SslBindings\\${ip_address}!${port}\\\" -Value (Get-ChildItem cert:\\ -Recurse | Where-Object {\$_.FriendlyName -match \\\"${certificate_name}\\\" } | Select-Object -First 1)\"",
        onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Get-ChildItem cert:\\ -Recurse | Where-Object {\$_.FriendlyName -match \\\"${certificate_name}\\\" } | Select-Object -First 1) -and ((Test-Path \\\"IIS:\\SslBindings\\${ip_address}!${port}\\\") -eq \$false)) { exit 0 } else { exit 1 }\"",
        require   => Exec["CreateBinding-${title}"],
        logoutput => true,
      }
    }
  } else {
    exec { "DeleteBinding-${title}":
    path      => "${iis::param::powershell::path};${::path}",
    command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Remove-WebBinding -Name \\\"${site_name}\\\" -Port ${port} -Protocol \\\"${protocol}\\\" -HostHeader \\\"${host_header}\\\" -IPAddress \\\"${ip_address}\\\"\"",
    onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if (!(Get-WebBinding -Name \\\"${site_name}\\\" -Port ${port} -Protocol \\\"${protocol}\\\" -HostHeader \\\"${host_header}\\\" -IPAddress \\\"${ip_address}\\\" | Where-Object {\$_.bindingInformation -eq \\\"${ip_address}:${port}:${host_header}\\\"})) { exit 1 } else { exit 0 }\"",
    logoutput => true,
    }
  }
}

