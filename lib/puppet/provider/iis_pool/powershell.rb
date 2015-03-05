require 'puppet/provider/iispowershell'
require 'json'

Puppet::Type.type(:iis_pool).provide(:powershell, :parent => Puppet::Provider::Iispowershell) do

  def initialize(value={})
    super(value)
    @property_flush = {
      'poolattrs' => {},
    }
  end

  def self.poolattrs
    {
      :enable_32_bit => 'enable32BitAppOnWin64',
      :runtime => 'managedRuntimeVersion',
      :pipeline => 'managedPipelineMode'
    }
  end

  def self.pipelines
    {
      0 => 'Integrated',
      1 => 'Classic'
    }
  end

  def self.instances
    inst_cmd = <<-ps1
Import-Module WebAdministration;
@{"Pools" = @(gci "IIS:\AppPools" | %{
    Get-ItemProperty $_.PSPath | Select Name, State, enable32BitAppOnWin64, managedRuntimeVersion, managedPipelineMode
  }
  )
} | ConvertTo-Json
    ps1
    pool_names = JSON.parse(run(inst_cmd))
    pool_names['Pools'].collect do |pool|
      new({
            :ensure        => pool['state'].downcase,
            :name          => pool['name'],
            :enable_32_bit => ("#{pool['enable32BitAppOnWin64']}".to_sym || :false),
            :runtime       => pool['managedRuntimeVersion'],
            :pipeline      => pool['managedPipelineMode']
          })
    end
  end

  def self.prefetch(resources)
    pools = instances
    resources.keys.each do |pool|
      if provider = pools.find { |p| p.name == pool }
        resources[pool].provider = provider
      end
    end
  end

  def exists?
    ['stopped', 'started'].include?(@property_hash[:ensure])
  end

  mk_resource_methods

  def create
    inst_cmd = "Import-Module WebAdministration; New-WebAppPool -Name \"#{@resource[:name]}\""
    Puppet::Type::Iis_pool::ProviderPowershell.poolattrs.each do |property, value|
      inst_cmd += "; Set-ItemProperty \"IIS:\\\\AppPools\\#{@resource[:name]}\" #{value} #{@resource[property]}" if @resource[property]
    end
    resp = Puppet::Type::Iis_pool::ProviderPowershell.run(inst_cmd)

    @resource.original_parameters.each_key do |k|
      @property_hash[k] = @resource[k]
    end
    @property_hash[:ensure] = :present unless @property_hash[:ensure]

    exists? ? (return true) : (return false)
  end

  def destroy
    inst_cmd = "Import-Module WebAdministration; Remove-WebAppPool -Name \"#{@resource[:name]}\""
    resp = Puppet::Type::Iis_pool::ProviderPowershell.run(inst_cmd)
    fail(resp) if resp.length > 0

    @property_hash.clear
    exists? ? (return false) : (return true)
  end

  Puppet::Type::Iis_pool::ProviderPowershell.poolattrs.each do |property, poolattr|
    define_method "#{property}=" do |value|
      @property_flush['poolattrs'][poolattr] = value
      @property_hash[property] = value
    end
  end

  def restart
    inst_cmd = "Import-Module WebAdministration; Restart-WebAppPool -Name \"#{@resource[:name]}\""
    resp = Puppet::Type::Iis_pool::ProviderPowershell.run(inst_cmd)
    fail(resp) if resp.length > 0
  end

  def start
    create if !exists?
    @property_hash[:name] = @resource[:name]
    @property_flush['state'] = :Started
    @property_hash[:ensure] = 'started'
  end

  def stop
    create if !exists?
    @property_hash[:name] = @resource[:name]
    @property_flush['state'] = :Stopped
    @property_hash[:ensure] = 'stopped'
  end


  def enabled?
    inst_cmd = "Import-Module WebAdministration; (Get-WebAppPoolState -Name \"#{@resource[:name]}\").value"
    resp = Puppet::Type::Iis_pool::ProviderPowershell.run(inst_cmd).rstrip
    if resp == 'Started'
      return true
    else
      return false
    end
  end

  def flush
    command_array = []
    command_array << "Import-Module WebAdministration; "
    if @property_flush['state']
      if @property_flush['state'] == :Started
        state_cmd = 'Start-WebAppPool'
      else
        state_cmd = 'Stop-WebAppPool'
      end
      state_cmd += " -Name \"#{@property_hash[:name]}\""
      command_array << state_cmd
    end
    @property_flush['poolattrs'].each do |poolattr, value|
      command_array << "Set-ItemProperty \"IIS:\\\\AppPools\\#{@property_hash[:name]}\" #{poolattr} #{value}"
    end
    resp = Puppet::Type::Iis_pool::ProviderPowershell.run(command_array.join('; '))
    fail(resp) if resp.length > 0
  end

end
