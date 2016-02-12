class iis::features::security {

  case $::kernelmajversion {
    '6.2','6.3': {
      ensure_resource('windowsfeature', 'IIS-RequestFiltering' )
    }
    '6.0','6.1': {
      ensure_resource('windowsfeature', 'Web-Filtering' )
    }
    default: {
      fail("Do not know how to install iis windows features for ${::kernelmajversion}")
    }
  }
}
