require 'spec_helper'

powershell = "powershell.exe -ExecutionPolicy RemoteSigned"

describe 'iis::manage_site', :type => :define do
  describe 'when managing the iis site' do
    let(:title) { 'www.internalapi.co.uk' }
    let(:params) { {
        :app_pool    => 'www.internalapi.co.uk',
        :host_header => 'www.internalapi.co.uk',
        :site_path   => 'C:\inetpub\wwwroot\test',
    } }

    it { should include_class('iis::param::powershell') }

    it { should contain_exec('CreateSite-www.internalapi.co.uk').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; New-WebSite -Name www.internalapi.co.uk -Port 80 -IP * -HostHeader www.internalapi.co.uk -PhysicalPath C:\\inetpub\\wwwroot\\test -ApplicationPool www.internalapi.co.uk \"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\www.internalapi.co.uk\")) { exit 1 } else { exit 0 }\"",
      #'require' => 'File[ iis::manage_app_pool[www.internalapi.co.uk]',
    })}
  end

  describe 'when managing the iis site passing in all parameters' do
    let(:title) { 'www.internalapi.co.uk' }
    let(:params) {{
        :app_pool    => 'internalapi_application_pool',
        :host_header => 'internalapi_header',
        :site_path   => 'C:\inetput\internalapi\path',
        :port        => '1080',
        :ip_address  => '127.0.0.1',
    }}

    it { should include_class('iis::param::powershell') }

    it { should contain_exec('CreateSite-www.internalapi.co.uk').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; New-WebSite -Name www.internalapi.co.uk -Port 1080 -IP 127.0.0.1 -HostHeader internalapi_header -PhysicalPath C:\\inetput\\internalapi\\path -ApplicationPool internalapi_application_pool \"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \"IIS:\\Sites\\www.internalapi.co.uk\")) { exit 1 } else { exit 0 }\"",
      #'require' => 'Iis::manage_app_pool[www.internalapi.co.uk]',
    })}
  end
end