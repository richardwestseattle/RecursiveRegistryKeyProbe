#Declare a global arraylist to which the recursive function below can append values.
$global:RegKeyFields = "KeyName","ValueName","Value";
[System.Collections.ArrayList]$global:RegKeysArray  = $RegKeyFields;

#RegOpenInitialKey does not need to be a separate function, but for the sake of organizaiton, I have separated it from the main body of the script.
Function RegOpenInitialKey($ComputerName, $RegPath)
{
    $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
    $RegKey= $Reg.OpenSubKey($RegPath);
    RecursiveRegKey -Key $RegKey

    $Reg.Close();
}

Function RecursiveRegKey($Key)
{
    #If it has no subkeys, retrieve the values and append to them to the global array. 
    if($Key.SubKeyCount-eq 0)
    {
        Foreach($value in $Key.GetValueNames())
        {
            if($Key.GetValue($value) -ne $null)
            {
                $item = New-Object psobject;
                $item | Add-Member -NotePropertyName "KeyName" -NotePropertyValue $Key.Name;
                $item | Add-Member -NotePropertyName "ValueName" -NotePropertyValue $value.ToString();
                $item | Add-Member -NotePropertyName "Value" -NotePropertyValue $Key.GetValue($value);
                $RegKeysArray.Add($item);
            }        
        }
    }
    else
    {   if($Key.ValueCount -gt 0)
        {
            Foreach($value in $Key.GetValueNames())
            {
                if($Key.GetValue($value) -ne $null)
                {
                    $item = New-Object PSObject;
                    $item | Add-Member -NotePropertyName "KeyName" -NotePropertyValue $Key.Name;
                    $item | Add-Member -NotePropertyName "ValueName" -NotePropertyValue $value.ToString();
                    $item | Add-Member -NotePropertyName "Value" -NotePropertyValue $Key.GetValue($value);
                    $RegKeysArray.Add($item);
                }     
            }
        }
        #Recursive lookup happens here. If the key has subkeys, send the key(s) back to this same function.
        if($Key.SubKeyCount -gt 0)
        {
            ForEach($subKey in $Key.GetSubKeyNames())
            {
                RecursiveRegKey -Key $Key.OpenSubKey($subKey);
            }
        }
    }
}

#Replace the value following ComputerName to fit your needs. This works, and is most useful, when scanning remote computers.
RegOpenInitialKey -ComputerName "$($env:computername)" -RegPath "HARDWARE\DESCRIPTION" | Out-Null

#Write the output to the console.
$RegKeysArray | Select-Object KeyName, ValueName, Value | Sort-Object ValueName | Format-Table