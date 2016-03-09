Puppet::Type.newtype(:iis_pool) do
  desc 'The iis_pool type creates and manages IIS application pools'

  newproperty(:ensure) do
    desc "Whether a pool should be started."

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
  
  newparam(:name, :namevar => true) do
    desc 'This is the name of the application pool'
    validate do |value|
      fail("#{name} is not a valid applcation pool name") unless value =~ /^[a-zA-Z0-9\-\_\.'\s]+$/
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
      fail("#{runtime} must be a float") unless value =~ /^v?\d+\.\d+$/
    end
    munge do |value|
      "v#{value.gsub(/^v/, '').to_f}"
    end
  end

  newproperty(:pipeline) do
    desc 'The pipeline mode for the application pool'
    newvalues(:Integrated, :Classic, :integrated, :classic)
    munge do |value|
      value.capitalize
    end
  end

  def refresh
    if self[:ensure] == :present and (provider.enabled? or self[:ensure] == 'started')
      provider.restart
    else
      debug "Skipping restart; pool is not running"
    end
  end

end
