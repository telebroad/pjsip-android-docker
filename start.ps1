
Set-PSDebug -Trace 1



# build images create and start containers
docker compose build && docker compose up -d --force-recreate 
