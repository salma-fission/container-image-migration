# Import environment variables using .env file.
Get-Content .env | ForEach-Object {
    $name, $value = $_.split('=')
    set-content env:\$name $value
}

# Get list of project from output file
$projects = Get-Content $env:OUTPUT_FILE | Out-String | ConvertFrom-Json

# Github login.
$env:GITHUB_TOKEN | docker login ghcr.io -u $env:GITHUB_USERNAME --password-stdin | Write-Host

foreach ($project in $projects) {
    $repos = $project.repo;
    foreach ($repo in $repos) {
        Write-Host 'Repository ' $repo.name 'started.'
        foreach ($tag in $repo.tags) {
            $repoTag = $tag.Split(':')
            $githubURL = "ghcr.io/$($env:GIT_ORGANIZATION)/$($repo.name)`:$($repoTag[1])"
            Write-Host "Pushing on $githubURL"
            docker tag $tag $githubURL
            docker push $githubURL
            Write-Host "$githubURL is Completed"
        }
    }
}