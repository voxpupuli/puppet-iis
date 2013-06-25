require 'spec_helper'

powershell = 'powershell.exe -ExecutionPolicy RemoteSigned'

describe 'iis::manage_binding', :type => :define do
  describe 'when managing an iis site binding' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) { {
        :site_name   => 'myWebSite',
        :protocol    => 'http',
        :host_header => 'myHost.example.com',
        :port        => '80',
    } }

    it { should include_class('iis::param::powershell') }

    it { should contain_exec('ManageBinding-myWebSite-port-80').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; New-WebBinding -Name \\\"myWebSite\\\" -Port 80 -Protocol \\\"http\\\" -HostHeader \\\"myHost.example.com\\\" -IPAddress \\\"*\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if (Get-WebBinding -Name \\\"myWebSite\\\" -Port 80 -Protocol \\\"http\\\" -HostHeader \\\"myHost.example.com\\\" -IPAddress \\\"*\\\" | Where-Object {\$_.bindingInformation -eq \\\"*:80:myHost.example.com\\\"}) { exit 1 } else { exit 0 }\"",
    })}
  end

  describe 'when I pass in a valid ip address' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) { {
        :site_name   => 'myWebSite',
        :protocol    => 'http',
        :host_header => 'myHost.example.com',
        :port        => '80',
        :ip_address  => '192.168.1.5',
    } }

    it { should contain_exec('ManageBinding-myWebSite-port-80').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; New-WebBinding -Name \\\"myWebSite\\\" -Port 80 -Protocol \\\"http\\\" -HostHeader \\\"myHost.example.com\\\" -IPAddress \\\"192.168.1.5\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if (Get-WebBinding -Name \\\"myWebSite\\\" -Port 80 -Protocol \\\"http\\\" -HostHeader \\\"myHost.example.com\\\" -IPAddress \\\"192.168.1.5\\\" | Where-Object {\$_.bindingInformation -eq \\\"192.168.1.5:80:myHost.example.com\\\"}) { exit 1 } else { exit 0 }\"",
    })}
  end

  describe 'when I pass in an invalid ip address' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) { {
        :site_name   => 'myWebSite',
        :protocol    => 'http',
        :host_header => 'myHost.example.com',
        :port        => '80',
        :ip_address  => 'this is not an address',
    } }

    it { expect { should contain_exec('ManageBinding-myWebSite-port-80') }.to raise_error(Puppet::Error, /"this is not an address" is not a valid ip address/) }
  end

  describe 'when I pass in an empty site_name' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) { {
        :site_name   => '',
        :protocol    => 'http',
        :host_header => 'myHost.example.com',
        :port        => '80',
    } }

    it { expect { should contain_exec('ManageBinding-myWebSite-port-80') }.to raise_error(Puppet::Error, /site_name must not be empty/) }
  end

  describe 'when protocol is not valid' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) { {
        :site_name   => 'myWebSite',
        :protocol    => 'banana',
        :host_header => 'myHost.example.com',
        :port        => '80',
    } }

    it { expect { should contain_exec('ManageBinding-myWebSite-port-80') }.to raise_error(Puppet::Error, /valid protocols 'http', 'https', 'net.tcp', 'net.pipe', 'netmsmq', 'msmq.formatname'/) }
  end
end