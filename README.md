Puppet-IIS
============================

Module for puppet that can be used to create sites, application pools and virtual applications with IIS 7 and above. 

[![Build Status](https://travis-ci.org/opentable/puppet-iis.png?branch=master)](https://travis-ci.org/opentable/puppet-iis)

Usage
--
This module is only available to Windows Server 208 and above due to using the WebAdministration module that ships with PowerShell. To use the module, simply:

    node 'nodename' {
        include iis
    }

Examples
--
      class iis {
        iis::manage_app_pool {'my_application_pool':
          enable_32_bit           => true,
          managed_runtime_version => 'v4.0',
        }

    	iis::manage_site {'www.mysite.com':
      	  site_path     => 'C:\inetpub\wwwroot\mysite',
      	  port          => '80',
      	  ip_address    => '*',
      	  host_header   => 'www.mysite.com',
      	  app_pool      => 'my_application_pool'
    	}

    	iis::manage_virtual_application {'application1':
      	  site_name   => 'www.mysite.com',
      	  site_path   => 'C:\inetpub\wwwroot\application1',
      	  app_pool    => 'my_application_pool'
    	}
    	
    	iis::manage_virtual_application {'application2':
      	  site_name   => 'www.mysite.com',
      	  site_path   => 'C:\inetpub\wwwroot\application2',
      	  app_pool    => 'my_application_pool'
    	}
     }
     
This will result in an IIS Directory setup as follows:

* www.mysite.com
	* Application1
	* Application2
	
The module knows that if requesting a virtual application, then it will have to create a site and application pool in the correct order so that it can build the correct model. Further usage would be to include the values as specified in the iis class above from hiera configuration.