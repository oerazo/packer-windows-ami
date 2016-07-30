#Get json file which has to be passed as a parameter when calling this file from cmd
param ($json)

#Read json file
$data = (Get-Content $json -Raw)| ConvertFrom-Json

#Get location from the json config to download the software
$global:swDestination = $data.config.downloadLocation

Add-Type -AssemblyName  System.IO.Compression.FileSystem

New-Item $swDestination -ItemType Directory -Force

<#
    .DESCRIPTION
        Downloads binary windows file and adds path to env variable 

    .PARAMETER $source 
        The url to install the exe or msi package, make sure this is a reliable source, i.e windows
    .PARAMETER $name
        The name of the software to install with no spaces , example jdk7
    .PARAMETER $description
        The description of the software being installed
    .PARAMETER $path
        Sometimes it is necessary to add a path to the PATH env, use this variable to set such value if required
    .PARAMETER $downloadOnlyTo
        When you do not need to install the software but download the exe only 
    .EXAMPLE

    .NOTES
        Sometimes applications are already packaged in a binary file and dont need an installer.
#>
function downloadOnly ($source, $name, $description, $path, $downloadOnlyTo ) {
    try {
         #Get the file type to be downloaded
        $type = [System.IO.Path]::GetExtension($source)
        #Get the name of the file to be downloaded, it will be used to create a folder that matches the version being downloaded
        $folderName = [System.IO.Path]::GetFileNameWithoutExtension($source)
        Write-Host "Type : $type"
        New-Item "$downloadOnlyTo"  -ItemType Directory -Force
        $destination = "$downloadOnlyTo$name$type"
        $client = new-object System.Net.WebClient
        Write-Host "Downloading $description ..."
        $client.downloadFile($source, $destination)
        try {
            if ($type -eq ".zip") {
                Write-Host "file format is zip, unzipping ..."
                $path = "$path\$folderName\bin" 
                #[System.IO.Compression.ZipFile]::ExtractToDirectory($destination, $downloadOnlyTo) 
                ExtractZip $destination $downloadOnlyTo                            
            }
            Write-Host "Setting up path $description"
            addPath $path        
            Write-Host "$description is ready."  
        } catch [System.Exception] {
            Write-Host "$(Get-Date -f $TimestampFormat) - Failed setting up path for $name : $_.Exception.Message;"
            exit 1
        }
    } catch  [System.Exception] {
         Write-Host "$(Get-Date -f $TimestampFormat) - Failed Downloading $description : $_.Exception.Message;"
        exit 1
    }

}

<#
    .DESCRIPTION
        Installs software based on configuration values passed as  a parameter 

    .PARAMETER $source 
        The url to install the exe or msi package, make sure this is a reliable source, i.e windows
    .PARAMETER $name
        The name of the software to install with no spaces , example jdk7
    .PARAMETER $description
        The description of the software being installed
    .PARAMETER $arguments
        Every windows package or exe has a set of switches that can be used, those can be passed as arguments
    .PARAMETER $path
        Sometimes it is necessary to add a path to the PATH env, use this variable to set such value if required
    .PARAMETER $cookie
        Oracle for example, uses a cookie that makes sure users agree to their policies before downloading software 
    .PARAMETER $type
        When the origin url does not provide the file type to be downloaded, then we should specify the type, 
        an example of an url that does not provide type is https://go.microsoft.com/fwlink/?LinkId=532606&clcid=0x409
    .PARAMETER $executeAfter
        In case you need to execute a cmd after install, for example for localdb you might want to start a local instance  
    .EXAMPLE

    .NOTES
    The previous parameters are read from a json configuration file that is passed when calling this powershell.
#>
function installSoftware($source, $name, $description, $arguments, $path, $cookie, $type, $executeAfter ) {
     try {
        
        #If type is not provided in the json config file, get it from the url 
        if (!$type) {
            $type = [System.IO.Path]::GetExtension($source)
        }

        New-Item "$swDestination\$name"  -ItemType Directory -Force
        $destination = "$swDestination\$name\$name$type"
        write-host $destination
        $client = new-object System.Net.WebClient
        if ($cookie) {
            $client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie)
        }
       
        Write-Host "Downloading $description ..."
        $client.downloadFile($source, $destination)
         try {
            Write-Host "Installing $description ..."
 
            $proc1 = Start-Process -FilePath "$destination" -ArgumentList "$arguments" -Wait -PassThru
            $proc1.waitForExit()
            if ($path) {
                Write-Host "setting up path for $description ..."
                addPath $path
            }
            Write-Host "$description has been successfully installed"
            if ($executeAfter) {
               iex $executeAfter
            }
            
        } catch [System.Exception] {
            Write-Host "$(Get-Date -f $TimestampFormat) - Failed installing $description : $_.Exception.Message;"
            exit 1
        }
    } catch  [System.Exception] {
         Write-Host "$(Get-Date -f $TimestampFormat) - Failed Downloading $description : $_.Exception.Message;"
        exit 1
    }
}

<#
    .DESCRIPTION
        Adds a path into the windows PATH environment var
    .PARAMETER $AddedFolder
        the path location to add so that windows can find the binaries of particular programs
    .NOTES
        Adding the path is not required for all programs, 
        unfortunally this is something you have to find by installing the program manually first
#>
function addPath($AddedFolder) {
    $environmentRegistryKey = 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment'
    $oldPath = (Get-ItemProperty -Path $environmentRegistryKey -Name PATH).Path
    $newPath = $oldPath + ';' + $AddedFolder
    Set-ItemProperty -Path $environmentRegistryKey -Name PATH -Value $newPath
}

<#
    .DESCRIPTION
        Extract a compressed file
    .PARAMETER $file
        the location of the zip file
    .PARAMETER $destination
        Where you want to uncompress the file
    .NOTES
        If the destination already exists, the files will be replaced.
#>
function ExtractZip($file, $destination) {
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items()){
        $shell.Namespace($destination).copyhere($item,16)
    }
}

#Walk json configuration structure to find out what programs to install
foreach($application in $data.software) {  
    
    if ($application.downloadOnlyTo) {
        downloadOnly $application.url $application.name $application.description $application.path $application.downloadOnlyTo
    } else {
        installSoftware $application.url $application.name $application.description $application.arguments $application.path $application.cookie $application.type $application.executeAfter
    }
}

#Remove folder that contains downloaded applications
Remove-Item  $swDestination  -Recurse -Force
