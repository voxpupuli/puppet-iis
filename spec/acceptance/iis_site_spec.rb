require 'spec_helper_acceptance'

RSpec.describe 'iis_site' do

  describe 'My New Site' do
    it 'apply manifest' do
      pp = <<-IIS_SITE
      include iis::install
iis_site{'My New Site':
  ensure   => 'started',
  app_pool => 'DefaultAppPool',
  ip       => '*',
  path     => 'C:\\inetpub\\MySite',
  port     => 8080,
  protocol => 'http',
  require  => Class['iis::install'],
}
      IIS_SITE
      apply_manifest pp
    end

    describe iis_website('My New Site') do
      it { should exist }
      it { should be_running }
      it { should be_in_app_pool('DefaultAppPool') }
      it { should have_physical_path('C:\\inetpub\\MySite') }
    end
  end


end