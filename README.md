Puppet-IIS
============================

Module for puppet that can be used to create sites, application pools and virtual applications with IIS 7 and above.

[![Build Status](https://travis-ci.org/voxpupuli/puppet-iis.svg?branch=master)](https://travis-ci.org/voxpupuli/puppet-iis)
Usage
--
This module is only available to Windows Server 2008 and above due to using the WebAdministration module that ships with PowerShell. To use the module, use git clone to a directory in your modules folder on your puppetmaster. Then create a module manifest for the site you wish to maintain configuration for. Then you need to include this new module manifest in your nodes.pp file as follows:

    node 'nodename' {
        include 'mywebsite'
    }

Please note, that you need to implement the iis class in your module as in the example below

Examples
--
      class mywebsite {
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

Additional Bindings
--
A default binding is setup using the values passed to the manage_site resource.
Additional bindings can be added to a site using the manage_binding resource.

--
    iis::manage_binding { 'www.mysite.com-port-8080':
      site_name => 'www.mysite.com',
      protocol  => 'http',
      port      => '8080',
    }

Host header and ip address can also be supplied.

--
    iis::manage_binding { 'www.mysite.com-port-8080':
      site_name   => 'www.mysite.com',
      protocol    => 'http',
      port        => '8080',
      ip_address  => '192.168.0.1',
      host_header => 'mysite.com',
    }

Notes on Managing App Pools
--

    class mywebsite {
      iis::manage_app_pool { 'my_application_pool0':
        enable_32_bit           => true,
        managed_runtime_version => 'v4.0',
        apppool_identitytype    => 'ApplicationPoolIdentity', # ApplicationPoolIdentity (or '4') is the default an IIS app pool will be created with
      }

      iis::manage_app_pool { 'my_application_pool1':
        enable_32_bit           => true,
        managed_runtime_version => 'v4.0',
        apppool_identitytype    => 'LocalSystem', # LocalSystem (or '0')
      }

      iis::manage_app_pool { 'my_application_pool2':
        enable_32_bit           => true,
        managed_runtime_version => 'v4.0',
        apppool_identitytype    => 'LocalService', # LocalService (or '1')
      }

      iis::manage_app_pool { 'my_application_pool3':
        enable_32_bit           => true,
        managed_runtime_version => 'v4.0',
        apppool_identitytype    => 'NetworkService', # NetworkService (or '2')
      }

      iis::manage_app_pool { 'my_application_pool4':
        enable_32_bit           => true,
        managed_runtime_version => 'v4.0',
        apppool_identitytype    => 'SpecificUser', # SpecificUser (or '3'),
        apppool_username        => 'username',     # MUST specify a username when 'SpecificUser'/'3' for apppool_identitytype
        apppool_userpw          => 'password'      # MUST specify a password when 'SpecificUser'/'3' for apppool_identitytype
      }

      iis::manage_app_pool { 'my_application_pool5':
        enable_32_bit                => true,
        managed_runtime_version      => 'v4.0',
        apppool_idle_timeout_minutes => 60, # 30 days (43200 min) is max value for this in iis, 0 disables
      }
    }
