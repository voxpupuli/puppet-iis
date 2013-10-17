require 'spec_helper'

powershell = 'powershell.exe -ExecutionPolicy RemoteSigned'

describe 'iis::manage_virtual_application', :type => :define do
  describe 'when I create a virtual application in IIS using default params' do
    let(:title) { 'mySite' }
    let(:params) {{
        :site_name => 'myWebSite',
        :site_path => 'C:\inetpub\wwwroot\myHost',
        :app_pool => 'myAppPool.example.com',
    }}

    it { should include_class('iis::param::powershell') }

    it { should contain_exec('CreateVirtualApplication-myWebSite-mySite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; New-WebApplication -Name mySite -Site myWebSite -PhysicalPath C:\\inetpub\\wwwroot\\myHost -ApplicationPool myAppPool.example.com\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\myWebSite\\mySite\")) { exit 1 } else { exit 0 }\"",
    })}
  end

  describe 'when I create a virtual application in IIS and set ensure to present' do
    let(:title) { 'mySite' }
    let(:params) {{
        :site_name => 'myWebSite',
        :site_path => 'C:\inetpub\wwwroot\myHost',
        :app_pool => 'myAppPool.example.com',
        :ensure => 'present',
    }}

    it { should contain_exec('CreateVirtualApplication-myWebSite-mySite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; New-WebApplication -Name mySite -Site myWebSite -PhysicalPath C:\\inetpub\\wwwroot\\myHost -ApplicationPool myAppPool.example.com\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\myWebSite\\mySite\")) { exit 1 } else { exit 0 }\"",
    })}
  end

  describe 'when I create a virtual application in IIS and set ensure to installed' do
    let(:title) { 'mySite' }
    let(:params) {{
        :site_name => 'myWebSite',
        :site_path => 'C:\inetpub\wwwroot\myHost',
        :app_pool => 'myAppPool.example.com',
        :ensure => 'installed',
    }}

    it { should contain_exec('CreateVirtualApplication-myWebSite-mySite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; New-WebApplication -Name mySite -Site myWebSite -PhysicalPath C:\\inetpub\\wwwroot\\myHost -ApplicationPool myAppPool.example.com\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\myWebSite\\mySite\")) { exit 1 } else { exit 0 }\"",
    })}
  end

  describe 'when I create a virtual application in IIS and set ensure to purged' do
    let(:title) { 'mySite' }
    let(:params) {{
        :site_name => 'myWebSite',
        :site_path => 'C:\inetpub\wwwroot\myHost',
        :app_pool => 'myAppPool.example.com',
        :ensure => 'purged',
    }}

    it { should contain_exec('DeleteVirtualApplication-myWebSite-mySite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Remove-WebApplication -Name mySite -Site myWebSite -Confirm:$false\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if(!(Test-Path \"IIS:\\Sites\\myWebSite\\mySite\")) { exit 1 } else { exit 0 }\"",
    })}
  end

  describe 'when I create a virtual application in IIS and set ensure to absent' do
    let(:title) { 'mySite' }
    let(:params) {{
        :site_name => 'myWebSite',
        :site_path => 'C:\inetpub\wwwroot\myHost',
        :app_pool => 'myAppPool.example.com',
        :ensure => 'absent',
    }}

    it { should contain_exec('DeleteVirtualApplication-myWebSite-mySite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Remove-WebApplication -Name mySite -Site myWebSite -Confirm:$false\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if(!(Test-Path \"IIS:\\Sites\\myWebSite\\mySite\")) { exit 1 } else { exit 0 }\"",
    })}
  end
end