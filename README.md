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

#### iis_site attributes

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

#### iis_pool attributes

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
