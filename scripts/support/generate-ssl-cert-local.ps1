$rootDir = (get-item $PSScriptRoot).Parent.Parent.FullName

try {
  $sslPath = "$rootDir\.ssl"
  if (!(Test-Path -Path $sslPath)) {
    New-Item -Path $sslPath -ItemType Directory | Out-Null
    Write-Host "created $sslPath" -ForegroundColor Blue
  }

  $pfxPath = Get-Content "$rootDir\.env" | Select-String '^SSL_PFX_FILE=' `
  | ForEach-Object { $_.ToString().Split('=')[1] }

  if ($null -eq $pfxPath -or !(Test-Path $pfxPath)) {
    throw [System.InvalidOperationException] `
      "Unable to generate SSL certificate files. PFX file not found."
  }

  $pfxPassword = Get-Content "$rootDir\.env" | Select-String '^SSL_PFX_PASSWORD=' `
  | ForEach-Object { $_.ToString().Split('=')[1] }

  if ($null -eq $pfxPassword) {
    throw [System.InvalidOperationException] `
      "Unable to generate SSL certificate files. PFX file password not found."
  }

  $keyPath = Get-Content "$rootDir\.env" | Select-String '^SSL_KEY_FILE=' `
  | ForEach-Object { $_.ToString().Split('=')[1] }

  if ($null -eq $keyPath) {
    throw [System.InvalidOperationException] `
      "Unable to generate SSL certificate KEY file. Destination path not specified."
  }

  if (!(Test-Path $keyPath)) {
    openssl pkcs12 -nocerts -nodes `
      -in $pfxPath `
      -out $keyPath `
      -passin pass:$pfxPassword

    Write-Host "Created $keyPath." -ForegroundColor Blue
  }

  $crtPath = Get-Content "$rootDir\.env" | Select-String '^SSL_CRT_FILE=' `
  | ForEach-Object { $_.ToString().Split('=')[1] }

  if ($null -eq $crtPath) {
    throw [System.InvalidOperationException] `
      "Unable to generate SSL certificate CER file. Destination path not specified."
  }

  if (!(Test-Path $crtPath)) {
    openssl pkcs12 -clcerts -nokeys `
      -in $pfxPath `
      -out $crtPath `
      -passin pass:$pfxPassword

    Write-Host "Created $crtPath."  -ForegroundColor Blue
  }
}
catch [System.Exception] {
  Write-Host $_.Exception.Message -ForegroundColor Red

  Write-Host ""
  Write-Host "To create a new trusted local dev certificate:" -ForegroundColor Blue
  Write-Host "$ dotnet dev-certs https" `
    "--export-path path/to/your/localhost.pfx" `
    "--password <PASSWORD> --trust" `
    -ForegroundColor Magenta
}
