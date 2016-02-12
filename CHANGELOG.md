#2016-02-12 - Release 2.0.0
###Summary

  New Major version. Support for installing IIS from scratch.
  Lots of new configuration options for managing application pools.

###Features
 - adding support for installing the windows features required to install IIS (#26)
 - added support for SNI (#56)
 - added `start_mode` and `rapid_fail_protection` app pool advanced settings (#70)
 - added `apppool_identitytype` to manage_app_pool (#72)
 - added `apppool_idle_timeout_minutes` to manage_app_pool (#74)
 - added `apppool_max_processes` to manage_app_pool (#75)
 - added `apppool_recycle_periodic_minutes` to manage_app_pool (#78)
 - added `apppool_recycle_logging` to manage_app_pool (#81)
 - added `apppool_recycle_schedule` to manage_app_pool (#82)

###Bugfixes
 - fix virtual applications names that contain slashes (#59)
 - fixed bug with space in virtual directory path (#67)
 - updated the `iis_version` fact to support versions above 10 (#66)

###Improvements
 - updated the `iis_version` fact to be ruby only (#66)
 - updated stdlib minimum version dependency to 4.6.0 (#72)
 - added .net 4.5 as a supported app runtime version (#83)

##2015-05-22 - Release 1.4.1
###Summary

  Bugfix release do move fact into usable location

###Bugfixes
- update the `iis_version` fact to a usable location
- add upper-bound to stdlib and powershell dependencies in metadata
- added puppet and pe requirements to metadata

##2015-05-01 - Release 1.4.0
###Summary

  First release in the new puppet-community namespace. Also adds new definition for managing virtual directories.

####Features
- add new define `iis::manage_virtual_directory` for managing virtual directories.

##2014-11-27 - Release 1.3.0
###Summary

  This release adds the option of only managing bindings. It also switches to the puppetlabs/powershell provider.

####Features
- add parameter `only_manage_binding` if we only want to manage the binding without managing the site

####Bugfixes
- update dependency from joshcooper/powershell to puppetlabs/powershell
- fixing some warnings.
- fixing bug when updating `managed_pipeline_mode`
- update all classes to properly use the powershell provider

##2014-08-14 - Release 1.2.0
###Summary

  This release fixes some bugs when defining virtual applications.

####Bugfixes
- fix being able to manage virtual applications with spaces in the name
- support for virtual applications on a directory that already exists

##2014-08-08 - Release 1.1.2
###Summary

  A small maintenance release fixing some containment issues.

####Bugfixes
- fixing lint and containment issues

##2014-06-19 - Release 1.1.1
###Summary

  Another small bugfix release with the certificates.

####Bugfixes
- fixing small bug in certificate binding

##2014-04-22 - Release 1.1.0
###Summary

  Quick bug fix release to make sure that the https binding is updated if/when you update a certificate.

####Bugfixes
- allow updating of https binding when certificate is updated.

##2014-04-16 - Release 1.0.0
###Summary

   After feedback on the ssl support from the previous 0.0.2 release this release adds support for using the certificate thumbprint rather than the name when adding an SSL certificate.

####Features
- change to using `certificate_thumbprint` rather than `certificate_name`

##2014-02-19 - Release 0.0.2
###Summary

   Fixing lots of small bugs with this release. But the biggest change is the support of enabling SSL for sites.

####Features
- added SSL support

####Bugfixes
- fixed idempotancy bug with spaces in the site name
- fixed bug with quoting in app pool creation command
- fix issue when IIS starts with zero existing sites
- update PhysicalPath and ApplicationPool for existing sites
- removed validation around wildcard '*' for IP address binding

##2013-08-22 - Release 0.0.1
###Summary

   Initial version
