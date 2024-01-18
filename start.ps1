
Set-PSDebug -Trace 1

# stop running containers
# docker compose stop


# the '-f' flag is to not prompt for confirmation

# pull the latest version of the image
# docker compose pull
# remove stopped service containers
# docker compose rm -f
docker compose build 
# create and start containers
docker compose up -d --force-recreate 