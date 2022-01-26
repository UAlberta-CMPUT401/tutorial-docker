# Docker Tutorial

This tutorial is intended to provide an introduction to Docker. In particular, you will learn how to Dockerize a simple Django application and how to run it 
in both development and production.

# Dockerfile
The Dockerfile located in the docker_example/ directory is responsible for building our Docker image.
```Dockerfile
# pull official base image
FROM python:3.8.10

# set work directory
WORKDIR /usr/src/app

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# install psycopg2 dependencies
RUN apt-get update && apt-get install libpq-dev python-dev -y

# install dependencies
RUN pip install --upgrade pip
COPY ./requirements.txt .
RUN pip install -r requirements.txt

# copy project
COPY . .

# collect static files
RUN python manage.py collectstatic --no-input

```

# Docker-Compose
The files docker-compose-dev.yaml and docker-compose-prod.yaml are responsible for running our application along with a PostgreSQL database in both a development
and production environment respectively.
### Development Server
```yaml
version: '3.1'

services:
  django:
    image: jmbillson/docker_django_example
    command: python manage.py runserver 0.0.0.0:8080
    volumes:
      - ./docker_example/:/usr/src/app/
    ports:
      - 8000:8000
    env_file:
      - ./.env.dev
  db:
    image: postgres:latest
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    environment:
      - POSTGRES_USER=jmbillson
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=dockerexample

volumes:
  postgres_data:
```

### Production Server
```yaml
version: '3.1'

services:
  django:
    image: jmbillson/docker_django_example
    command: gunicorn docker_example.wsgi:application --bind 0.0.0.0:8000
    volumes:
      - ./docker_example/:/usr/src/app/
    ports:
      - 8000:8000
    env_file:
      - ./.env.dev
  db:
    image: postgres:latest
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    environment:
      - POSTGRES_USER=jmbillson
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=dockerexample

volumes:
  postgres_data:
```
