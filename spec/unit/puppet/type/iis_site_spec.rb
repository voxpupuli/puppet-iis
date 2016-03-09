require 'puppet'
require 'puppet/type/iis_site'

describe Puppet::Type.type(:iis_site) do

  before :each do
    @site = Puppet::Type.type(:iis_site).new(
      :name        => 'test_web',
      :ensure      => 'started',
      :path        => 'C:/Temp',
      :app_pool    => 'DefaultAppPool',
      :host_header => 'test.com',
      :protocol    => 'http',
      :ip          => '*',
      :port        => '81',
      :ssl         => false,
    )
  end

  it 'should accept a site name' do
    expect(@site[:name]).to eq('test_web')
  end

  it 'should accept an ensure state' do
    expect(@site[:ensure]).to eq(:started)
  end

  it 'should accept a path' do
    expect(@site[:path]).to eq('C:/Temp')
  end

  it 'should accept an app_pool' do
    expect(@site[:app_pool]).to eq('DefaultAppPool')
  end

  it 'should accept a host_header' do
    expect(@site[:host_header]).to eq('test.com')
  end

  it 'should accept a protocol' do
    expect(@site[:protocol]).to eq('http')
  end

  it 'should accept an ip' do
    expect(@site[:ip]).to eq('*')
  end

  it 'should accept a port' do
    expect(@site[:port]).to eq(81)
  end

  it 'should accept an ssl state' do
    expect(@site[:ssl]).to eq(:false)
  end

end
