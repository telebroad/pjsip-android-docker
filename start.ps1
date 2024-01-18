
Set-PSDebug -Trace 1



# build images
docker compose build 
# create and start containers
docker compose up -d --force-recreate 