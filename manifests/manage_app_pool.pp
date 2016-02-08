define iis::manage_app_pool (
  $app_pool_name           = $title,
  $enable_32_bit           = false,
  $managed_runtime_version = 'v4.0',
  $managed_pipeline_mode   = 'Integrated',
  $ensure                  = 'present',
  $start_mode              = 'OnDemand',
  $rapid_fail_protection   = true,
  $apppool_recycle_schedule  = undef) {
  validate_bool($enable_32_bit)
  validate_re($managed_runtime_version, ['^(v2\.0|v4\.0|v4\.5)$'])
  validate_re($managed_pipeline_mode, ['^(Integrated|Classic)$'])
  validate_re($ensure, '^(present|installed|absent|purged)$', 'ensure must be one of \'present\', \'installed\', \'absent\', \'purged\'')
  validate_re($start_mode, '^(OnDemand|AlwaysRunning)$')
  validate_bool($rapid_fail_protection)

  if $apppool_recycle_schedule != undef {
    if (!empty($apppool_recycle_schedule)) {
      $restart_times_string = join($apppool_recycle_schedule, ',')
      validate_re($restart_times_string, '^\d{2}:\d{2}:\d{2}$|^\b\d{2}:\d{2}:\d{2}(?:,\b\d{2}:\d{2}:\d{2}\b)*$',
      "${restart_times_string} bad - time format hh:mm:ss in array")
      $temptimestr           = regsubst($restart_times_string, '([,]+)', "\"\\1\"", 'G')
      $fixed_times_string      = "\"${temptimestr}\""

      $processscheduledtimes = true
    } else {
      $processscheduledtimes = true
    }
  } else {
    $processscheduledtimes = false
  }

  if ($ensure in ['present','installed']) {
    exec { "Create-${app_pool_name}":
      command   => "Import-Module WebAdministration; New-Item \"IIS:\\AppPools\\${app_pool_name}\"",
      provider  => powershell,
      onlyif    => "Import-Module WebAdministration; if((Test-Path \"IIS:\\AppPools\\${app_pool_name}\")) { exit 1 } else { exit 0 }",
      logoutput => true,
    }

    exec { "StartMode-${app_pool_name}" :
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

    exec { "Framework-${app_pool_name}" :
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

    if ($processscheduledtimes) {
      if (empty($apppool_recycle_schedule)) {
        exec { "CLEAR App Pool Recycle Schedule - ${app_pool_name}":
          command   => "[string]\$ApplicationPoolName = \"${app_pool_name}\";Import-Module WebAdministration;Write-Output \"removing scheduled recycles\";Clear-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule;",
          provider  => powershell,
          unless    => "[string]\$ApplicationPoolName = \"${app_pool_name}\";Import-Module WebAdministration;if((Get-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule.collection).Length -eq \$null){exit 0;}else{exit 1;}",
          require   => Exec["Create-${app_pool_name}"],
          logoutput => true,
        }
      } else {
        exec { "App Pool Recycle Schedule - ${app_pool_name} - ${fixed_times_string}":
          command   => "[string]\$ApplicationPoolName = \"${app_pool_name}\";[string[]]\$RestartTimes = @(${fixed_times_string});Import-Module WebAdministration;Clear-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule;\
foreach (\$restartTime in \$RestartTimes){Write-Output \"Adding recycle at \$restartTime\";New-ItemProperty -Path \"IIS:\\AppPools\\\$ApplicationPoolName\" -Name Recycling.periodicRestart.schedule -Value @{value=\$restartTime};}",
          provider  => powershell,
          unless    => "[string]\$ApplicationPoolName = \"${app_pool_name}\";[string[]]\$RestartTimes = @(${fixed_times_string});Import-Module WebAdministration;[Collections.Generic.List[String]]\$collectionAsList = @();\
for(\$i=0; \$i -lt (Get-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule.collection).Count; \$i++){\$collectionAsList.Add((Get-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule.collection)[\$i].value.ToString());}\
if(\$collectionAsList.Count -ne \$RestartTimes.Length){exit 1;}foreach (\$restartTime in \$RestartTimes) {if(!\$collectionAsList.Contains(\$restartTime)){exit 1;}}exit 0;",
          require   => Exec["Create-${app_pool_name}"],
          logoutput => true,
        }
      }
    }
  } else {
    exec { "Delete-${app_pool_name}":
      command   => "Import-Module WebAdministration; Remove-Item \"IIS:\\AppPools\\${app_pool_name}\" -Recurse",
      provider  => powershell,
      onlyif    => "Import-Module WebAdministration; if(!(Test-Path \"IIS:\\AppPools\\${app_pool_name}\")) { exit 1 } else { exit 0 }",
      logoutput => true,
    }
  }
}
