class iis::features::performance {

  case $::kernelmajversion {
    '6.2','6.3': {
      ensure_resource('windowsfeature', 'IIS-HttpCompressionStatic' )
      ensure_resource('windowsfeature', 'IIS-HttpCompressionDynamic' )
    }
    '6.0','6.1': {
      ensure_resource('windowsfeature', 'Web-Stat-Compression' )
      ensure_resource('windowsfeature', 'Web-Dyn-Compression' )
    }
    default: {
      fail("Do not know how to install iis windows features for ${::kernelmajversion}")
    }
  }
}
