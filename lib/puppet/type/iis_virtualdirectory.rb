Puppet::Type.newtype(:iis_virtualdirectory) do
  desc 'The iis_virtualdirectory type creates and manages IIS virtual directories'
  ensurable

  newparam(:name, namevar: true) do
    desc 'This is the name of the virtual directory'
    validate do |value|
      raise("#{value} is not a valid virtual directory name") unless value =~ %r{^[a-zA-Z0-9\-\_\/\s]+$}
    end
  end

  newproperty(:path) do
    desc 'Path to the web site folder'
    validate do |value|
      raise("File paths must be fully qualified, not '#{value}'") unless value =~ %r{^.:(\/|\\)} || value =~ %r{^\/\/[^\/]+\/[^\/]+}
    end
  end

  newparam(:site, namevar: true) do
    desc 'The site in which this virtual directory exists'
    validate do |value|
      raise("#{site} is not a valid site name") unless value =~ %r{^[a-zA-Z0-9\-\_\/\s]+$}
    end
  end

  # Our title_patterns method for mapping titles to namevars for supporting
  # composite namevars.
  def self.title_patterns
    [
      [
        /^([^:]+)$/m,
        [
          [ :name ]
        ]
      ],
      [
        /^(.*):(.*)$/,
        [
          [ :site ],
          [ :name ]
        ]
      ]
    ]
  end

  autorequire(:iis_site) do
    self[:site] if @parameters.include? :site
  end
end
