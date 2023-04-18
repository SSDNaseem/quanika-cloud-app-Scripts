function Print-Yellow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Yellow
}

function SetDefaultLocation($msg,$state){
    Write-Error $msg
    Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
    $state | ConvertTo-Json | Set-Content -Path "config.json"
    exit 1
}

# Load the state from the file, if it exists
if (Test-Path config.json) {
    $state = Get-Content config.json | ConvertFrom-Json
   } else {
       $state = @{ database = "MyDatabase"; table = "MyTable"; data = @() }
   }

# Set the working directory to the project root
$basePath = "D:\Project\src\Services"
Set-Location $basePath



# Build SiteManager.API project
if ($state.lastSuccessfulCommand -match "sitemanager-api-build") {
    Print-Yellow "Building Site Manager api........" 
   dotnet build .\SiteManager\SiteManager.API\SiteManager.API.csproj
   if ($LASTEXITCODE -ne 0) {
   SetDefaultLocation("Error in SiteManager Build.",$state)
}
    $state.lastSuccessfulCommand = "accesscontrol-api-build"
}



# Build AccessControl.API
if ($state.lastSuccessfulCommand -match "accesscontrol-api-build") {
    
    Print-Yellow "Building AccessControl api........" 
   dotnet build .\AccessControl\AccessControl.API\AccessControl.API.csproj
   if ($LASTEXITCODE -ne 0) {
    SetDefaultLocation("Error in accesscontrol Build.",$state)

}
    
    $state.lastSuccessfulCommand = "executor-api-build"
}



# Build Executor.API
if ($state.lastSuccessfulCommand -match "executor-api-build") {
    Print-Yellow "Building executor-api........" 
    dotnet build .\Q.ApiExecutor\Q.ApiExecutor.csproj
    if ($LASTEXITCODE -ne 0) {
        SetDefaultLocation("Error in executor api Build.",$state)
    }
    $state.lastSuccessfulCommand = "eventfetch-api-build"
}

# Build eventfetch-api
if ($state.lastSuccessfulCommand -match "eventfetch-api-build") {
    Print-Yellow "building eventfetch-api........" 
    dotnet build .\Q.EventFetch\Q.EventFetch.csproj 
    if ($LASTEXITCODE -ne 0) {
        SetDefaultLocation("Error in eventFetch api Build.",$state)
    }   
    $state.lastSuccessfulCommand = "database-update-sitemanager"
}


# Create a database For Sitemanager
if ($state.lastSuccessfulCommand -match "database-update-sitemanager") {
    Print-Yellow "database-update-sitemanager......." 
    Set-Location "D:\Project\src\Services\SiteManager\SiteManager.API"
   dotnet ef database update 
   if ($LASTEXITCODE -ne 0) {
    SetDefaultLocation("Error in sitemanage database update.",$state)
}
    $state.lastSuccessfulCommand = "sitemanager-seeding-data"
}



 #seeding data Sitemanager
if ($state.lastSuccessfulCommand -match "sitemanager-seeding-data") {
    # Read the connection string from appsettings.json file
    $appSettings = Get-Content "D:\Project\src\Services\SiteManager\SiteManager.API\appsettings.json" -Raw | ConvertFrom-Json
    $connectionString = $appSettings.ConnectionStrings.SiteManagerConnectionString
    
    # Set the current directory to the folder containing the SQL script
    Set-Location "D:\Project\src\Services\SiteManager\SiteManager.API\SqlFiles"
    
    # Use sqlcmd to execute the SQL script contained in the .txt file
    Sqlcmd -S "192.168.1.197\SQLEXPRESS" -d "SiteManagerDb" -U "sa" -P "123456" -i "D:\Project\src\Services\SiteManager\SiteManager.API\SqlFiles\seeder.txt"    
    
    Print-Yellow "sitemanager-seeding-data......." 
    if ($LASTEXITCODE -ne 0) {
        SetDefaultLocation("Error in SiteManager seeding data.",$state)
    }
    $state.lastSuccessfulCommand = "accesscontrol-db-update"
    }


