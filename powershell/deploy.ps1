function PrintYellow {
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
    $state | ConvertTo-Json | Set-Content -Path "state.json"
    exit 1
}

# Load the state from the file, if it exists
if (Test-Path state.json) {
    $state = Get-Content state.json | ConvertFrom-Json
   } 

# Load the configuration from the file, if it exists
if (Test-Path config.json) {
    $config = Get-Content config.json | ConvertFrom-Json
   } 


# Set the working directory to the project root

Set-Location $config.ProjectPath



# Build SiteManager.API project
if ($state.lastSuccessfulCommand -match "sitemanager-api-build") {
    PrintYellow "Building Site Manager api........" 
   dotnet build .\SiteManager\SiteManager.API\SiteManager.API.csproj
   if ($LASTEXITCODE -ne 0) {
    Write-Error "SiteManager api build failed"
    Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
    $state | ConvertTo-Json | Set-Content -Path "state.json"
    exit 1
}
    $state.lastSuccessfulCommand = "accesscontrol-api-build"
}



# Build AccessControl.API
if ($state.lastSuccessfulCommand -match "accesscontrol-api-build") {
    
    PrintYellow "Building AccessControl api........" 
   dotnet build .\AccessControl\AccessControl.API\AccessControl.API.csproj
   if ($LASTEXITCODE -ne 0) {
    Write-Error "accessControl api build failed"
    Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
    $state | ConvertTo-Json | Set-Content -Path "state.json"
    exit 1
}
      $state.lastSuccessfulCommand = "executor-api-build"
}



# Build Executor.API
if ($state.lastSuccessfulCommand -match "executor-api-build") {
    PrintYellow "Building executor-api........" 
    dotnet build .\Q.ApiExecutor\Q.ApiExecutor.csproj
    if ($LASTEXITCODE -ne 0) {
        Write-Error "executor api build failed"
        Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
        $state | ConvertTo-Json | Set-Content -Path "state.json"
        exit 1
    }
    $state.lastSuccessfulCommand = "eventfetch-api-build"
}


# Build eventfetch-api
if ($state.lastSuccessfulCommand -match "eventfetch-api-build") {
    PrintYellow "building eventfetch-api........" 
    dotnet build .\Q.EventFetch\Q.EventFetch.csproj 
    if ($LASTEXITCODE -ne 0) {
        Write-Error "event fetch api build failed"
        Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
        $state | ConvertTo-Json | Set-Content -Path "state.json"
        exit 1
    }  
    $state.lastSuccessfulCommand = "database-update-sitemanager"
}


# Create a database For Sitemanager
if ($state.lastSuccessfulCommand -match "database-update-sitemanager") {
    PrintYellow "database-update-sitemanager......." 
    Set-Location "D:\Project\src\Services\SiteManager\SiteManager.API"
   dotnet ef database update 
   if ($LASTEXITCODE -ne 0) {
    Write-Error "data base update sitemanager failed"
    Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
    $state | ConvertTo-Json | Set-Content -Path "state.json"
    exit 1
}
    $state.lastSuccessfulCommand = "sitemanager-seeding-data"
}


 #seeding data Sitemanager
if ($state.lastSuccessfulCommand -match "sitemanager-seeding-data") {
    # Use sqlcmd to execute the SQL script contained in the .txt file
    Sqlcmd -S $config.Server -d $config.SiteManagerDB -U $config.Username -P $config.Password -i "D:\Project\src\Services\SiteManager\SiteManager.API\SqlFiles\seeder.txt"    
    
    PrintYellow "sitemanager-seeding-data......." 
    if ($LASTEXITCODE -ne 0) {
        Write-Error "sitemanager-seeding-data failed"
        Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
        $state | ConvertTo-Json | Set-Content -Path "state.json"
        exit 1
    }
    $state.lastSuccessfulCommand = "accesscontrol-db-update"
    }


