# iis_version.rb
Facter.add("iis_version") do
 confine :kernel => :windows
  setcode do
    begin
      psexec = if File.exists?("#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
                 "#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
               elsif File.exists?("#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe")
                "#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe"
               else
                'powershell.exe'
               end

      iis_ver = %x{#{psexec} -ExecutionPolicy ByPass -Command "(Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\InetStp\\ -Name VersionString).VersionString.SubString(8,3)"}
    rescue
      iis_ver = ""
    end

    iis_ver
  end
end
