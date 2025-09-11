# Projeto: Keycloak como Broker de Autenticação SAML

Este projeto provisiona um ambiente Docker completo com Keycloak e um banco de dados PostgreSQL, pré-configurado para atuar como um broker de identidade.

O objetivo principal é usar o Keycloak para se conectar a um provedor de identidade (IdP) corporativo que usa o protocolo **SAML v2.0** e oferecer uma interface de autenticação moderna e simplificada (via **OpenID Connect - OIDC**) para as aplicações finais.

## Estrutura de Arquivos

```
/projeto-keycloak-broker/
  ├── docker-compose.yml       <-- Arquivo de orquestração do Docker
  ├── .env                     <-- Arquivo para senhas e segredos (NÃO ENVIAR PARA O GIT)
  ├── README.md                <-- Este arquivo
  └── postgresql/
      └── data/                <-- Pasta para persistência dos dados do banco
```

## Como Usar

### 1. Pré-requisitos
* Docker
* Docker Compose

### 2. Configuração Inicial
1.  **Clone este repositório** ou crie a estrutura de arquivos localmente.
2.  **Crie a pasta de dados:** Se ela não existir, crie-a com o comando `mkdir -p postgresql/data`.
3.  **Crie o arquivo `.env`:** Copie o arquivo de exemplo `.env.example` para um novo arquivo chamado `.env`.
    ```bash
    cp .env.example .env
    ```
4.  **Edite o arquivo `.env`:** Abra o arquivo `.env` recém-criado e **substitua os valores vazios das senhas** (`POSTGRES_PASSWORD` e `KEYCLOAK_ADMIN_PASSWORD`) por valores seguros de sua escolha.

### 3. Execução
Com o Docker em execução, abra um terminal na raiz do projeto e execute:

```bash
docker compose up -d
```
O primeiro início pode levar alguns minutos para baixar as imagens.

### 4. Acesso
* **Console de Administração do Keycloak:** `http://localhost:8080`
* **Usuário:** `admin` (ou o que estiver em `KEYCLOAK_ADMIN`)
* **Senha:** A senha que você definiu em `KEYCLOAK_ADMIN_PASSWORD`

### 5. Parando o Ambiente
Para parar os containers, execute:
```bash
docker compose down
```
Os dados do banco de dados continuarão salvos na pasta `./postgresql/data`.

## Produção
Para produção, é recomendado configurar um proxy reverso (Nginx, Traefik, etc.) com HTTPS e ajustar a variável `KC_HOSTNAME` no arquivo `.env` para o domínio público.

Também precisa trocar:
```yaml
services:
  keycloak:
    command: start
```
hoje esta como `start-dev` trocar para `start`.

## Tutorial: Configurando o Keycloak como Broker SAML v2.0

Este guia mostra como conectar o Keycloak a um IdP SAML externo.

**Objetivo do Exemplo:** Permitir que usuários de um IdP SAML da "Nossa Empresa Corp" se autentiquem para usar a "Minha Aplicação", que só entende OIDC.

### Passo 1: Login e Criação do Realm
1.  Acesse a console do Keycloak.
2.  Por padrão, você estará no Realm `master`. É uma boa prática criar um novo Realm para seus projetos.
3.  No canto superior esquerdo, clique em **master** e depois em **Create Realm**.
4.  Dê um nome ao Realm (ex: `meus-projetos`) e clique em **Create**.

### Passo 2: Configurar o Provedor de Identidade (A "Entrada" SAML)
1.  No menu à esquerda, certifique-se de que você está no seu novo Realm (`meus-projetos`).
2.  Vá para **Identity Providers**.
3.  Na lista de provedores, clique em **SAML v2.0**.
4.  Preencha o formulário:
    * **Alias:** Um nome único para esta conexão (ex: `nossa-empresa-corp`).
    * **Import from URL:** Esta é a forma mais fácil. Cole a URL do arquivo de metadados do seu IdP SAML aqui (ex: `https://idp.nossaempresa.com/saml/metadata`). Clique em **Import**. A maioria dos campos será preenchida automaticamente.
    * Verifique as configurações e clique em **Save** no final da página.

### Passo 3: Configurar os Mappers (A "Tradução" de Atributos)
Depois de salvar, você será levado de volta às configurações do provedor. Agora precisamos dizer ao Keycloak como "traduzir" os atributos que o SAML envia.

1.  Vá para a aba **Mappers**.
2.  Clique em **Add mapper**.
3.  **Exemplo: Mapeando o E-mail do Usuário**
    * **Name:** `Mapeador de E-mail`
    * **Mapper Type:** Selecione `Attribute Importer`.
    * **Attribute Name:** Digite o nome exato do atributo SAML que contém o e-mail. Isso pode variar, mas nomes comuns são `email`, `mail`, ou uma URI completa como `urn:oid:0.9.2342.19200300.100.1.3`. Você precisa confirmar isso com o administrador do IdP.
    * **User Attribute Name:** Digite `email`. Este é o nome do campo de e-mail padrão do usuário no Keycloak.
    * Clique em **Save**.

