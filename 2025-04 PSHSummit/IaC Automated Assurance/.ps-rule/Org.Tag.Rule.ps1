# Synopsis: Must have env tag defined.
Rule 'Org.Azure.RG.Tags' -Type 'Microsoft.Storage/storageAccounts' {
    $hasTags = $Assert.HasField($TargetObject, 'Tags')

    $Assert.In($TargetObject, 'tags.env', @(
        'dev',
        'prod',
        'uat'
    ), $True)
}