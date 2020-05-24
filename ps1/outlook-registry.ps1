$RegistyPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\options\general"
$DelegateWastebasketStyle= (Get-ItemProperty -path $RegistyPath -Name DelegateWastebasketStyle -ErrorAction SilentlyContinue).DelegateWastebasketStyle
if(!(test-path $RegistyPath))
{
New-Item -path $RegistyPath -Force|out-null
New-ItemProperty -path $RegistyPath -Name 'DelegateWastebasketStyle' -Value '4' -PropertyType DWORD -Force|out-null

}
elseIf(($DelegateWastebasketStyle -ne "4")) 
{
New-ItemProperty -path $RegistyPath -Name 'DelegateWastebasketStyle' -Value '4' -PropertyType DWORD -Force|out-null
}
