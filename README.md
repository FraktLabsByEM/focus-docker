---
# Docker Desktop
Herramienta para la administración de imágenes y contenedores. Es indispensable que docker desktop esté corriendo para poder usar los comandos tanto para administración de imágenes como contenedores. Aunque toda la gestión de imágenes y contenedores se puede hacer a través de la interfaz de la app, el uso de comandos nos permite automatizar las acciones para desplegar de manera fácil y rápida cualquier instancia de nuestro contenedor.

**Docker Hub**
Para identificar las imágenes necesarias en nuestro proyecto es recomendable visitar [https://hub.docker.com/](Docker Hub), un repositorio de imágenes docker en el cual podremos buscar de manera más intuitiva la imagen a usar, así como consultar etiquetas disponibles y las especificaciones de cada una de ellas.

---
# Gestion de Imágenes
## images:

Listado completo de todas las imágenes descargadas.

```bash
docker images
```
## pull:

Descargar la imagen por su nombre, si no especificamos la etiqueta, por defecto descarga la última versión de la imagen. Este comando descarga todas las capas que componen la imagen, a menos que alguna capa esté descargada actualmente por alguna otra imagen, ahorrando espacio al eludir las capas replicadas.

```bash
docker pull [nombre_imagen]
```

**Argumentos**:
+ `:[etiqueta]` Especifica la etiqueta que se descargara.
+ `--platform [plataforma]` Especifica la plataforma que se va a descargar.

**Ejemplos**:
```bash
docker pull node
docker pull node:18 # especificando la versión (etiqueta) 18
docker pull –platform linux/x86_64 node # especificando para la plataforma linux
```
## rm
Eliminar una imagen, docker se encargará de administrar automáticamente la eliminación de imágenes, evitando eliminar capas que estén en uso por otras imágenes no eliminadas.
```bash
docker image rm [nombre_imagen]
```

## build
Con el comando build crearemos una imagen con las especificaciones brindadas por el DockerFile:
```bash
docker build -t [nombre_imagen]:[etiqueta_asignada] [ubicacion_dockerfile]
```

**Argumentos**:
- `-t [nombre_imagen]:[etiqueta_asignada]` Nombre de la nueva imagen y nueva etiqueta

Si tu ubicación en la consola es la misma donde se encuentra el dockerfile puedes usar:
```bash
docker build -t [nombre_imagen]:[etiqueta_asignada] . # el punto (.) referencia el directorio actual
```

---
# Gestión de Contenedores

## create
Crea un contenedor usando una imagen especificada en el comando, devolviendo el ID del contenedor. Esta es una forma corta de usar el comando completo: docker container create [imagen].
```bash
	docker create [imagen]
```
**Argumentos**:
- `–name [nombre]` Crear un contenedor con el nombre que hemos asignado
- `-p[puerto_anfitrion]:[puerto_contenedor]` Crear un contenedor usando puertos específicos.
- `–network [nombre_red]` Crea un contenedor dentro de la red proporcionada

**Nota**: Las imágenes también pueder tener sus propios argumentos. Para el ejemplo supongamos que la imagen es de mongo y los argumentos que en este caso son variables de entorno (Leer documentacion de cada imagen):

```batch
docker create -p27017 -e USERNAME=mi_usuario -e PASS=mi_contrasena
```

## start
Correr o inicializar un contenedor, devuelve el ID del contenedor inicializado.
```batch
docker start [nombre/id]
```

## stop
Detener un contenedor en ejecución, devuelve el ID del contenedor detenido.
```batch
docker stop [nombre/id]
```

## ps
Muestra los contenedores corriendo actualmente en una tabla con algunos datos como: imagen usada, status, puerto, el comando específico para ejecutar el contenedor, entre otros datos más.

```batch
docker ps
```

**Argumentos**:
- `-a` Muestra todos los contenedores, incluso los que no estan en ejecucion

## rm
Eliminar un contenedor.

```batch
docker rm [nombre/id] 
```

## logs
Nos muestra a través de la consola el log del contenedor.

```batch
docker logs  [id/nombre]
```

**Argumentos**:
- `–follow [nombre]` Escucha activa de cambios en el log del contenedor.

## run
Con este comando, se automatiza toda la tarea de: descargar la imagen, crear un contenedor usando la imagen, correr el contenedor y quedar a la escucha del log, en un solo comando.

```batch
docker run [imagen]
```
**Argumentos**:
- `-d` Corre el comando desvinculando el log, de esta manera se libera la consola.
- `Importante`: Este comando acepta todos los parámetros de docker create.

**Nota**: Debemos tener cuidado con este comando, ya que aunque utilicemos la misma imagen con los mismos parámetros, cada ejecución creará un nuevo contenedor.

---
# Port Mapping
A través de este proceso, mapeamos los puertos de nuestra máquina física (no de los contenedores) para conectarlos con los respectivos puertos de los contenedores. Para ello, desde la creación del contenedor asignamos los puertos del anfitrión que usaremos para conectarnos con el anfitrión.

```batch
docker create -p[puerto_anfitrion]:[puerto_contenedor]
```

Luego si verificamos con ***docker ps***, podremos ver que en el apartado de PORTS ahora nos aparece una dirección de nuestro anfitrión, la cual nos permitirá conectarnos con nuestro contenedor. Si lo preferimos (aunque por buenas prácticas no es recomendable) solo le asignamos el puerto de tipo contenedor y que docker administre los puertos físicos de manera automática, aunque, para mantener un orden de puertos es preferible administrarlos de manera manual, de esta manera tenemos contenedores relacionados muy cerca en términos de puertos, y no dispersos en lo que podríamos llamar, nuestra VM. Para ello, solo usamos:

```batch
docker create -p[puerto_contenedor]
```

---
# Portabilidad
Una vez tenemos configurado nuestro contenedor, el siguiente paso es incluir nuestra aplicación dentro del contenedor. Para ello, lo primero que haremos es crear un archivo de configuración de docker justo donde se encuentra nuestra aplicación, que se llamara Dockerfile (este nombre es obligatorio) ejemplo:

```Dockerfile
FROM [imagen:etiqueta]
RUN mkdir -p /home/app # Ruta dentro del contenedor no de nuestro sistema
COPY . [ruta_app_anfitrion] # Ruta al código en nuestro sistema
EXPOSE [puerto]
	CMD [“node /home/app/index.js”] # Comando para ejecutar nuestra app
```

---
# Redes Docker
Los contenedores por defecto solo se pueden comunicar con el exterior, con el cliente, pero si por algún motivo nuestro proyecto escala o ya de por sí está escalado, tenemos que crear una red y poner allí nuestros contenedores para que se puedan comunicar entre ellos. Para estas operaciones usaremos los comandos asociados a docker network.

## ls
Con este comando podremos ver una lista de redes docker creadas.

```batch
docker network ls
```
## create
Con este comando, podremos crear una red nueva con el nombre proporcionado.

```batch
docker network create [nombre_red]
```

## rm
Con este comando podremos eliminar redes creadas en Docker.

```batch
docker network rm [nombre_red]
```

Por defecto, nuestras apps se comunican a través de “localhost”, ya sea en la etapa de desarrollo como en producción (dentro de un hosting). Al usar docker esto cambia, ya que localhost pasaría a ser nuestro contenedor dentro de la misma red, por lo cual debemos reemplazar en nuestro código cualquier conexión con localhost con una conexión a nuestro contenedor dentro de la misma red.

---
# Docker Compose
Docker compose nos permite automatizar la creación de contenedores, para lo cual solo necesitaremos crear un archivo docker-compose.yml (Nombre no negociable).

```batch
	version: “3.9” (version yaml)
	services: 
		nombre_contenedor_1:
			build: . (ruta)
			ports: “3000:3000” (anfitrión:contenedor)
			links:
                nombre_contenedor_2 (sin comillas)
		nombre_contenedor_2:
			image: nombre_imagen
			ports: “27017:27017”
			environment:
                USERNAME=user
                PASSWORD=administrator
```

Una vez tenemos nuestro yaml listo, usaremos el comando compose para crear e inicializar nuestras imágenes. Docker compose, de manera inherente a nuestro yaml, entenderá que nuestros contenedores requieren comunicarse entre ellos, por lo que, de manera automática creará y gestionará una docker network que contenga nuestros contenedores.

## compose
desde la consola de comandos ingresamos a la ubicación donde se encuentra nuestro archivo yaml, y desde aquí ejecutamos:

Si deseamos inicializar nuestra arquitectura:

```batch
docker compose up
```
**Argumentos**:
- `-f [nombre_archivo]` Usar un custom compose

De esta manera se crearan las instancias de nuestros contenedores, y la red para que los contenedores se comuniquen entre ellos.

Si deseamos eliminar las instancias creadas por nuestro arquitectura, lo podemos hacer de manera manual, buscando los id correspondientes para la red y los contenedores, pero si lo queremos hacer de una manera rápida, podemos usar:

```batch
docker compose down
```

---
# Docker Volumes
Docker volumes nos permite gestionar el almacenamiento que una arquitectura usará, de esta manera aunque las instancias de nuestros contenedores desaparezcan, los datos generados durante la ejecución por cada una de ellas, persista en nuestra máquina incluso después de apagar y eliminará las arquitecturas montadas, por ejemplo, logs, bases de datos, etc. Estos volúmenes se pueden categorizar en dos tipos, los anónimos y los de anfitrión. Los anónimos no pueden ser referenciados para indicar que app debe usarlo, en cambio los de anfitrión nos permite ser mas especificos al nivel de poder indicar exactamente que directorio dentro de nuestro sistema de archivos anfitrion, debe usar cada contenedor o red.
Esto lo podemos hacer directamente en nuestro docker compose:

```batch
volumes:
	[nombre_volumen]:
```

y en nuestro contenedor, le asignamos el volumen:

```batch
contenedor_2:
	volumes:
        [nombre_volumen]:[ruta en la cual se montara el volumen] (la ruta es dentro del contenedor)
```

Hay que tener cuidado con las rutas en donde se monta el volumen dentro de nuestro contenedor, por lo general no son arbitrarias, sino que son predefinidas de acuerdo a la tecnología usada. Por ejemplo:
- **mongo**: /data/db
- **mysql**: /var/lib/mysql
- **postgres**: /var/lib/postgresql/data

Igualmente para nuestras aplicaciones, si por defecto nuestra app durante el desarrollo fue programada para guardar imágenes en **/home/user/images/profile_pics** en nuestro contenedor montamos el volumen en la ruta indicada.

---
# Preview en Desarrollo
Docker implementa un sistema que permite que nuestra imagen esté montada durante la etapa de desarrollo para poder ver en tiempo real los cambios realizados las apps hosteadas en nuestros contenedores, algo como un live preview. Pero para ello tenemos que configurar nuestro entorno de desarrollo.

Los primeros cambios los haremos en el Dockerfile, pero no lo haremos sobre el dockerfile de implementación, sino crearemos un nuevo dockerfile llamado: **Dockerfile.dev**. Allí haremos unos cambios para que nuestro contenedor se configure correctamente.

**Pasamos de esto**:
```batch
FROM [imagen:etiqueta]
RUN mkdir -p /home/app
COPY . [ruta_app_anfitrion] 
EXPOSE [puerto]
CMD [“node /home/app/index.js”] 
```
**A esto**:
```batch
FROM [imagen:etiqueta]
RUN npm i -g nodemon # Nodemon enruta los cambios a nuestro contenedor
WORKDIR [ruta_app_anfitrion] # El COPY no es necesario, ya que el controlador hará un enlace simbólico a nuestro código.
EXPOSE [puerto]
CMD [“nodemon index.js”] # Ahora usaremos nodemon en lugar de node, y como definimos nuestro workdir, ya no necesitaremos la ruta completa a la app
```

Además de ello, también debemos hacer unos cambios en compose, por lo que haremos un custom compose para usarlo durante el desarrollo:

**Pasando de esto**:

```yaml
version: “3.9” (version yaml)
services: 
	nombre_contenedor_1:
		build: . (ruta)
		ports: “3000:3000”
		links:
            nombre_contenedor_2 
	nombre_contenedor_2:
		image: nombre_imagen
		ports: “27017:27017”
		environment:
            USERNAME=user
            PASSWORD=administrator
```

**A esto**:

```yaml
version: “3.9”
services: 
	nombre_contenedor_1:
		build:
			context: . (ruta donde se encuentra custom compose)
			dockerfile: Dockerfile.dev (le especificamos usar el dev)
		ports: “3000:3000”
		links:
            nombre_contenedor_2
        volumes: (usar volumenes)
            .:[ruta_montaje] (volumen anonimo)
	nombre_contenedor_2:
		image: nombre_imagen
		ports: “27017:27017”
		environment:
            USERNAME=user
            PASSWORD=administrator
```

---