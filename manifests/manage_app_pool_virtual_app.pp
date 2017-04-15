define iis::manage_app_pool_virtual_app(
	$website_name, 
	$site_base_path, 
	$region,
	$virtual_app_name) {

	iis::manage_app_pool { "${virtual_app_name}-${region}":
	enable_32_bit           => false,
	managed_runtime_version => 'v4.0',
	}

	iis::manage_virtual_application {"${website_name}\\${virtual_app_name}":
	site_name                => $website_name,
	site_path                => "${site_base_path}\\${region}\\${virtual_app_name}",
	app_pool                 => "${virtual_app_name}-${region}",
	virtual_application_name => $virtual_app_name,
	}
}
