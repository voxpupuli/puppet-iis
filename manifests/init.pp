class iis {
  warning('puppet-iis is now deprecated. Please use puppetlabs-iis instead')
  include ::iis::features::application_deployment
  include ::iis::features::common_http
  include ::iis::features::health_and_diagnostics
  include ::iis::features::management_tools
  include ::iis::features::performance
  include ::iis::features::security
}
