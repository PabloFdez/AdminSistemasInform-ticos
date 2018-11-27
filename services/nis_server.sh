#! /bin/bash

# ==============================================================================================================
# Autores:
# --------
# - Pablo Fernández Díaz, v130148
# - Víctor Viller Mori, t110010
# ==============================================================================================================
# Fichero: ./nis_server.sh
# --------------------------------
# Fichero de ejecución del servicio "NIS_SERVER". Configura y comprueba los argumentos de entrada para efectuar
#	una conexión SSH a la IP proporcionada anteriormente y configurar un servidor NIS.
# ==============================================================================================================


#SERVIDOR
#Definir el dominio: /etc/defaultdomain
#Gestiona bd de usuarios y publica a los clientes: /etc/ypserv.securenets
#	Acceder a /etc/ypserv.securenet
#	Si se deja 0.0.0.0 puede acceder todo el mundo
#Lanza el servidor: ypserv


#Comprobar si el paquete esta instalado
#	sudo apt-get install nis
#Cuando se instala de pide introducir:
#	- el nombre del dominio a crear, si eres server
#	- el nombre de dominio a conectar, si eres cliente
# Si le das a intro, te pone el nombre por defecto de la máquina
# Para modificarlo: sudo nano /etc/defaultdomain

#Comrpobamos el número de argumentos
if [ $# -ne 2 ]; then
	echo "Error 41: El número de argumentos de la ejecución a de ser 2."
	exit 41
fi

#Comprobamos el numero de lineas del fichero de configuración

IP=$1;			#Guardamos en IP el primer argumento
NUM_LINEA=0;
DOM='';		#En la primera linea del fichero debe aparecer el nombre del dominio
while read linea
do
	if [ $NUM_LINEA -eq 0 ]; then
		DOM=$linea
	fi

NUM_LINEA=$((NUM_LINEA+1))
done < $2

if [ $NUM_LINEA -ne 1 ]; then
	echo "Error 42: El número de lineas del fichero de configuracion debe de ser únicamente 1."
	exit 42
fi	


ssh -oStrictHostKeyChecking=no $IP '
# Comprobamos si el paquete "nis" está instalado en el sistema. De no ser así se instalará
#	en la máquina destino.
if dpkg -l | grep "nis" > /dev/null ; then 
		echo "El paquete para nis está instalado";
	else
		echo "El paquete no existe. Se procederá a instalarlo...";
		export DEBIAN_FRONTEND=noninteractive;
		sudo apt-get -y -o Dpkg::Options::="--force-confnew" install nis;
	fi;

#Actualizamos el nombre del dominio
sudo echo "'$DOM'" | sudo tee /etc/defaultdomain;

#Lanzamos el servidor
sudo ypserv;' < /dev/null
