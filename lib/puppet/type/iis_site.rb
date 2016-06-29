Puppet::Type.newtype(:iis_site) do
  desc 'The iis_site type creates and manages IIS Web Sites'

  newproperty(:ensure) do
    desc 'Whether a site should be started.'

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
    desc 'This is the name of the web site'
    validate do |value|
      raise("#{name} is not a valid web site name") unless value =~ %r{[a-zA-Z0-9\-\_'\s]+$}
    end
  end

  newproperty(:path) do
    desc 'Path to the web site folder'
    validate do |value|
      raise("File paths must be fully qualified, not '#{value}'") unless value =~ %r{.:(\/|\\)} || value =~ %r{\/\/[^\/]+\/[^\/]+}
    end
  end

  newproperty(:app_pool) do
    desc 'Application pool for the site'
    validate do |value|
      raise("#{app_pool} is not a valid application pool name") unless value =~ %r{[a-zA-Z0-9\-\_'\s]+$}
    end
    defaultto :DefaultAppPool
  end

  newproperty(:host_header) do
    desc 'Host header for the site'
    validate do |value|
      raise("#{host_header} is not a valid application pool name") unless value =~ %r{[a-zA-Z0-9\-\_'\.\s]+$} || value == :false
    end
  end

  newproperty(:protocol) do
    desc 'Protocol for the site'
    validate do |value|
      raise("#{protcol} is not a valid application pool name") unless value =~ %r{[a-z]+$}
    end
  end

  newproperty(:ip) do
    desc 'IP Address for the web site'

    def valid_v4?(addr)
      if %r{(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$} =~ addr
        return $LAST_MATCH_INFO.captures.all? do |i|
          i = i.to_i
          i >= 0 && i <= 255
        end
      end
      false
    end

    def valid_v6?(addr)
      # http://forums.dartware.com/viewtopic.php?t=452
      # ...and, yes, it is this hard.  Doing it programatically is harder.
      return true if addr =~ %r{\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$}
      false
    end

    validate do |value|
      raise("Invalid IP address #{value.inspect}") unless valid_v4?(value) || valid_v6?(value) || value == '*'
    end
    defaultto '*'
  end

  newproperty(:port) do
    desc 'Port the web site listens on'
    munge(&:to_i)
    validate do |_value|
      # fail('Port must be an integer') unless value =~ /\d+/ || value.is_a? Numeric
    end
    defaultto 80
  end

  newproperty(:ssl) do
    desc 'If ssl is enabled for the site'
    newvalues(:false, :true)
    defaultto :false
  end

  autorequire(:iis_pool) do
    self[:app_pool] if @parameters.include? :app_pool
  end

  def refresh
    if self[:ensure] == :present && (provider.enabled? || self[:ensure] == 'started')
      provider.restart
    else
      debug 'Skipping restart; site is not running'
    end
  end
end
