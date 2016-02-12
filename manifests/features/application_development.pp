class iis::features::application_development {

  case $::kernelmajversion {
    '6.2','6.3': {
      ensure_resource('windowsfeature', 'IIS-ASPNET' )
      ensure_resource('windowsfeature', 'IIS-ASPNET45' )
      ensure_resource('windowsfeature', 'IIS-NetFxExtensibility' )
      ensure_resource('windowsfeature', 'IIS-NetFxExtensibility45' )
      ensure_resource('windowsfeature', 'IIS-ISAPIExtentions' )
      ensure_resource('windowsfeature', 'IIS-ISAPIFilter' )
    }
    '6.0','6.1': {
      ensure_resource('windowsfeature', 'Web-Asp-Net' )
      ensure_resource('windowsfeature', 'Web-Net-Ext' )
      ensure_resource('windowsfeature', 'Web-ISAPI-Ext' )
      ensure_resource('windowsfeature', 'Web-ISAPI-Filter' )
    }
    default: {
      fail("Do not know how to install iis windows features for ${::kernelmajversion}")
    }
  }
}
