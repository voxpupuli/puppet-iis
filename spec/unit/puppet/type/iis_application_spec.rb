require 'puppet'
require 'puppet/type/iis_application'

describe Puppet::Type.type(:iis_application) do

  before :each do
    @application = Puppet::Type.type(:iis_application).new(
      :name          => 'test_application',
      :ensure        => 'started',
      :path          => 'C:/Temp',
      :site          => 'Default Web Site',
      :app_pool      => 'DefaultAppPool',
    )
  end

  it 'should accept a application name' do
    expect(@application[:name]).to eq('test_application')
  end

  it 'should accept an ensure state' do
    expect(@application[:ensure]).to eq(:started)
  end

  it 'should accept a path' do
    expect(@application[:path]).to eq('C:/Temp')
  end

  it 'should accept a site' do
    expect(@application[:site]).to eq('Default Web Site')
  end

  it 'should accept an app_pool' do
    expect(@application[:app_pool]).to eq('DefaultAppPool')
  end

end
