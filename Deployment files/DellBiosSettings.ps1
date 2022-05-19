function Get-RandomPassword {
    param (
        [Parameter(Mandatory)]
        [ValidateRange(4,[int]::MaxValue)]
        [int] $length,
        [int] $upper = 1,
        [int] $lower = 1,
        [int] $numeric = 1,
        [int] $special = 1
    )
    if($upper + $lower + $numeric + $special -gt $length) {
        throw "number of upper/lower/numeric/special char must be lower or equal to length"
    }
    $uCharSet = "ABCDEFGHJKLMNOPQRSTUVWXYZ"
    $lCharSet = "abcdefghijkmnopqrstuvwxyz"
    $nCharSet = "123456789"
    $sCharSet = "/*-+,!?=()@;:._"
    $charSet = ""
    if($upper -gt 0) { $charSet += $uCharSet }
    if($lower -gt 0) { $charSet += $lCharSet }
    if($numeric -gt 0) { $charSet += $nCharSet }
    if($special -gt 0) { $charSet += $sCharSet }
    
    $charSet = $charSet.ToCharArray()
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[]($length)
    $rng.GetBytes($bytes)
 
    $result = New-Object char[]($length)
    for ($i = 0 ; $i -lt $length ; $i++) {
        $result[$i] = $charSet[$bytes[$i] % $charSet.Length]
    }
    $password = (-join $result)
    $valid = $true
    if($upper   -gt ($password.ToCharArray() | Where-Object {$_ -cin $uCharSet.ToCharArray() }).Count) { $valid = $false }
    if($lower   -gt ($password.ToCharArray() | Where-Object {$_ -cin $lCharSet.ToCharArray() }).Count) { $valid = $false }
    if($numeric -gt ($password.ToCharArray() | Where-Object {$_ -cin $nCharSet.ToCharArray() }).Count) { $valid = $false }
    if($special -gt ($password.ToCharArray() | Where-Object {$_ -cin $sCharSet.ToCharArray() }).Count) { $valid = $false }
 
    if(!$valid) {
         $password = Get-RandomPassword $length $upper $lower $numeric $special
    }
    return $password
}

$bios_admin_pwd = Get-RandomPassword 15 3 3 3 3
$bios_system_pwd = Get-RandomPassword 20 3 3 3 3
$computer_Serial = wmic bios get serialnumber

"Admin_PWD: $bios_admin_pwd, System PWD: $bios_system_pwd" | out-file -filepath Z:\BiosPWD\$computer_Serial.txt -append -width 200

cd "C:\Program Files (x86)\Dell\Command Configure\X86_64\"
.\cctk.exe --secureboot=enable
.\cctk.exe --AdminSetupLockout=enable
.\cctk.exe --AllowBiosDowngrade=Disable
.\cctk.exe --ChasIntrusion=Enabled

.\cctk.exe --SetupPwd=$bios_admin_pwd
.\cctk.exe --SysPwd=$bios_system_pwd
 
