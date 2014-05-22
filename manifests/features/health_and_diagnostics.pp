class iis::features::health_and_diagnostics {

  case $::kernelmajversion {
    '6.2','6.3': {
      ensure_resource('windowsfeature', 'IIS-HttpLogging' )
      ensure_resource('windowsfeature', 'IIS-RequestMonitor' )
    }
    '6.0','6.1': {
      ensure_resource('windowsfeature', 'Web-Http-Logging' )
      ensure_resource('windowsfeature', 'Web-Request-Monitor' )
    }
    default: {
      fail("Do not know how to install iis windows features for ${::kernelmajversion}")
    }
  }
}
