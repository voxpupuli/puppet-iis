require 'puppet'
require 'puppet/type/iis_pool'
require File.expand_path(File.join(File.dirname(__FILE__), 'iis_stateful_shared_examples.rb'))

describe Puppet::Type.type(:iis_pool) do
  let(:params) do
    {
      name: 'test_pool',
      ensure: 'started',
      enable_32_bit: true,
      runtime: '4.0',
      pipeline: 'Classic',
      autostart: true,
      start_mode: 'OnDemand',
      rapid_fail_protection: false,
      identitytype: 'LocalSystem',
      username: 'Username',
      password: 'Password',
      idle_timeout: '04:00:00',
      idle_timeout_action: 'Terminate',
      max_processes: '12',
      max_queue_length: '4',
      recycle_periodic_minutes: '1.01:10:01',
      recycle_schedule: '02:03:04',
      recycle_logging: %w(Time Memory Schedule)
    }
  end

  # rubocop:disable RSpec/NamedSubject
  def subject(p = params)
    Puppet::Type.type(:iis_pool).new(p)
  end

  it 'accepts a pool name' do
    expect(subject[:name]).to eq('test_pool')
  end

  describe 'ensure' do
    include_context 'stateful types'
    it_behaves_like 'stateful type'
  end

  it 'accepts an enable_32_bit state' do
    expect(subject[:enable_32_bit]).to eq(:true)
  end

  describe 'runtime =>' do
    it 'accepts a runtime' do
      expect(subject[:runtime]).to eq('v4.0')
    end
    it 'munges runtime' do
      expect(subject(params.merge(runtime: '4.0'))[:runtime]).to eq('v4.0')
    end
  end

  describe 'pipeline =>' do
    %w(Integrated Classic).each do |pipeline|
      it "should accept #{pipeline}" do
        param = params.merge(pipeline: pipeline)
        expect(subject(param)[:pipeline]).to eq(pipeline)
      end
    end
  end

  it 'accepts an autostart state' do
    expect(subject[:autostart]).to eq(:true)
  end

  describe 'start_mode' do
    %w(OnDemand AlwaysRunning).each do |start_mode|
      it "should accept #{start_mode}" do
        param = params.merge(start_mode: start_mode)
        expect(subject(param)[:start_mode]).to eq(start_mode)
      end
    end
  end

  it 'accepts an rapid fail protection state' do
    expect(subject[:rapid_fail_protection]).to eq(:false)
  end

  describe 'identitytype =>' do
    %w(
      LocalSystem LocalService NetworkService
      SpecificUser ApplicationPoolIdentity
    ).each do |identitytype|
      it "should accept #{identitytype}" do
        param = params.merge(identitytype: identitytype)
        expect(subject(param)[:identitytype]).to eq(identitytype)
      end
    end
  end

  it 'accepts a username' do
    expect(subject[:username]).to eq('Username')
  end

  it 'accepts a password' do
    expect(subject[:password]).to eq('Password')
  end

  describe 'idle timeout action =>' do
    %w(Suspend Terminate).each do |idle_timeout_action|
      it "should accept #{idle_timeout_action}" do
        param = params.merge(idle_timeout_action: idle_timeout_action)
        expect(subject(param)[:idle_timeout_action]).to eq(idle_timeout_action)
      end
    end
  end

  it 'accepts an idle timeout time' do
    expect(subject[:idle_timeout]).to eq('04:00:00')
  end

  it 'accepts a max processes number' do
    expect(subject[:max_processes]).to eq('12')
  end

  it 'accepts a max processes queue number' do
    expect(subject[:max_queue_length]).to eq('4')
  end

  it 'accepts recycle periodic minutes' do
    expect(subject[:recycle_periodic_minutes]).to eq('1.01:10:01')
  end

  it 'accepts a recycle schedule' do
    expect(subject[:recycle_schedule]).to eq('02:03:04')
  end

  it 'accepts a recycle logging array' do
    expect(subject[:recycle_logging]).to eq(%w(Time Memory Schedule))
  end
end
