require 'spec_helper'

powershell = "powershell.exe -ExecutionPolicy RemoteSigned"

describe 'iis::manage_virtual_application', :type => :define do
  describe 'when I create a virtual application in IIS' do
    let(:title) { 'reviews' }
    let(:params) {{
        :site_name => 'www.internalapi.co.uk',
        :site_path => 'C:\inetpub\wwwroot\test',
        :app_pool => 'www.internalapi.co.uk',
    }}

    it { should include_class('iis::param::powershell') }

    it { should contain_exec('CreateAppPool-www.internalapi.co.uk').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; New-WebApplication -Name reviews -Site www.internalapi.co.uk -PhysicalPath C:\\inetpub\\wwwroot\\test -ApplicationPool www.internalapi.co.uk\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\www.internalapi.co.uk\\reviews\")) { exit 1 } else { exit 0 }\"",
      #'require' => 'iis::manage_site[www.internalapi.co.uk]',
    })}
  end
end