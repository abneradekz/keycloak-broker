# cat Dockerfile
# Use a sua versão específica do Keycloak: 26.3.4
FROM quay.io/keycloak/keycloak:26.3.4 as builder

# --- FASE DE BUILD ---
# Configurações que precisam estar presentes durante o build.
# Exemplo para PostgreSQL. Adapte se usar outro banco.
ENV KC_DB=postgres

# Opcional: Se tiver providers customizados, descomente a linha abaixo
# COPY ./providers/*.jar /opt/keycloak/providers/

# Executa a fase de otimização ("build")
RUN /opt/keycloak/bin/kc.sh build

# --- FASE DE EXECUÇÃO ---
# Use a mesma versão base
FROM quay.io/keycloak/keycloak:26.3.4

# Copie a instalação otimizada do Keycloak da fase de build
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# O comando para iniciar o servidor otimizado.
# Não use "start-dev" aqui.
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start"]
