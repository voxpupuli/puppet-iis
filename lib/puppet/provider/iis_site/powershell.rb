require 'puppet/provider/iispowershell'
require 'json'

Puppet::Type.type(:iis_site).provide(:powershell, parent: Puppet::Provider::Iispowershell) do
  def initialize(value = {})
    super(value)
    @property_flush = {
      'itemproperty' => {},
      'binders'      => {}
    }
  end

  def self.iisnames
    {
      name: 'name',
      path: 'physicalPath',
      app_pool: 'applicationPool'
    }
  end

  def self.instances
    inst_cmd = <<-ps1
Import-Module WebAdministration;
gci "IIS:\\sites" | %{ Get-ItemProperty $_.PSPath  | Select name, PhysicalPath, ApplicationPool, HostHeader, State, Bindings } | ConvertTo-Json -Depth 4 -Compress
ps1
    site_json = JSON.parse(run(inst_cmd))
    # The command returns a Hash if there is 1 site
    site_json = [site_json] if site_json.is_a?(Hash)
    site_json.map do |site|
      site_hash               = {}
      site_hash[:ensure]      = site['state'].downcase
      site_hash[:name]        = site['name']
      site_hash[:path]        = site['physicalPath']
      site_hash[:app_pool]    = site['applicationPool']
      binding_collection      = site['bindings']['Collection']
      bindings                = binding_collection.first['bindingInformation']
      site_hash[:protocol]    = site['bindings']['Collection'].first['protocol']
      site_hash[:ip]          = bindings.split(':')[0]
      site_hash[:port]        = bindings.split(':')[1]
      site_hash[:host_header] = bindings.split(':')[2]
      site_hash[:ssl] = if site['bindings']['Collection'].first['sslFlags'].zero?
                          :false
                        else
                          :true
                        end
      new(site_hash)
    end
  end

  def self.prefetch(resources)
    sites = instances
    resources.keys.each do |site|
      # rubocop:disable Lint/AssignmentInCondition
      if provider = sites.find { |s| s.name == site }
        resources[site].provider = provider
      end
    end
  end

  def exists?
    %w(stopped started).include?(@property_hash[:ensure])
  end

  mk_resource_methods

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
    inst_cmd = "Import-Module WebAdministration; New-Website #{create_switches.join(' ')}"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(inst_cmd)
    Puppet.debug "Creation powershell response was #{resp}"

    @resource.original_parameters.each_key do |k|
      @property_hash[k] = @resource[k]
    end
    @property_hash[:ensure]      = :present unless @property_hash[:ensure]
    @property_hash[:port]        = @resource[:port]
    @property_hash[:ip]          = @resource[:ip]
    @property_hash[:host_header] = @resource[:host_header]
    @property_hash[:path]        = @resource[:path]
    @property_hash[:ssl]         = @resource[:ssl]

    exists? ? (return true) : (return false)
  end

  def destroy
    inst_cmd = "Import-Module WebAdministration; Remove-Website -Name \"#{@property_hash[:name]}\""
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(inst_cmd)
    raise(resp) unless resp.empty?
    @property_hash.clear
    exists? ? (return false) : (return true)
  end

  iisnames.each do |property, iisname|
    next if property == :ensure
    define_method "#{property}=" do |value|
      @property_flush['itemproperty'][iisname] = value
      @property_hash[property.to_sym] = value
    end
  end

  # These three properties have to be submitted together
  def self.binders
    %w(
      protocol
      ip
      port
      host_header
      ssl
    )
  end

  binders.each do |property|
    define_method "#{property}=" do |value|
      @property_flush['binders'][property] = value
      @property_hash[property.to_sym] = value
    end
  end

  def start
    create unless exists?
    @property_hash[:name]    = @resource[:name]
    @property_flush['state'] = :Started
    @property_hash[:ensure]  = 'started'
  end

  def stop
    create unless exists?
    @property_hash[:name]    = @resource[:name]
    @property_flush['state'] = :Stopped
    @property_hash[:ensure]  = 'stopped'
  end

  def restart
    inst_cmd = [
      'Import-Module WebAdministration',
      "Stop-WebSite -Name \"#{@resource[:name]}\"",
      "Start-WebSite -Name \"#{@resource[:name]}\""
    ]
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(inst_cmd.join('; '))
    raise(resp) unless resp.empty?
  end

  def enabled?
    inst_cmd = "Import-Module WebAdministration; (Get-WebSiteState -Name \"#{@resource[:name]}\").value"
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(inst_cmd).rstrip
    case resp
    when 'Started'
      true
    else
      false
    end
  end

  def flush
    command_array = []
    command_array << 'Import-Module WebAdministration; '
    if @property_flush['state']
      state_cmd = if @property_flush['state'] == :Started
                    'Start-Website'
                  else
                    'Stop-Website'
                  end
      state_cmd += " -Name \"#{@property_hash[:name]}\""
      command_array << state_cmd
    end
    @property_flush['itemproperty'].each do |iisname, value|
      command_array << "Set-ItemProperty -Path \"IIS:\\\\Sites\\#{@property_hash[:name]}\" -Name \"#{iisname}\" -Value \"#{value}\""
    end
    bhash = {}
    unless @property_flush['binders'].empty?
      Puppet::Type::Iis_site::ProviderPowershell.binders.each do |b|
        if @property_flush['binders'].key?(b)
          bhash[b] = @property_flush['binders'][b] unless @property_flush['binders'][b] == 'false'
        else
          bhash[b] = @property_hash[b.to_sym]
        end
      end
      binder_cmd = "Set-ItemProperty -Path \"IIS:\\\\Sites\\#{@property_hash[:name]}\" -Name Bindings -Value @{protocol=\"#{bhash['protocol']}\";bindingInformation=\"#{bhash['ip']}:#{bhash['port']}:#{bhash['host_header']}"
      binder_cmd += '"'
      # Append sslFlags to args is enabled
      binder_cmd += '; sslFlags=0' if bhash['ssl'] && bhash['ssl'] != :false
      binder_cmd += '}'
      command_array << binder_cmd
    end
    resp = Puppet::Type::Iis_site::ProviderPowershell.run(command_array.join('; '))
    raise(resp) unless resp.empty?
  end
end
