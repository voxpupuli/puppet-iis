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

####Refresh event
Sending a refresh event to an iis_pool type will recycle the application pool.

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
