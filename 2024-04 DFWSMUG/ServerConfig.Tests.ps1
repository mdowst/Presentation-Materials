# Testing Local Server Configuration

# Testing if a Service is Running
Describe "WinRM Service" {
    It "Should be running" {
        $service = Get-Service -Name "WinRM"
        $service.Status | Should -Be "Running"
    }
}

# Verifying a File Exists
Describe "Configuration File" {
    It "Should exist" {
        Test-Path "C:\configs\myconfig.cfg" | Should -Be $true
    }
}

# Checking an Application Setting (Registry)
Describe "Registry Setting for MyApp" {
    It "Should have the correct value" {
        $regValue = Get-ItemPropertyValue -Path "HKLM:\Software\MyApp\Settings" -Name "SettingName"
        $regValue | Should -Be "ExpectedValue"
    }
}

# Ensuring a Network Port is Listening
Describe "Port 3389" {
    It "Should be listening" {
        $port = Test-NetConnection -ComputerName localhost -Port 3389
        $port.TcpTestSucceeded | Should -Be $true
    }
}