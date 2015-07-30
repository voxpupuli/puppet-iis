class iis::install(
  $service_enabled = true,
  $service_ensure = 'running',
) {
  dism { 'IIS-WebServer':
    ensure => present,
    all    => true,
    notify => Service['w3svc'],
    before => Service['w3svc']
  }

  service { 'w3svc':
    ensure => $service_ensure,
    enable => $service_enabled,
  }
}