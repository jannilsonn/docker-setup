## Descrição do projeto

Um arquivo shell script para automatizar a criação de um projeto em Ruby on Rails dockerizado, facilitando o setup inicial.

[Baseado na documentação do Docker](https://docs.docker.com/samples/rails/)

# Ao executar o script

## Opções
>Obs: Você pode seguir com as últimas versões do Ruby e do Rails apertando a tecla Enter.
- Primeiramente você precisa passar o nome do projeto, que será usado para definir o nome do container.

- Em seguida informe  a versão do Ruby que deseja usar.

- Logo após a versão do Rails que deseja utilizar no seu projeto.

## Arquivos
>Obs: Para que tudo funcione corretamente é necessário criar alguns arquivos.

- `Dockerfile` com configurações padrões.

- `docker-compose.yml` com os `services`, `db` utilizando Postgresql e `web` com o container criado anteriormente.

- `Gemfile` e `Gemfile.lock` para não quebrar quando rodar o container e criar o projeto normalmente. Isso acontece quando o Docker tenta copiar esses arquivos e eles não existem.

- `entrypoint.sh` vem para corrigir um problema do Rails, que impede a reinicialização do servidor caso já exista um `server.pid`.

## Projeto
- `docker-compose run --no-deps --rm web rails new . --force --database=postgresql` cria um container sem depender do `service` `db`, executa o `rails new` utilizando o Postgresql em `web`.

- `docker-compose build --no-cache` constrói a imagem com o projeto já criado.

## Variáveis - Banco de Dados
- Nessa etapa as variáveis de ambiente do banco de dados que estão no `docker-compose.yml` são usadas no `database.yml`.

## Banco de dados
- `docker-compose run --rm web rake db:create` para que o banco de dados seja criado com as novas variáveis.

# Como usar o script

Clone o repositório:
```
$ git clone git@github.com:Jannilsonn/docker-setup.git
```

Crie e entre na pasta do seu projeto:
```
$ mkdir myapp && cd myapp
```

Copie o conteúdo do arquivo:
```
$ pbcopy < ../docker-setup/docker-setup.sh
```

Crie o arquivo `docker-setup.sh`:
```
$ pbpaste >> docker-setup.sh
```

Execute o script:
```
$ source docker-setup.sh
```