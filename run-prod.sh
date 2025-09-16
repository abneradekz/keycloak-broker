echo "Stopping and removing any existing containers..."
echo "docker compose -f ./docker-compose-prod.yml down"
docker compose -f ./docker-compose-prod.yml down
echo "Updating codebase..."
echo "git pull"
git pull
echo "Starting prod containers..."
echo "docker compose -f ./docker-compose-prod.yml up -d"
docker compose -f ./docker-compose-prod.yml up -d
