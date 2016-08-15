# Puppet-IIS
Module for puppet that can be used to create sites, application pools and virtual applications with IIS 7 and above.

[![Build Status](https://travis-ci.org/voxpupuli/puppet-iis.svg?branch=master)](https://travis-ci.org/voxpupuli/puppet-iis)
Usage

#### Table of Contents
1. [Overview](#overview)
1. [Requirements] (#requirements)
1. [Types] (#types)
  * [iis_site] (#iis_site)
  * [iis_pool] (#iis_pool)
  * [iis_virtualdirectory] (#iis_virtualdirectory)
  * [iis_application] (#iis_application)

## Overview

Create and manage IIS websites, application pools, and virtual applications.

## Requirements

- >= Windows 2012
- IIS installed

## Types

### iis_site

Enumerate all IIS websites:
* `puppet resource iis_site`

Example output for `puppet resource iis_site 'Default Web Site'`
```puppet
iis_site { 'Default Web Site':
  ensure   => 'started',
  app_pool => 'DefaultAppPool',
  ip       => '*',
  path     => 'C:\InetPub\WWWRoot',
  port     => '80',
  protocol => 'http',
  ssl      => 'false',
}
```

#### iis_site attributes

* `ensure`
Denotes the presence and state of site. `{ present, absent, started, stopped}`
Default: `started`

* `name`
(namevar) Web site's name.

* `path`
Web root for the site.  This can be left blank, although IIS won't
be able to start the site.

* `app_pool`
The application pool which should contain the site. Default: `DefaultAppPool`

* `host_header`
A host header that should apply to the site. Set to `false` to maintain
no host header.

* `protocol`
The protocol for the site. Default `http`

* `ip`
The IP address for the site to listen on. Default: `$::ipaddress`

* `port`
The port for the site to listen on. Default: `80`

* `ssl`
If SSL should be enabled. Default: `false`

* `state`
Whether the site should be `Started` or `Stopped`.  Default: `Started`

####Refresh event
Sending a refresh event to an iis_site type will recycle the web site.

### iis_pool

Enumerate all IIS application pools:
* `puppet resource iis_pool`

Example output for `puppet resource iis_site 'DefaultAppPool'`
```puppet
iis_pool { 'DefaultAppPool':
  ensure        => 'started',
  enable_32_bit => 'false',
  pipeline      => 'Integrated',
  runtime       => 'v4.0',
}
```

#### iis_pool attributes

* `ensure`
Denotes the presence and state of pool. `{ present, absent, started, stopped}`
Default: `started`

* `name`
(namevar) Application pool's name.

* `enable_32_bit`
Enable 32-bit applications (boolean). Default: `false`

* `pipeline`
The managed pipeline mode for the pool {'Classic', 'Integrated'}.

* `runtime`
Version of .NET runtime for the pool (float).

* `state`
Whether the site should be `Started` or `Stopped`.  Default: `Started`

* `autostart`
Toggle the autostart option for the application pool. `{true, false}`

* `start_mode`
Toggle start mode. OnDemand (when http request is made) or AlwaysRunning (reduces
startup on initial request). `{OnDemand, AlwaysRunning}`

* `rapid_fail_protection`
Downs the application pool if it fails x times within a time period. `{true, false}`

* `identitytype`
Name of the service or user account under which the application pool's worker process runs.
Choose `SpecificUser` to add a username and password for a specific account.
`{LocalSystem, LocalService, NetworkService, SpecificUser, ApplicationPoolIdentity}`

*  `username`
Account managing the application pool. Requires `identitytype => 'SpecificUser'`.

* `password`
Password for the username managing the application pool. Requires `identitytype => 'SpecificUser'`.

* `idle_timeout`
How long a worker process should run idle with no new requests before requesting shutdown. `{HH:MM:SS}`

* `idle_timeout_action`
How the worker process show respond when reaching the idle timeout. `{Terminate, Suspend}`

* `max_processes`
Maximum number of worker processes for the application pool. `{0, 1, 2}`

* `max_queue_length`
Maximum number of queued http requests for application pool.  Gives *503* when limit is reached. `{'1000', '2000'}`,

* `recycle_periodic_minutes`
Set the schedule of worker process recycling for the pool. `{'D.HH:MM:SS, 1.01:10:01'}`

* `recycle_schedule` 
Set the schedule of periodic restarts of the pool. `{'HH:MM:SS','02:03:04'}`,

* `recycle_logging` 
Log and event if the application pool is recycled. 
`{['Time','Memory','Requests','Schedule','IsapiUnhealthy','ConfigChange','PrivateMemory']}`
Note: at the moment this has to match the order that powershell wants, so you might see an error with
the order listed if you have it wrong.

####Refresh event
Sending a refresh event to an iis_pool type will recycle the application pool.

### iis_binding

Enumerate all IIS bindings :
* `puppet resource iis_binding`

#### iis_virtualdirectory attributes
* `name`
Set the name to the IP ':' the port ':' the host header.  This is the unique
identifier used by Windows to find the binding. `{'127.0.0.1:80:puppetonwindows.com'}`

* `ensure`
Set the state of the binding. `{present, absent}`

* `site_name`
The associated web site for the binding. `{'Default Web Site'}`

* `protocol`
The protocol for the binding. `{'http','https','net.pipe','netmsmq','msmq.formatname'}`

* `port`
The port for the binding. `{'80','443'}`

* `host_header`
The host header for the binding. `{'puppetonwindows.com','defaultwebsite.com'}`

* `ip_address`
The ip address for the binding `{'127.0.0.1'}`

* `ssl_flag`
Toggle ssl for this binding `{true, false}`

* `certificate`
If you enable ssl, supply a certificate by including the full path
to the certificate store and the thumbprint here.
`{'cert:\localmachine\webhosting\<certificatethumbprint>'}`

### iis_virtualdirectory

Enumerate all IIS virtual directories:
* `puppet resource iis_virtualdirectory`

Example output for `puppet resource iis_virtualdirectory 'default'`
```puppet
iis_virtualdirectory { 'default':
  ensure => 'present',
  path   => 'C:\inetpub\wwwroot',
  site   => 'Default Web Site',
}
```

#### iis_virtualdirectory attributes

* `path`
Target directory for the virtual directory.

* `site`
(Read-only) Web site in which the virtual directory resides.
To change sites, remove and re-create virtual directory.

### iis_application

Enumerate all IIS applications:
* `puppet resource iis_application`

Example output for `puppet resource iis_site 'test_app'`
```puppet
iis_application { 'test_app':
  ensure   => 'present',
  app_pool => 'DefaultAppPool',
  path     => 'C:\Temp',
  site     => 'Default Web Site',
}
```

#### iis_application attributes

* `app_pool`
The application pool which should contain the application. Default: `DefaultAppPool`

* `path`
Root for the application.  This can be left blank, although IIS won't
be able to use it.

* `site`
(Read-only) Web site in which the application resides.
To change sites, remove and re-create application.

## Troubleshooting / Known Issues

`Error: /Stage[main]/Main/Iis_pool[MyAppPool]: Could not evaluate: Set-ItemProperty : Flags must be some combination of Time, Requests, Schedule, Memory, IsapiUnhealthy, OnDemand, ConfigChange, PrivateMemory`

If you receive this error you need to set the order of the items in the recycle_logging array to match the order of the flags above. For example,
If you have the array set to `["Time","Memory","Requests"]` you will need to reorder it to `["Time","Requests","Memory"]`