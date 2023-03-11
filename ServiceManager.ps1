# powershell -executionpolicy bypass -File .\ServiceManager.ps1 <operation> <service_name (optional) >
# script arguments
param ($operation, $Service_Name)

Function List_Services {
    $Json_String = Get-Content -Path ./service-definition.json
    $Services = $Json_String | ConvertFrom-Json
    ForEach ($service in $Services) {
        $Process_Id = Process_Id($Service.name)
        Write-Output ($Service.name + "  [" + $Process_Id + "]")

    }
}

Function Restart_Process {
    Param($Service_Name)
    Terminate_Process($Service_Name)
    Begin_Process($Service_Name)
}

Function Begin_Process {
    param($Service)

    # read from the service definition file amd get the JSON object specific to this service (if it exists)
    $Json_String = Get-Content -Path ./service-definition.json
    $Services = $Json_String | ConvertFrom-Json

    ForEach ($_Service in $Services) {
        if ($_Service.name -eq $Service) {
            $ArgsArray = [Collections.Generic.List[String]]::new()
            ForEach ($a in $_Service.argsList) {
                $ArgsArray.Add([String] $a)
            }
            $id = (Start-Process -NoNewWIndow -FilePath $_Service.executablePath -ArgumentList $ArgsArray -RedirectStandardError $_Service.redirectStandardErrorPath -RedirectStandardOutput $_Service.redirectStandardOutputPath -passthru).ID
            Write-Output ("Starting " + $Service + " on Process ID : " + $id)
            Set-Content -Path ./$Service.pid -Value $id
        } else {
            Write-Output("Unknown Service : " + $Service)
        }
    }
}


Function Terminate_Process {
    Param ($Service_Name)
    $Process_Id = Process_Id($Service_Name)
    if ($Process_Id -ne "-") {
        Write-Output("[INFO] Stopping process : " + $Process_Id)
        Stop-Process -Id $Process_Id
    }
    Get-Process | Where-Object {$_.HasExited}
    Reset_Process_Id($Service_Name)
}

Function Process_Id {
    Param($Service_Name)
    $Process_Id = Get-Content -Path ./$Service_Name.pid
    Return $Process_Id
}

Function Reset_Process_id {
    param($Service_Name)
    Set-Content -Path ./$Service_Name.pid -Value "-"
}

Function Show_Default {
    Write-Output("Unknown operation or operation not defined")
}

if ($operation -eq "list") {
    List_Services
}
elseif ($Operation -eq "start") {
    Begin_Process ($Service_Name)
}
elseif ($Operation -eq "restart") {
    Restart_Process ($Service_Name)
}
elseif ($Operation -eq "stop") {
    Terminate_Process($Service_Name)
}
else {
    Show_Default
}