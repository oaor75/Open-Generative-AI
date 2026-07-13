# Crea tu fork en GitHub y conecta este clon local a él.
# Requisito: GitHub CLI autenticado. Si no lo está, ejecuta primero:  gh auth login
# Uso:  powershell -ExecutionPolicy Bypass -File .\setup-fork.ps1

$ErrorActionPreference = 'Stop'

gh auth status
if (-not $?) { Write-Error "Ejecuta 'gh auth login' primero."; exit 1 }

# 1. Crea el fork en tu cuenta (no clona: ya tenemos el clon) y lo añade como remoto 'origin'
gh repo fork anil-matcha/open-generative-ai --clone=false
$user = gh api user --jq .login
git remote remove origin 2>$null
git remote add origin "https://github.com/$user/open-generative-ai.git"

# 2. Sube main (espejo de upstream) y la rama con tus mejoras de seguridad
git push -u origin main
git push -u origin mejoras-seguridad

# 3. Haz de 'mejoras-seguridad' la rama por defecto del fork
#    (el workflow de sync semanal corre sobre la rama por defecto)
gh repo edit "$user/open-generative-ai" --default-branch mejoras-seguridad

Write-Host ""
Write-Host "Fork listo: https://github.com/$user/open-generative-ai"
Write-Host "Sync semanal con upstream: pestaña Actions -> 'Sync con upstream' (tambien manual con Run workflow)."
Write-Host "Sync local cuando quieras:  git fetch upstream; git merge upstream/main"
