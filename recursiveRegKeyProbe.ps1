<#PSScriptInfo
 
.VERSION 1.0.0
 
.GUID 
 
.AUTHOR Richard West
 
.COMPANYNAME
 
.COPYRIGHT
 
.TAGS
 
.LICENSEURI
 
.PROJECTURI 'https://github.com/richardwestseattle/RecursiveRegistryKeyProbe'
 
.ICONURI
 
.EXTERNALMODULEDEPENDENCIES
 
.REQUIREDSCRIPTS
 
.EXTERNALSCRIPTDEPENDENCIES
 
.RELEASENOTES
 
 
#>

<#
 
.DESCRIPTION
 Recursively probe registry key's sub-key's and values and output a sorted array.
 
#> 

Function RecursiveRegKey()
{
    param
        (
        [Parameter(Mandatory=$true)]
        [String]$ComputerName,

        [Parameter(Mandatory=$true)]
        [String]$RegPath
        )

    #Declare an arraylist to which the recursive function below can append values.
    $RegKeyFields = "KeyName","ValueName","Value";
    [System.Collections.ArrayList]$global:RegKeysArray  = $RegKeyFields;

    $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
    $RegKey= $Reg.OpenSubKey($RegPath);

    Function DigThroughKeys()
    {
        param (

            [Parameter(Mandatory=$true)]
            [AllowNull()]
            [AllowEmptyString()]
            [Microsoft.Win32.RegistryKey]$Key
            )

        #If it has no subkeys, retrieve the values and append to them to the global array. 
        if($Key.SubKeyCount-eq 0)
        {
            Foreach($value in $Key.GetValueNames())
            {
                if($null -ne $Key.GetValue($value))
                {
                    $item = New-Object psobject;
                    $item | Add-Member -NotePropertyName "KeyName" -NotePropertyValue $Key.Name;
                    $item | Add-Member -NotePropertyName "ValueName" -NotePropertyValue $value.ToString();
                    $item | Add-Member -NotePropertyName "Value" -NotePropertyValue $Key.GetValue($value);
                    [void]$RegKeysArray.Add($item);
                }
            }
        }
        else
        {
            if($Key.ValueCount -gt 0)
            {
                Foreach($value in $Key.GetValueNames())
                {
                    if($null -ne $Key.GetValue($value))
                    {
                        $item = New-Object PSObject;
                        $item | Add-Member -NotePropertyName "KeyName" -NotePropertyValue $Key.Name;
                        $item | Add-Member -NotePropertyName "ValueName" -NotePropertyValue $value.ToString();
                        $item | Add-Member -NotePropertyName "Value" -NotePropertyValue $Key.GetValue($value);
                        [void]$RegKeysArray.Add($item);
                    }
                }
            }
            #Recursive lookup happens here. If the key has subkeys, send the key(s) back to this same function.
            if($Key.SubKeyCount -gt 0)
            {
                ForEach($subKey in $Key.GetSubKeyNames())
                {
                    DigThroughKeys -Key $Key.OpenSubKey($subKey);
                }
            }
        }
    }

    #Replace the value following ComputerName to fit your needs. This works, and is most useful, when scanning remote computers.
    DigThroughKeys -Key $RegKey

    #Write the output to the console.
    $RegKeysArray | Select-Object KeyName, ValueName, Value | Sort-Object ValueName | Format-Table

    $Reg.Close();
}
