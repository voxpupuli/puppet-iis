require 'puppet/provider/iispowershell'
require 'json'

Puppet::Type.type(:iis_virtualdirectory).provide(:powershell, parent: Puppet::Provider::Iispowershell) do
  def initialize(value = {})
    super(value)
    @property_flush = {
      'vdattrs' => {}
    }
  end

  def self.instances
    virtual_directories = []
    inst_cmd = 'Import-Module WebAdministration; Get-WebVirtualDirectory | Select path, physicalPath, ItemXPath | ConvertTo-JSON -Depth 4'
    result = run(inst_cmd)
    unless result.empty?
      vd_names = JSON.parse(result)
      vd_names = [vd_names] if vd_names.is_a?(Hash)
      vd_names.each do |vd|
        vd_hash = {}
        vd_hash[:name] = vd['path'].gsub(%r{^\/}, '')
        vd_hash[:path] = vd['physicalPath']
        vd_hash[:site] = vd['ItemXPath'].match(%r{@name='([a-z0-9_\ ]+)'}i)[1]
        vd_hash[:ensure] = :present
        virtual_directories << new(vd_hash)
      end
    end

    virtual_directories
  end

  def self.prefetch(resources)
    vds = instances
    resources.keys.each do |vd|
      # rubocop:disable Lint/AssignmentInCondition
      if provider = vds.find { |v| v.name == vd }
        resources[vd].provider = provider
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
      "New-WebVirtualDirectory -Name \"#{@resource[:name]}\"",
      "-PhysicalPath \"#{@resource[:path]}\"",
      "-Site \"#{@resource[:site]}\"",
      '-Force'
    ]
    resp = Puppet::Type::Iis_virtualdirectory::ProviderPowershell.run(inst_cmd.join(' '))
    Puppet.debug "Creation powershell response was #{resp}"

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
    resp = Puppet::Type::Iis_virtualdirectory::ProviderPowershell.run(inst_cmd.join(' '))
    raise(resp) unless resp.empty?

    @property_hash.clear
    exists? ? (return false) : (return true)
  end

  def path=(value)
    @property_flush['vdattrs']['physicalPath'] = value
    @property_hash[:path] = value
  end

  def site=(_value)
    raise('site is a read-only attribute.')
  end

  def flush
    command_array = []
    command_array << 'Import-Module WebAdministration'
    @property_flush['vdattrs'].each do |vdattr, value|
      command_array << "Set-ItemProperty \"IIS:\\\\Sites\\#{@property_hash[:site]}\\#{@property_hash[:name]}\" #{vdattr} #{value}"
    end
    resp = Puppet::Type::Iis_virtualdirectory::ProviderPowershell.run(command_array.join('; '))
    raise(resp) unless resp.empty?
  end
end
