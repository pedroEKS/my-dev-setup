function gs { git status }
function gp { git pull }
function gpush { git push }
function ll { Get-ChildItem -Force }
function grep { Select-String $args }

# Prompt Customizado
function prompt {
    $path = $(Get-Location).Path.Replace($HOME, "~")
    Write-Host "[$path]" -NoNewline -ForegroundColor Cyan
    return "> "
}

Write-Host "Engineering Environment Loaded." -ForegroundColor Green