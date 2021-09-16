#region : Load Word Objects and dictionary
$dictionary = New-Object -COM Scripting.Dictionary 
$wordApp = New-Object -COM Word.Application
[void]$wordApp.Documents.Add()

#endregion

#region: Set dictionary language
$wordApp.Languages | Format-Table Name, ID

$ID = (Get-Culture).LCID
$Language = $wordApp.Languages | Where-Object { $_.ID -eq $ID } 
$dictionary = $Language.ActiveSpellingDictionary

#endregion

#region : Spell check a word
# $wordApp.checkSpelling(Word, CustomDictionary, IgnoreUppercase, MainDictionary)
$Text = 'definitly'
$wordApp.checkSpelling($Text, $null, $true, $dictionary)

#endregion

#region : Get spelling suggestions

$Text = 'definitly'
$wordApp.GetSpellingSuggestions($Text)

#endregion

#region : Get spelling suggestions

$Content = Get-Content ".\PSNotes.ps1"
$ScriptComments = [System.Management.Automation.PSParser]::Tokenize($Content, [ref]$null) | 
    Where-Object { $_.type -eq "Comment" }

Foreach ($comment in $ScriptComments) {
    if(-not $wordApp.checkSpelling($comment.Content, $null, $true, $dictionary)){
        $comment
        break
    }
}

$wordApp.GetSpellingSuggestions($comment.Content)

#endregion

#region : Get spelling suggestions
Function Test-Spelling($Comment) {
    foreach ($text in $Comment.Content.Split()) {
        if (-Not $wordApp.checkSpelling($Text, $null, $true, $dictionary)) {
            $Suggestions = $wordApp.GetSpellingSuggestions($Text) | Select-Object -ExpandProperty Name
            [pscustomobject]@{
                Word        = $Text
                Line        = $Comment.StartLine
                Suggestions = $Suggestions -join ('; ')
            }
        }
    }
}

Foreach ($comment in $ScriptComments) {
    Test-Spelling $comment
}

#endregion