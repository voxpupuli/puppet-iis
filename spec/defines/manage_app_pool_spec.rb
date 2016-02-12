require 'spec_helper'

describe 'iis::manage_app_pool', :type => :define do
  describe 'when managing the iis application pool' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{
      :enable_32_bit                => true,
      :managed_runtime_version      => 'v4.0',
      :managed_pipeline_mode        => 'Integrated',
      :apppool_idle_timeout_minutes => 60,
      :apppool_identitytype         => 'ApplicationPoolIdentity',
      :apppool_max_processes        => 0,
      :apppool_max_queue_length     => 1000,
      :apppool_recycle_periodic_minutes => 60,
      :apppool_recycle_schedule => %w(01:00:00 23:59:59),
      :apppool_recycle_logging => %w(Time Requests)
    }}

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; New-Item "IIS:\\AppPools\\myAppPool.example.com"',
      :onlyif  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v4.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" enable32BitAppOnWin64 true',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedPipelineMode 0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Integrated') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('App Pool Idle Timeout - myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + "myAppPool.example.com");[TimeSpan]$ts = 36000000000;Set-ItemProperty $appPoolPath -name processModel -value @{idletimeout=$ts}',
      :unless  => 'Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + "myAppPool.example.com");[TimeSpan]$ts = 36000000000;if((get-ItemProperty $appPoolPath -name processModel.idletimeout.value) -ne $ts){exit 1;}exit 0;',)
    }

    it { should contain_exec('app pool identitytype - myAppPool.example.com - ApplicationPoolIdentity').with(
      :command => 'Import-Module WebAdministration;$iis = New-Object Microsoft.Web.Administration.ServerManager;iis:;$pool = get-item IIS:\\AppPools\\myAppPool.example.com;$pool.processModel.identityType = 4;$pool | set-item;',
      :unless  => 'Import-Module WebAdministration;$iis = New-Object Microsoft.Web.Administration.ServerManager;iis:;$pool = get-item IIS:\\AppPools\\myAppPool.example.com;if($pool.processModel.identityType -eq "ApplicationPoolIdentity"){exit 0;}else{exit 1;}',)
    }

    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - SPECIFICUSER - username') }

    it { should contain_exec('App Pool Max Processes - myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + "myAppPool.example.com");Set-ItemProperty $appPoolPath -name processModel -value @{maxProcesses=0}',
      :unless  => 'Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + "myAppPool.example.com");if((get-ItemProperty $appPoolPath -name processModel.maxprocesses.value) -ne 0){exit 1;}exit 0;',)
    }

    it { should contain_exec('App Pool Max Queue Length - myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + "myAppPool.example.com");Set-ItemProperty $appPoolPath queueLength 1000;',
      :unless  => 'Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + "myAppPool.example.com");if((get-ItemProperty $appPoolPath).queuelength -ne 1000){exit 1;}exit 0;',)
    }

    it { should contain_exec('App Pool Recycle Periodic - myAppPool.example.com - 60').with(
      :command => '$appPoolName = "myAppPool.example.com";[TimeSpan] $ts = 36000000000;Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + $appPoolName);Get-ItemProperty $appPoolPath -Name recycling.periodicRestart.time;Set-ItemProperty $appPoolPath -Name recycling.periodicRestart.time -value $ts;',
      :unless  => '$appPoolName = "myAppPool.example.com";[TimeSpan] $ts = 36000000000;Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + $appPoolName);if((Get-ItemProperty $appPoolPath -Name recycling.periodicRestart.time.value) -ne $ts.Ticks){exit 1;}exit 0;',)
    }

    it { should contain_exec('App Pool Recycle Schedule - myAppPool.example.com - "01:00:00","23:59:59"').with(
      :command => "[string]\$ApplicationPoolName = \"myAppPool.example.com\";[string[]]\$RestartTimes = @(\"01:00:00\",\"23:59:59\");Import-Module WebAdministration;Clear-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule;\
foreach (\$restartTime in \$RestartTimes){Write-Output \"Adding recycle at \$restartTime\";New-ItemProperty -Path \"IIS:\\AppPools\\\$ApplicationPoolName\" -Name Recycling.periodicRestart.schedule -Value @{value=\$restartTime};}",
      :unless  => "[string]\$ApplicationPoolName = \"myAppPool.example.com\";[string[]]\$RestartTimes = @(\"01:00:00\",\"23:59:59\");Import-Module WebAdministration;[Collections.Generic.List[String]]\$collectionAsList = @();\
for(\$i=0; \$i -lt (Get-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule.collection).Count; \$i++){\$collectionAsList.Add((Get-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule.collection)[\$i].value.ToString());}\
if(\$collectionAsList.Count -ne \$RestartTimes.Length){exit 1;}foreach (\$restartTime in \$RestartTimes) {if(!\$collectionAsList.Contains(\$restartTime)){exit 1;}}exit 0;",)
    }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }

    it { should contain_exec('App Pool Logging - myAppPool.example.com').with(
      :command => '$appPoolName = "myAppPool.example.com";Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + $appPoolName);Set-ItemProperty $appPoolPath -name recycling -value @{logEventOnRecycle="Time,Requests"};',
      :unless  => "\$appPoolName = \"myAppPool.example.com\";Import-Module WebAdministration;\$appPoolPath = (\"IIS:\\AppPools\\\" + \$appPoolName);[string[]]\$LoggingOptions = @(\"Time\",\"Requests\");if((Get-ItemProperty \$appPoolPath -Name Recycling.LogEventOnRecycle).value -eq 0){exit 1;}\
[string[]]\$enumsplit = (Get-ItemProperty \$appPoolPath -Name Recycling.LogEventOnRecycle).Split(',');if(\$LoggingOptions.Length -ne \$enumsplit.Length){exit 1;}foreach(\$s in \$LoggingOptions){if(\$enumsplit.Contains(\$s) -eq \$false){exit 1;}}exit 0;",)
    }

    it { should_not contain_exec('Clear App Pool Logging - myAppPool.example.com') }
  end

  describe 'when managing the iis application pool with SpecificUser identitytype' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{
      :enable_32_bit           => true,
      :managed_runtime_version => 'v4.0',
      :managed_pipeline_mode   => 'Integrated',
      :apppool_identitytype    => 'ApplicationPoolIdentity',
      :apppool_username        => 'username',
      :apppool_userpw          => 'password'
    }}

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; New-Item "IIS:\\AppPools\\myAppPool.example.com"',
      :onlyif  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v4.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" enable32BitAppOnWin64 true',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedPipelineMode 0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Integrated') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('app pool identitytype - myAppPool.example.com - ApplicationPoolIdentity').with(
      :command => 'Import-Module WebAdministration;$iis = New-Object Microsoft.Web.Administration.ServerManager;iis:;$pool = get-item IIS:\\AppPools\\myAppPool.example.com;$pool.processModel.identityType = 4;$pool | set-item;',
      :unless  => 'Import-Module WebAdministration;$iis = New-Object Microsoft.Web.Administration.ServerManager;iis:;$pool = get-item IIS:\\AppPools\\myAppPool.example.com;if($pool.processModel.identityType -eq "ApplicationPoolIdentity"){exit 0;}else{exit 1;}',)
    }

    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - SPECIFICUSER - username') }
  end

  describe 'when managing the iis application pool with SpecificUser identitytype' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{
      :enable_32_bit           => true,
      :managed_runtime_version => 'v4.0',
      :managed_pipeline_mode   => 'Integrated',
      :apppool_identitytype    => 'SpecificUser',
      :apppool_username        => 'username',
      :apppool_userpw          => 'password',
      :apppool_max_processes   => 0,
      :apppool_max_queue_length => 1000
    }}

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; New-Item "IIS:\\AppPools\\myAppPool.example.com"',
      :onlyif  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v4.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" enable32BitAppOnWin64 true',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedPipelineMode 0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Integrated') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('app pool identitytype - myAppPool.example.com - SPECIFICUSER - username').with(
      :command => 'Import-Module WebAdministration;$iis = New-Object Microsoft.Web.Administration.ServerManager;iis:;$pool = get-item IIS:\\AppPools\\myAppPool.example.com;$pool.processModel.username = "username";$pool.processModel.password = "password";$pool.processModel.identityType = 3;$pool | set-item;',
      :unless  => "Import-Module WebAdministration;\$iis = New-Object Microsoft.Web.Administration.ServerManager;iis:;\$pool = get-item IIS:\\AppPools\\myAppPool.example.com;if(\$pool.processModel.identityType -ne \"SpecificUser\"){exit 1;}\
if(\$pool.processModel.userName -ne username){exit 1;}if(\$pool.processModel.password -ne password){exit 1;}exit 0;",)
    }

    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - ApplicationPoolIdentity') }
  end

  describe 'when managing the iis application pool and clearing scheduled app pool recycling' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{
      :enable_32_bit           => true,
      :managed_runtime_version => 'v4.0',
      :managed_pipeline_mode   => 'Integrated',
      :apppool_recycle_schedule => []
    }}

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; New-Item "IIS:\\AppPools\\myAppPool.example.com"',
      :onlyif  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v4.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" enable32BitAppOnWin64 true',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedPipelineMode 0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Integrated') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('CLEAR App Pool Recycle Schedule - myAppPool.example.com').with(
      :command => '[string]$ApplicationPoolName = "myAppPool.example.com";Import-Module WebAdministration;Write-Output "removing scheduled recycles";Clear-ItemProperty IIS:\\AppPools\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule;',
      :unless  => '[string]$ApplicationPoolName = "myAppPool.example.com";Import-Module WebAdministration;if((Get-ItemProperty IIS:\\AppPools\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule.collection).Length -eq $null){exit 0;}else{exit 1;}',)
    }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec('Clear App Pool Logging - myAppPool.example.com') }
  end

  describe 'when managing the iis application pool with cleared app pool logging' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{
      :enable_32_bit           => true,
      :managed_runtime_version => 'v4.0',
      :managed_pipeline_mode   => 'Integrated',
      :apppool_recycle_logging => []
    }}

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; New-Item "IIS:\\AppPools\\myAppPool.example.com"',
      :onlyif  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v4.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" enable32BitAppOnWin64 true',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedPipelineMode 0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Integrated') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('Clear App Pool Logging - myAppPool.example.com').with(
      :command => '$appPoolName = "myAppPool.example.com";Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + $appPoolName);Set-ItemProperty $appPoolPath -name recycling -value @{""};',
      :unless  => '$appPoolName = "myAppPool.example.com";Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + $appPoolName);if((Get-ItemProperty $appPoolPath -Name Recycling.LogEventOnRecycle).value -eq 0){exit 0;}else{exit 1;}',)
    }

    it { should_not contain_exec('App Pool Logging - myAppPool.example.com') }
  end

  describe 'when managing the iis application pool - v2.0 Classic' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{
      :enable_32_bit           => true,
      :managed_runtime_version => 'v2.0',
      :managed_pipeline_mode   => 'Classic',
      :apppool_idle_timeout_minutes => 60,
      :apppool_max_processes => 0,
      :apppool_max_queue_length => 1000,
      :apppool_recycle_periodic_minutes => 60,
      :apppool_recycle_schedule => %w(01:00:00 23:59:59),
      :apppool_recycle_logging => %w(Time Requests)
    }}

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; New-Item "IIS:\\AppPools\\myAppPool.example.com"',
      :onlyif  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v2.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v2.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" enable32BitAppOnWin64 true',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedPipelineMode 1',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Classic') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('App Pool Logging - myAppPool.example.com').with(
      :command => '$appPoolName = "myAppPool.example.com";Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + $appPoolName);Set-ItemProperty $appPoolPath -name recycling -value @{logEventOnRecycle="Time,Requests"};',
      :unless  => "\$appPoolName = \"myAppPool.example.com\";Import-Module WebAdministration;\$appPoolPath = (\"IIS:\\AppPools\\\" + \$appPoolName);[string[]]\$LoggingOptions = @(\"Time\",\"Requests\");if((Get-ItemProperty \$appPoolPath -Name Recycling.LogEventOnRecycle).value -eq 0){exit 1;}\
[string[]]\$enumsplit = (Get-ItemProperty \$appPoolPath -Name Recycling.LogEventOnRecycle).Split(',');if(\$LoggingOptions.Length -ne \$enumsplit.Length){exit 1;}foreach(\$s in \$LoggingOptions){if(\$enumsplit.Contains(\$s) -eq \$false){exit 1;}}exit 0;",)
    }

    it { should_not contain_exec('Clear App Pool Logging - myAppPool.example.com') }
  end

  describe 'when managing the iis application pool - v2.0 Classic with cleared app pool logging' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{
      :enable_32_bit           => true,
      :managed_runtime_version => 'v2.0',
      :managed_pipeline_mode   => 'Classic',
      :apppool_recycle_logging => []
    }}

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; New-Item "IIS:\\AppPools\\myAppPool.example.com"',
      :onlyif  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v2.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v2.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" enable32BitAppOnWin64 true',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedPipelineMode 1',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Classic') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('Clear App Pool Logging - myAppPool.example.com').with(
      :command => '$appPoolName = "myAppPool.example.com";Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + $appPoolName);Set-ItemProperty $appPoolPath -name recycling -value @{""};',
      :unless  => '$appPoolName = "myAppPool.example.com";Import-Module WebAdministration;$appPoolPath = ("IIS:\\AppPools\\" + $appPoolName);if((Get-ItemProperty $appPoolPath -Name Recycling.LogEventOnRecycle).value -eq 0){exit 0;}else{exit 1;}',)
    }

    it { should_not contain_exec('App Pool Logging - myAppPool.example.com') }
  end

  describe 'when managing the iis application pool - v2.0 Classic and clearing scheduled app pool recycling' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{
      :enable_32_bit           => true,
      :managed_runtime_version => 'v2.0',
      :managed_pipeline_mode   => 'Classic',
      :apppool_recycle_schedule => []
    }}

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; New-Item "IIS:\\AppPools\\myAppPool.example.com"',
      :onlyif  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v2.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v2.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" enable32BitAppOnWin64 true',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedPipelineMode 1',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Classic') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('CLEAR App Pool Recycle Schedule - myAppPool.example.com').with(
      :command => '[string]$ApplicationPoolName = "myAppPool.example.com";Import-Module WebAdministration;Write-Output "removing scheduled recycles";Clear-ItemProperty IIS:\\AppPools\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule;',
      :unless  => '[string]$ApplicationPoolName = "myAppPool.example.com";Import-Module WebAdministration;if((Get-ItemProperty IIS:\\AppPools\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule.collection).Length -eq $null){exit 0;}else{exit 1;}',)
    }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }
  end

  describe 'when managing the iis application pool - v2.0 Classic with SpecificUser identitytype' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{
      :enable_32_bit           => true,
      :managed_runtime_version => 'v2.0',
      :managed_pipeline_mode   => 'Classic',
      :apppool_identitytype    => 'SpecificUser',
      :apppool_username		   => 'username',
      :apppool_userpw		   => 'password'
    }}

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; New-Item "IIS:\\AppPools\\myAppPool.example.com"',
      :onlyif  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v2.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v2.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" enable32BitAppOnWin64 true',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedPipelineMode 1',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Classic') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('app pool identitytype - myAppPool.example.com - SPECIFICUSER - username').with(
      :command => 'Import-Module WebAdministration;$iis = New-Object Microsoft.Web.Administration.ServerManager;iis:;$pool = get-item IIS:\\AppPools\\myAppPool.example.com;$pool.processModel.username = "username";$pool.processModel.password = "password";$pool.processModel.identityType = 3;$pool | set-item;',
      :unless  => "Import-Module WebAdministration;\$iis = New-Object Microsoft.Web.Administration.ServerManager;iis:;\$pool = get-item IIS:\\AppPools\\myAppPool.example.com;if(\$pool.processModel.identityType -ne \"SpecificUser\"){exit 1;}\
if(\$pool.processModel.userName -ne username){exit 1;}if(\$pool.processModel.password -ne password){exit 1;}exit 0;",)
    }

    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - ApplicationPoolIdentity') }
  end

  describe 'when managing the iis application pool without passing parameters' do
    let(:title) { 'myAppPool.example.com' }

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; New-Item "IIS:\\AppPools\\myAppPool.example.com"',
      :onlyif  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v4.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" enable32BitAppOnWin64 false',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'false\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedPipelineMode 0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Integrated') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should_not contain_exec('App Pool Idle Timeout - myAppPool.example.com') }

    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - ApplicationPoolIdentity') }
    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - SPECIFICUSER - username') }

    it { should_not contain_exec('App Pool Max Processes - myAppPool.example.com') }

    it { should_not contain_exec('App Pool Max Queue Length - myAppPool.example.com') }

    it { should_not contain_exec(/.*App Pool Recycle Periodic - myAppPool.example.com -.*/) }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }

    it { should_not contain_exec('App Pool Logging - myAppPool.example.com') }

    it { should_not contain_exec('Clear App Pool Logging - myAppPool.example.com') }
  end

  describe 'when managing the iis application with a managed_runtime_version of v2.0' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :managed_runtime_version => 'v2.0' } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to_not raise_error }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v2.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v2.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should_not contain_exec('App Pool Idle Timeout - myAppPool.example.com') }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }
  end

  describe 'when managing the iis application with a managed_runtime_version of v4.0' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :managed_runtime_version => 'v4.0' } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to_not raise_error }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v4.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }
  end

  describe 'when managing the iis application with invalid managed_runtime_version parameter' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :managed_runtime_version => 'v9.0' } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /"v9.0" does not match [^(v2\\.0\|v4\\.0)$]"/) }
  end

  describe 'when managing the iis application with invalid managed_runtime_version parameter' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :managed_runtime_version => 'v400' } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /"v400" does not match [^(v2\\.0\|v4\\.0)$]"/) }
  end

  describe 'when managing the iis application and enable_32_bit is not a boolean value' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :enable_32_bit => 'false' } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /"false" is not a boolean\./) }
  end

  describe 'when managing the iis application with out of bounds apppool_idle_timeout_minutes parameter' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :apppool_idle_timeout_minutes => -1 } }
    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /.*validate_integer\(\)\: Expected -1 to be greater or equal to 0, got -1.*/) }
  end

  describe 'when managing the iis application with out of bounds apppool_idle_timeout_minutes parameter' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :apppool_idle_timeout_minutes => 432_01 } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /.*validate_integer\(\)\: Expected 43201 to be smaller or equal to 43200, got 43201.*/) }
  end

  describe 'when managing the iis application and identity type invalid' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :apppool_identitytype => '5' } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /identitytype must be one of \'0\', \'1\',\'2\',\'3\',\'4\',\'LocalSystem\',\'LocalService\',\'NetworkService\',\'SpecificUser\',\'ApplicationPoolIdentity\'/) }
  end

  describe 'when managing the iis application and identity SpecificUser and no username supplied' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :apppool_identitytype => '3', :apppool_userpw => 'password' } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /attempt set app pool identity to SpecificUser null or zero length \$apppool_username param/) }
  end

  describe 'when managing the iis application and identity SpecificUser and no password supplied' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :apppool_identitytype => '3', :apppool_username => 'username' } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /attempt set app pool identity to SpecificUser null or zero length \$apppool_userpw param/) }
  end

  describe 'when managing the iis application and identity SpecificUser and no username or password supplied' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :apppool_identitytype => '3' } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /attempt set app pool identity to SpecificUser null or zero length \$apppool_username param/) }
  end

  describe 'when managing the iis application and apppool_max_queue_length value too low' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :apppool_max_queue_length => 1 } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /.*validate_integer\(\)\: Expected 1 to be greater or equal to 10, got 1.*/) }
  end

  describe 'when managing the iis application and apppool_max_queue_length value too high' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :apppool_max_queue_length => 655_36 } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /.*validate_integer\(\)\: Expected 65536 to be smaller or equal to 65535, got 65536.*/) }
  end

  describe 'when managing the iis application and apppool_recycle_periodic_minutes value too low' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :apppool_recycle_periodic_minutes => -1 } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /.*validate_integer\(\)\: Expected -1 to be greater or equal to 0, got -1.*/) }
  end

  describe 'when managing the iis application and apppool_recycle_periodic_minutes value too high' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :apppool_recycle_periodic_minutes => 153_722_867_29 } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /.*validate_integer\(\)\: Expected 15372286729 to be smaller or equal to 15372286728, got 15372286729.*/) }
  end

  describe 'when managing the iis application and apppool scheduled recycling value bad' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :apppool_recycle_schedule => %w(01:00 23:59:59) } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /01:00,23:59:59 bad - time format hh:mm:ss in array/) }
  end

  describe 'when managing the iis application and apppool_recycle_logging is bad value' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :apppool_recycle_logging => %w(foo bar) } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /\[\$apppool_recycle_logging\] values must be in \['Time','Requests','Schedule','Memory','IsapiUnhealthy','OnDemand','ConfigChange','PrivateMemory'\]/) }
  end

  describe 'when managing the iis application pool and setting ensure to present' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :ensure => 'present' } }

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; New-Item "IIS:\\AppPools\\myAppPool.example.com"',
      :onlyif  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v4.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" enable32BitAppOnWin64 false',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'false\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should_not contain_exec('App Pool Idle Timeout - myAppPool.example.com') }

    it { should_not contain_exec('App Pool Max Queue Length - myAppPool.example.com') }

    it { should_not contain_exec(/.*App Pool Recycle Periodic - myAppPool.example.com -.*/) }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }

    it { should_not contain_exec('App Pool Logging - myAppPool.example.com') }

    it { should_not contain_exec('Clear App Pool Logging - myAppPool.example.com') }
  end

  describe 'when managing the iis application pool and setting ensure to installed' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :ensure => 'installed' } }

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; New-Item "IIS:\\AppPools\\myAppPool.example.com"',
      :onlyif  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedRuntimeVersion v4.0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" enable32BitAppOnWin64 false',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'false\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\myAppPool.example.com" managedPipelineMode 0',
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Integrated') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - ApplicationPoolIdentity') }

    it { should_not contain_exec('App Pool Idle Timeout - myAppPool.example.com') }

    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - ApplicationPoolIdentity') }
    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - SPECIFICUSER - username') }

    it { should_not contain_exec('App Pool Max Queue Length - myAppPool.example.com') }

    it { should_not contain_exec(/.*App Pool Recycle Periodic - myAppPool.example.com -.*/) }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }

    it { should_not contain_exec('App Pool Logging - myAppPool.example.com') }

    it { should_not contain_exec('Clear App Pool Logging - myAppPool.example.com') }
  end

  describe 'when managing the iis application pool and setting ensure to absent' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :ensure => 'absent' } }

    it { should contain_exec('Delete-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Remove-Item "IIS:\\AppPools\\myAppPool.example.com" -Recurse',
      :onlyif  => 'Import-Module WebAdministration; if(!(Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should_not contain_exec('Framework-myAppPool.example.com') }

    it { should_not contain_exec('32bit-myAppPool.example.com') }

    it { should_not contain_exec('ManagedPipelineMode-myAppPool.example.com') }

    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - ApplicationPoolIdentity') }

    it { should_not contain_exec('App Pool Idle Timeout - myAppPool.example.com') }

    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - ApplicationPoolIdentity') }
    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - SPECIFICUSER - username') }

    it { should_not contain_exec('App Pool Max Processes - myAppPool.example.com') }

    it { should_not contain_exec('App Pool Max Queue Length - myAppPool.example.com') }

    it { should_not contain_exec(/.*App Pool Recycle Periodic - myAppPool.example.com -.*/) }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }

    it { should_not contain_exec('App Pool Logging - myAppPool.example.com') }

    it { should_not contain_exec('Clear App Pool Logging - myAppPool.example.com') }
  end

  describe 'when managing the iis application pool and setting ensure to purged' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :ensure => 'purged' } }

    it { should contain_exec('Delete-myAppPool.example.com').with(
      :command => 'Import-Module WebAdministration; Remove-Item "IIS:\\AppPools\\myAppPool.example.com" -Recurse',
      :onlyif  => 'Import-Module WebAdministration; if(!(Test-Path "IIS:\\AppPools\\myAppPool.example.com")) { exit 1 } else { exit 0 }',)
    }

    it { should_not contain_exec('Framework-myAppPool.example.com') }

    it { should_not contain_exec('32bit-myAppPool.example.com') }

    it { should_not contain_exec('ManagedPipelineMode-myAppPool.example.com') }

    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - ApplicationPoolIdentity') }

    it { should_not contain_exec('App Pool Idle Timeout - myAppPool.example.com') }

    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - ApplicationPoolIdentity') }
    it { should_not contain_exec('app pool identitytype - myAppPool.example.com - SPECIFICUSER - username') }

    it { should_not contain_exec('App Pool Max Processes - myAppPool.example.com') }

    it { should_not contain_exec('App Pool Max Queue Length - myAppPool.example.com') }

    it { should_not contain_exec(/.*App Pool Recycle Periodic - myAppPool.example.com -.*/) }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }

    it { should_not contain_exec('App Pool Logging - myAppPool.example.com') }

    it { should_not contain_exec('Clear App Pool Logging - myAppPool.example.com') }
  end
end
