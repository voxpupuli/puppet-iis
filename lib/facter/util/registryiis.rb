module Facter::Util::Registryiis
  def self.iis_version_string_from_registry
    require 'win32/registry'
    Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Microsoft\InetStp')['VersionString']
  rescue Win32::Registry::Error => e
    Facter.debug "Accessing SOFTWARE\\Microsoft\\InetStp gave an error: #{e}"
    Facter.debug 'IIS is probably not installed'
    nil
  end
end
