#
class iis::param::powershell {
  $executable = 'powershell.exe'
  $exec_policy = '-ExecutionPolicy RemoteSigned'
  $path = 'C:\Windows\sysnative\WindowsPowershell\v1.0'

  $command = "${executable} ${exec_policy}"
}