require 'puppet'
require 'puppet/type/iis_virtualdirectory'

describe Puppet::Type.type(:iis_virtualdirectory) do

  before :each do
    @virtualdirectory = Puppet::Type.type(:iis_virtualdirectory).new(
      :name          => 'test_virtualdirectory',
      :ensure        => 'present',
      :path          => 'C:/Temp',
      :site          => 'Default Web Site',
    )
  end

  it 'should accept a virtualdirectory name' do
    expect(@virtualdirectory[:name]).to eq('test_virtualdirectory')
  end

  it 'should accept an ensure state' do
    expect(@virtualdirectory[:ensure]).to eq(:present)
  end

  it 'should accept a path' do
    expect(@virtualdirectory[:path]).to eq('C:/Temp')
  end

  it 'should accept a site' do
    expect(@virtualdirectory[:site]).to eq('Default Web Site')
  end

end
