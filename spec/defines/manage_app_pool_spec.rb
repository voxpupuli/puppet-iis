require 'spec_helper'

describe 'iis::manage_app_pool', type: :define do
  describe 'with default parameters' do
    let(:title) { 'my_cool_app_pool' }

    let(:params) do
      {

      }
    end

    it do
      is_expected.to contain_exec('Create-my_cool_app_pool')
        .with('command' => 'Import-Module WebAdministration; New-Item "IIS:\AppPools\my_cool_app_pool"',
              'provider' => 'powershell',
              'onlyif' => 'Import-Module WebAdministration; if((Test-Path "IIS:\AppPools\my_cool_app_pool")) { exit 1 } else { exit 0 }',
              'logoutput' => 'true')
    end
    it do
      is_expected.to contain_exec('StartMode-my_cool_app_pool')
        .with('command' => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\my_cool_app_pool" startMode OnDemand',
              'provider' => 'powershell',
              'onlyif' => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\my_cool_app_pool\" startMode).CompareTo('OnDemand') -eq 0) { exit 1 } else { exit 0 }",
              'require' => 'Exec[Create-my_cool_app_pool]',
              'logoutput' => 'true')
    end
    it do
      is_expected.to contain_exec('RapidFailProtection-my_cool_app_pool')
        .with('command' => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\my_cool_app_pool" failure.rapidFailProtection true',
              'provider' => 'powershell',
              'onlyif' => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\my_cool_app_pool\" failure.rapidFailProtection).Value -eq [System.Convert]::ToBoolean('true')) { exit 1 } else { exit 0 }",
              'require' => 'Exec[Create-my_cool_app_pool]',
              'logoutput' => 'true')
    end
    it do
      is_expected.to contain_exec('Framework-my_cool_app_pool')
        .with('command' => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\my_cool_app_pool" managedRuntimeVersion v4.0',
              'provider' => 'powershell',
              'onlyif' => 'Import-Module WebAdministration; if((Get-ItemProperty "IIS:\AppPools\my_cool_app_pool" managedRuntimeVersion).Value.CompareTo(\'v4.0\') -eq 0) { exit 1 } else { exit 0 }',
              'require' => 'Exec[Create-my_cool_app_pool]',
              'logoutput' => 'true')
    end
    it do
      is_expected.to contain_exec('32bit-my_cool_app_pool')
        .with('command' => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\AppPools\\my_cool_app_pool" enable32BitAppOnWin64 false',
              'provider' => 'powershell',
              'onlyif' => 'Import-Module WebAdministration; if((Get-ItemProperty "IIS:\AppPools\my_cool_app_pool" enable32BitAppOnWin64).Value -eq [System.Convert]::ToBoolean(\'false\')) { exit 1 } else { exit 0 }',
              'require' => 'Exec[Create-my_cool_app_pool]',
              'logoutput' => 'true')
    end
    it do
      is_expected.to contain_exec('ManagedPipelineMode-my_cool_app_pool')
        .with('command' => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\AppPools\my_cool_app_pool" managedPipelineMode 0',
              'provider' => 'powershell',
              'onlyif' => "Import-Module WebAdministration; if((Get-ItemProperty \"IIS:\\AppPools\\my_cool_app_pool\" managedPipelineMode).CompareTo('Integrated') -eq 0) { exit 1 } else { exit 0 }",
              'require' => 'Exec[Create-my_cool_app_pool]',
              'logoutput' => 'true')
    end
  end
end
