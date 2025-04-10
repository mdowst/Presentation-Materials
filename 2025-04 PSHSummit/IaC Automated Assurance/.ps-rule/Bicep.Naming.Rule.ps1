# Synopsis: Parameters should be in in camel case
Rule 'Azure.Bicep.Parameter.CamelCase' -Type 'Microsoft.Resources/deployments' {
    foreach ($parameter in $TargetObject.properties.template.parameters.PSObject.properties) {
        $Assert.Match($parameter, 'Name', '^[a-z]+[A-Za-z0-9]*$', $true)
    }
}

# Synopsis: Variables should be in in camel case
Rule 'Azure.Bicep.Variable.CamelCase' -Type 'Microsoft.Resources/deployments' {
    foreach ($parameter in $TargetObject.properties.template.variables.PSObject.properties) {
        $Assert.Match($parameter, 'Name', '^[a-z]+[A-Za-z0-9]*$', $true)
    }
}
