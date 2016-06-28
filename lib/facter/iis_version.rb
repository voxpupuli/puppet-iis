require 'facter/util/registryiis'

Facter.add(:iis_version) do
  confine :kernel => :windows # rubocop:disable Style/HashSyntax
  setcode do
    iis_version_string = Facter::Util::Registryiis.iis_version_string_from_registry
    # String returned on:
    # Windows 2012 R2 - "Version 8.5"
    # Windows 2008 R2 - "Version 7.5"
    # Lets gsub to get just the number
    iis_version_string.gsub(%r{Version\s+}, '') unless iis_version_string.nil?
  end
end