### Passo 4: Configurar o Cliente (A "Saída" OIDC para sua Aplicação)
Agora, vamos configurar como a sua aplicação final irá se comunicar com o Keycloak.

1.  No menu à esquerda, vá para **Clients**.
2.  Clique em **Create client**.
3.  Preencha as informações:
    * **Client type:** `OpenID Connect`
    * **Client ID:** Um identificador único para sua aplicação (ex: `minha-aplicacao-web`).
    * Clique em **Next**.
4.  Na próxima tela, ative a opção **Client authentication** e deixe `Standard flow` marcado.
5.  Em **Valid redirect URIs**, adicione a URL para a qual sua aplicação deverá ser redirecionada após o login (ex: `http://localhost:3000/*` ou `https://meuapp.com/callback/*`).
6.  Clique em **Save**.
7.  Após salvar, vá para a aba **Credentials**. Aqui você encontrará o **Client secret**, que sua aplicação usará para se comunicar de forma segura com o Keycloak.

### Passo 5: Testando o Fluxo
1.  Configure sua aplicação para usar OIDC com os dados do Keycloak (Issuer URL, Client ID, Client Secret).
2.  Ao acessar a página de login da sua aplicação, ela deverá redirecionar para a página de login do Keycloak.
3.  Nesta página, além do formulário de usuário/senha normal do Keycloak, você verá um botão novo: **"Fazer login com nossa-empresa-corp"** (ou o alias que você definiu).
4.  Clicando neste botão, você será redirecionado ao IdP SAML da empresa para se autenticar. Após o sucesso, você será redirecionado de volta para sua aplicação, já logado.

## Como Implementar o Login Automático (Sem Cliques)

Por padrão, após configurar um provedor de identidade externo, a tela de login do Keycloak exibirá um botão para que o usuário escolha se autenticar através daquele provedor. Para criar uma experiência fluida onde o usuário é redirecionado automaticamente para o login corporativo sem precisar clicar em nenhum botão, utilizamos o método `kc_idp_hint`.

Esta abordagem é ideal para cenários com múltiplos provedores de identidade, pois permite que a aplicação cliente decida para qual deles o usuário deve ser direcionado.

### O Método: Parâmetro `kc_idp_hint`

A solução consiste em adicionar o parâmetro `kc_idp_hint` à URL de autenticação do Keycloak. O valor desse parâmetro é o **Alias** do provedor de identidade que você deseja usar.

#### Passo 1: Encontre o Alias do seu Provedor
1.  Na console de administração do Keycloak, dentro do seu Realm, vá para **Identity Providers**.
2.  Você verá a lista de provedores que configurou. A coluna **Alias** contém o valor que você precisa (ex: `nossa-empresa-corp`).

#### Passo 2: Construa a URL de Autenticação
A sua aplicação cliente, ao invés de redirecionar para a URL de autenticação padrão, deverá adicionar o novo parâmetro.

* **URL Padrão (mostra a tela de login do Keycloak):**
    ```
    http://localhost:8080/realms/meus-projetos/protocol/openid-connect/auth?client_id=minha-aplicacao-web&response_type=code&scope=openid&redirect_uri=...
    ```

* **URL com `kc_idp_hint` (redireciona direto para o IdP):**
    ```
    http://localhost:8080/realms/[meus-projetos]/protocol/openid-connect/auth?client_id=[minha-aplicacao-web]&response_type=code&scope=openid&redirect_uri=[http://localhost:3000/callback]&kc_idp_hint=[auth0-saml-test]
    ```
  Substitua `[alias-do-seu-idp]` pelo valor encontrado no Passo 1.

#### Passo 3: Construa a URL de Autenticação
Na configuração do realm colocar o "First Name" e "Last Name" como não obrigatórios, assim o Keycloak não irá pedir estes dados na primeira vez que o usuário logar.

### Exemplo para Múltiplos Projetos

Imagine que no Keycloak você configurou dois provedores com os seguintes aliases:
* `empresa-a-saml`
* `empresa-b-adfs`

Sua aplicação poderia ter a seguinte lógica:

* Se o usuário acessar `projetoA.meudominio.com`, a aplicação montará a URL de login com `&kc_idp_hint=empresa-a-saml`. O usuário será enviado diretamente para o IdP da Empresa A.
* Se o usuário acessar `projetoB.meudominio.com`, a aplicação montará a URL de login com `&kc_idp_hint=empresa-b-adfs`. O usuário será enviado diretamente para o IdP da Empresa B.

Dessa forma, a sua aplicação cliente tem controle total sobre o fluxo de login, mantendo a configuração de SSO centralizada no Keycloak.

## Considerações para Produção
* **Segurança:** Nunca envie o arquivo `.env` para um repositório Git. Adicione-o ao seu `.gitignore`.
* **HTTPS e Domínio:** Em produção, você deve rodar o Keycloak atrás de um reverse proxy (como Nginx ou Traefik) com HTTPS configurado. A variável `KC_HOSTNAME` no arquivo `.env` deve ser alterada para o seu domínio público (ex: `sso.meudominio.com`).
* **Backups:** Lembre-se de fazer backup regularmente da pasta `./postgresql/data`, pois ela contém todos os seus dados e configurações.