# Create a database For AccessControl.API QDbContext
if ($state.lastSuccessfulCommand -match "accesscontrol-db-update") {
    PrintYellow "accesscontrol-db-update in progress......." 
    Set-Location "D:\Project\src\Services\AccessControl\AccessControl.Persistence"
    dotnet ef database update --context QDbContext --startup-project ../AccessControl.API -- --environment Production --verbose
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Accesscontrol-db-update failed."
        Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
        $state | ConvertTo-Json | Set-Content -Path "state.json"
        exit 1
    }
    $state.lastSuccessfulCommand = "accesscontrol-outboxdb-update"
}


# Create a database For AccessControl.API OutboxDbContext
if ($state.lastSuccessfulCommand -match "accesscontrol-outboxdb-update") {
    PrintYellow "accesscontrol-dboutbox-update in progress......." 
    Set-Location "D:\Project\src\Services\AccessControl\AccessControl.Persistence"
    dotnet ef database update --context OutboxDbContext --startup-project ../AccessControl.API -- --environment $config.Environment --verbose
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to accesscontrol-outboxdb-update."
        Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
        $state | ConvertTo-Json | Set-Content -Path "state.json"
        exit 1
    }
    $state.lastSuccessfulCommand = "database-update-apiExecutor"
}


#CreateDabase  ApiExecutor
if ($state.lastSuccessfulCommand -match "database-update-apiExecutor") {
    PrintYellow "database-update-ApiExecutor......." 
    Sqlcmd -S "192.168.1.197\SQLEXPRESS" -U "sa" -P "123456"  -Q "CREATE DATABASE ApiExecutor"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to update database apiexecutor"
        Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
        $state | ConvertTo-Json | Set-Content -Path "state.json"
        exit 1
    }
    $state.lastSuccessfulCommand = "apiExecutor-seeding-data"
}


 #seeding data ApiExecutor
 if ($state.lastSuccessfulCommand -match "apiExecutor-seeding-data") {
    Set-Location "D:\Project\src\Services\Q.ApiExecutor\SqlFiles"
    PrintYellow "ApiExecutor-seeding-data......." 
    # Use sqlcmd to execute the SQL script contained in the .txt file
    Sqlcmd -S $config.Server -d $config.ApiExecutor -U $config.Username -P $config.Password  -i "D:\Project\src\Services\Q.ApiExecutor\SqlFiles\Create_Table_API_Controller.txt"    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to seed data in apiexecutor."
        Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
        $state | ConvertTo-Json | Set-Content -Path "state.json"
        exit 1
    }
    $state.lastSuccessfulCommand = "create-database-eventdb"
    }


#CreateDabase  EventDB
if ($state.lastSuccessfulCommand -match "create-database-eventdb") {
    PrintYellow "database-update-EventDB......." 
    Sqlcmd -S "192.168.1.197\SQLEXPRESS" -U "sa" -P "123456"  -Q "CREATE DATABASE EventDB"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create database EventDb ."
        Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
        $state | ConvertTo-Json | Set-Content -Path "state.json"
        exit 1
    }
    $state.lastSuccessfulCommand = "eventdb-seeding-data"
}


 #seeding data EventDB
 if ($state.lastSuccessfulCommand -match "eventdb-seeding-data") {
    Set-Location "D:\Project\src\Services\Q.EventFetch\SqlFiles"
    PrintYellow "EventDB-seeding-data......." 
    # Use sqlcmd to execute the SQL script contained in the .txt file
    Sqlcmd -S $config.Server -d $config.EventDB -U $config.Username -P $config.Password -i "D:\Project\src\Services\Q.EventFetch\SqlFiles\CreateTables.txt"     
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to seed data in EeventDB."
        Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
        $state | ConvertTo-Json | Set-Content -Path "state.json"
        exit 1
    }
    $state.lastSuccessfulCommand = "docker-compose-portainer"
    }


    # Docker Compose Portainer
