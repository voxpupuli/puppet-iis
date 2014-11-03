require 'spec_helper'

powershell = "powershell.exe -ExecutionPolicy RemoteSigned"

describe 'iis::manage_app_pool', :type => :define do
  describe 'when managing the iis application pool' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :enable_32_bit => true, :managed_runtime_version => 'v4.0' } }

    it { should contain_class('iis::param::powershell') }

    it { should contain_exec('Create-myAppPool.example.com').with( {
        :command => "#{powershell} -Command \"Import-Module WebAdministration; New-Item \\\"IIS:\\AppPools\\myAppPool.example.com\\\"\"",
        :onlyif  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\AppPools\\myAppPool.example.com\\\")) { exit 1 } else {exit 0}\"",
    }) }

    it { should contain_exec('Framework-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" managedRuntimeVersion v4.0\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}

    it { should contain_exec('32bit-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" enable32BitAppOnWin64 true\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}
  end

  describe 'when managing the iis application pool without passing parameters' do
    let(:title) { 'myAppPool.example.com' }

    it { should contain_class('iis::param::powershell') }

    it { should contain_exec('Create-myAppPool.example.com').with( {
      :command => "#{powershell} -Command \"Import-Module WebAdministration; New-Item \\\"IIS:\\AppPools\\myAppPool.example.com\\\"\"",
      :onlyif  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\AppPools\\myAppPool.example.com\\\")) { exit 1 } else {exit 0}\"",
    }) }

    it { should contain_exec('Framework-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" managedRuntimeVersion v4.0\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}

    it { should contain_exec('32bit-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" enable32BitAppOnWin64 false\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'false\')) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}

    it { should contain_exec('QueueLength-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" queueLength 1000\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" queueLength).Value -eq 1000) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}

    it { should contain_exec('MaxWorkerProcesses-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" processModel.maxProcesses 1\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" processModel.maxProcesses).Value -eq 1) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}

    it { should contain_exec('RecyclingTimeInterval-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" recycling.periodicRestart.time (New-TimeSpan -Minutes 1740)\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" recycling.periodicRestart.time.Value).TotalMinutes -eq 1740) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}
  end

  describe 'when managing the iis application with a managed_runtime_version of v2.0' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :managed_runtime_version => 'v2.0' } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to_not raise_error()}
  end

  describe 'when managing the iis application with a managed_runtime_version of v4.0' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) { { :managed_runtime_version => 'v4.0' } }

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to_not raise_error()}
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
    let(:params) {{ :enable_32_bit => 'false' }}

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /"false" is not a boolean\./) }
  end

  describe 'when managing the iis application pool with a queue_length of 500' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{ :queue_length => 500 }}

    it { should contain_exec('QueueLength-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" queueLength 500\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" queueLength).Value -eq 500) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}
  end

  describe 'when managing the iis application pool with invalid queue_length parameter' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{ :queue_length => 'five hundred' }}

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /queue_length must be a positive integer/) }
  end

  describe 'when managing the iis application pool with a max_worker_processes of 5' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{ :max_worker_processes => 5 }}

    it { should contain_exec('MaxWorkerProcesses-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" processModel.maxProcesses 5\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" processModel.maxProcesses).Value -eq 5) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}
  end

  describe 'when managing the iis application pool with invalid max_worker_processes' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{ :max_worker_processes => 'five' }}

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /max_worker_processes must be a positive integer/) }
  end

  describe 'when managing the iis application pool with a recycling_time_interval of 1000' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{ :recycling_time_interval => 1000 }}

    it { should contain_exec('RecyclingTimeInterval-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" recycling.periodicRestart.time (New-TimeSpan -Minutes 1000)\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" recycling.periodicRestart.time.Value).TotalMinutes -eq 1000) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}
  end

  describe 'when managing the iis application pool with invalid recycling_time_interval' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{ :recycling_time_interval => 'one thousand' }}

    it { expect { should contain_exec('Create-myAppPool.example.com') }.to raise_error(Puppet::Error, /recycling_time_interval must be a positive integer/) }
  end

  describe 'when managing the iis application pool and setting ensure to present' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{ :ensure => 'present' }}

    it { should contain_exec('Create-myAppPool.example.com').with( {
      :command => "#{powershell} -Command \"Import-Module WebAdministration; New-Item \\\"IIS:\\AppPools\\myAppPool.example.com\\\"\"",
      :onlyif  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\AppPools\\myAppPool.example.com\\\")) { exit 1 } else {exit 0}\"",
    }) }

    it { should contain_exec('Framework-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" managedRuntimeVersion v4.0\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}

    it { should contain_exec('32bit-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" enable32BitAppOnWin64 false\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'false\')) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}
  end

  describe 'when managing the iis application pool and setting ensure to installed' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{ :ensure => 'installed' }}

    it { should contain_exec('Create-myAppPool.example.com').with( {
      :command => "#{powershell} -Command \"Import-Module WebAdministration; New-Item \\\"IIS:\\AppPools\\myAppPool.example.com\\\"\"",
      :onlyif  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\AppPools\\myAppPool.example.com\\\")) { exit 1 } else {exit 0}\"",
    }) }

    it { should contain_exec('Framework-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" managedRuntimeVersion v4.0\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}

    it { should contain_exec('32bit-myAppPool.example.com').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" enable32BitAppOnWin64 false\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \\\"IIS:\\AppPools\\myAppPool.example.com\\\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'false\')) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-myAppPool.example.com]',
    })}
  end

  describe 'when managing the iis application pool and setting ensure to absent' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{ :ensure => 'absent' }}

    it { should contain_exec('Delete-myAppPool.example.com').with( {
      :command => "#{powershell} -Command \"Import-Module WebAdministration; Remove-Item \\\"IIS:\\AppPools\\myAppPool.example.com\\\" -Recurse\"",
      :onlyif  => "#{powershell} -Command \"Import-Module WebAdministration; if(!(Test-Path \\\"IIS:\\AppPools\\myAppPool.example.com\\\")) { exit 1 } else {exit 0}\"",
    }) }

    it { should_not contain_exec('Framework-myAppPool.example.com') }

    it { should_not contain_exec('32bit-myAppPool.example.com') }
  end

  describe 'when managing the iis application pool and setting ensure to purged' do
    let(:title) { 'myAppPool.example.com' }
    let(:params) {{ :ensure => 'purged' }}

    it { should contain_exec('Delete-myAppPool.example.com').with( {
      :command => "#{powershell} -Command \"Import-Module WebAdministration; Remove-Item \\\"IIS:\\AppPools\\myAppPool.example.com\\\" -Recurse\"",
      :onlyif  => "#{powershell} -Command \"Import-Module WebAdministration; if(!(Test-Path \\\"IIS:\\AppPools\\myAppPool.example.com\\\")) { exit 1 } else {exit 0}\"",
    }) }

    it { should_not contain_exec('Framework-myAppPool.example.com') }

    it { should_not contain_exec('32bit-myAppPool.example.com') }
  end
end
