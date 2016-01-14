Facter.add(:iis_version) do
  confine :kernel => :windows
  setcode do
    version = nil
    require 'win32/registry'
    begin
      Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Microsoft\InetStp') do |reg|
        version = reg['VersionString']
        version = version[8..-1]
      end
    rescue Win32::Registry::Error
      nil
    end
    version
  end
end
