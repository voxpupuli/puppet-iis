require 'spec_helper'

describe 'iis::manage_binding', type: :define do
  describe 'when managing an iis site binding' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) do
      {
        site_name: 'myWebSite',
        protocol: 'http',
        host_header: 'myHost.example.com',
        port: '80'
      }
    end

    it do
      should contain_exec('CreateBinding-myWebSite-port-80').with(
        command: 'Import-Module WebAdministration; New-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "*" -SslFlags "0"',
        onlyif: 'Import-Module WebAdministration; if (Get-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "*" | Where-Object {$_.bindingInformation -eq "*:80:myHost.example.com"}) { exit 1 } else { exit 0 }',
        require: 'Iis_site[myWebSite]'
)
    end
  end

  describe 'when I pass in a valid ip address' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) do
      {
        site_name: 'myWebSite',
        protocol: 'http',
        host_header: 'myHost.example.com',
        port: '80',
        ip_address: '192.168.1.5'
      }
    end

    it do
      should contain_exec('CreateBinding-myWebSite-port-80').with(
        command: 'Import-Module WebAdministration; New-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "192.168.1.5" -SslFlags "0"',
        onlyif: 'Import-Module WebAdministration; if (Get-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "192.168.1.5" | Where-Object {$_.bindingInformation -eq "192.168.1.5:80:myHost.example.com"}) { exit 1 } else { exit 0 }',
        require: 'Iis_site[myWebSite]'
)
    end
  end

  describe 'when I pass in an invalid ip address' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) do
      {
        site_name: 'myWebSite',
        protocol: 'http',
        host_header: 'myHost.example.com',
        port: '80',
        ip_address: 'this is not an address'
      }
    end

    it { expect { should contain_exec('CreateBinding-myWebSite-port-80') }.to raise_error(Puppet::Error, %r{"this is not an address" is not a valid ip address}) }
  end

  describe 'when I pass in an empty site_name' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) do
      {
        site_name: '',
        protocol: 'http',
        host_header: 'myHost.example.com',
        port: '80'
      }
    end

    it { expect { should contain_exec('CreateBinding-myWebSite-port-80') }.to raise_error(Puppet::Error, %r{site_name must not be empty}) }
  end

  describe 'when protocol is not valid' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) do
      {
        site_name: 'myWebSite',
        protocol: 'banana',
        host_header: 'myHost.example.com',
        port: '80'
      }
    end

    it { expect { should contain_exec('CreateBinding-myWebSite-port-80') }.to raise_error(Puppet::Error, %r{valid protocols 'http', 'https', 'net.tcp', 'net.pipe', 'netmsmq', 'msmq.formatname'}) }
  end

  describe 'when protocol is https' do
    let(:title) { 'myWebSite-port-443' }
    let(:params) do
      {
        site_name: 'myWebSite',
        protocol: 'https',
        port: '443',
        ip_address: '127.0.0.1'
      }
    end

    it { expect { should contain_exec('Attach-Certificate-myWebSite-port-443') }.to raise_error(Puppet::Error, %r{certificate_thumbprint required for https bindings}) }
  end

  describe 'when protocol is https and ip address *' do
    let(:title) { 'myWebSite-port-443' }
    let(:params) do
      {
        site_name: 'myWebSite',
        certificate_thumbprint: 'myCertificate',
        protocol: 'https',
        port: '443',
        ip_address: '*'
      }
    end

    it { should contain_exec('Attach-Certificate-myWebSite-port-443') }
  end

  describe 'when protocol is https and ip address 0.0.0.0' do
    let(:title) { 'myWebSite-port-443' }
    let(:params) do
      {
        site_name: 'myWebSite',
        certificate_thumbprint: 'myCertificate',
        protocol: 'https',
        port: '443',
        ip_address: '0.0.0.0'
      }
    end

    it { expect { should contain_exec('Attach-Certificate-myWebSite-port-443') }.to raise_error(Puppet::Error, %r{https bindings require a valid ip_address}) }
  end

  describe 'when protocol is https and all required parameters exist' do
    let(:title) { 'myWebSite-port-443' }
    let(:params) do
      {
        site_name: 'myWebSite',
        certificate_thumbprint: 'myCertificate',
        protocol: 'https',
        port: '443',
        ip_address: '127.0.0.1'
      }
    end

    it do
      should contain_exec('Attach-Certificate-myWebSite-port-443').with(
        command: 'C:\\temp\\create-myWebSite-port-443.ps1',
        onlyif: 'C:\\temp\\inspect-myWebSite-port-443.ps1',
        provider: 'powershell'
)
    end
  end

  describe 'when managing an iis site binding and setting ensure to present' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) do
      {
        site_name: 'myWebSite',
        protocol: 'http',
        host_header: 'myHost.example.com',
        port: '80',
        ensure: 'present'
      }
    end

    it do
      should contain_exec('CreateBinding-myWebSite-port-80').with(
        command: 'Import-Module WebAdministration; New-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "*" -SslFlags "0"',
        onlyif: 'Import-Module WebAdministration; if (Get-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "*" | Where-Object {$_.bindingInformation -eq "*:80:myHost.example.com"}) { exit 1 } else { exit 0 }'
)
    end
  end

  describe 'when managing an iis site binding and setting ensure to installed' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) do
      {
        site_name: 'myWebSite',
        protocol: 'http',
        host_header: 'myHost.example.com',
        port: '80',
        ensure: 'installed'
      }
    end

    it do
      should contain_exec('CreateBinding-myWebSite-port-80').with(
        command: 'Import-Module WebAdministration; New-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "*" -SslFlags "0"',
        onlyif: 'Import-Module WebAdministration; if (Get-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "*" | Where-Object {$_.bindingInformation -eq "*:80:myHost.example.com"}) { exit 1 } else { exit 0 }',
        require: 'Iis_site[myWebSite]'
)
    end
  end

  describe 'when managing an iis site binding and setting ensure to absent' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) do
      {
        site_name: 'myWebSite',
        protocol: 'http',
        host_header: 'myHost.example.com',
        port: '80',
        ensure: 'absent'
      }
    end

    it do
      should contain_exec('DeleteBinding-myWebSite-port-80').with(
        command: 'Import-Module WebAdministration; Remove-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "*"',
        onlyif: 'Import-Module WebAdministration; if (!(Get-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "*" | Where-Object {$_.bindingInformation -eq "*:80:myHost.example.com"})) { exit 1 } else { exit 0 }'
)
    end

    it { should_not contain_exec('Attach-Certificate-myWebSite-port-80') }
  end

  describe 'when managing an iis site binding and setting ensure to purged' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) do
      {
        site_name: 'myWebSite',
        protocol: 'http',
        host_header: 'myHost.example.com',
        port: '80',
        ensure: 'purged'
      }
    end

    it do
      should contain_exec('DeleteBinding-myWebSite-port-80').with(
        command: 'Import-Module WebAdministration; Remove-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "*"',
        onlyif: 'Import-Module WebAdministration; if (!(Get-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "*" | Where-Object {$_.bindingInformation -eq "*:80:myHost.example.com"})) { exit 1 } else { exit 0 }'
)
    end

    it { should_not contain_exec('Attach-Certificate-myWebSite-port-80') }
  end

  describe 'when managing an iis binding independently - with no managed site' do
    let(:title) { 'myWebSite-port-80' }
    let(:params) do
      {
        site_name: 'myWebSite',
        protocol: 'http',
        host_header: 'myHost.example.com',
        port: '80',
        require_site: false
      }
    end

    it do
      should contain_exec('CreateBinding-myWebSite-port-80').with(
        command: 'Import-Module WebAdministration; New-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "*" -SslFlags "0"',
        onlyif: 'Import-Module WebAdministration; if (Get-WebBinding -Name "myWebSite" -Port 80 -Protocol "http" -HostHeader "myHost.example.com" -IPAddress "*" | Where-Object {$_.bindingInformation -eq "*:80:myHost.example.com"}) { exit 1 } else { exit 0 }',
        require: nil
)
    end
  end
end
