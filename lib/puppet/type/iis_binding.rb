Puppet::Type.newtype(:iis_binding) do
  desc 'create web bindings in iis'
  ensurable

  newparam(:binding, namevar: true) do
    validate do |value|
      unless value =~ %r{^(\*|(([0-9]){1,3}\.([0-9]){1,3}\.([0-9]){1,3}\.([0-9]){1,3})):\d*:.*$}
        raise 'Title/Binding must be in the format of "127.0.0.1:80:mywebsite.com". "*" are allowed.'
      end
    end
  end

  newparam(:ensure) do
  end

  newproperty(:site_name) do
  end

  newproperty(:protocol) do
    validate do |value|
      unless value =~ %r{http|https|net.pipe|netmsmq|msmq.formatname}
        raise 'protocol must be http,https,net.pipe,netmsmq or msmq.formatname'
      end
    end
  end

  newproperty(:port) do
    validate do |value|
      raise 'port must be a number' unless value.to_i
    end
  end

  newproperty(:host_header) do
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
      is.downcase == should.downcase
    end
    #TODO: Validate should be a path starting with CERT:\<something>
  end

  autorequire(:iis_site) do
    self[:site_name]
  end

end
