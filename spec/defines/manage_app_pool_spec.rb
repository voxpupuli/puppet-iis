require 'spec_helper'

describe 'iis::manage_app_pool', :type => :define do
  describe 'when managing the iis application pool' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{
      :enable_32_bit           => true,
      :managed_runtime_version => 'v4.0',
      :managed_pipeline_mode   => 'Integrated',
      :apppool_recycle_schedule => %w(01:00:00 23:59:59)
    }}

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; New-Item \"IIS:\\AppPools\\myAppPool.example.com\"",
      :onlyif  => "Import-Module WebAdministration; if((Test-Path \"IIS:\\AppPools\\myAppPool.example.com\")) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion v4.0",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64 true",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode 0",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Integrated') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec("App Pool Recycle Schedule - myAppPool.example.com - \"01:00:00\",\"23:59:59\"").with(
      :command => "[string]\$ApplicationPoolName = \"myAppPool.example.com\";[string[]]\$RestartTimes = @(\"01:00:00\",\"23:59:59\");Import-Module WebAdministration;Clear-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule;\
foreach (\$restartTime in \$RestartTimes){Write-Output \"Adding recycle at \$restartTime\";New-ItemProperty -Path \"IIS:\\AppPools\\\$ApplicationPoolName\" -Name Recycling.periodicRestart.schedule -Value @{value=\$restartTime};}",
      :unless  => "[string]\$ApplicationPoolName = \"myAppPool.example.com\";[string[]]\$RestartTimes = @(\"01:00:00\",\"23:59:59\");Import-Module WebAdministration;[Collections.Generic.List[String]]\$collectionAsList = @();\
for(\$i=0; \$i -lt (Get-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule.collection).Count; \$i++){\$collectionAsList.Add((Get-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule.collection)[\$i].value.ToString());}\
if(\$collectionAsList.Count -ne \$RestartTimes.Length){exit 1;}foreach (\$restartTime in \$RestartTimes) {if(!\$collectionAsList.Contains(\$restartTime)){exit 1;}}exit 0;",)
    }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }
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
      :command => "Import-Module WebAdministration; New-Item \"IIS:\\AppPools\\myAppPool.example.com\"",
      :onlyif  => "Import-Module WebAdministration; if((Test-Path \"IIS:\\AppPools\\myAppPool.example.com\")) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion v4.0",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64 true",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode 0",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Integrated') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('CLEAR App Pool Recycle Schedule - myAppPool.example.com').with(
      :command => "[string]\$ApplicationPoolName = \"myAppPool.example.com\";Import-Module WebAdministration;Write-Output \"removing scheduled recycles\";Clear-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule;",
      :unless  => "[string]\$ApplicationPoolName = \"myAppPool.example.com\";Import-Module WebAdministration;if((Get-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule.collection).Length -eq \$null){exit 0;}else{exit 1;}",)
    }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }
  end

  describe 'when managing the iis application pool - v2.0 Classic' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{
      :enable_32_bit           => true,
      :managed_runtime_version => 'v2.0',
      :managed_pipeline_mode   => 'Classic',
      :apppool_recycle_schedule => %w(01:00:00 23:59:59)
    }}

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; New-Item \"IIS:\\AppPools\\myAppPool.example.com\"",
      :onlyif  => "Import-Module WebAdministration; if((Test-Path \"IIS:\\AppPools\\myAppPool.example.com\")) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion v2.0",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v2.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64 true",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode 1",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Classic') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec("App Pool Recycle Schedule - myAppPool.example.com - \"01:00:00\",\"23:59:59\"").with(
      :command => "[string]\$ApplicationPoolName = \"myAppPool.example.com\";[string[]]\$RestartTimes = @(\"01:00:00\",\"23:59:59\");Import-Module WebAdministration;Clear-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule;\
foreach (\$restartTime in \$RestartTimes){Write-Output \"Adding recycle at \$restartTime\";New-ItemProperty -Path \"IIS:\\AppPools\\\$ApplicationPoolName\" -Name Recycling.periodicRestart.schedule -Value @{value=\$restartTime};}",
      :unless  => "[string]\$ApplicationPoolName = \"myAppPool.example.com\";[string[]]\$RestartTimes = @(\"01:00:00\",\"23:59:59\");Import-Module WebAdministration;[Collections.Generic.List[String]]\$collectionAsList = @();\
for(\$i=0; \$i -lt (Get-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule.collection).Count; \$i++){\$collectionAsList.Add((Get-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule.collection)[\$i].value.ToString());}\
if(\$collectionAsList.Count -ne \$RestartTimes.Length){exit 1;}foreach (\$restartTime in \$RestartTimes) {if(!\$collectionAsList.Contains(\$restartTime)){exit 1;}}exit 0;",)
    }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }
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
      :command => "Import-Module WebAdministration; New-Item \"IIS:\\AppPools\\myAppPool.example.com\"",
      :onlyif  => "Import-Module WebAdministration; if((Test-Path \"IIS:\\AppPools\\myAppPool.example.com\")) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion v2.0",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v2.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64 true",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode 1",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Classic') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('CLEAR App Pool Recycle Schedule - myAppPool.example.com').with(
      :command => "[string]\$ApplicationPoolName = \"myAppPool.example.com\";Import-Module WebAdministration;Write-Output \"removing scheduled recycles\";Clear-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule;",
      :unless  => "[string]\$ApplicationPoolName = \"myAppPool.example.com\";Import-Module WebAdministration;if((Get-ItemProperty IIS:\\AppPools\\\$ApplicationPoolName -Name Recycling.periodicRestart.schedule.collection).Length -eq \$null){exit 0;}else{exit 1;}",)
    }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }
  end

  describe 'when managing the iis application pool without passing parameters' do
    let(:title) { 'myAppPool.example.com' }

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; New-Item \"IIS:\\AppPools\\myAppPool.example.com\"",
      :onlyif  => "Import-Module WebAdministration; if((Test-Path \"IIS:\\AppPools\\myAppPool.example.com\")) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion v4.0",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64 false",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'false\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode 0",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Integrated') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }
  end

  describe 'when managing the iis application with a managed_runtime_version of v2.0' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :managed_runtime_version => 'v2.0' } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to_not raise_error }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion v2.0",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v2.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }
  end

  describe 'when managing the iis application with a managed_runtime_version of v4.0' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :managed_runtime_version => 'v4.0' } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to_not raise_error }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion v4.0",
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

  describe 'when managing the iis application and apppool scheduled recycling value bad' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :apppool_recycle_schedule => %w(01:00 23:59:59) } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /01:00,23:59:59 bad - time format hh:mm:ss in array/) }
  end

  describe 'when managing the iis application pool and setting ensure to present' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :ensure => 'present' } }

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; New-Item \"IIS:\\AppPools\\myAppPool.example.com\"",
      :onlyif  => "Import-Module WebAdministration; if((Test-Path \"IIS:\\AppPools\\myAppPool.example.com\")) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion v4.0",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64 false",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'false\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }
  end

  describe 'when managing the iis application pool and setting ensure to installed' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :ensure => 'installed' } }

    it { should contain_exec('Create-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; New-Item \"IIS:\\AppPools\\myAppPool.example.com\"",
      :onlyif  => "Import-Module WebAdministration; if((Test-Path \"IIS:\\AppPools\\myAppPool.example.com\")) { exit 1 } else { exit 0 }",)
    }

    it { should contain_exec('Framework-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion v4.0",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('32bit-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64 false",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'false\')) { exit 1 } else { exit 0 }",
      :require => 'Exec[Create-myAppPool.example.com]',)
    }

    it { should contain_exec('ManagedPipelineMode-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode 0",
      :onlyif  => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\myAppPool.example.com\" managedPipelineMode).CompareTo('Integrated') -eq 0) { exit 1 } else { exit 0 }",)
    }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }
  end

  describe 'when managing the iis application pool and setting ensure to absent' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :ensure => 'absent' } }

    it { should contain_exec('Delete-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Remove-Item \"IIS:\\AppPools\\myAppPool.example.com\" -Recurse",
      :onlyif  => "Import-Module WebAdministration; if(!(Test-Path \"IIS:\\AppPools\\myAppPool.example.com\")) { exit 1 } else { exit 0 }",)
    }

    it { should_not contain_exec('Framework-myAppPool.example.com') }

    it { should_not contain_exec('32bit-myAppPool.example.com') }

    it { should_not contain_exec('ManagedPipelineMode-myAppPool.example.com') }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }
  end

  describe 'when managing the iis application pool and setting ensure to purged' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :ensure => 'purged' } }

    it { should contain_exec('Delete-myAppPool.example.com').with(
      :command => "Import-Module WebAdministration; Remove-Item \"IIS:\\AppPools\\myAppPool.example.com\" -Recurse",
      :onlyif  => "Import-Module WebAdministration; if(!(Test-Path \"IIS:\\AppPools\\myAppPool.example.com\")) { exit 1 } else { exit 0 }",)
    }

    it { should_not contain_exec('Framework-myAppPool.example.com') }

    it { should_not contain_exec('32bit-myAppPool.example.com') }

    it { should_not contain_exec('ManagedPipelineMode-myAppPool.example.com') }

    it { should_not contain_exec(/App Pool Recycle Schedule.*/) }

    it { should_not contain_exec(/CLEAR App Pool Recycle Schedule.*/) }
  end
end
