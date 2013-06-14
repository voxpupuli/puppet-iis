define iis::manage_binding($site_name, $protocol, $port, $host_header, $ip_address = '*') {
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
    command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; New-WebBinding -Name ${site_name} -Port ${port} -Protocol ${protocol} -HostHeader ${host_header} -IPAddress \\\"${ip_address}\\\"\"",
    onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if (Get-WebBinding -Name ${site_name} -Port ${port} -Protocol ${protocol} -HostHeader ${host_header} -IPAddress \\\"${ip_address}\\\" | Where-Object {\$_.bindingInformation -eq \\\"${ip_address}:${port}:${host_header}\\\"}) { exit 1 } else { exit 0 }\"",
    logoutput => true,
    require   => Iis::Manage_site[$site_name],
  }
}

