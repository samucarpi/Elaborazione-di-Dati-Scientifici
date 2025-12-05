# Check to see if any jobs are still running and stop them
Get-Process -Name "conda-env" -ErrorAction SilentlyContinue | Stop-Process -Force