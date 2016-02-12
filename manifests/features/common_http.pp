class iis::features::common_http {

  case $::kernelmajversion {
    '6.2','6.3': {
      ensure_resource('windowsfeature', 'IIS-StaticContent' )
      ensure_resource('windowsfeature', 'IIS-HttpErrors' )
      ensure_resource('windowsfeature', 'IIS-DefaultDocument' )
    }
    '6.0','6.1': {
      ensure_resource('windowsfeature', 'Web-Static-Content' )
      ensure_resource('windowsfeature', 'Web-Http-Errors' )
      ensure_resource('windowsfeature', 'Web-Default-Doc' )
    }
    default: {
      fail("Do not know how to install iis windows features for ${::kernelmajversion}")
    }
  }
}
