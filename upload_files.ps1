# Define local to remote directory mappings
$dirMappings = @{
    "C:\Karnataka-sw-astra-main"  = "/ftp_mw/Karnataka-sw-astra-main"
    "C:\Karnataka-sw-astra-old"   = "/ftp_mw/Karnataka-sw-astra-old"
    "C:\karnataka-sw-azista-mysur"  = "/ftp_mw/karnataka-sw-azista-mysur"
    "C:\Karnataka-sw-azista-yeramarus" = "/ftp_mw/Karnataka-sw-azista-yeramarus"
    "C:\karnataka-sw-canaraya"         = "/ftp_mw/karnataka-sw-canaraya"
    "C:\karnataka-sw-injen"            = "/ftp_mw/karnataka-sw-injen"
    "C:\Karnataka-sw-Sumtechnology-Yermaras"   = "/ftp_mw/Karnataka-sw-Sumtechnology-Yermaras"
    "C:\Karnataka-SW-Suntechnology-Mysore"     = "/ftp_mw/Karnataka-SW-Suntechnology-Mysore"
    "C:\WIMS-SFTP-INGEN"                       = "/ftp_mw/WIMS-SFTP-INGEN"
}

# FTP credentials
$ftpHost = "103.171.96.233"
$ftpUser = "ftp_mw"
$ftpPass = "12345"

# Load WinSCP .NET assembly - adjust path if installed elsewhere
Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

# Set up session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Ftp
    HostName = $ftpHost
    UserName = $ftpUser
    Password = $ftpPass
    FtpMode  = [WinSCP.FtpMode]::Passive
}

# Create a new WinSCP session
$session = New-Object WinSCP.Session

Write-Host "Starting FTP upload using WinSCP PowerShell script..."

try {
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Opening FTP session to $ftpHost..."
    $session.Open($sessionOptions)

    foreach ($localDir in $dirMappings.Keys) {
        $remoteDir = $dirMappings[$localDir]

        if (-Not (Test-Path $localDir)) {
            Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Local directory $localDir does not exist. Skipping..."
            continue
        }

        # Ensure 'uploaded' folder exists
        $archiveDir = Join-Path $localDir "uploaded"
        if (-Not (Test-Path $archiveDir)) {
            New-Item -ItemType Directory -Path $archiveDir | Out-Null
        }

        # Get .csv files edited in the last 15 minutes
        $files = Get-ChildItem $localDir -Filter *.csv | Where-Object {
            ($_.LastWriteTime -gt (Get-Date).AddMinutes(-15)) -and ($_.Length -gt 0)
        }

        if ($files.Count -eq 0) {
            Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - No files found that meet the upload criteria in $localDir"
            continue
        }

        foreach ($file in $files) {
            Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Uploading $($file.FullName) to $remoteDir..."
            $transferResult = $session.PutFiles($file.FullName, "$remoteDir/", $False)
            $transferResult.Check()

            Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Upload successful: $($file.Name)"
            $dest = Join-Path $archiveDir $file.Name

            try {
                Move-Item $file.FullName $dest -Force
                Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Moved file to archive: $dest"
            } catch {
                Write-Warning "Failed to move file $($file.FullName): $_"
            }
        }
    }

} catch {
    Write-Error "FTP upload failed: $_"
} finally {
    $session.Dispose()
}

Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - All done."
Write-Host "Upload process finished.`n"
