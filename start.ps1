
Set-PSDebug -Trace 1


$env:DOCKER_BUILDKIT=1
# $env:BUILDKIT_PROGRESS = "plain"
# build images create and start containers
docker compose build && docker compose up --force-recreate 
