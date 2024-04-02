Describe 'Check Storage Account' {
    It "Test Sku" {
        $Env:Sku | Should -Be 'Standard_LRS'
    }

    It "Test Public Access" {
        $Env:allowBlobPublicAccess | Should -Be 'False'
    }

    It "Test HTTPS Traffic" {
        $Env:allowBlobPublicAccess | Should -BeTrue
    }
}
