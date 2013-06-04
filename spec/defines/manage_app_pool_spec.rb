require 'spec_helper'

powershell = "powershell.exe -ExecutionPolicy RemoteSigned"

describe 'iis::manage_app_pool', :type => :define do
  describe 'when managing the iis application pool' do
    let(:title) { 'www.internalapi.co.uk' }
    let(:params) { { :enable_32_bit => true, :managed_runtime_version => 'v4.0' } }

    it { should include_class('iis::param::powershell') }

    it { should contain_exec('Create-www.internalapi.co.uk').with( {
        :command => "#{powershell} -Command \"Import-Module WebAdministration; New-Item \"IIS:\\AppPools\\www.internalapi.co.uk\"\"",
        :onlyif  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \"IIS:\\AppPools\\www.internalapi.co.uk\")) { exit 1 } else {exit 0}\"",
    }) }

    it { should contain_exec('Framework-www.internalapi.co.uk').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\www.internalapi.co.uk\" managedRuntimeVersion v4.0\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\www.internalapi.co.uk\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-www.internalapi.co.uk]',
    })}

    it { should contain_exec('32bit-www.internalapi.co.uk').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\www.internalapi.co.uk\" enable32BitAppOnWin64 true\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\www.internalapi.co.uk\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'true\')) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Framework-www.internalapi.co.uk]',
    })}
  end

  describe 'when managing the iis application pool without passing parameters' do
    let(:title) { 'www.internalapi.co.uk' }

    it { should include_class('iis::param::powershell') }

    it { should contain_exec('Create-www.internalapi.co.uk').with( {
      :command => "#{powershell} -Command \"Import-Module WebAdministration; New-Item \"IIS:\\AppPools\\www.internalapi.co.uk\"\"",
      :onlyif  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \"IIS:\\AppPools\\www.internalapi.co.uk\")) { exit 1 } else {exit 0}\"",
    }) }

    it { should contain_exec('Framework-www.internalapi.co.uk').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\www.internalapi.co.uk\" managedRuntimeVersion v4.0\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\www.internalapi.co.uk\" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Create-www.internalapi.co.uk]',
    })}

    it { should contain_exec('32bit-www.internalapi.co.uk').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \"IIS:\\AppPools\\www.internalapi.co.uk\" enable32BitAppOnWin64 false\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\www.internalapi.co.uk\" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'false\')) { exit 1 } else { exit 0 }\"",
      'require' => 'Exec[Framework-www.internalapi.co.uk]',
    })}
  end

  describe 'when managing the iis application with invalid managed_runtime_version parameter' do
    let(:title) { 'www.internalapi.co.uk' }
    let(:params) { { :managed_runtime_version => 'v9.0' } }

    it { expect { should contain_exec('Create-www.internalapi.co.uk') }.to raise_error(Puppet::Error, /"v9.0" does not match \["\^\(v2\.0\|v4\.0\)\$"\]/) }
  end

  describe 'when managing the iis application and enable_32_bit is not a boolean value' do
    let(:title) { 'www.internalapi.co.uk' }
    let(:params) {{ :enable_32_bit => 'false' }}

    it { expect { should contain_exec('Create-www.internalapi.co.uk') }.to raise_error(Puppet::Error, /"false" is not a boolean\./) }
  end
end
