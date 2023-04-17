function Print-Yellow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Yellow
}

# Load the state from the file, if it exists
if (Test-Path config.json) {
    $state = Get-Content config.json | ConvertFrom-Json
   } else {
       $state = @{ database = "MyDatabase"; table = "MyTable"; data = @() }
   }

   Print-Yellow $state
# Set the working directory to the project root
$basePath = "D:\Project\src\Services"
Set-Location $basePath



# Build SiteManager.API project
if ($state.lastSuccessfulCommand -match "sitemanager-api-build") {
    Print-Yellow "Building Site Manager api........" 
   dotnet build .\SiteManager\SiteManager.API\SiteManager.API.csproj
   if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build the project."
    Set-Location "C:\Users\balti\Desktop\ProjectScripts\powershell"
    $state | ConvertTo-Json | Set-Content -Path "config.json"
    exit 1
}
    $state.lastSuccessfulCommand = "accesscontrol-api-build"
}



# Build AccessControl.API
if ($state.lastSuccessfulCommand -match "accesscontrol-api-build") {
    
    Print-Yellow "Building AccessControl api........" 
   dotnet build .\AccessControl\AccessControl.API\AccessControl.API.csproj
   if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build the project."
    Set-Location "C:\Users\balti\Desktop\ProjectScripts\powershell"
    $state | ConvertTo-Json | Set-Content -Path "config.json"
    exit 1
}
    
    $state.lastSuccessfulCommand = "executor-api-build"
}



# Build Executor.API
if ($state.lastSuccessfulCommand -match "executor-api-build") {
    Print-Yellow "Building executor-api........" 
    dotnet build .\Q.ApiExecutor\Q.ApiExecutor.csproj
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build the project."
        Set-Location "C:\Users\balti\Desktop\ProjectScripts\powershell"
        $state | ConvertTo-Json | Set-Content -Path "config.json"
        exit 1
    }
    $state.lastSuccessfulCommand = "eventfetch-api-build"
}

# Build eventfetch-api
if ($state.lastSuccessfulCommand -match "eventfetch-api-build") {
    Print-Yellow "building eventfetch-api........" 
    dotnet build .\Q.EventFetch\Q.EventFetch.csproj 
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build the project."
        Set-Location "C:\Users\balti\Desktop\ProjectScripts\powershell"
        $state | ConvertTo-Json | Set-Content -Path "config.json"
        exit 1
    }   
    $state.lastSuccessfulCommand = "database-update-sitemanager"
}


# Create a database
if ($state.lastSuccessfulCommand -match "database-update-sitemanager") {
    Print-Yellow "database-update-sitemanager......." 
    Set-Location "D:\Project\src\Services\SiteManager\SiteManager.API"
   dotnet ef database update 
   if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build the project."
    Set-Location "C:\Users\balti\Desktop\ProjectScripts\powershell"
    $state | ConvertTo-Json | Set-Content -Path "config.json"
    exit 1
}
    $state.lastSuccessfulCommand = "sitemanager-seeding-data"
}



# #seeding data
if ($state.lastSuccessfulCommand -match "sitemanager-seeding-data") {
    # Read the connection string from appsettings.json file
    $appSettings = Get-Content "D:\Project\src\Services\SiteManager\SiteManager.API\appsettings.json" -Raw | ConvertFrom-Json
    $connectionString = $appSettings.ConnectionStrings.SiteManagerConnectionString
    
    # Set the current directory to the folder containing the SQL script
    Set-Location "D:\Project\src\Services\SiteManager\SiteManager.API\SqlFiles"
    
    # Use sqlcmd to execute the SQL script contained in the .txt file
    $sqlScript = Get-Content "seeder.txt" -Raw
    sqlcmd -S $connectionString -Q $sqlScript -b
    Print-Yellow "sitemanager-seeding-data......." 
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build the project."
        Set-Location "C:\Users\balti\Desktop\ProjectScripts\powershell"
        $state | ConvertTo-Json | Set-Content -Path "config.json"
        exit 1
    }
    $state.lastSuccessfulCommand = "seeding data"
    }



Set-Location "C:\Users\balti\Desktop\ProjectScripts\powershell"
$state | ConvertTo-Json | Set-Content -Path "config.json"