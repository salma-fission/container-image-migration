# Import environment variables using .env file.
get-content .env | ForEach-Object {
    $name, $value = $_.split('=')
    set-content env:\$name $value
}

$repositories = Get-Content  -Path repositories.json | Out-String | ConvertFrom-Json

$headers = @{
    "Accept" = "application/vnd.github+json"
    "Authorization" = "Bearer $env:GITHUB_TOKEN"
}

Write-Host $headers

foreach ($repo in $repositories) {
    <# $repo is the current item #>
    Write-Host "Cloning " $repo.name "Repository"
    $createRepoBody = @{
        "name"= $repo.name
        "description"= $repo.name
        "homepage"= "https=//github.com"
        "private"= $true
        "has_issues"= $true
        "has_projects"= $true
        "has_wiki"= $true
    } | ConvertTo-Json

    $migrateRepoBody = @{
        "vcs"= "git"
        "vcs_url"= $repo.webUrl
        "vcs_username"= $env:GITLAB_USERNAME
        "vcs_password"= $env:GITLAB_TOKEN
    } | ConvertTo-Json
    Invoke-RestMethod -Method "POST" -Uri $repoURL -Headers $headers -Body $createRepoBody
    $pushCodeAPIURL = "https://api.github.com/repos/$env:GIT_ORGANIZATION/$($repo.name.replace(" ", "-"))/import"
    Invoke-RestMethod -Method "PUT" -Uri $pushCodeAPIURL -Headers $headers -Body $migrateRepoBody
}


