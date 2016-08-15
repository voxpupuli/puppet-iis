Puppet::Type.newtype(:iis_pool) do
  desc 'The iis_pool type creates and manages IIS application pools'

  newproperty(:ensure) do
    desc 'Whether a pool should be started.'

    newvalue(:stopped) do
      provider.stop
    end

    newvalue(:started) do
      provider.start
    end

    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end

    aliasvalue(:false, :stopped)
    aliasvalue(:true, :started)
  end

  newparam(:name, namevar: true) do
    desc 'This is the name of the application pool'
    validate do |value|
      raise("#{name} is not a valid applcation pool name") unless value =~ %r{^[a-zA-Z0-9\-\_\.'\s]+$}
    end
  end

  newproperty(:enable_32_bit) do
    desc 'If 32-bit is enabled for the pool'
    newvalues(:false, :true)
    defaultto :false
  end

  newproperty(:runtime) do
    desc '.NET runtime version for the pool'
    validate do |value|
      raise("#{runtime} must be a float") unless value =~ %r{^v?\d+\.\d+$}
    end
    munge do |value|
      "v#{value.gsub(%r{^v}, '').to_f}"
    end
  end

  newproperty(:pipeline) do
    desc 'The pipeline mode for the application pool'
    newvalues(%r{integrated|classic}i)
  end

  ## NEW APP POOL SETTINGS
  newproperty(:autostart) do
    desc 'Set the autostart property.'
    newvalues(:false, :true)
    defaultto(:true)
  end

  newproperty(:start_mode) do
    desc 'The start mode for the app pool.'
    newvalues(%r{ondemand|alwaysrunning}i)
  end

  newproperty(:rapid_fail_protection) do
    desc 'Set the rapid fail protection property.'
    newvalues(:false, :true)
    defaultto(:true)
  end

  newproperty(:identitytype) do
    desc 'Set the identity type'
    newvalues(%r{localsystem|localservice|networkservice|specificuser|applicationpoolidentity}i)
  end

  newproperty(:username) do
    desc 'set a username'
  end

  newproperty(:password) do
    desc 'set a password'
  end

  newproperty(:idle_timeout) do
    desc 'set the idle timeout'
    validate do |value|
      unless
        value =~ %r{^(?:(?:([01]?\d|2[0-3]):)?([0-5]?\d):)?([0-5]?\d)$}
        raise 'idle_timeout must be formatted as HH::MM::SS'
      end
    end
  end

  newproperty(:idle_timeout_action) do
    # property does not exists in Win2008r2?
    desc 'set the default idle timeout action'
    newvalues(%r{suspend|terminate}i)
  end

  newproperty(:max_processes) do
    desc 'set max processes'
  end

  newproperty(:max_queue_length) do
    desc 'set max queue length'
  end

  newproperty(:recycle_periodic_minutes) do
    desc 'recycle an app pool after an elapsed amount of time'
    validate do |value|
      unless
        value =~ %r{^([1-7].|[0][0-7].)(?:(?:([01]?\d|2[0-3]):)([0-5]?\d):)([0-5]?\d)$}
        raise 'recycle_periodic_minutes must take the format of D.HH:MM:SS'
      end
    end
  end

  newproperty(:recycle_schedule) do
    desc 'recycle the app pool at a scheduled time'
    validate do |value|
      unless
        value =~ %r{^(?:(?:([01]?\d|2[0-3]):)?([0-5]?\d):)?([0-5]?\d)$}
        raise 'recycle_schedule must be formatted as HH::MM::SS'
      end
    end
  end

  newproperty(:recycle_logging, array_matching: :all) do
    desc 'enable recycle logging'
    # Regex strings for case sensitivity and easier array handling
    newvalues(%r{time|memory|requests|schedule|isapiunhealthy|configchange|privatememory}i)
    # this must be an array
    validate do |value|
      raise 'recycle_logging must be an Array' unless value.split(',').is_a?(Array)
    end
    # the sorted property array must match the sorted resource array
    def insync?(is)
      is = is.to_s.split(',')
      is.sort == should.sort
    end
    munge do |value|
      # these values must match the right case to be accepted
      # by Powershell.
      # TODO THESE MUST SORT BY MICROSOFTS ORDER OF THINGS.
      case value
      when %r{isapiunhealthy}i
        'IsapiUnhealthy'
      when %r{configchange}i
        'ConfigChange'
      when %r{privatememory}i
        'PrivateMemory'
      else
        value.capitalize
      end
    end
  end

  def refresh
    if self[:ensure] == :present && (provider.enabled? || self[:ensure] == 'started')
      provider.restart
    else
      debug 'Skipping restart; pool is not running'
    end
  end
end
