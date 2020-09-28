if (!( Test-Path "C:\Windows\Temp\7z1900-x64.msi")) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://www.7-zip.org/a/7z1900-x64.msi', 'C:\Windows\Temp\7z1900-x64.msi')
  }
  if (!(Test-Path "C:\Windows\Temp\7z1900-x64.msi")) {
    Start-Sleep 5; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://www.7-zip.org/a/7z1900-x64.msi', 'C:\Windows\Temp\7z1900-x64.msi')
  }
  cmd /c msiexec /qb /i C:\Windows\Temp\7z1900-x64.msi
  
  if ("$env:PACKER_BUILDER_TYPE" -eq "virtualbox-iso") {
      Write-Host "Using Virtualbox"
      if (Test-Path "C:\Users\vagrant\VBoxGuestAdditions.iso") {
          Move-Item -Force C:\Users\vagrant\VBoxGuestAdditions.iso C:\Windows\Temp
      }
  
      if (!(Test-Path "C:\Windows\Temp\VBoxGuestAdditions.iso")) {
          Try {
              $pageContentLinks = (Invoke-WebRequest('https://download.virtualbox.org/virtualbox') -UseBasicParsing).Links | where-object {$_.href -Match "[0-9]"} | Select-Object href |  where-object {$_.href -NotMatch "BETA"} |  where-object {$_.href -NotMatch "RC"} |   where-object {$_.href -Match "[0-9]\.[0-9]"} | % { $_.href.Trim('/') }
              $versionObject = $pageContentLinks | %{ new-object System.Version ($_) } | sort-object -Descending | select-object -First 1 -Property:Major,Minor,Build
              $newestVersion = $versionObject.Major.ToString()+"."+$versionObject.Minor.ToString()+"."+$versionObject.Build.ToString() | out-string
              $newestVersion = $newestVersion.TrimEnd("`r?`n")
  
              $nextURISubdirectoryObject = (Invoke-WebRequest("https://download.virtualbox.org/virtualbox/$newestVersion/") -UseBasicParsing).Links | Select-Object href | where-object {$_.href -Match "GuestAdditions"}
              $nextUriSubdirectory = $nextURISubdirectoryObject.href | Out-String
              $nextUriSubdirectory = $nextUriSubdirectory.TrimEnd("`r?`n")
              $newestVboxToolsURL = "https://download.virtualbox.org/virtualbox/$newestVersion/$nextUriSubdirectory"
              Write-Host "The latest version of VirtualBox tools has been determined to be downloadable from $newestVboxToolsURL"
              [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile("$newestVboxToolsURL", 'C:\Windows\Temp\VBoxGuestAdditions.iso')
          } Catch {
              Write-Host "Unable to determine the latest version of VBox tools. Falling back to hardcoded URL."
              [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://download.virtualbox.org/virtualbox/6.1.8/VBoxGuestAdditions_6.1.8.iso', 'C:\Windows\Temp\VBoxGuestAdditions.iso')
          }
      }
  
      cmd /c ""C:\PROGRA~1\7-Zip\7z.exe" x C:\Windows\Temp\VBoxGuestAdditions.iso -oC:\Windows\Temp\virtualbox"
      Get-ChildItem "C:\Windows\Temp\virtualbox\cert\" -Filter vbox*.cer | Foreach-Object { C:\Windows\Temp\virtualbox\cert\VBoxCertUtil add-trusted-publisher $_.FullName --root $_.FullName }
      cmd /c C:\Windows\Temp\virtualbox\VBoxWindowsAdditions.exe /S
      cmd /c rd /S /Q "C:\Windows\Temp\virtualbox"
  }
  
  cmd /c msiexec /qb /x C:\Windows\Temp\7z1900-x64.msi