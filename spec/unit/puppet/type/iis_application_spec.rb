require 'puppet'
require 'puppet/type/iis_application'
require File.expand_path(File.join(File.dirname(__FILE__), 'iis_stateful_shared_examples.rb'))

describe Puppet::Type.type(:iis_application) do
  let(:params) { {
      :name => 'test_application',
      :ensure => 'started',
      :path => 'C:/Temp',
      :site => 'Default Web Site',
      :app_pool => 'DefaultAppPool',
  } }

  def subject(p = params)
    Puppet::Type.type(:iis_application).new(p)
  end

  describe 'name =>' do
    it 'should accept underscore' do
      expect(subject[:name]).to eq('test_application')
    end
    it 'should accept uppercase' do
      expect(subject(params.merge({:name => 'MyApplication'}))[:name]).to eq('MyApplication')
    end
  end

  describe 'ensure =>' do
    include_context 'stateful types'
    it_behaves_like 'stateful type'
  end
  describe 'path =>' do
    it 'should accept forwardslash' do
      expect(subject[:path]).to eq('C:/Temp')
    end
    it 'should accept backslash' do
      expect(subject(params.merge({:path => 'C:\Temp'}))[:path]).to eq('C:\Temp')
    end
    it 'should reject network' do
      expect { subject(params.merge({:path => '//remote/Temp'}))[:path] }.to raise_error
    end
  end

  describe 'site =>' do
    it 'should accept default site' do
      expect(subject[:site]).to eq('Default Web Site')
    end
    it 'should accept non default site' do
      expect(subject(params.merge({:site => 'MySite'}))[:site]).to eq('MySite')
    end
  end

  it 'should accept an app_pool' do
    expect(subject[:app_pool]).to eq('DefaultAppPool')
  end

end
