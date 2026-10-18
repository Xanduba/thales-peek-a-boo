<#
  Tiny local web server for testing the app (service workers need http://localhost,
  they don't run from file://). No installs needed.

      powershell -ExecutionPolicy Bypass -File tools\serve.ps1          # http://localhost:8080/
      powershell -ExecutionPolicy Bypass -File tools\serve.ps1 -Port 9000

  Press Ctrl+C to stop.
#>
param([int]$Port = 8080)
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.js'   = 'text/javascript; charset=utf-8'
  '.css'  = 'text/css; charset=utf-8'
  '.webmanifest' = 'application/manifest+json'
  '.json' = 'application/json'
  '.png'  = 'image/png'
  '.jpg'  = 'image/jpeg'
  '.svg'  = 'image/svg+xml'
  '.mp3'  = 'audio/mpeg'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Output "Serving $root at http://localhost:$Port/  (Ctrl+C to stop)"

try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $res = $ctx.Response
    try {
      $rel = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
      if ($rel -eq '') { $rel = 'index.html' }
      $file = [IO.Path]::GetFullPath((Join-Path $root $rel))

      if ($file.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path $file -PathType Leaf)) {
        $bytes = [IO.File]::ReadAllBytes($file)
        $ext = [IO.Path]::GetExtension($file).ToLower()
        $res.ContentType = $(if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' })
        $res.AddHeader('Cache-Control', 'no-cache')
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $status = 200
      } else {
        $res.StatusCode = 404
        $status = 404
      }
      Write-Output ("{0} {1}" -f $status, $ctx.Request.Url.AbsolutePath)
    } catch {
      $res.StatusCode = 500
    } finally {
      $res.Close()
    }
  }
} finally {
  $listener.Stop()
}
