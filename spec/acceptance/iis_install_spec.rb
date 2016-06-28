require 'spec_helper_acceptance'

RSpec.describe 'iis::install' do
  def create_apply_manifest(params)
    pp = "class {'wsus_client':"
    params.each do |k, v|
      v = "'#{v}'" if v.is_a? String
      pp << "\n  #{k} => #{v},"
    end
    pp << '}'
    apply_manifest_on(default, pp)
  end

  describe 'install IIS' do
    it do
      pp = <<-IIS
      class {'::iis':}
      IIS
      apply_manifest_on(default, pp)
    end
    describe windows_feature('IIS-WebServer') do
      it { should be_installed.by('dism') }
    end
    describe service('w3svc') do
      it { should be_running }
    end
  end
end
