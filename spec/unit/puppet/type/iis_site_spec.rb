require 'puppet'
require 'puppet/type/iis_site'

describe Puppet::Type.type(:iis_site) do
  let(:site) do
    Puppet::Type.type(:iis_site).new(
      name: 'test_web',
      ensure: 'started',
      path: 'C:/Temp',
      app_pool: 'DefaultAppPool',
      host_header: 'test.com',
      protocol: 'http',
      ip: '*',
      port: '81',
      ssl: false
    )
  end

  it 'accepts a site name' do
    expect(site[:name]).to eq('test_web')
  end

  it 'accepts an ensure state' do
    expect(site[:ensure]).to eq(:started)
  end

  it 'accepts a path' do
    expect(site[:path]).to eq('C:/Temp')
  end

  it 'accepts an app_pool' do
    expect(site[:app_pool]).to eq('DefaultAppPool')
  end

  it 'accepts a host_header' do
    expect(site[:host_header]).to eq('test.com')
  end

  it 'accepts a protocol' do
    expect(site[:protocol]).to eq('http')
  end

  it 'accepts an ip' do
    expect(site[:ip]).to eq('*')
  end

  it 'accepts a port' do
    expect(site[:port]).to eq(81)
  end

  it 'accepts an ssl state' do
    expect(site[:ssl]).to eq(:false)
  end
end
