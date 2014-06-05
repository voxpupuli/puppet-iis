require 'spec_helper'

powershell = 'powershell.exe -ExecutionPolicy RemoteSigned'

describe 'iis::manage_site_state', :type => :define do
  describe 'when ensuring an iis site is running' do
    let(:title) { 'StartSite-DefaultWebsite' }
    let(:params) { {
        :site_name => 'DefaultWebsite',
        :ensure    => 'running',
    } }

    it { should contain_class('iis::param::powershell') }

    it { should contain_exec('StartSite-DefaultWebsite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Start-Website -Name \\\"DefaultWebsite\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-Item \\\"IIS:\\Sites\\DefaultWebsite\\\").state -eq \\\"started\\\") { exit 1 }\"",
    })}
  end

  describe 'when ensuring an iis site is true' do
    let(:title) { 'StartSite-DefaultWebsite' }
    let(:params) { {
        :site_name => 'DefaultWebsite',
        :ensure    => 'true',
    } }

    it { should contain_class('iis::param::powershell') }

    it { should contain_exec('StartSite-DefaultWebsite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Start-Website -Name \\\"DefaultWebsite\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-Item \\\"IIS:\\Sites\\DefaultWebsite\\\").state -eq \\\"started\\\") { exit 1 }\"",
    })}
  end

  describe 'when ensuring an iis site is stopped' do
    let(:title) { 'StopSite-DefaultWebsite' }
    let(:params) { {
        :site_name => 'DefaultWebsite',
        :ensure    => 'stopped',
    } }

    it { should contain_class('iis::param::powershell') }

    it { should contain_exec('StopSite-DefaultWebsite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Stop-Website -Name \\\"DefaultWebsite\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-Item \\\"IIS:\\Sites\\DefaultWebsite\\\").state -eq \\\"stopped\\\") { exit 1 }\"",
    })}
  end

  describe 'when ensuring an iis site is false' do
    let(:title) { 'StopSite-DefaultWebsite' }
    let(:params) { {
        :site_name => 'DefaultWebsite',
        :ensure    => 'false',
    } }

    it { should contain_class('iis::param::powershell') }

    it { should contain_exec('StopSite-DefaultWebsite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Stop-Website -Name \\\"DefaultWebsite\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Get-Item \\\"IIS:\\Sites\\DefaultWebsite\\\").state -eq \\\"stopped\\\") { exit 1 }\"",
    })}
  end
end
