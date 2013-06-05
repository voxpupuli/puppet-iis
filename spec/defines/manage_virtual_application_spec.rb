require 'spec_helper'

powershell = "powershell.exe -ExecutionPolicy RemoteSigned"

describe 'iis::manage_virtual_application', :type => :define do
  describe 'when I create a virtual application in IIS' do
    let(:title) { 'reviews' }
    let(:params) {{
        :site_name => 'myWebSite',
        :site_path => 'C:\inetpub\wwwroot\myHost',
        :app_pool => 'myAppPool.example.com',
    }}

    it { should include_class('iis::param::powershell') }

    it { should contain_exec('CreateVirtualApplication-myWebSite-reviews').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; New-WebApplication -Name reviews -Site myWebSite -PhysicalPath C:\\inetpub\\wwwroot\\myHost -ApplicationPool myAppPool.example.com\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\myWebSite\\reviews\")) { exit 1 } else { exit 0 }\"",
      'require' => 'Iis::Manage_site[myWebSite]',
    })}
  end
end