require 'tempfile'

class Puppet::Provider::Iispowershell < Puppet::Provider
  initvars

  commands :powershell =>
    if File.exists?("#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
      "#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
    elsif File.exists?("#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe")
      "#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe"
    else
      'powershell.exe'
    end

  def self.run(command, check = false)
    write_script(command) do |native_path|
      psh = "cmd.exe /c \"\"#{native_path(command(:powershell))}\" #{args} -Command - < \"#{native_path}\"\""
      return %x(#{psh})
    end
  end

  private
  def self.write_script(content, &block)
    Tempfile.open(['puppet-powershell', '.ps1']) do |file|
      file.write(content)
      file.flush
      yield native_path(file.path)
    end
  end

  def self.native_path(path)
    path.gsub(File::SEPARATOR, File::ALT_SEPARATOR)
  end

  def self.args
    '-NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass'
  end

end
