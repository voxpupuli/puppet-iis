require 'spec_helper'
require 'facter/util/registryiis'

describe Facter::Util::Fact do
  before do
    Facter.clear
  end

  describe 'Windows' do
    context 'returns IIS version when avaliable' do
      before do
        Facter.fact(:kernel).stubs(:value).returns('Windows')
        Facter::Util::Resolution.stubs(:exec)
        Facter::Util::Registryiis.stubs(:iis_version_string_from_registry).returns('Version 8.5')
      end
      let(:facts) { { kernel: 'Windows' } }
      it do
        expect(Facter.value(:iis_version)).to eq('8.5')
      end
    end

    context 'returns nil when IIS version no avaliable' do
      before do
        Facter.fact(:kernel).stubs(:value).returns('Windows')
        Facter::Util::Resolution.stubs(:exec)
        Facter::Util::Registryiis.stubs(:iis_version_string_from_registry).returns(nil)
      end
      let(:facts) { { kernel: 'Windows' } }
      it do
        expect(Facter.value(:iis_version)).to eq(nil)
      end
    end
  end
end
