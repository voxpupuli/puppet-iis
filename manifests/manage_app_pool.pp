define iis::manage_app_pool (
  $app_pool_name           = $title,
  $enable_32_bit           = false,
  $managed_runtime_version = 'v4.0',
  $managed_pipeline_mode   = 'Integrated',
  $ensure                  = 'present',
  $start_mode              = 'OnDemand',
  $rapid_fail_protection   = true,
  $apppool_identitytype    = undef,
  $apppool_username        = undef,
  $apppool_userpw          = undef,
  $apppool_idle_timeout_minutes = undef,
  $apppool_max_processes    = undef,
  $apppool_max_queue_length = undef
) {

  validate_bool($enable_32_bit)
  validate_re($managed_runtime_version, ['^(v2\.0|v4\.0|v4\.5)$'])
  validate_re($managed_pipeline_mode, ['^(Integrated|Classic)$'])
  validate_re($ensure, '^(present|installed|absent|purged)$', 'ensure must be one of \'present\', \'installed\', \'absent\', \'purged\'')
  validate_re($start_mode, '^(OnDemand|AlwaysRunning)$')
  validate_bool($rapid_fail_protection)

  if $apppool_idle_timeout_minutes != undef {
    validate_integer($apppool_idle_timeout_minutes, 43200, 0)
    $process_app_pool_idle_timeout = true
    $idle_timeout_ticks          = $apppool_idle_timeout_minutes * 600000000
  } else {
    $process_app_pool_idle_timeout = false
  }

  # keeping new stuff optional for backwards compatibility
  if $apppool_identitytype != undef {

    validate_re($apppool_identitytype, ['^(0|1|2|3|4|LocalSystem|LocalService|NetworkService|SpecificUser|ApplicationPoolIdentity)$'], 'identitytype must be one of \'0\', \'1\',\'2\',\'3\',\'4\',\'LocalSystem\',\'LocalService\',\'NetworkService\',\'SpecificUser\',\'ApplicationPoolIdentity\'')

    if ($apppool_identitytype in ['3','SpecificUser']) {
      if ($apppool_username == undef) or (empty($apppool_username)) {
        fail('attempt set app pool identity to SpecificUser null or zero length $apppool_username param')
      }

      if ($apppool_userpw == undef) or (empty($apppool_userpw)) {
        fail('attempt set app pool identity to SpecificUser null or zero length $apppool_userpw param')
      }
    }

    case $apppool_identitytype {
      '0', 'LocalSystem'             : {
        $identitystring = 'LocalSystem'
        $identityenum   = '0'
      }
      '1', 'LocalService'            : {
        $identitystring = 'LocalService'
        $identityenum   = '1'
      }
      '2', 'NetworkService'          : {
        $identitystring = 'NetworkService'
        $identityenum   = '2'
      }
      '3', 'SpecificUser'            : {
        $identitystring = 'SpecificUser'
        $identityenum   = '3'
      }
      '4', 'ApplicationPoolIdentity' : {
        $identitystring = 'ApplicationPoolIdentity'
        $identityenum   = '4'
      }
      default : {
        $identitystring = 'ApplicationPoolIdentity'
        $identityenum   = '4'
      }
    }

    $process_apppool_identity = true

  }
  else {
    $process_apppool_identity = false
  }

  if $apppool_max_processes != undef {
    validate_integer($apppool_max_processes, undef, 0)
    $process_max_processes = true
  } else {
    $process_max_processes = false
  }

  if $apppool_max_queue_length != undef{
    validate_integer($apppool_max_queue_length, 65535, 10)
    $process_max_queue_length = true
  }
  else{
    $process_max_queue_length = false
  }


  if ($ensure in ['present','installed']) {
    exec { "Create-${app_pool_name}":
      command   => "Import-Module WebAdministration; New-Item \"IIS:\\AppPools\\${app_pool_name}\"",
      provider  => powershell,
      onlyif    => "Import-Module WebAdministration; if((Test-Path \"IIS:\\AppPools\\${app_pool_name}\")) { exit 1 } else { exit 0 }",
      logoutput => true,
    }

    exec { "StartMode-${app_pool_name}":
      command   => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" startMode ${start_mode}",
      provider  => powershell,
      onlyif    => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" startMode).CompareTo('${start_mode}') -eq 0) { exit 1 } else { exit 0 }",
      require   => Exec["Create-${app_pool_name}"],
      logoutput => true,
    }

    exec { "RapidFailProtection-${app_pool_name}":
      command   => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" failure.rapidFailProtection ${rapid_fail_protection}",
      provider  => powershell,
      onlyif    => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" failure.rapidFailProtection).Value -eq [System.Convert]::ToBoolean('${rapid_fail_protection}')) { exit 1 } else { exit 0 }",
      require   => Exec["Create-${app_pool_name}"],
      logoutput => true,
    }

    exec { "Framework-${app_pool_name}":
      command   => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" managedRuntimeVersion ${managed_runtime_version}",
      provider  => powershell,
      onlyif    => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" managedRuntimeVersion).Value.CompareTo('${managed_runtime_version}') -eq 0) { exit 1 } else { exit 0 }",
      require   => Exec["Create-${app_pool_name}"],
      logoutput => true,
    }

    exec { "32bit-${app_pool_name}":
      command   => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" enable32BitAppOnWin64 ${enable_32_bit}",
      provider  => powershell,
      onlyif    => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean('${enable_32_bit}')) { exit 1 } else { exit 0 }",
      require   => Exec["Create-${app_pool_name}"],
      logoutput => true,
    }

    $managed_pipeline_mode_value = downcase($managed_pipeline_mode) ? {
      'integrated' => 0,
      'classic'    => 1,
      default      => 0,
    }

    exec { "ManagedPipelineMode-${app_pool_name}":
      command   => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" managedPipelineMode ${managed_pipeline_mode_value}",
      provider  => powershell,
      onlyif    => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" managedPipelineMode).CompareTo('${managed_pipeline_mode}') -eq 0) { exit 1 } else { exit 0 }",
      require   => Exec["Create-${app_pool_name}"],
      logoutput => true,
    }

    if ($process_app_pool_idle_timeout) {
      exec { "App Pool Idle Timeout - ${app_pool_name}":
        command   => "Import-Module WebAdministration;\$appPoolPath = (\"IIS:\\AppPools\\\" + \"${app_pool_name}\");[TimeSpan]\$ts = ${idle_timeout_ticks};Set-ItemProperty \$appPoolPath -name processModel -value @{idletimeout=\$ts}",
        provider  => powershell,
        unless    => "Import-Module WebAdministration;\$appPoolPath = (\"IIS:\\AppPools\\\" + \"${app_pool_name}\");[TimeSpan]\$ts = ${idle_timeout_ticks};if((get-ItemProperty \$appPoolPath -name processModel.idletimeout.value) -ne \$ts){exit 1;}exit 0;",
      }
    }

    if ($process_apppool_identity) {
      if ($identitystring == 'SpecificUser') {
        exec { "app pool identitytype - ${app_pool_name} - SPECIFICUSER - ${apppool_username}":
          command   => "Import-Module WebAdministration;\$iis = New-Object Microsoft.Web.Administration.ServerManager;iis:;\$pool = get-item IIS:\\AppPools\\${app_pool_name};\$pool.processModel.username = \"${apppool_username}\";\$pool.processModel.password = \"${apppool_userpw}\";\$pool.processModel.identityType = ${identityenum};\$pool | set-item;",
          provider  => powershell,
          unless    => "Import-Module WebAdministration;\$iis = New-Object Microsoft.Web.Administration.ServerManager;iis:;\$pool = get-item IIS:\\AppPools\\${app_pool_name};if(\$pool.processModel.identityType -ne \"${identitystring}\"){exit 1;}\
if(\$pool.processModel.userName -ne ${apppool_username}){exit 1;}if(\$pool.processModel.password -ne ${apppool_userpw}){exit 1;}exit 0;",
          require   => Exec["Create-${app_pool_name}"],
          logoutput => true,
        }
      } else {
        exec { "app pool identitytype - ${app_pool_name} - ${identitystring}":
          command   => "Import-Module WebAdministration;\$iis = New-Object Microsoft.Web.Administration.ServerManager;iis:;\$pool = get-item IIS:\\AppPools\\${app_pool_name};\$pool.processModel.identityType = ${identityenum};\$pool | set-item;",
          provider  => powershell,
          unless    => "Import-Module WebAdministration;\$iis = New-Object Microsoft.Web.Administration.ServerManager;iis:;\$pool = get-item IIS:\\AppPools\\${app_pool_name};if(\$pool.processModel.identityType -eq \"${identitystring}\"){exit 0;}else{exit 1;}",
          require   => Exec["Create-${app_pool_name}"],
          logoutput => true,
        }
      }
    }

    if ($process_max_processes) {
      exec { "App Pool Max Processes - ${app_pool_name}":
        command   => "Import-Module WebAdministration;\$appPoolPath = (\"IIS:\\AppPools\\\" + \"${app_pool_name}\");Set-ItemProperty \$appPoolPath -name processModel -value @{maxProcesses=${apppool_max_processes}}",
        provider  => powershell,
        unless    => "Import-Module WebAdministration;\$appPoolPath = (\"IIS:\\AppPools\\\" + \"${app_pool_name}\");if((get-ItemProperty \$appPoolPath -name processModel.maxprocesses.value) -ne ${apppool_max_processes}){exit 1;}exit 0;",
      }
    }

    if($process_max_queue_length)
    {
        exec { "App Pool Max Queue Length - ${app_pool_name}":
        command   => "Import-Module WebAdministration;\$appPoolPath = (\"IIS:\\AppPools\\\" + \"${app_pool_name}\");Set-ItemProperty \$appPoolPath queueLength ${apppool_max_queue_length};",
        provider  => powershell,
        unless    => "Import-Module WebAdministration;\$appPoolPath = (\"IIS:\\AppPools\\\" + \"${app_pool_name}\");if((get-ItemProperty \$appPoolPath).queuelength -ne ${apppool_max_queue_length}){exit 1;}exit 0;",
        require   => Exec["Create-${app_pool_name}"],
        logoutput => true,
      }
    }

  }
  else {
    exec { "Delete-${app_pool_name}":
      command   => "Import-Module WebAdministration; Remove-Item \"IIS:\\AppPools\\${app_pool_name}\" -Recurse",
      provider  => powershell,
      onlyif    => "Import-Module WebAdministration; if(!(Test-Path \"IIS:\\AppPools\\${app_pool_name}\")) { exit 1 } else { exit 0 }",
      logoutput => true,
    }

  }
}
