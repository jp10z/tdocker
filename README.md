# tdocker

tdocker es una herramienta que permite leer un directorio de archivos docker-compose
y realizar operaciones sobre ellos, como actualizarlos o levantarlos

## Requisitos

- Sistema operativo Linux
- Docker configurado
- Python3 y PIP
- virtualenv
- docker-compose

virtualenv se puede instalar usando PIP con: `pip install virtualenv`

docker-compose se instalará más adelante cuándo se haga la configuración

## Configuración

Clone el proyecto e ingrese al directorio

```
https://github.com/jp10z/tdocker
cd tdocker
```

Setee permisos de ejecución sobre el script

```
chmod +x ./tdocker.sh
```

Cree un entorno virtual para usar docker-compose y activelo

```
virtualenv venv
source venv/bin/activate
```

Instalar docker-compose

```
pip install docker-compose
```

Copie el archivo de configuración base

```
cp ./docs/sample_config/config.ini ./config.ini
```

Modifique el archivo ./config.init:

- `BIN_DOCKER_COMPOSE_PATH`: Acá deberá indicar dónde tiene almacenado el binario de docker-compose, en principio no debería modificar este parámetro a menos quiera algo más avanzado
- `COMPOSE_PATH`: Acá deberá indicar la ruta de la carpeta que contiene sus archivos compose
- `ENV_PATH`: Acá deberá indicar la ruta de la carpeta que contiene sus archivos de variables

Puede ver la carpeta `docs/sample-compose` y `docs/sample-env` para ver un ejemplo de uso de un docker-compose y variables env, dónde se define en el archivo .env el usuario y contraseña del contenedor

## Ejemplos de uso

El siguiente script levantará todos los contenedores de todos los archivos compose

Este script también actualizará automáticamente todas las imagenes y recrearé los contenedores en caso de actualización

Este script es el que deberá utilizar para levantar y actualizar periodicamente

```
./tdocker up
```

En caso de querer levantar/actualizar solamente un archivo compose puede pasarle como parámetro el nombre del stack

```
./tdocker up databases
```

El siguiente script detiene y elimina todas los contenedores y recursos de un compose

```
./tdocker down databases
```

En caso de que elimine algún archivo compose deberá ejecutar el siguiente script para autodetectar los compose eliminados y dar de baja sus recursos

```
./tdocker autodown
```