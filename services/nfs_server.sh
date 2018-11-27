#!/bin/sh
# ==============================================================================================================
# Autores:
# --------
# - Pablo Fernández Díaz, v130148
# - Víctor Viller Mori, t110010
# ==============================================================================================================
# Fichero: ./nfs_server.sh
# --------------------------------
# Fichero de ejecución del servicio "NFS_SERVER". Configura y comprueba los argumentos de entrada para efectuar
#	una conexión SSH a la IP proporcionada anteriormente y configurar un servidor NFS.
# ==============================================================================================================

# Comprobacion de argumentos. Debe de ser 2 (./nfs_server IP fichero)
if [ $# -ne 2 ]; then
	echo "Error 61: El número de argumentos de la ejecución a de ser únicamente 2."
	exit 61
fi

IP=$1

# Se conectará por SSH a la máquina IP donde se pretende que sea un Servidor por cada línea especificada en el
#	fichero de configuración. El servicio se parará, se configurará el directorio NFS, se indicará qué
#	directorios se "exportarán", se realizará dicha acción y se reanudará el servicio.
NUM_LINEA=0;
while read linea
do

ssh -oStrictHostKeyChecking=no $IP '
	linea='$linea'
	# Comprobamos si el paquete "nfs-kernel-server" está instalado en el sistema. De no ser así se instalará
	#	en la máquina destino.
	if dpkg -l | grep "nfs-kernel-server" > /dev/null ; then 
			echo "El paquete para nfs_server está instalado";
		else
			echo "El paquete no existe. Se procederá a instalarlo...";
			export DEBIAN_FRONTEND=noninteractive;
			sudo apt-get -y -o Dpkg::Options::="--force-confnew" install nfs-kernel-server;
		fi;

	# Se para el servicio NFS
	sudo service nfs-kernel-server stop

	# Si no existe el directorio de configuración NFS se crea
	if [ ! -d /var/nfs ]; then
	    sudo mkdir /var/nfs
	    echo "Directorio NFS Servidor creado."
	fi
	
	# Se configura el directorio de configuración NFS
	sudo chown nobody:nogroup /var/nfs

	# Si el directorio no existe, se crea
   	if [ ! -d $linea ]; then
   		echo "El directorio especificado en la línea '$((NUM_LINEA+1))' no existe. Este se creará."
   		mkdir $linea
   	fi

	# Si no se tiene permisos en el directorio o no es válido, se cerrará
	if [ ! -x $linea ]; then
		echo "Error 62: No tiene permisos sobre el directorio o no es permitido."
		echo 62
	fi
   	
   	# Se añade el directorio especificado en "linea" a /etc/exports con la IP Proporcionada.
   	echo "$linea *(rw,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
   	
   	# Se "exporta" el directorio añadido al NFS.
   	sudo exportfs -a
   	
   	# Se reanuda el servicio NFS
   	sudo service nfs-kernel-server start
   	' < /dev/null
NUM_LINEA=$((NUM_LINEA+1))
done < $2

# BIBLIOGRAFIA:
# [1]: http://www.linux-party.com/index.php/35-linux/8465-montar-un-directorio-remoto-via-nfs-en-linux-por-editar
# [2]: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-14-04
