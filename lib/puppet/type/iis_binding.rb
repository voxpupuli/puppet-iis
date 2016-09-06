Puppet::Type.newtype(:iis_binding) do
  desc 'create web bindings in iis'
  ensurable

  newparam(:name) do
#    validate do |value|
#      unless value =~ %r{^(\*|(([0-9]){1,3}\.([0-9]){1,3}\.([0-9]){1,3}\.([0-9]){1,3})):\d*:.*$}
#        raise 'Title/Binding must be in the format of "127.0.0.1:80:mywebsite.com". "*" are allowed.'
#      end
#    end
    munge do |value|
      port = @resource.original_parameters[:port]
      ip   = @resource.original_parameters[:ip_address]
      host = @resource.original_parameters[:host_header]
      "#{ip}:#{port}:#{host}"
    end
  end

  newproperty(:site_name) do
  end

  newproperty(:protocol) do
    validate do |value|
      unless value =~ %r{http|https|net.pipe|netmsmq|msmq.formatname}
        raise 'protocol must be http,https,net.pipe,netmsmq or msmq.formatname'
      end
    end
    defaultto 'http'
  end

  newproperty(:port) do
    validate do |value|
      raise 'port must be a number' unless value.to_i
    end
  end

  newproperty(:host_header) do
    defaultto '*'
  end

  newproperty(:ip_address) do
    validate do |value|
      unless value =~ %r{^([0-9]){1,3}\.([0-9]){1,3}\.([0-9]){1,3}\.([0-9]){1,3}$}
        raise 'ip_address is not a valid ip address.'
      end
    end
  end

  newproperty(:ssl_flag) do
  end

  newproperty(:certificate) do
    def insync?(is)
      is.casecmp(should.downcase).zero?
    end
    # TODO: Validate should be a path starting with CERT:\<something>
  end

  autorequire(:iis_site) do
    self[:site_name]
  end
end
