require 'spec_helper'

describe 'iis::manage_site', :type => :define do
  describe 'when managing the iis site using default params' do
    let(:title) { 'myWebSite' }
    let(:params) { {
      :app_pool    => 'myAppPool.example.com',
      :host_header => 'myHost.example.com',
      :site_path   => 'C:\inetpub\wwwroot\myWebSite'
    } }
    let(:facts) {{
      :path        => 'C:\Windows\system32'
    }}

    it { should contain_exec('CreateSite-myWebSite').with(
      'command' => 'Import-Module WebAdministration; $id = (Get-WebSite | foreach {$_.id} | sort -Descending | select -first 1) + 1; New-WebSite -Name "myWebSite" -Port 80 -IP * -HostHeader "myHost.example.com" -PhysicalPath "C:\\inetpub\\wwwroot\\myWebSite" -ApplicationPool "myAppPool.example.com" -Ssl:$false -ID $id',
      'onlyif'  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\Sites\\myWebSite")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('UpdateSite-PhysicalPath-myWebSite').with(
      'command' => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\Sites\\myWebSite" -Name physicalPath -Value "C:\\inetpub\\wwwroot\\myWebSite"',
      'onlyif'  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\Sites\\myWebSite") -eq $false) { exit 1 } if ((Get-ItemProperty "IIS:\\Sites\\myWebSite" physicalPath) -eq "C:\\inetpub\\wwwroot\\myWebSite") { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('UpdateSite-ApplicationPool-myWebSite').with(
      'command' => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\Sites\\myWebSite" -Name applicationPool -Value "myAppPool.example.com"',
      'onlyif'  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\Sites\\myWebSite") -eq $false) { exit 1 } if((Get-ItemProperty "IIS:\\Sites\\myWebSite" applicationPool) -eq "myAppPool.example.com") { exit 1 } else { exit 0 }',)
    }
  end

  describe 'when managing the iis site passing in all parameters' do
    let(:title) { 'myWebSite' }
    let(:params) {{
      :app_pool    => 'myAppPool.example.com',
      :host_header => 'myHost.example.com',
      :site_path   => 'C:\inetpub\wwwroot\path',
      :port        => '1080',
      :ip_address  => '127.0.0.1',
      :ensure      => 'present'
    }}
    let(:facts) {{
      :path        => 'C:\Windows\system32'
    }}

    it { should contain_exec('CreateSite-myWebSite').with(
      'command' => 'Import-Module WebAdministration; $id = (Get-WebSite | foreach {$_.id} | sort -Descending | select -first 1) + 1; New-WebSite -Name "myWebSite" -Port 1080 -IP 127.0.0.1 -HostHeader "myHost.example.com" -PhysicalPath "C:\\inetpub\\wwwroot\\path" -ApplicationPool "myAppPool.example.com" -Ssl:$false -ID $id',
      'onlyif'  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\Sites\\myWebSite")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('UpdateSite-PhysicalPath-myWebSite').with(
      'command' => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\Sites\\myWebSite" -Name physicalPath -Value "C:\\inetpub\\wwwroot\\path"',
      'onlyif'  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\Sites\\myWebSite") -eq $false) { exit 1 } if ((Get-ItemProperty "IIS:\\Sites\\myWebSite" physicalPath) -eq "C:\\inetpub\\wwwroot\\path") { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('UpdateSite-ApplicationPool-myWebSite').with(
      'command' => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\Sites\\myWebSite" -Name applicationPool -Value "myAppPool.example.com"',
      'onlyif'  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\Sites\\myWebSite") -eq $false) { exit 1 } if((Get-ItemProperty "IIS:\\Sites\\myWebSite" applicationPool) -eq "myAppPool.example.com") { exit 1 } else { exit 0 }',)
    }
  end

  describe 'when managing the iis site and setting ensure to present' do
    let(:title) { 'myWebSite' }
    let(:params) { {
      :app_pool    => 'myAppPool.example.com',
      :host_header => 'myHost.example.com',
      :site_path   => 'C:\inetpub\wwwroot\myWebSite',
      :ensure      => 'present'
    } }
    let(:facts) {{
      :path        => 'C:\Windows\system32'
    }}

    it { should contain_exec('CreateSite-myWebSite').with(
      'command' => 'Import-Module WebAdministration; $id = (Get-WebSite | foreach {$_.id} | sort -Descending | select -first 1) + 1; New-WebSite -Name "myWebSite" -Port 80 -IP * -HostHeader "myHost.example.com" -PhysicalPath "C:\\inetpub\\wwwroot\\myWebSite" -ApplicationPool "myAppPool.example.com" -Ssl:$false -ID $id',
      'onlyif'  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\Sites\\myWebSite")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('UpdateSite-PhysicalPath-myWebSite').with(
      'command' => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\Sites\\myWebSite" -Name physicalPath -Value "C:\\inetpub\\wwwroot\\myWebSite"',
      'onlyif'  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\Sites\\myWebSite") -eq $false) { exit 1 } if ((Get-ItemProperty "IIS:\\Sites\\myWebSite" physicalPath) -eq "C:\\inetpub\\wwwroot\\myWebSite") { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('UpdateSite-ApplicationPool-myWebSite').with(
      'command' => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\Sites\\myWebSite" -Name applicationPool -Value "myAppPool.example.com"',
      'onlyif'  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\Sites\\myWebSite") -eq $false) { exit 1 } if((Get-ItemProperty "IIS:\\Sites\\myWebSite" applicationPool) -eq "myAppPool.example.com") { exit 1 } else { exit 0 }',)
    }
  end

  describe 'when managing the iis site and setting ensure to installed' do
    let(:title) { 'myWebSite' }
    let(:params) { {
      :app_pool    => 'myAppPool.example.com',
      :host_header => 'myHost.example.com',
      :site_path   => 'C:\inetpub\wwwroot\myWebSite',
      :ensure      => 'installed'
    } }
    let(:facts) {{
      :path        => 'C:\Windows\system32'
    }}

    it { should contain_exec('CreateSite-myWebSite').with(
      'command' => 'Import-Module WebAdministration; $id = (Get-WebSite | foreach {$_.id} | sort -Descending | select -first 1) + 1; New-WebSite -Name "myWebSite" -Port 80 -IP * -HostHeader "myHost.example.com" -PhysicalPath "C:\\inetpub\\wwwroot\\myWebSite" -ApplicationPool "myAppPool.example.com" -Ssl:$false -ID $id',
      'onlyif'  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\Sites\\myWebSite")) { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('UpdateSite-PhysicalPath-myWebSite').with(
      'command' => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\Sites\\myWebSite" -Name physicalPath -Value "C:\\inetpub\\wwwroot\\myWebSite"',
      'onlyif'  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\Sites\\myWebSite") -eq $false) { exit 1 } if ((Get-ItemProperty "IIS:\\Sites\\myWebSite" physicalPath) -eq "C:\\inetpub\\wwwroot\\myWebSite") { exit 1 } else { exit 0 }',)
    }

    it { should contain_exec('UpdateSite-ApplicationPool-myWebSite').with(
      'command' => 'Import-Module WebAdministration; Set-ItemProperty "IIS:\\Sites\\myWebSite" -Name applicationPool -Value "myAppPool.example.com"',
      'onlyif'  => 'Import-Module WebAdministration; if((Test-Path "IIS:\\Sites\\myWebSite") -eq $false) { exit 1 } if((Get-ItemProperty "IIS:\\Sites\\myWebSite" applicationPool) -eq "myAppPool.example.com") { exit 1 } else { exit 0 }',)
    }
  end

  describe 'when managing the iis site and setting ensure to absent' do
    let(:title) { 'myWebSite' }
    let(:params) { {
      :app_pool    => 'myAppPool.example.com',
      :host_header => 'myHost.example.com',
      :site_path   => 'C:\inetpub\wwwroot\myWebSite',
      :ensure      => 'absent'
    } }
    let(:facts) {{
      :path        => 'C:\Windows\system32'
    }}

    it { should contain_exec('DeleteSite-myWebSite').with(
      'command' => 'Import-Module WebAdministration; Remove-WebSite -Name "myWebSite"',
      'onlyif'  => 'Import-Module WebAdministration; if(!(Test-Path "IIS:\\Sites\\myWebSite")) { exit 1 } else { exit 0 }',)
    }
  end

  describe 'when managing the iis site and setting ensure to purged' do
    let(:title) { 'myWebSite' }
    let(:params) { {
      :app_pool    => 'myAppPool.example.com',
      :host_header => 'myHost.example.com',
      :site_path   => 'C:\inetpub\wwwroot\myWebSite',
      :ensure      => 'purged'
    } }
    let(:facts) {{
      :path        => 'C:\Windows\system32'
    }}

    it { should contain_exec('DeleteSite-myWebSite').with(
      'command' => 'Import-Module WebAdministration; Remove-WebSite -Name "myWebSite"',
      'onlyif'  => 'Import-Module WebAdministration; if(!(Test-Path "IIS:\\Sites\\myWebSite")) { exit 1 } else { exit 0 }',)
    }
  end

  describe 'when ssl parameter is not valid' do
    let(:title) { 'myWebSite' }
    let(:params) { {
      :app_pool    => 'myAppPool.example.com',
      :host_header => 'myHost.example.com',
      :site_path   => 'C:\inetpub\wwwroot\myWebSite',
      :ssl         => 'nope'
    } }
    let(:facts) {{
      :path        => 'C:\Windows\system32'
    }}

    it { expect { should contain_exec('CreateSite-myWebSite') }.to raise_error(Puppet::Error, /"nope" is not a boolean/) }
  end
end
