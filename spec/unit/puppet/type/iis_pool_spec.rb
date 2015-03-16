require 'puppet'
require 'puppet/type/iis_pool'

describe Puppet::Type.type(:iis_pool) do

  before :each do
    @pool = Puppet::Type.type(:iis_pool).new(
      :name          => 'test_pool',
      :ensure        => 'started',
      :enable_32_bit => true,
      :runtime       => '4.0',
      :pipeline      => 'Classic',
    )
  end

  it 'should accept a pool name' do
    expect(@pool[:name]).to eq('test_pool')
  end

  it 'should accept an ensure state' do
    expect(@pool[:ensure]).to eq(:started)
  end

  it 'should accept an enable_32_bit state' do
    expect(@pool[:enable_32_bit]).to eq(:true)
  end

  it 'should accept a runtime' do
    expect(@pool[:runtime]).to eq('v4.0')
  end

  it 'should accept a pipeline' do
    expect(@pool[:pipeline]).to eq('Classic')
  end

end
