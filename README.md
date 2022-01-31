# Docker Tutorial

This tutorial is intended to provide an introduction to Docker. In particular, you will learn how to Dockerize a simple Django application and how to run it 
in both development and production.

# Original Screencast
[Docker Workshop - Winter 2022](https://drive.google.com/file/d/10tYCZE_WZ9Km1Gky4qW89gcrpqrHOqC5/view?usp=sharing)

# Additional Information
[![](https://img.youtube.com/vi/3c-iBn73dDE/0.jpg)](https://www.youtube.com/watch?v=33c-iBn73dDE)

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

# Configuring Django
To allow our application to run according to different settings in development and in production, we rely on environmental variables to configure our server. 
Environmental variables are defined in ```.env.dev``` and are set inside our docker-compose files. We can then reference these variables inside ```settings.py```.

### Environment File
```Dockerfile
DEBUG=1
SECRET_KEY=foo
DJANGO_ALLOWED_HOSTS=localhost 0.0.0.0 [::1] 127.0.0.1
SQL_ENGINE=django.db.backends.postgresql
SQL_DATABASE=dockerexample
SQL_USER=jmbillson
SQL_PASSWORD=password
SQL_HOST=db
SQL_PORT=5432
```

### Django Settings.py
```python3
from pathlib import Path
import os

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/4.0/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get("SECRET_KEY", default='j6y7+4bo1ce@eea4_x*dq^7i!@s!4h@6nl555gn(3a5z30640y')

# SECURITY WARNING: don't run with debug turned on in production!
debug_settings = {"0": False, "1": True}
DEBUG = debug_settings[os.environ.get("DEBUG", default="1")]

ALLOWED_HOSTS = os.environ.get("DJANGO_ALLOWED_HOSTS", default="0.0.0.0 localhost").split(" ")


# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'docker_example.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'docker_example.wsgi.application'


# Database
# https://docs.djangoproject.com/en/4.0/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': os.environ.get("SQL_ENGINE", default="django.db.backends.postgresql"),
        'NAME': os.environ.get("SQL_DATABASE", default="dockerexample"),
        'USER': os.environ.get("SQL_USER", default="jmbillson"),
        'PASSWORD': os.environ.get("SQL_PASSWORD", default="password"),
        'HOST': os.environ.get("SQL_HOST", default="localhost"),
        'PORT': os.environ.get("SQL_PORT", default='5432'),
    }
}


# Password validation
# https://docs.djangoproject.com/en/4.0/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/4.0/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/4.0/howto/static-files/

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / "staticfiles"

# Default primary key field type
# https://docs.djangoproject.com/en/4.0/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
```