# Create a database For AccessControl.API QDbContext
if ($state.lastSuccessfulCommand -match "accesscontrol-db-update") {
    Print-Yellow "accesscontrol-db-update in progress......." 
    Set-Location "D:\Project\src\Services\AccessControl\AccessControl.Persistence"
    dotnet ef database update --context QDbContext --startup-project ../AccessControl.API -- --environment Production --verbose
   if ($LASTEXITCODE -ne 0) {
    SetDefaultLocation("Error in accesscontorl db update",$state)
}
    $state.lastSuccessfulCommand = "accesscontrol-outboxdb-update"
}


# Create a database For AccessControl.API OutboxDbContext
if ($state.lastSuccessfulCommand -match "accesscontrol-outboxdb-update") {
    Print-Yellow "accesscontrol-dboutbox-update in progress......." 
    Set-Location "D:\Project\src\Services\AccessControl\AccessControl.Persistence"
    dotnet ef database update --context OutboxDbContext --startup-project ../AccessControl.API -- --environment Production --verbose
   if ($LASTEXITCODE -ne 0) {
    SetDefaultLocation("Error in accesscontorl outboxdb update.",$state)

}
    $state.lastSuccessfulCommand = "Create-Dabase ApiExecutor"
}


#CreateDabase  ApiExecutor
if ($state.lastSuccessfulCommand -match "Create-Dabase ApiExecutor") {
    Print-Yellow "database-update-ApiExecutor......." 
    Sqlcmd -S "192.168.1.197\SQLEXPRESS" -U "sa" -P "123456"  -Q "CREATE DATABASE ApiExecutor"
   if ($LASTEXITCODE -ne 0) {
    SetDefaultLocation("Error in apiexecutor create database.",$state)

}
    $state.lastSuccessfulCommand = "ApiExecutor-seeding-data"
}


 #seeding data ApiExecutor
 if ($state.lastSuccessfulCommand -match "ApiExecutor-seeding-data") {
    Set-Location "D:\Project\src\Services\Q.ApiExecutor\SqlFiles"
    # Use sqlcmd to execute the SQL script contained in the .txt file
    Sqlcmd -S "192.168.1.197\SQLEXPRESS" -d "ApiExecutor" -U "sa" -P "123456" -i "D:\Project\src\Services\Q.ApiExecutor\SqlFiles\Create_Table_API_Controller.txt"    

    Print-Yellow "ApiExecutor-seeding-data......." 
    if ($LASTEXITCODE -ne 0) {
        SetDefaultLocation("Error in SiteManager ApiExecutor seeding data.",$state)

    }
    $state.lastSuccessfulCommand = "Create-Dabase EventDB"
    }

#CreateDabase  EventDB
if ($state.lastSuccessfulCommand -match "Create-Dabase EventDB") {
    Print-Yellow "database-update-EventDB......." 
    Sqlcmd -S "192.168.1.197\SQLEXPRESS" -U "sa" -P "123456"  -Q "CREATE DATABASE EventDB"
   if ($LASTEXITCODE -ne 0) {
    SetDefaultLocation("Error in Create Database EventDB.",$state)
}
    $state.lastSuccessfulCommand = "EventDB-seeding-data"
}


 #seeding data EventDB
 if ($state.lastSuccessfulCommand -match "EventDB-seeding-data") {
    Set-Location "D:\Project\src\Services\Q.EventFetch\SqlFiles"
    # Use sqlcmd to execute the SQL script contained in the .txt file
    Sqlcmd -S "192.168.1.197\SQLEXPRESS" -d "EventDB" -U "sa" -P "123456" -i "D:\Project\src\Services\Q.EventFetch\SqlFiles\CreateTables.txt"    

    Print-Yellow "EventDB-seeding-data......." 
    if ($LASTEXITCODE -ne 0) {
        SetDefaultLocation("Error in EventDB seeding data.",$state)
    }
    $state.lastSuccessfulCommand = "finished"
    }




Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
$state | ConvertTo-Json | Set-Content -Path "config.json"