require 'puppet/provider/iispowershell'
require 'rexml/document'
include REXML

Puppet::Type.type(:iis_pool).provide(:powershell, parent: Puppet::Provider::Iispowershell) do
  def initialize(value = {})
    super(value)
    @property_flush = {
      'poolattrs' => {}
    }
  end

  def self.poolattrs
    # If the PS values vary from the Puppet values, like strings to Int32, then use a
    # hash (see pipeline).
    {
      autostart: 'autostart',
      enable_32_bit: 'enable32BitAppOnWin64',
      runtime: 'managedRuntimeVersion',
      pipeline: {
        'managedPipelineMode' => {
          'integrated' => 0,
          'classic'    => 1
        }
      },
      start_mode: {
        'startMode' => {
          'ondemand'      => 0,
          'alwaysrunning' => 1
        }
      },
      rapid_fail_protection: 'failure.rapidFailProtection',
      identitytype: {
        'processModel.identityType' => {
          'localsystem'             => 0,
          'localservice'            => 1,
          'networkservice'          => 2,
          'specificuser'            => 3,
          'applicationpoolidentity' => 4
        }
      },
      username: 'processModel.username',
      password: 'processModel.password',
      idle_timeout: 'processModel.idleTimeout',
      idle_timeout_action: 'processModel.idleTimeoutAction',
      max_processes: 'processModel.maxprocesses',
      max_queue_length: 'queueLength',
      recycle_periodic_minutes: 'recycling.periodicRestart.time',
      recycle_logging: 'recycling.logEventOnRecycle',
      recycle_schedule: 'recycling.periodicRestart.schedule'
    }
  end

  def self.get_recycle_schedule(name)
    # need to get the recycling schedule via Get-ItemProperty for the AppPools
    # as the collection info from the main XML dump is blank (at least on 2008).
    result = run("Import-Module WebAdministration;Get-ItemProperty IIS:\\AppPools\\'#{name}' | Select recycling | ConvertTo-XML -As String -Depth 4 -NoTypeInformation")
    xml = Document.new result
    xml.root.each_element do |object|
      schedule = if !object.elements["Property[@Name='recycling']/Property[@Name='periodicRestart']/Property[@Name='schedule']/Property[@Name='Collection']/Property/Property[@Name='value']"]
                   ''
                 else
                   object.elements["Property[@Name='recycling']/Property[@Name='periodicRestart']/Property[@Name='schedule']/Property[@Name='Collection']/Property/Property[@Name='value']"].text
                 end
      return schedule
    end
  end

  def self.instances
    pools = []
    inst_cmd = 'Import-Module WebAdministration;gci "IIS:\AppPools" | Select * | ConvertTo-Xml -Depth 4 -NoTypeInformation -As String -ErrorAction SilentlyContinue'
    result = run(inst_cmd)
    unless result.empty?
      xml = Document.new result
      xml.root.each_element do |object|
        name = object.elements["Property[@Name='name']"].text
        r_schedule = get_recycle_schedule(name)
        pool_hash = {
          ensure: object.elements["Property[@Name='state']"].text,
          name: name,
          enable_32_bit: object.elements["Property[@Name='enable32BitAppOnWin64']"].text, # .to_s.to_sym || :false,
          runtime: object.elements["Property[@Name='managedRuntimeVersion']"].text,
          pipeline: object.elements["Property[@Name='managedPipelineMode']"].text,
          start_mode: object.elements["Property[@Name='startMode']"].text,
          autostart: object.elements["Property[@Name='autoStart']"].text,
          username: object.elements["Property[@Name='processModel']/Property[@Name='userName']"].text,
          password: object.elements["Property[@Name='processModel']/Property[@Name='password']"].text,
          idle_timeout: object.elements["Property[@Name='processModel']/Property[@Name='idleTimeout']"].text,
          identitytype: object.elements["Property[@Name='processModel']/Property[@Name='identityType']"].text,
          max_processes: object.elements["Property[@Name='processModel']/Property[@Name='maxProcesses']"].text,
          max_queue_length: object.elements["Property[@Name='queueLength']"].text,
          rapid_fail_protection: object.elements["Property[@Name='failure']/Property[@Name='rapidFailProtection']"].text,
          recycle_periodic_minutes: object.elements["Property[@Name='recycling']/Property[@Name='periodicRestart']/Property[@Name='time']"].text,
          recycle_schedule: r_schedule,
          recycle_logging: object.elements["Property[@Name='recycling']/Property[@Name='logEventOnRecycle']"].text
        }
        unless Facter.value(:kernelmajversion) == '6.1'
          pool_hash[:idle_timeout_action] = object.elements["Property[@Name='processModel']/Property[@Name='idleTimeoutAction']"].text
        end
        pools.push(pool_hash)
      end
      pools.map do |pool|
        new(
          ensure: pool[:ensure].downcase,
          name: pool[:name],
          enable_32_bit: pool[:enable_32_bit].downcase,
          runtime: pool[:runtime],
          pipeline: pool[:pipeline].downcase,
          start_mode: pool[:start_mode].downcase,
          autostart: pool[:autostart].downcase,
          username: pool[:username],
          password: pool[:password],
          idle_timeout: pool[:idle_timeout],
          idle_timeout_action: pool[:idle_timeout_action],
          identitytype: pool[:identitytype].downcase,
          max_processes: pool[:max_processes],
          max_queue_length: pool[:max_queue_length],
          rapid_fail_protection: pool[:rapid_fail_protection].downcase,
          recycle_periodic_minutes: pool[:recycle_periodic_minutes],
          recycle_schedule: pool[:recycle_schedule].strip,
          recycle_logging: pool[:recycle_logging]
        )
      end
    end
  end

  def self.prefetch(resources)
    pools = instances
    resources.keys.each do |pool|
      # rubocop:disable Lint/AssignmentInCondition
      if provider = pools.find { |p| p.name == pool }
        resources[pool].provider = provider
      end
    end
  end

  def exists?
    %w(stopped started).include?(@property_hash[:ensure])
  end

  mk_resource_methods

  def create
    inst_cmd = "Import-Module WebAdministration; New-WebAppPool -Name \"#{@resource[:name]}\""
    Puppet::Type::Iis_pool::ProviderPowershell.poolattrs.each do |property, value|
      if property.is_a?(Hash)
        # set variables for the key, downcase the value, get the property value for powershell
        value = value.downcase
        key = property.keys[0]
        property_value = property[key.to_s][value.to_s]
        inst_cmd += ";Set-ItemProperty \"IIS:\\\\AppPools\\#{@resource[:name]}\" #{key} #{property_value}"
      # if the values are an array we set the values with a hash
      elsif value.is_a?(Array)
        alt_key = property.split('.')[0]
        alt_property = property.split('.')[1]
        alt_value = value.join(',')
        alt_hash = "@{#{alt_property}='#{alt_value}'}"
        inst_cmd += ";Set-ItemProperty \"IIS:\\\\AppPools\\#{@resource[:name]}\" -Name #{alt_key} -Value #{alt_hash}"
      elsif property == 'recycling.periodicRestart.schedule'
        inst_cmd += ";Set-ItemProperty \"IIS:\\\\AppPools\\#{@resource[:name]}\" -Name #{property} -Value @{value=\"#{value}\"}"
        elseif @resource[property]
        inst_cmd += "; Set-ItemProperty \"IIS:\\\\AppPools\\#{@resource[:name]}\" #{value} #{@resource[property]}"
      end
    end
    resp = Puppet::Type::Iis_pool::ProviderPowershell.run(inst_cmd)
    Puppet.debug "Creation powershell response was #{resp}"
    @resource.original_parameters.each_key do |k|
      @property_hash[k] = @resource[k]
    end
    @property_hash[:ensure] = :present unless @property_hash[:ensure]

    exists? ? (return true) : (return false)
  end

  def destroy
    inst_cmd = "Import-Module WebAdministration; Remove-WebAppPool -Name \"#{@resource[:name]}\""
    resp = Puppet::Type::Iis_pool::ProviderPowershell.run(inst_cmd)
    raise(resp) unless resp.empty?

    @property_hash.clear
    exists? ? (return false) : (return true)
  end

  poolattrs.each do |property, poolattr|
    define_method "#{property}=" do |value|
      @property_hash[property] = value
      @property_flush['poolattrs'][poolattr] = value
    end
  end

  def restart
    inst_cmd = "Import-Module WebAdministration; Restart-WebAppPool -Name \"#{@resource[:name]}\""
    resp = Puppet::Type::Iis_pool::ProviderPowershell.run(inst_cmd)
    raise(resp) unless resp.empty?
  end

  def start
    create unless exists?
    @property_hash[:name] = @resource[:name]
    @property_flush['state'] = :Started
    @property_hash[:ensure] = 'started'
  end

  def stop
    create unless exists?
    @property_hash[:name] = @resource[:name]
    @property_flush['state'] = :Stopped
    @property_hash[:ensure] = 'stopped'
  end

  def enabled?
    inst_cmd = "Import-Module WebAdministration; (Get-WebAppPoolState -Name \"#{@resource[:name]}\").value"
    resp = Puppet::Type::Iis_pool::ProviderPowershell.run(inst_cmd).rstrip
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
                    'Start-WebAppPool'
                  else
                    'Stop-WebAppPool'
                  end
      state_cmd += " -Name \"#{@property_hash[:name]}\""
      command_array << state_cmd
    end
    @property_flush['poolattrs'].each do |poolattr, value|
      if poolattr.is_a?(Hash)
        # set variables for the key, downcase the value, get the property value for powershell
        value = value.downcase
        key = poolattr.keys[0]
        property_value = poolattr[key.to_s][value.to_s]
        command_array << "Set-ItemProperty \"IIS:\\\\AppPools\\#{@property_hash[:name]}\" #{key} #{property_value}"
      # if the values are an array we set the values with a hash
      elsif value.is_a?(Array)
        alt_key = poolattr.split('.')[0]
        alt_property = poolattr.split('.')[1]
        alt_value = value.join(',')
        alt_hash = "@{#{alt_property}='#{alt_value}'}"
        command_array << "Set-ItemProperty \"IIS:\\\\AppPools\\#{@property_hash[:name]}\" -Name #{alt_key} -Value #{alt_hash}"
      elsif poolattr == 'recycling.periodicRestart.schedule'
        command_array << "Set-ItemProperty \"IIS:\\\\AppPools\\#{@property_hash[:name]}\" -Name #{poolattr} -Value @{value=\"#{value}\"}"
      else
        command_array << "Set-ItemProperty \"IIS:\\\\AppPools\\#{@property_hash[:name]}\" #{poolattr} #{value}"
      end
    end
    resp = Puppet::Type::Iis_pool::ProviderPowershell.run(command_array.join('; '))
    raise(resp) unless resp.empty?
  end
end
