require 'spec_helper'

powershell = 'powershell.exe -ExecutionPolicy RemoteSigned'

describe 'iis::manage_site', :type => :define do
  describe 'when managing the iis site using default params' do
    let(:title) { 'myWebSite' }
    let(:params) { {
        :app_pool    => 'myAppPool.example.com',
        :host_header => 'myHost.example.com',
        :site_path   => 'C:\inetpub\wwwroot\myWebSite',
    } }

    it { should contain_class('iis::param::powershell') }

    it { should contain_exec('CreateSite-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; $id = (Get-WebSite | foreach {$_.id} | sort -Descending | select -first 1) + 1; New-WebSite -Name \\\"myWebSite\\\" -Port 80 -IP * -HostHeader \\\"myHost.example.com\\\" -PhysicalPath \\\"C:\\inetpub\\wwwroot\\myWebSite\\\" -ApplicationPool \\\"myAppPool.example.com\\\" -Ssl:$false -ID $id \"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\Sites\\myWebSite\\\")) { exit 1 } else { exit 0 }\"",
    })}

    it { should contain_exec('UpdateSite-PhysicalPath-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" -Name physicalPath -Value \\\"C:\\inetpub\\wwwroot\\myWebSite\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\Sites\\myWebSite\\\") -eq \$false) { exit 1 } if ((Get-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" physicalPath) -eq \\\"C:\\inetpub\\wwwroot\\myWebSite\\\") { exit 1 } else { exit 0 }\"",
    })}

    it { should contain_exec('UpdateSite-ApplicationPool-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" -Name applicationPool -Value \\\"myAppPool.example.com\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\Sites\\myWebSite\\\") -eq \$false) { exit 1 } if((Get-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" applicationPool) -eq \\\"myAppPool.example.com\\\") { exit 1 } else { exit 0 }\"",
    })}
  end

  describe 'when managing the iis site passing in all parameters' do
    let(:title) { 'myWebSite' }
    let(:params) {{
        :app_pool    => 'myAppPool.example.com',
        :host_header => 'myHost.example.com',
        :site_path   => 'C:\inetpub\wwwroot\path',
        :port        => '1080',
        :ip_address  => '127.0.0.1',
        :ensure      => 'present',
    }}

    it { should contain_class('iis::param::powershell') }

    it { should contain_exec('CreateSite-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; $id = (Get-WebSite | foreach {$_.id} | sort -Descending | select -first 1) + 1; New-WebSite -Name \\\"myWebSite\\\" -Port 1080 -IP 127.0.0.1 -HostHeader \\\"myHost.example.com\\\" -PhysicalPath \\\"C:\\inetpub\\wwwroot\\path\\\" -ApplicationPool \\\"myAppPool.example.com\\\" -Ssl:$false -ID $id \"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\Sites\\myWebSite\\\")) { exit 1 } else { exit 0 }\"",
    })}

    it { should contain_exec('UpdateSite-PhysicalPath-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" -Name physicalPath -Value \\\"C:\\inetpub\\wwwroot\\path\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\Sites\\myWebSite\\\") -eq \$false) { exit 1 } if ((Get-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" physicalPath) -eq \\\"C:\\inetpub\\wwwroot\\path\\\") { exit 1 } else { exit 0 }\"",
    })}

    it { should contain_exec('UpdateSite-ApplicationPool-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" -Name applicationPool -Value \\\"myAppPool.example.com\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\Sites\\myWebSite\\\") -eq \$false) { exit 1 } if((Get-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" applicationPool) -eq \\\"myAppPool.example.com\\\") { exit 1 } else { exit 0 }\"",
    })}
  end

  describe 'when managing the iis site and setting ensure to present' do
    let(:title) { 'myWebSite' }
    let(:params) { {
        :app_pool    => 'myAppPool.example.com',
        :host_header => 'myHost.example.com',
        :site_path   => 'C:\inetpub\wwwroot\myWebSite',
        :ensure      => 'present',
    } }

    it { should contain_exec('CreateSite-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; $id = (Get-WebSite | foreach {$_.id} | sort -Descending | select -first 1) + 1; New-WebSite -Name \\\"myWebSite\\\" -Port 80 -IP * -HostHeader \\\"myHost.example.com\\\" -PhysicalPath \\\"C:\\inetpub\\wwwroot\\myWebSite\\\" -ApplicationPool \\\"myAppPool.example.com\\\" -Ssl:$false -ID $id \"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\Sites\\myWebSite\\\")) { exit 1 } else { exit 0 }\"",
    })}

    it { should contain_exec('UpdateSite-PhysicalPath-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" -Name physicalPath -Value \\\"C:\\inetpub\\wwwroot\\myWebSite\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\Sites\\myWebSite\\\") -eq \$false) { exit 1 } if ((Get-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" physicalPath) -eq \\\"C:\\inetpub\\wwwroot\\myWebSite\\\") { exit 1 } else { exit 0 }\"",
    })}

    it { should contain_exec('UpdateSite-ApplicationPool-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" -Name applicationPool -Value \\\"myAppPool.example.com\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\Sites\\myWebSite\\\") -eq \$false) { exit 1 } if((Get-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" applicationPool) -eq \\\"myAppPool.example.com\\\") { exit 1 } else { exit 0 }\"",
    })}
  end

  describe 'when managing the iis site and setting ensure to installed' do
    let(:title) { 'myWebSite' }
    let(:params) { {
        :app_pool    => 'myAppPool.example.com',
        :host_header => 'myHost.example.com',
        :site_path   => 'C:\inetpub\wwwroot\myWebSite',
        :ensure      => 'installed',
    } }

    it { should contain_exec('CreateSite-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; $id = (Get-WebSite | foreach {$_.id} | sort -Descending | select -first 1) + 1; New-WebSite -Name \\\"myWebSite\\\" -Port 80 -IP * -HostHeader \\\"myHost.example.com\\\" -PhysicalPath \\\"C:\\inetpub\\wwwroot\\myWebSite\\\" -ApplicationPool \\\"myAppPool.example.com\\\" -Ssl:$false -ID $id \"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\Sites\\myWebSite\\\")) { exit 1 } else { exit 0 }\"",
    })}

    it { should contain_exec('UpdateSite-PhysicalPath-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" -Name physicalPath -Value \\\"C:\\inetpub\\wwwroot\\myWebSite\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\Sites\\myWebSite\\\") -eq \$false) { exit 1 } if ((Get-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" physicalPath) -eq \\\"C:\\inetpub\\wwwroot\\myWebSite\\\") { exit 1 } else { exit 0 }\"",
    })}

    it { should contain_exec('UpdateSite-ApplicationPool-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Set-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" -Name applicationPool -Value \\\"myAppPool.example.com\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if((Test-Path \\\"IIS:\\Sites\\myWebSite\\\") -eq \$false) { exit 1 } if((Get-ItemProperty \\\"IIS:\\Sites\\myWebSite\\\" applicationPool) -eq \\\"myAppPool.example.com\\\") { exit 1 } else { exit 0 }\"",
    })}
  end

  describe 'when managing the iis site and setting ensure to absent' do
    let(:title) { 'myWebSite' }
    let(:params) { {
        :app_pool    => 'myAppPool.example.com',
        :host_header => 'myHost.example.com',
        :site_path   => 'C:\inetpub\wwwroot\myWebSite',
        :ensure      => 'absent',
    } }

    it { should contain_exec('DeleteSite-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Remove-WebSite -Name \\\"myWebSite\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if(!(Test-Path \\\"IIS:\\Sites\\myWebSite\\\")) { exit 1 } else { exit 0 }\"",
    })}
  end

  describe 'when managing the iis site and setting ensure to purged' do
    let(:title) { 'myWebSite' }
    let(:params) { {
        :app_pool    => 'myAppPool.example.com',
        :host_header => 'myHost.example.com',
        :site_path   => 'C:\inetpub\wwwroot\myWebSite',
        :ensure      => 'purged',
    } }

    it { should contain_exec('DeleteSite-myWebSite').with({
      'command' => "#{powershell} -Command \"Import-Module WebAdministration; Remove-WebSite -Name \\\"myWebSite\\\"\"",
      'onlyif'  => "#{powershell} -Command \"Import-Module WebAdministration; if(!(Test-Path \\\"IIS:\\Sites\\myWebSite\\\")) { exit 1 } else { exit 0 }\"",
    })}
  end
end
