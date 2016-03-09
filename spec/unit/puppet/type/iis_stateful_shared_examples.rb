RSpec.shared_context 'stateful types' do
  shared_examples 'stateful type' do
    [:started, :stopped, :present, :absent].each do |state|
      it "should accept #{state}" do
        expect(subject(params.merge(params.merge({:ensure => state.to_s})))[:ensure]).to eq(state)
      end
    end
    it 'should convert true to started' do
      expect(subject(params.merge(params.merge({:ensure => 'true'})))[:ensure]).to eq(:started)
    end
    it 'should convert false to stopped' do
      expect(subject(params.merge(params.merge({:ensure => 'false'})))[:ensure]).to eq(:stopped)
    end
  end
end