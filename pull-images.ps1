get-content .env | ForEach-Object {
    $name, $value = $_.split('=')
    set-content env:\$name $value
}

$headers = @{
    'PRIVATE-TOKEN' = $env:GITLAB_TOKEN
}

Write-Host "Gitlab login with" $env:GITLAB_USER "username"
# GITHUB login
$env:GITLAB_TOKEN | docker login registry.gitlab.com -u $env:GITLAB_USERNAME -p $env:GITLAB_TOKEN --password-stdin 

# Created project array json file
$all_projects = @()
$breakProjectLoop = $false
$projectPage = 1
while(!$breakProjectLoop){
    $projects = Invoke-RestMethod -Method GET -Uri https://gitlab.com/api/v4/projects?visibility=private`&per_page=100`&page=$projectPage`&id=2994555 -Headers $headers
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

$all_projects | Write-Output

$tags = @()
foreach ($project in $all_projects) {
    $tempProject = @{
        name = $project.name
        namespace = $project.namespace
        repo = @()
    }
    $project_id = $project.id
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
    Write-Host ($currentItemName.name | Out-String)
}

ConvertTo-Json @($tags) -Depth 10 | Out-File $env:OUTPUT_FILE

Write-Host """Operation done successfull!""" -foregroundcolor blue
