echo "docker compose up -d"
docker compose up -d
echo "docker compose logs keycloak -ft"
trap "echo 'docker compose down' && docker compose down" SIGINT
docker compose logs keycloak -ft
