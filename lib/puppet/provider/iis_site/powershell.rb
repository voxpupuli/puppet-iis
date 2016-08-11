require 'puppet/provider/iispowershell'
require 'rexml/document'
include REXML

Puppet::Type.type(:iis_site).provide(:powershell, parent: Puppet::Provider::Iispowershell) do
  mk_resource_methods

  def self.instances
    inst_cmd = <<-ps1
Import-Module WebAdministration;
Get-ChildItem "IIS:\\Sites" | %{Get-ItemProperty $_.PSPath | Select ID,Name,PhysicalPath,ApplicationPool,HostHeader,State,Bindings} | ConvertTo-XML -Depth 4 -As String -NoTypeInformation
ps1
    sites = []
    ps_info = run(inst_cmd)
    xml = Document.new ps_info
    xml.root.each_element do |object|
      ssl_flags = if object.elements["Property[@Name='bindings']/Property[@Name='Collection']/Property/Property[@Name='sslFlags']"].text == false
                    false
                  else
                    true
                  end
      site_hash = {
          :state        => object.elements["Property[@Name='state']"].text.downcase,
          :name         => object.elements["Property[@Name='name']"].text,
          :id           => object.elements["Property[@Name='id']"].text,
          :protocol     => object.elements["Property[@Name='bindings']/Property[@Name='Collection']/Property/Property[@Name='protocol']"].text,
          :ip           => object.elements["Property[@Name='bindings']/Property[@Name='Collection']/Property/Property[@Name='bindingInformation']"].text.split(':')[0],
          :port         => object.elements["Property[@Name='bindings']/Property[@Name='Collection']/Property/Property[@Name='bindingInformation']"].text.split(':')[1],
          :host_header  => object.elements["Property[@Name='bindings']/Property[@Name='Collection']/Property/Property[@Name='bindingInformation']"].text.split(':')[2],
          :app_pool     => object.elements["Property[@Name='applicationPool']"].text,
          :path         => object.elements["Property[@Name='physicalPath']"].text,
          :ssl          => ssl_flags,
      }
      sites.push(site_hash)
    end
    sites.map do |site|
        new(
            :ensure      => site[:state],
            :name        => site[:name],
            :port        => site[:port],
            :id          => site[:id],
            :protocol    => site[:protocol],
            :ip          => site[:ip],
            :host_header => site[:host_header],
            :app_pool    => site[:app_pool],
            :path        => site[:path],
            :ssl         => site[:ssl],
        )
    end
  end
  
  def self.prefetch(resources)
    sites = instances
    resources.keys.each do |site|
      if provider = sites.find { |s| s.name == site }
        resources[site].provider = provider
      end
    end
  end

  def exists?
    ps = "Import-Module WebAdministration;Get-Website \"#{@property_hash[:name]}\""
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps)
    resp.empty?
    Puppet.notice resp.empty?
  end

  def create
    create_switches = [
      "-Name \"#{@resource[:name]}\"",
      "-Port #{@resource[:port]} -IP #{@resource[:ip]}",
      "-HostHeader \"#{@resource[:host_header]}\"",
      "-PhysicalPath \"#{@resource[:path]}\"",
      "-ApplicationPool \"#{@resource[:app_pool]}\"",
      "-Ssl:$#{@resource[:ssl]}",
      '-Force'
    ]
    if @resource[:id]
      create_switches.push("-Id #{@resource[:id]}")
    end
    ps = "Import-Module WebAdministration; New-Website #{create_switches.join(' ')}"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps)
    Puppet.debug "Creation powershell response was #{resp}"
  end

  def destroy
    ps = "Import-Module WebAdministration; Remove-Website -Name \"#{@property_hash[:name]}\""
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps)
    raise(resp) unless resp.empty?
  end

# ENSURE STATES - How to start/stop

  def start
    create unless exists?
    current_state = state
    if current_state == 'stopped'
      ps = "Start-Website \"#{@property_hash[:name]}\"}"
      resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps)
      raise(resp) unless resp.empty?
    end
  end

  def stop
    create unless exists?
    current_state = state
    if current_state == 'started'
      ps = "Stop-Website \"#{@property_hash[:name]}\""
      resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps)
      raise(resp) unless resp.empty?
    end
  end

# Gets the current state of the website. (Started/Stopped)

  def state
    ps = "Import-Module WebAdministration;(Get-Website -Name \"#{@property_hash[:name]}\").State"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps).strip.downcase
    return resp
  end


