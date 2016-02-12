class iis::features::management_tools {

  case $::kernelmajversion {
    '6.2','6.3': {
      ensure_resource('windowsfeature', 'IIS-WebServerManagementTools' )
      ensure_resource('windowsfeature', 'IIS-ManagementConsole' )
    }
    '6.0','6.1': {
      ensure_resource('windowsfeature', 'Web-Mgmt-Tools' )
      ensure_resource('windowsfeature', 'Web-Mgmt-Console' )
    }
    default: {
      fail("Do not know how to install iis windows features for ${::kernelmajversion}")
    }
  }
}
