require 'puppet/provider/iispowershell'
require 'csv'
Puppet::Type.type(:iis_binding).provide(:powershell, parent: Puppet::Provider::Iispowershell) do
  mk_resource_methods

  def self.instances
    b_array = []
    result = run("Import-Module WebAdministration; Get-WebBinding | ConvertTo-Csv -NoTypeInformation")
    unless result.empty?
      csv = CSV.parse(result, headers: true)
      csv.each do |item|
        site_name = item['ItemXPath'].match("'([^']*)'")[0].delete("\'")
        host_header = item['bindingInformation'].split(':')[2]
        host_header = '*' unless host_header
        certificate = if item['certificateHash']
                        "Cert:\\LocalMachine\\#{item['certificateStoreName']}\\#{item['certificateHash']}"
                      else
                        ''
                      end
        binding = {
          ensure: :present,
          name: item['bindingInformation'],
          site_name: site_name,
          ip_address: item['bindingInformation'].split(':')[0],
          host_header: host_header,
          port: item['bindingInformation'].split(':')[1],
          protocol: item['protocol'],
          certificate: certificate,
          ssl_flag: item['sslFlags'],
        }
        b_array.push(binding)
      end
        b_array.map { |web_binding| new(web_binding) }
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def generate_binding_variables(bindinginfo)
    binding_array = bindinginfo.split(':')
    return binding_array
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    win2008 = Facter.value(:kernelmajversion) == '6.1'
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
    Puppet.debug "Creating web binding with #{cmd}"
    result = Puppet::Type::Iis_binding::ProviderPowershell.run(cmd)
    Puppet.debug "Response from PowerShell create task: #{result}"
    create_certificate_binding if @resource[:certificate]
    @property_hash[:ensure] == :present
  end

  def destroy
    cmd = "Import-Module WebAdministration; Remove-WebBinding -BindingInformation #{resource[:name]}"
    result = Puppet::Type::Iis_binding::ProviderPowershell.run(cmd)
    Puppet.debug "Response from PowerShell destroy task: #{result}"
    @property_hash.clear
  end

  def create_certificate_binding
    cmd = <<-ps1.gsub(%r{^\s+}, '')
    Import-Module WebAdministration
    Get-Item '#{@resource[:certificate]}' | New-Item IIS:\\SslBindings\\#{@resource[:ip_address]}!#{@resource[:port]}
  ps1
    resp = Puppet::Type::Iis_binding::ProviderPowershell.run(cmd)
    Puppet.debug resp
  end

  def certificate=(value)
    cmd = <<-ps1.gsub(%r{^\s+}, '')
      Import-Module WebAdministration
      $sslbinding = If(Get-Item IIS:\\SslBindings\\#{@property_hash[:ip_address]}!#{@property_hash[:port]} -ErrorAction SilentlyContinue){$true}
      if($sslbinding){Get-Item IIS:\\SslBindings\\#{@property_hash[:ip_address]}!#{@property_hash[:port]} | Remove-Item}
      Get-Item '#{value}' | New-Item IIS:\\SslBindings\\#{@property_hash[:ip_address]}!#{@property_hash[:port]}
    ps1
    Puppet.debug cmd
    resp = Puppet::Type::Iis_binding::ProviderPowershell.run(cmd)
    Puppet.debug resp
  end

  def flush
    # TODO: Currently not working. Name is munged from ip/port/host
    # so change events change the 'name' and therefore create a new
    # entry instead of changing the current one. Maybe this if for
    # the best, as if a person tries to change all params for an
    # iis_binding resource all hell would break loose. The only
    # consistant unique key is ip:port:host.
    unless @property_hash.empty? || @property_hash.nil?
      cmd = <<-ps1.gsub(%r{^\s+}, '')
        Import-Module WebAdministration
        Set-WebBinding -Name #{@property_hash[:site_name]} -IPAddress #{@resource[:ip_address]} `
        -Port #{@resource[:port]} -HostHeader #{@resource[:host_header]}
      ps1
      Puppet::Type::Iis_binding::ProviderPowershell.run(cmd)
    end
  end
end