if ($state.lastSuccessfulCommand -match "docker-compose-portainer") {
    

    PrintYellow "Docker Compose Portainer........" 
    Set-Location $config.SrcPath
    docker-compose -f .\docker-compose.yml -f .\docker-compose.override.yml up portainer  -d --build
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to compose docker portainer."
        Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
        $state | ConvertTo-Json | Set-Content -Path "state.json"
        exit 1
    }
    $state.lastSuccessfulCommand = "docker-compose-cache"
}

    # Docker Compose Portainer
    if ($state.lastSuccessfulCommand -match "docker-compose-cache") {
        PrintYellow "Docker Compose cache........"
    Set-Location $config.SrcPath

        docker-compose -f .\docker-compose.yml -f .\docker-compose.override.yml up cache  -d --build
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to compose docker cache."
            Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
            $state | ConvertTo-Json | Set-Content -Path "state.json"
            exit 1
        }
        $state.lastSuccessfulCommand = "docker-compose-rabbitmq"
    }


      # Docker Compose Rabbit MQ
      if ($state.lastSuccessfulCommand -match "docker-compose-rabbitmq") {
        PrintYellow "Docker Compose RabbitMQ........" 
        Set-Location $config.SrcPath

        docker-compose -f .\docker-compose.yml -f .\docker-compose.override.yml up rabbitmq  -d --build
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to compose docker Rabbit MQ."
            Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
            $state | ConvertTo-Json | Set-Content -Path "state.json"
            exit 1
        }
        $state.lastSuccessfulCommand = "docker-compose-sitemanager"
    }


        # Docker Compose SiteManagerApi
        if ($state.lastSuccessfulCommand -match "docker-compose-sitemanager") {
            PrintYellow "Docker Compose sitemanager........" 
           Set-Location $config.SrcPath
          docker-compose --env-file .env -f .\docker-compose.yml -f .\docker-compose.override.yml up sitemanager.api -d --build
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to compose docker sitemanager"
                Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
                $state | ConvertTo-Json | Set-Content -Path "state.json"
                exit 1
            }
            $state.lastSuccessfulCommand = "docker-compose-accesscontrol"
        }


          # Docker Compose AccessControl Service
          if ($state.lastSuccessfulCommand -match "docker-compose-accesscontrol") {
            PrintYellow "Docker Compose accesscontrol service........" 
             Set-Location $config.SrcPath

            docker-compose --env-file=.env -f .\docker-compose.yml -f .\docker-compose.override.yml up accesscontrol.api  -d --build
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to compose docker accesscontrol"
                Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
                $state | ConvertTo-Json | Set-Content -Path "state.json"
                exit 1
            }
            $state.lastSuccessfulCommand = "docker-compose-apiexecutor"
        }


          # Docker Compose Api Executor Service
          if ($state.lastSuccessfulCommand -match "docker-compose-apiexecutor") {
            PrintYellow "Docker Compose api executor service........" 
             Set-Location $config.SrcPath

            docker-compose --env-file=.env -f .\docker-compose.yml -f .\docker-compose.override.yml up q.apiexecutor  -d --build
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to compose docker api executor service"
                Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
                $state | ConvertTo-Json | Set-Content -Path "state.json"
                exit 1
            }
            $state.lastSuccessfulCommand = "docker-compose-eventfetch"
        }


      # Docker Compose Api Event Fetch
      if ($state.lastSuccessfulCommand -match "docker-compose-eventfetch") {
        PrintYellow "Docker Compose event fetch........" 
        Set-Location $config.SrcPath

        docker-compose --env-file=.env -f .\docker-compose.yml -f .\docker-compose.override.yml up q.eventfetch  -d --build
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to compose docker event fetch"
            Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
            $state | ConvertTo-Json | Set-Content -Path "state.json"
            exit 1
        }
        $state.lastSuccessfulCommand = "finished"
    }  


        


Set-Location "C:\Users\balti\Desktop\quanika-cloud-app Scripts\powershell"
$state | ConvertTo-Json | Set-Content -Path "state.json"