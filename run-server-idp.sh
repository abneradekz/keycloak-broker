echo "Stopping and removing any existing containers..."
echo "docker compose -f ./docker-compose-server-idp.yml down"
docker compose -f ./docker-compose-server-idp.yml down
echo "Updating codebase..."
echo "git pull"
git pull
echo "Starting server containers..."
echo "docker compose -f ./docker-compose-server-idp.yml up -d"
docker compose -f ./docker-compose-server-idp.yml up -d
