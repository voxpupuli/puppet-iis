#
define iis::manage_app_pool(
  $ensure = 'present',
  $app_pool_name = $title,
  $enable_32_bit = false,
  $managed_runtime_version = 'v4.0',
  $managed_pipeline_mode = 'Integrated',
  $queue_length = 1000,
  $max_worker_processes = 1,
  $recycling_time_interval = 1740,
) {

  validate_bool($enable_32_bit)
  validate_re($managed_runtime_version, ['^(v2\.0|v4\.0)$'])
  validate_re($managed_pipeline_mode, ['^(Integrated|Classic)$'])
  validate_re($ensure, '^(present|installed|absent|purged)$', 'ensure must be one of \'present\', \'installed\', \'absent\', \'purged\'')
  validate_re("${queue_length}", '^[0-9]+$', 'queue_length must be a positive integer')
  validate_re("${max_worker_processes}", '^[0-9]+$', 'max_worker_processes must be a positive integer')
  validate_re("${recycling_time_interval}", '^[0-9]+$', 'recycling_time_interval must be a positive integer')

  if ($ensure in ['present','installed']) {
    exec { "Create-${app_pool_name}" :
      command   => "Import-Module WebAdministration; New-Item \"IIS:\\AppPools\\${app_pool_name}\"",
      provider  => powershell,
      onlyif    => "Import-Module WebAdministration; if((Test-Path \"IIS:\\AppPools\\${app_pool_name}\")) { exit 1 } else { exit 0 }",
      logoutput => true,
    }

    exec { "Framework-${app_pool_name}" :
      command   => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" managedRuntimeVersion ${managed_runtime_version}",
      provider  => powershell,
      onlyif    => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" managedRuntimeVersion).Value.CompareTo('${managed_runtime_version}') -eq 0) { exit 1 } else { exit 0 }",
      require   => Exec["Create-${app_pool_name}"],
      logoutput => true,
    }

    exec { "32bit-${app_pool_name}" :
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

    exec { "ManagedPipelineMode-${app_pool_name}" :
      command   => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" managedPipelineMode ${managed_pipeline_mode_value}",
      provider  => powershell,
      onlyif    => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\${app_pool_name}\" managedPipelineMode).CompareTo('${managed_pipeline_mode}') -eq 0) { exit 1 } else { exit 0 }",
      require   => Exec["Create-${app_pool_name}"],
      logoutput => true,
    }

    exec { "QueueLength-${app_pool_name}" :
      path      => "${iis::param::powershell::path};${::path}",
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\${app_pool_name}\\\" queueLength ${queue_length}\"",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\${app_pool_name}\\\" queueLength).Value -eq ${queue_length}) { exit 1 } else { exit 0 }\"",
      require   => Exec["Create-${app_pool_name}"],
      logoutput => true,
    }

    exec { "MaxWorkerProcesses-${app_pool_name}" :
      path      => "${iis::param::powershell::path};${::path}",
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\${app_pool_name}\\\" processModel.maxProcesses ${max_worker_processes}\"",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\${app_pool_name}\\\" processModel.maxProcesses).Value -eq ${max_worker_processes}) { exit 1 } else { exit 0 }\"",
      require   => Exec["Create-${app_pool_name}"],
      logoutput => true,
    }

    exec { "RecyclingTimeInterval-${app_pool_name}" :
      path      => "${iis::param::powershell::path};${::path}",
      command   => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\${app_pool_name}\\\" recycling.periodicRestart.time (New-TimeSpan -Minutes ${recycling_time_interval})\"",
      onlyif    => "${iis::param::powershell::command} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\${app_pool_name}\\\" recycling.periodicRestart.time.Value).TotalMinutes -eq ${recycling_time_interval}) { exit 1 } else { exit 0 }\"",
      require   => Exec["Create-${app_pool_name}"],
      logoutput => true,
    }
  } else {
    exec { "Delete-${app_pool_name}" :
      command   => "Import-Module WebAdministration; Remove-Item \"IIS:\\AppPools\\${app_pool_name}\" -Recurse",
      provider  => powershell,
      onlyif    => "Import-Module WebAdministration; if(!(Test-Path \"IIS:\\AppPools\\${app_pool_name}\")) { exit 1 } else { exit 0 }",
      logoutput => true,
    }
  }
}
