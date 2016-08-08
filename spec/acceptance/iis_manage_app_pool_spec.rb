require 'spec_helper_acceptance'

RSpec.describe 'iis::manage_site' do
  describe 'apppool_idle_timeout_action' do
    it 'apply manifest' do
      # Install chocolatey to make setting up packages either
      # Means we dont have to do a bunch of msi downloading...
      choco_install = <<-CHOCO_INSTALL
      include ::chocolatey
      CHOCO_INSTALL

      apply_manifest(choco_install, catch_failures: true)

      # Setup a basic IIS pool and app running on port 8080
      pp = <<-IIS_SITE

      iis::manage_app_pool {'MyAppPool':
        enable_32_bit               => true,
        managed_runtime_version     => 'v4.0',
        apppool_idle_timeout_action => 'Terminate',
      }

      iis_site {'My Website':
        path                        => 'C:\inetpub\wwwroot',
        port                        => '81',
        ip                          => '*',
        app_pool                    => 'MyAppPool',
      }

      IIS_SITE
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end
  end
end
