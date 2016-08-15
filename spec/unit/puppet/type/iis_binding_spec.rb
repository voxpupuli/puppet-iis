require 'puppet'
require 'puppet/type/iis_binding'

describe Puppet::Type.type(:iis_binding) do
  let(:binding) do
    Puppet::Type.type(:iis_binding).new(
      name: '127.0.0.1:80:mywebsite.com',
      ensure: 'present',
      protocol: 'http',
      port: '80',
      ip_address: '127.0.0.1',
      host_header: 'mywebsite.com',
      site_name: 'Default Web Site'
    )
  end

  it 'accepts a binding name' do
    expect(binding[:name]).to eq('127.0.0.1:80:mywebsite.com')
  end

  it 'accepts a site name' do
    expect(binding[:site_name]).to eq('Default Web Site')
  end

  it 'accepts an ensure state' do
    expect(binding[:ensure]).to eq(:present)
  end

  it 'accepts a protocol' do
    expect(binding[:protocol]).to eq('http')
  end

  it 'accepts a port' do
    expect(binding[:port]).to eq('80')
  end

  it 'accepts a host header' do
    expect(binding[:host_header]).to eq('mywebsite.com')
  end

  it 'accepts an ip address' do
    expect(binding[:ip_address]).to eq('127.0.0.1')
  end
end
