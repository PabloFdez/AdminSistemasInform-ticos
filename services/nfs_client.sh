#!/bin/sh
# ==============================================================================================================
# Autores:
# --------
# - Pablo Fernández Díaz, v130148
# - Víctor Viller Mori, t110010
# ==============================================================================================================
# Fichero: ./nfs_client.sh
# --------------------------------
# Fichero de ejecución del servicio "NFS_CLIENT". Configura y comprueba los argumentos de entrada para efectuar
#	una conexión SSH a la IP proporcionada anteriormente y configurar un cliente NFS.
# ==============================================================================================================

# Comprobacion de argumentos. Debe de ser 2 (./nfs_client IP fichero)
if [ $# -ne 2 ]; then
	echo "Error 71: El número de argumentos de la ejecución a de ser únicamente 2."
	exit 71
fi

IP=$1

# Se comprueba que la dirección IP especificada en el fichero de configuración es una IP válida, que el directorio
#	remoto existe, que el punto de montaje también existe y que el número de argumentos es de exactamente tres.
NUM_LINEA=0;
while read linea
do
	# Preparación de variables
   	numPalabra=1;
   	IPRemoto=''	# IP del NFS Server
   	RutaRemota=''	# Ruta del NFS Server
   	PuntoMontaje='' # Ruta donde se desea hacer el mount
	for palabra in $linea; do
		if [ $numPalabra -eq 1 ]; then
			# Comprobación de IP válida
			./checks/ipaddress.sh $palabra 0
			IPRemoto=$palabra
		elif [ $numPalabra -eq 2 ]; then
			# Comprobación de la existencia de la ruta remota en base  a la IP remota
			ssh -oStrictHostKeyChecking=no $IPRemoto 'if [ ! -d '$palabra' ]; then exit 72; fi;' < /dev/null
			if [ $? = *"72"* ]; then
				echo "Error 72: El directorio remoto especificado en la línea "$NUM_LINEA" no existe."
				exit 72
			else
				RutaRemota=$palabra	
			fi
		# Comprobación de que el punto de montaje de IP existe.
		elif [ $numPalabra -eq 3 ]; then
			ssh -oStrictHostKeyChecking=no $IP 'if [ ! -d '$palabra' ]; then exit 73; fi;' < /dev/null
			if [ $? = *"73"* ]; then
				echo "Error 73: El punto de montaje de la línea "$NUM_LINEA" no existe."
				exit 73
			else
				PuntoMontaje=$palabra
			fi
		else
			echo "Error 74: En la línea "$NUM_LINEA" hay más de tres argumentos."
			exit 74
		fi
		numPalabra=$((numPalabra+1))
	done

# Conexión SSH para la realización del NFS Client	
ssh -oStrictHostKeyChecking=no $IP '
	IPRemoto='$IPRemoto'
	RutaRemota='$RutaRemota'
	PuntoMontaje='$PuntoMontaje'
	
	# Comprobamos si el paquete "nfs-common" está instalado en el sistema. De no ser así se
	#	procederá a instalarlo.
	if dpkg -l | grep "nfs-common" > /dev/null ; then 
		echo "El paquete para nfs_client está instalado";
	else
		echo "El paquete no existe. Se procederá a instalarlo...";
		export DEBIAN_FRONTEND=noninteractive;
		sudo apt-get -y -o Dpkg::Options::="--force-confnew" install nfs-common;
	fi;
	
	# Arrancamos el servicio
	sudo service nfs-common start
	
	# -------------------------------------------------------------------------------------
	#TODO: COMPROBAR QUE EL DIRECTORIO EXISTE Y NO ESTÁ VACIO
	# -------------------------------------------------------------------------------------
	if [ ! -d PuntoMontaje ]; then
		sudo mkdir $PuntoMontaje
	fi
	
	if [ $(ls -1A $PuntoMontaje | wc -l) -eq 0 ]; then
		# Se monta el directorio remoto especificado en el nuevo creado
		sudo mount $IPRemoto:$RutaRemota $PuntoMontaje

		# Montar automaticamente el NFS
		echo "$IPRemoto:$RutaRemota $PuntoMontaje nfs auto,noatime,nolock,bg,nfsvers=4,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab

		# Paramos el servicio
		sudo service nfs-common stop
	else
		echo "Error 75: el punto de montaje no esta vacio."
		exit 75;
	fi
	' < /dev/null
	
NUM_LINEA=$((NUM_LINEA+1))
done < $2

# BIBLIOGRAFIA:
# [1]: http://www.linux-party.com/index.php/35-linux/8465-montar-un-directorio-remoto-via-nfs-en-linux-por-editar
# [2]: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-14-04