# PARAMETERS  

  def id
    ps = "Import-Module WebAdministration;(Get-Website -Name \"#{@property_hash[:name]}\").Id"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps).chomp
  end

  def id=(value)
    ps = "Import-Module WebAdministration;Set-WebConfigurationProperty '/system.applicationhost/sites/site[@name=\"#{@property_hash[:name]}\"]' -name id -Value #{value}"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps)
    raise(resp) unless resp.empty?
  end  

 

  def state=(value)
    cmd = if value == 'stopped' then 'Stop' elsif value == 'started' then 'Start' end
    ps = "Import-Module WebAdministration; #{cmd}-Website -Name \"#{@property_hash[:name]}\""
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps)
    raise(resp) unless resp.empty?
  end

  def ip
    ps = "Import-Module WebAdministration;(Get-Website -Name \"#{@property_hash[:name]}\").Bindings.Collection.bindingInformation.Split(':')[0]"
    # chomp'd the response, because wtf powershell
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps).chomp
  end

  def ip=(value)
    bindings = "@{protocol='#{@property_hash[:protocol]}';bindingInformation='#{value}:#{@property_hash[:port]}:#{@property_hash[:host_header]}'}"
    ps = "Import-Module WebAdministration;Set-ItemProperty -Path \"IIS:\\Sites\\#{@property_hash[:name]}\" -Name Bindings -Value #{bindings}"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps)
    raise(resp) unless resp.empty?
  end

  def port
    ps = "Import-Module WebAdministration;(Get-Website -Name \"#{@property_hash[:name]}\").Bindings.Collection.bindingInformation.Split(':')[1]"
    # chomp'd the response, because wtf powershell
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps).chomp
  end

  def port=(value)
    bindings = "@{protocol='#{@property_hash[:protocol]}';bindingInformation='#{@property_hash[:ip]}:#{value}:#{@property_hash[:host_header]}'}"
    ps = "Import-Module WebAdministration;Set-ItemProperty -Path \"IIS:\\Sites\\#{@property_hash[:name]}\" -Name Bindings -Value #{bindings}"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps)
    raise(resp) unless resp.empty?
  end

  def host_header
    ps = "Import-Module WebAdministration;(Get-Website -Name \"#{@property_hash[:name]}\").Bindings.Collection.bindingInformation.Split(':')[2]"
    # chomp'd the response, because wtf powershell
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps).chomp
  end

  def host_header=(value)
    bindings = "@{protocol='#{@property_hash[:protocol]}';bindingInformation='#{@property_hash[:ip]}:#{@property_hash[:port]}:#{value}'}"
    ps = "Import-Module WebAdministration;Set-ItemProperty -Path \"IIS:\\Sites\\#{@property_hash[:name]}\" -Name Bindings -Value #{bindings}"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps)
    raise(resp) unless resp.empty?
  end

  def app_pool
    ps="Import-Module WebAdministration;(Get-Website \"#{@property_hash[:name]}\").ApplicationPool"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps).chomp
  end

  def app_pool=(value)
    ps = "Import-Module WebAdministration;Set-ItemProperty -Path \"IIS:\\Sites\\#{@property_hash[:name]}\" -Name ApplicationPool -Value #{value}"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps)
    raise(resp) unless resp.empty?
  end

  def path
    ps = "Import-Module WebAdministration;(Get-Website \"#{@property_hash[:name]}\").physicalPath"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps).chomp
  end

  def path=(value)
    ps = "Import-Module WebAdministration;Set-ItemProperty -Path \"IIS:\\Sites\\#{@property_hash[:name]}\" -Name PhysicalPath -Value #{value}"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps)
    raise(resp) unless resp.empty?
  end

  def ssl
    ps = "Import-Module WebAdministration;If ((Get-Website \"#{@property_hash[:name]}\").Bindings.Collection.sslFlags -eq 0) {$false} else {$true}"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps).chomp.downcase
  end

  def ssl=(value)
    sslvalue = if value == 'false' then '0' else '1' end
    bindings = "@{protocol='#{@property_hash[:protocol]}';bindingInformation='#{@property_hash[:ip]}:#{@property_hash[:port]}:#{@property_hash[:host_header]}';sslFlags=#{sslvalue}}"
    ps = "Import-Module WebAdministration;Set-ItemProperty -Path \"IIS:\\Sites\\#{@property_hash[:name]}\" -Name Bindings -Value #{bindings}"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(ps)
    raise(resp) unless resp.empty?
  end

end
