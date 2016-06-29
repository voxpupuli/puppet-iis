require 'puppet/provider/iispowershell'
require 'json'

Puppet::Type.type(:iis_application).provide(:powershell, parent: Puppet::Provider::Iispowershell) do
  mk_resource_methods

  def initialize(value = {})
    super(value)
    @property_flush = {
      'appattrs' => {}
    }
  end

  def self.instances
    app_instances = []
    inst_cmd = 'Import-Module WebAdministration; Get-WebApplication | Select path, physicalPath, applicationPool, ItemXPath | ConvertTo-JSON -Depth 4'
    result = run(inst_cmd)
    Puppet.debug("WebApplicationResult is empty? #{result.empty?}")
    unless result.empty?
      app_names = JSON.parse(result)
      # Powershell returns different data structure if length >1
      app_names = [app_names] if app_names.is_a?(Hash)
      app_names.each do |app|
        app_hash = {}
        Puppet.debug("Parsing result for #{app}")
        app_hash[:name] = app['path'].gsub(%r{^\/}, '')
        app_hash[:path] = app['PhysicalPath']
        app_hash[:app_pool] = app['applicationPool']
        app_hash[:site] = app['ItemXPath'].match(%r{@name='([a-z0-9_\ ]+)'}i)[1]
        app_hash[:ensure] = :present
        app_instances << new(app_hash)
      end
    end

    app_instances
  end

  def self.prefetch(resources)
    apps = instances
    resources.keys.each do |app|
      # rubocop:disable Lint/AssignmentInCondition
      if provider = apps.find { |a| a.name == app }
        resources[app].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    inst_cmd = [
      'Import-Module WebAdministration; ',
      "New-WebApplication -Name \"#{@resource[:name]}\"",
      "-PhysicalPath \"#{@resource[:path]}\"",
      "-Site \"#{@resource[:site]}\"",
      "-ApplicationPool \"#{@resource[:app_pool]}\"",
      '-Force'
    ]
    resp = Puppet::Type::Iis_application::ProviderPowershell.run(inst_cmd.join(' '))
    raise(resp) unless resp.empty?

    @resource.original_parameters.each_key do |k|
      @property_hash[k] = @resource[k]
    end
    @property_hash[:ensure] = :present unless @property_hash[:ensure]

    exists? ? (return true) : (return false)
  end

  def destroy
    inst_cmd = [
      'Import-Module WebAdministration; ',
      'Remove-Item',
      "\"IIS:\\Sites\\#{@property_hash[:site]}\\#{@property_hash[:name]}\"",
      '-Force -Recurse'
    ]
    resp = Puppet::Type::Iis_application::ProviderPowershell.run(inst_cmd.join(' '))
    raise(resp) unless resp.empty?

    @property_hash.clear
    exists? ? (return false) : (return true)
  end

  def path=(value)
    @property_flush['appattrs']['physicalPath'] = value
    @property_hash[:path] = value
  end

  def app_pool=(value)
    @property_flush['appattrs']['applicationPool'] = value
    @property_hash[:app_pool] = value
  end

  def site=(_value)
    raise('site is a read-only attribute.')
  end

  def flush
    command_array = []
    command_array << 'Import-Module WebAdministration'
    @property_flush['appattrs'].each do |appattr, value|
      command_array << "Set-ItemProperty \"IIS:\\\\Sites\\#{@property_hash[:site]}\\#{@property_hash[:name]}\" #{appattr} #{value}"
    end
    resp = Puppet::Type::Iis_application::ProviderPowershell.run(command_array.join('; '))
    raise(resp) unless resp.empty?
  end
end
