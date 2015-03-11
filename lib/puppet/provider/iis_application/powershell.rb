require 'puppet/provider/iispowershell'
require 'json'

Puppet::Type.type(:iis_application).provide(:powershell, :parent => Puppet::Provider::Iispowershell) do

  def initialize(value={})
    super(value)
    @property_flush = {
      'appattrs' => {},
    }
  end

  def self.instances
    inst_cmd = 'Import-Module WebAdministration; Get-WebApplication | Select path, physicalPath, applicationPool, ItemXPath | ConvertTo-JSON'
    app_names = JSON.parse(run(inst_cmd))
    app_names = [app_names] if app_names.is_a?(Hash)
    app_names.collect do |app|
      app_hash            = {}
      app_hash[:name]     = app['path'].gsub(/^\//, '')
      app_hash[:path]     = app['PhysicalPath']
      app_hash[:app_pool] = app['applicationPool']
      app_hash[:site]     = app['ItemXPath'].match(/@name='([a-z0-9_\ ]+)'/i)[1]
      app_hash[:ensure]   = :present
      new(app_hash)
    end
  end

  def self.prefetch(resources)
    apps = instances
    resources.keys.each do |app|
      if provider = apps.find{ |a| a.name == app }
        resources[app].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  mk_resource_methods

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
    fail(resp) if resp.length > 0

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

  def site=(value)
    fail("site is a read-only attribute.")
  end

  def flush
    command_array = []
    command_array << "Import-Module WebAdministration"
    @property_flush['appattrs'].each do |appattr,value|
      command_array << "Set-ItemProperty \"IIS:\\\\Sites\\#{@property_hash[:site]}\\#{@property_hash[:name]}\" #{appattr} #{value}"
    end
    resp = Puppet::Type::Iis_application::ProviderPowershell.run(command_array.join('; '))
    fail(resp) if resp.length > 0
  end

end
