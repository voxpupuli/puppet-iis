require 'puppet/provider/iispowershell'
require 'csv'
Puppet::Type.type(:iis_binding).provide(:powershell, parent: Puppet::Provider::Iispowershell) do
  mk_resource_methods

  def self.instances
    b_array = []
    result = if Facter.value(:kernelmajversion) == '6.1'
               run('Import-Module WebAdministration; Get-WebBinding | ConvertTo-Csv -NoTypeInformation')
             else
               run('Get-WebBinding | ConvertTo-Csv -NoTypeInformation')
             end
    csv = CSV.parse(result, :headers => true)
    csv.each do |item|
      site_name = item['ItemXPath'].match("'([^']*)'")[0].gsub("\'","")
      host_header = item['bindingInformation'].split(':')[2]
      host_header = '*' unless host_header
      if item['certificateHash']
        certificate = "Cert:\\LocalMachine\\#{item['certificateStoreName']}\\#{item['certificateHash']}"
      else
        certificate = ""
      end
      binding = {
        :ensure      => :present,
        :name        => item['bindingInformation'],
        :site_name   => site_name,
        :ip_address  => item['bindingInformation'].split(':')[0],
        :host_header => host_header,
        :port        => item['bindingInformation'].split(':')[1],
        :protocol    => item['protocol'],
        :certificate => certificate,
        :ssl_flag    => item['sslFlags'],
        :binding     => item['bindingInformation'],
      }
      b_array.push(binding)
    end
    b_array.map { |b| new(b) }
  end

  def self.prefetch(resources)
    bnd = instances
    resources.keys.each do |bd|
     # rubocop:disable Lint/AssignmentInCondition
      if provider = bnd.find { |b| b.name == bd } then resources[bd].provider = provider end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    win2008 = Facter.value(:kernelmajversion) == '6.1'
    @resource[:port] = @resource[:binding].split(':')[1] unless @resource[:port]
    @resource[:host_header] = @resource[:binding].split(':')[2] unless @resource[:host_header]
    @resource[:ip_address] = @resource[:binding].split(':')[0] unless @resource[:ip_address]
    @resource[:host_header] = '*' unless @resource[:host_header]
    create_switches = [
      "-Name #{@resource[:site_name]}",
      "-Port #{@resource[:port]}",
      "-Protocol #{@resource[:protocol]}",
      "-HostHeader #{@resource[:host_header]}",
      "-IPAddress #{@resource[:ip_address]}"
    ]
    if win2008 == false && protocol == 'https'
      create_switches << '-SslFlags $true'
    elsif win2008 == false && @resource['ssl_flag']
      create_switches << "-SslFlags #{@resource['ssl_flag']}"
    end
    cmd = "Import-Module WebAdministration; New-WebBinding #{create_switches.join(' ')}"
    result = Puppet::Type::Iis_binding::ProviderPowershell.run(cmd)
    Puppet.debug "Response from PowerShell create task: #{result}"
    if @resource[:certificate] then self.create_certificate_binding end
  end

  def destroy
    cmd = "Import-Module WebAdministration; Remove-WebBinding -BindingInformation #{resource[:binding]}"
    result = Puppet::Type::Iis_binding::ProviderPowershell.run(cmd)
    Puppet.debug "Response from PowerShell destroy task: #{result}"
  end

  def create_certificate_binding
  cmd = <<-ps1.gsub(/^\s+/, "")
    Import-Module WebAdministration
    Get-Item '#{@resource[:certificate]}' | New-Item IIS:\\SslBindings\\#{@resource[:ip_address]}!#{@resource[:port]}
  ps1
      resp = Puppet::Type::Iis_binding::ProviderPowershell.run(cmd)
      Puppet.debug resp
  end

  def clean_certificate_binding
    cmd = <<-ps1.gsub(/^\s+/, "")
      Import-Module WebAdministration
      Get-Item IIS:\\SslBindings\\#{@resource[:ip_address]}!#{@resource[:port]} | Remove-Item
    ps1
  end

  def certificate=(value)
    cmd = <<-ps1.gsub(/^\s+/, "")
      Import-Module WebAdministration
      $sslbinding = If(Get-Item IIS:\\SslBindings\\#{@property_hash[:ip_address]}!#{@property_hash[:port]} -ErrorAction SilentlyContinue){$true}
      if($sslbinding){Get-Item IIS:\\SslBindings\\#{@property_hash[:ip_address]}!#{@property_hash[:port]} | Remove-Item}
      Get-Item '#{value}' | New-Item IIS:\\SslBindings\\#{@property_hash[:ip_address]}!#{@property_hash[:port]}
    ps1
    Puppet.notice cmd
    resp = Puppet::Type::Iis_binding::ProviderPowershell.run(cmd)
    Puppet.debug resp
  end
end
