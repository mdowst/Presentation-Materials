Describe "Spooler Service" {
    It "Should be stopped and disabled" {
        $service = Get-Service -Name "Spooler"
        $service.Status | Should -Be "Stopped"
        $service.StartupType | Should -Be "Disabled"
    }
}

Describe "Spooler Service Separate Tests" {
    BeforeAll {
        $service = Get-Service -Name "Spooler"
    }
    It "Should be stopped" {
        $service.Status | Should -Be "Stopped"
    }
    It "Should be disabled" {
        $service.StartupType | Should -Be "Disabled"
    }
}

Describe "Service Status with Foreach" {
    $servicesToCheck = @(
        @{ Name = "Spooler" }
    )
    Context "<Name> Service" -Foreach $servicesToCheck {
        BeforeAll {
            $service = Get-Service -Name $Name
        }
        It "Should be stopped" {
            $service.Status | Should -Be "Stopped"
        }
        It "Should be disabled" {
            $service.StartupType | Should -Be "Disabled"
        }
    }
}

Describe "Service Status" {
    $servicesToCheck = @(
        @{Name = "mpssvc"; Status = 'Running'; Startup = 'Automatic' }
        @{Name = "Spooler"; Status = 'Stopped'; Startup = 'Disabled' }
    ) 
    Context "<Name> Service" -Foreach $servicesToCheck {
        BeforeAll {
            $service = Get-Service -Name $Name
        }
        It "Should be <Status>" {
            $service.Status | Should -Be $Status
        }
        It "Should be <Startup>" {
            $service.StartupType | Should -Be $Startup
        }
    }
}

Describe "Service Status" {
    $servicesToCheck = Get-Content .\ServiceChecks.json -Raw | ConvertFrom-Json -AsHashtable

    Context "<name> Service" -Foreach $servicesToCheck {
        BeforeAll {
            $service = Get-Service -Name $name
        }
        It "Should be <Status>" {
            $service.Status | Should -Be $Status
        }
        It "Should be <Startup>" {
            $service.StartupType | Should -Be $Startup
        }
    }
}
