require 'spec_helper'

describe 'iis::manage_site_state', :type => :define do
  describe 'when ensuring an iis site is running' do
    let(:title) { 'StartSite-DefaultWebsite' }
    let(:params) { {
      :site_name => 'DefaultWebsite',
      :ensure    => 'running'
    } }

    it { should contain_exec('StartSite-DefaultWebsite').with(
      'command' => 'Import-Module WebAdministration; Start-Website -Name "DefaultWebsite"',
      'onlyif'  => 'Import-Module WebAdministration; if((Get-Item "IIS:\\Sites\\DefaultWebsite").state -eq "started") { exit 1 }',)
    }
  end

  describe 'when ensuring an iis site is stopped' do
    let(:title) { 'StopSite-DefaultWebsite' }
    let(:params) { {
      :site_name => 'DefaultWebsite',
      :ensure    => 'stopped'
    } }

    it { should contain_exec('StopSite-DefaultWebsite').with(
      'command' => 'Import-Module WebAdministration; Stop-Website -Name "DefaultWebsite"',
      'onlyif'  => 'Import-Module WebAdministration; if((Get-Item "IIS:\\Sites\\DefaultWebsite").state -eq "stopped") { exit 1 }',)
    }
  end
end
