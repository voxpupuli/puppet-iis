require 'spec_helper_acceptance'

RSpec.describe 'iis_site' do
  describe 'Simple Chocolatey Server IIS Install' do
    it 'apply manifest' do
      # Install chocolatey to make setting up packages either
      # Means we dont have to do a bunch of msi downloading...
      choco_install = <<-CHOCO_INSTALL
      include ::chocolatey
      CHOCO_INSTALL

      apply_manifest(choco_install, catch_failures: true)

      # Setup a basic IIS pool and app running on port 8080
      pp = <<-IIS_SITE
      include ::iis

      windowsfeature { 'Web-Asp-Net45':
      } ->
      package {'chocolatey.server':
        ensure    => installed,
        provider  => chocolatey,
        source    => 'https://chocolatey.org/api/v2/',
      } ->
      iis::manage_site {'Default Web Site':
        ensure        => absent,
        site_path     => 'any',
        app_pool      => 'DefaultAppPool'
      } ->
      # application in iis
      iis::manage_app_pool { 'chocolatey.server':
        enable_32_bit           => true,
        managed_runtime_version => 'v4.0',
      } ->
      iis::manage_site {'chocolatey.server':
        site_path     => 'C:\\tools\\chocolatey.server',
        port          => '8080',
        ip_address    => '*',
        app_pool      => 'chocolatey.server',
      } ->

      # lock down web directory
      acl { 'C:\\tools\\chocolatey.server':
        purge      => true,
        inherit_parent_permissions  => false,
        permissions => [
         { identity => 'Administrators', rights => ['full'] },
         { identity => 'IIS_IUSRS', rights => ['read'] },
         { identity => 'IUSR', rights => ['read'] },
         { identity => 'IIS APPPOOL\\chocolatey.server', rights => ['read'] }
       ],
      } ->
      acl { 'C:\\tools\\chocolatey.server/App_Data':
        permissions => [
         { identity => 'IIS APPPOOL\\chocolatey.server', rights => ['modify'] },
         { identity => 'IIS_IUSRS', rights => ['modify'] }
       ],
      }

      package { 'curl':
        provider => chocolatey,
      }

      IIS_SITE
      apply_manifest(pp, catch_failures: true)
    end

    describe iis_website('chocolatey.server') do
      it { should exist }
      it { should be_running }
      it { should be_in_app_pool('chocolatey.server') }
      it { should have_physical_path('C:/tools/chocolatey.server') }
    end

    # Setup a basic IIS pool and app running on port 8080
    context 'chocolatey.server should be running on port 8080' do
      describe command('(New-Object Net.WebClient).DownloadString("http://127.0.0.1:8080")') do
        its(:stdout) { should match(/Simple Chocolatey Repository/) }
      end
    end
  end
end
