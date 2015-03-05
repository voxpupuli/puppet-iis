<<<<<<< HEAD
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
          site_id       => '10'
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
        iis::manage_app_pool { 'my_application_pool_0':
          enable_32_bit           => true,
          managed_runtime_version => 'v4.0',
          apppool_identitytype    => 'ApplicationPoolIdentity', # ApplicationPoolIdentity (or '4') is the default an IIS app pool will be created with
        }

        iis::manage_app_pool { 'my_application_pool_1':
          enable_32_bit           => true,
          managed_runtime_version => 'v4.0',
          apppool_identitytype    => 'LocalSystem', # LocalSystem (or '0')
        }

        iis::manage_app_pool { 'my_application_pool_2':
          enable_32_bit           => true,
          managed_runtime_version => 'v4.0',
          apppool_identitytype    => 'LocalService', # LocalService (or '1')
        }

        iis::manage_app_pool { 'my_application_pool_3':
          enable_32_bit           => true,
          managed_runtime_version => 'v4.0',
          apppool_identitytype    => 'NetworkService', # NetworkService (or '2')
        }

        iis::manage_app_pool { 'my_application_pool_4':
          enable_32_bit           => true,
          managed_runtime_version => 'v4.0',
          apppool_identitytype    => 'SpecificUser', # SpecificUser (or '3'),
          apppool_username        => 'username',     # MUST specify a username when 'SpecificUser'/'3' for apppool_identitytype
          apppool_userpw          => 'password'      # MUST specify a password when 'SpecificUser'/'3' for apppool_identitytype
        }

        iis::manage_app_pool { 'my_application_pool_5':
          enable_32_bit                => true,
          managed_runtime_version      => 'v4.0',
          apppool_idle_timeout_minutes => 60, # 30 days (43200 min) is max value for this in iis, 0 disables
        }

        iis::manage_app_pool { 'my_application_pool_6':
          enable_32_bit           => true,
          managed_runtime_version => 'v4.0',
          apppool_max_processes   => 0, # 0 lets iis detect optimal on numa system, not enforcing max (its an int64)
        }

        iis::manage_app_pool { 'my_application_pool_7':
          enable_32_bit            => true,
          managed_runtime_version  => 'v4.0',
          apppool_max_queue_length => 1000, # apppool max queue length - max queue length must be set 10 <= n <= 65535
        }

        iis::manage_app_pool { 'my_application_pool_8':
          enable_32_bit                    => true,
          managed_runtime_version          => 'v4.0',
          apppool_recycle_periodic_minutes => 1440, # apppool periodic cycle - disable app pool cycling on periodic time set $apppoolperiodicrecycle to 0 - it's minutes - max 15372286728
        }

        iis::manage_app_pool { 'my_application_pool9':
          enable_32_bit            => true,
          managed_runtime_version  => 'v4.0',
          apppool_recycle_schedule => ['01:00:00','23:59:59'] # apppool scheduled recycling ['hh:mm:ss','...'] - empty array to clear scheduled recycling on an app pool
        }

        iis::manage_app_pool { 'my_application_pool_10':
          enable_32_bit            => true,
          managed_runtime_version  => 'v4.0',
          apppool_recycle_schedule => [] # empty array to clear scheduled recycling on an app pool
        }

        iis::manage_app_pool { 'my_application_pool_11':
          enable_32_bit           => true,
          managed_runtime_version => 'v4.0',
          apppool_recycle_logging => ['Time','Requests','Schedule','Memory','IsapiUnhealthy','OnDemand','ConfigChange','PrivateMemory'],
        }

        iis::manage_app_pool {'my_application_pool_12':
          enable_32_bit           => true,
          managed_runtime_version => 'v4.0',
          apppool_recycle_logging => [], # clear all app pool recycle logging from 'my_application_pool_12 assuming other params set appropriately
        }
    }
=======
# IIS Types

#### Table of Contents
1. [Overview](#overview)
1. [Requirements] (#requirements)
1. [Types] (#types)
  * [iis_site] (#iis_site)
  * [iis_pool] (#iis_pool)

## Overview

Create and manage IIS websites, application pools, and virtual applications.

## Requirements

- >= Windows 2012
- IIS installed

## Types

### iis_site

Enumerate all IIS websites:
* `puppet resource iis_site`<br />

Example output for `puppet resource iis_site 'Default Web Site'`
```
iis_site { 'Default Web Site':
  ensure   => 'present',
  app_pool => 'DefaultAppPool',
  ip       => '*',
  path     => 'C:\InetPub\WWWRoot',
  port     => '80',
  protocol => 'http',
  ssl      => 'false',
  state    => 'Started',
}
```

### iis_site attributes

* `name`<br />
(namevar) Web site's name.

* `path`<br />
Web root for the site.  This can be left blank, although IIS won't
be able to start the site.

* `app_pool`<br />
The application pool which should contain the site. Default: `DefaultAppPool`

* `host_header`<br />
A host header that should apply to the site. Set to `false` to maintain
no host header.

* `protocol`<br />
The protocol for the site. Default `http`

* `ip`<br />
The IP address for the site to listen on. Default: `$::ipaddress`

* `port`<br />
The port for the site to listen on. Default: `80`

* `ssl`<br />
If SSL should be enabled. Default: `false`

* `state` <br />
Whether the site should be `Started` or `Stopped`.  Default: `Started`

####Refresh event <br />
Sending a refresh event to an iis_site type will recycle the web site.

### iis_pool

Enumerate all IIS application pools:
* `puppet resource iis_pool`<br />

Example output for `puppet resource iis_site 'DefaultAppPool'`
```
iis_pool { 'DefaultAppPool':
  ensure        => 'present',
  enable_32_bit => 'false',
  pipeline      => 'Integrated',
  runtime       => '4.0',
  state         => 'Started',
}
```

### iis_pool attributes

* `name`<br />
(namevar) Application pool's name.

* `enable_32_bit`<br />
Enable 32-bit applications (boolean). Default: `false`

* `pipeline`<br />
The managed pipeline mode for the pool {'Classic', 'Integrated'}.

* `runtime`<br />
Version of .NET runtime for the pool (float).

* `state` <br />
Whether the site should be `Started` or `Stopped`.  Default: `Started`

####Refresh event <br />
Sending a refresh event to an iis_pool type will recycle the application pool.
>>>>>>> (maint) iis_site rewrite
