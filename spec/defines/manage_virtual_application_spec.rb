require 'spec_helper'

describe 'iis::manage_virtual_application', :type => :define do
  describe 'when I create a virtual application in IIS using default params' do
    let(:title) { 'mySite' }
    let(:params) {{
      :site_name => 'myWebSite',
      :site_path => 'C:\inetpub\wwwroot\myHost',
      :app_pool  => 'myAppPool.example.com',
    }}

    it { should contain_exec('CreateVirtualApplication-myWebSite-mySite').with(
      'command' => "Import-Module WebAdministration; New-WebApplication -Name mySite -Site \"myWebSite\" -PhysicalPath \"C:\\inetpub\\wwwroot\\myHost\" -ApplicationPool \"myAppPool.example.com\"",
      'onlyif'  => "Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\myWebSite\") -and (Get-ChildItem \"IIS:\\Sites\\myWebSite\" | where {\$_.Schema.Name -eq 'Application' -and \$_.Name -eq 'mySite'})) { exit 1 } else { exit 0 }",)
    }
  end

  describe 'when I create a virtual application in IIS and set ensure to present' do
    let(:title) { 'mySite' }
    let(:params) {{
      :site_name => 'myWebSite',
      :site_path => 'C:\inetpub\wwwroot\myHost',
      :app_pool  => 'myAppPool.example.com',
      :ensure    => 'present',
    }}

    it { should contain_exec('CreateVirtualApplication-myWebSite-mySite').with(
      'command' => "Import-Module WebAdministration; New-WebApplication -Name mySite -Site \"myWebSite\" -PhysicalPath \"C:\\inetpub\\wwwroot\\myHost\" -ApplicationPool \"myAppPool.example.com\"",
      'onlyif'  => "Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\myWebSite\") -and (Get-ChildItem \"IIS:\\Sites\\myWebSite\" | where {\$_.Schema.Name -eq 'Application' -and \$_.Name -eq 'mySite'})) { exit 1 } else { exit 0 }",)
    }
  end

  describe 'when I create a virtual application in IIS on a site with spaces in the name' do
    let(:title) { 'myVirtualApp' }
    let(:params) {{
      :site_name => 'My Web Site',
      :site_path => 'C:\inetpub\wwwroot\myHost',
      :app_pool => 'myAppPool.example.com',
      :ensure   => 'present',
    }}

    it { should contain_exec('CreateVirtualApplication-My Web Site-myVirtualApp').with(
      'command' => "Import-Module WebAdministration; New-WebApplication -Name myVirtualApp -Site \"My Web Site\" -PhysicalPath \"C:\\inetpub\\wwwroot\\myHost\" -ApplicationPool \"myAppPool.example.com\"",
      'onlyif'  => "Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\My Web Site\") -and (Get-ChildItem \"IIS:\\Sites\\My Web Site\" | where {\$_.Schema.Name -eq 'Application' -and \$_.Name -eq 'myVirtualApp'})) { exit 1 } else { exit 0 }",)
    }
  end

  describe 'when I create a virtual application in IIS and set ensure to installed' do
    let(:title) { 'mySite' }
    let(:params) {{
      :site_name => 'myWebSite',
      :site_path => 'C:\inetpub\wwwroot\myHost',
      :app_pool => 'myAppPool.example.com',
      :ensure   => 'installed',
    }}

    it { should contain_exec('CreateVirtualApplication-myWebSite-mySite').with(
      'command' => "Import-Module WebAdministration; New-WebApplication -Name mySite -Site \"myWebSite\" -PhysicalPath \"C:\\inetpub\\wwwroot\\myHost\" -ApplicationPool \"myAppPool.example.com\"",
      'onlyif'  => "Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\myWebSite\") -and (Get-ChildItem \"IIS:\\Sites\\myWebSite\" | where {\$_.Schema.Name -eq 'Application' -and \$_.Name -eq 'mySite'})) { exit 1 } else { exit 0 }",)
    }
  end

  describe 'when I create a virtual application in IIS and set ensure to purged' do
    let(:title) { 'mySite' }
    let(:params) {{
      :site_name => 'myWebSite',
      :site_path => 'C:\inetpub\wwwroot\myHost',
      :app_pool  => 'myAppPool.example.com',
      :ensure    => 'purged',
    }}

    it { should contain_exec('DeleteVirtualApplication-myWebSite-mySite').with(
      'command' => "Import-Module WebAdministration; Remove-WebApplication -Name mySite -Site \"myWebSite\"",
      'onlyif'  => "Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\myWebSite\") -and (Get-ChildItem \"IIS:\\Sites\\myWebSite\" | where {\$_.Schema.Name -eq 'Application' -and \$_.Name -eq 'mySite'})) { exit 0 } else { exit 1 }",)
    }
  end

  describe 'when I create a virtual application in IIS and set ensure to absent' do
    let(:title) { 'mySite' }
    let(:params) {{
      :site_name => 'myWebSite',
      :site_path => 'C:\inetpub\wwwroot\myHost',
      :app_pool => 'myAppPool.example.com',
      :ensure   => 'absent',
    }}

    it { should contain_exec('DeleteVirtualApplication-myWebSite-mySite').with(
      'command' => "Import-Module WebAdministration; Remove-WebApplication -Name mySite -Site \"myWebSite\"",
      'onlyif'  => "Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\myWebSite\") -and (Get-ChildItem \"IIS:\\Sites\\myWebSite\" | where {\$_.Schema.Name -eq 'Application' -and \$_.Name -eq 'mySite'})) { exit 0 } else { exit 1 }",)
    }
  end
end
