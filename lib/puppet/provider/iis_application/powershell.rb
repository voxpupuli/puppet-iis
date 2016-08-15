require 'puppet/provider/iispowershell'
require 'rexml/document'
include REXML

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
    inst_cmd = 'Import-Module WebAdministration; Get-WebApplication | Select Path,PhysicalPath,applicationPool,ItemXPath | ConvertTo-XML -As String -Depth 4 -NoTypeInformation'
    result = run(inst_cmd)
    xml = Document.new result
    xml.root.each_element do |object|
      app_hash = {
        :name     => object.elements["Property[@Name='path']"].text.gsub(%r{^\/}, ''),
        :path     => object.elements["Property[@Name='Collection']/Property/Property[@Name='physicalPath']"].text,
        :app_pool => object.elements["Property[@Name='applicationPool']"].text,
        :site     => object.elements["Property[@Name='ItemXPath']"].text.match(%r{@name='([a-z0-9_\ ]+)'}i)[1],
        :ensure   => :present,
      }
      app_instances.push(app_hash)
    end
    app_instances.map do |app|
      new(
        :ensure   => :present,
        :name     => app[:name],
        :path     => app[:path],
        :app_pool => app[:app_pool],
        :site     => app[:site],
      )
    end
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
      '-Force', "-ErrorVariable err | Out-Null; \$err"
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
