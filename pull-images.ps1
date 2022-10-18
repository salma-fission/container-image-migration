# Import environment variables using .env file.
get-content .env | ForEach-Object {
    $name, $value = $_.split('=')
    set-content env:\$name $value
}

# Common header variable to add in GITLAB APIs
$headers = @{
    'PRIVATE-TOKEN' = $env:GITLAB_TOKEN
}

# GITHUB login
Write-Host "Gitlab login with" $env:GITLAB_USER "username"
$env:GITLAB_TOKEN | docker login registry.gitlab.com -u $env:GITLAB_USERNAME -p $env:GITLAB_TOKEN --password-stdin 

# Created project array JSON
$all_projects = @()
$breakProjectLoop = $false
$projectPage = 1
while(!$breakProjectLoop){
    # API to get projects visibility public is default. Add visibility private to get all private private repositories.
    $projects = Invoke-RestMethod -Method GET -Uri https://gitlab.com/api/v4/projects?visibility=private`&per_page=100`&page=$projectPage -Headers $headers
    if($projects.Count -eq 0){
        $breakProjectLoop = $true
    }
    foreach ($project in $projects) {
        if(($env:PROJECTS -eq "*") -or ($env:PROJECTS -match $project.name)){
            $all_projects += @{
                name = $project.name
                namespace = $project.name_with_namespace
                id = $project.id
            };
        }
    }
    $projectPage++;
}

Write-Host "Total projects found " $all_projects.Count

# Tags Array to export file
$tags = @()

# Iterate through projects
foreach ($project in $all_projects) {
    $tempProject = @{
        name = $project.name
        namespace = $project.namespace
        repo = @()
    }
    $project_id = $project.id

    # API to get all repositories for specific project using project ID.
    $repositories = Invoke-RestMethod -Method GET -Uri https://gitlab.com/api/v4/projects/$project_id/registry/repositories?tags=true -Headers $headers
    foreach ($repo in $repositories) {
        $tempRepo = @{
            name = $repo.name
            path = $repo.path
            tags = @();
        }
        foreach ($tag in $repo.tags) {
            $tempRepo.tags += $tag.location
            docker pull $tag.location
        }
        if($tempRepo.Count -gt 0){
            $tempProject.repo += $tempRepo
        }
    }
    if($tempProject.repo.Count -gt 0){
        $tags += $tempProject
    }
}

# Command to export the file.
ConvertTo-Json @($tags) -Depth 10 | Out-File $env:OUTPUT_FILE

Write-Host """Operation done successfull!""" -foregroundcolor blue
