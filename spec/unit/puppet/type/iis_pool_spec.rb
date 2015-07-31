require 'puppet'
require 'puppet/type/iis_pool'
require File.expand_path(File.join(File.dirname(__FILE__), 'iis_stateful_shared_examples.rb'))

describe Puppet::Type.type(:iis_pool) do
  let(:params) { {
      :name => 'test_pool',
      :ensure => 'started',
      :enable_32_bit => true,
      :runtime => '4.0',
      :pipeline => 'Classic',
  } }

  def subject(p = params)
    Puppet::Type.type(:iis_pool).new(p)
  end

  it 'should accept a pool name' do
    expect(subject[:name]).to eq('test_pool')
  end

  describe 'ensure' do
    include_context 'stateful types'
    it_behaves_like 'stateful type'
  end

  it 'should accept an enable_32_bit state' do
    expect(subject[:enable_32_bit]).to eq(:true)
  end

  describe 'runtime =>' do
    it 'should accept a runtime' do
      expect(subject[:runtime]).to eq('v4.0')
    end
    it 'should munge runtime' do
      expect(subject(params.merge({:runtime => '4.0'}))[:runtime]).to eq('v4.0')
    end
  end

  describe 'pipeline =>' do
    ['Integrated', 'Classic'].each do |pipeline|
      it "should accept #{pipeline}" do
        param = params.merge({:pipeline => pipeline})
        expect(subject(param)[:pipeline]).to eq(pipeline)
      end
      it "should munge #{pipeline.downcase} to capital" do
        param = params.merge({:pipeline => pipeline.downcase})
        expect(subject(param)[:pipeline]).to eq(pipeline)
      end
    end
  end

end
