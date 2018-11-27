#! /bin/bash
# ==============================================================================================================
# Autores:
# --------
# - Pablo Fernández Díaz, v130148
# - Víctor Viller Mori, t110010
# ==============================================================================================================
# Fichero: ./nis_client.sh
# --------------------------------
# Fichero de ejecución del servicio "NIS_CLIENT". Configura y comprueba los argumentos de entrada para efectuar
#	una conexión SSH a la IP proporcionada anteriormente y configurar un cliente NIS.
# ==============================================================================================================

#CLIENTE


#Comrpobamos el número de argumentos
if [ $# -ne 2 ]; then
	echo "Error 51: El número de argumentos de la ejecución a de ser 2."
	exit 51
fi

#Comprobamos el numero de lineas del fichero de configuración

IP=$1;			#Guardamos en IP el primer argumento
NUM_LINEA=0;
DOM='';		#En la primera linea del fichero debe aparecer el nombre del dominio
IP_SER='';	#Servidor NIS al que se quiere conectar
while read linea
do
	if [ $NUM_LINEA -eq 0 ]; then
		DOM=$linea
	elif [ $NUM_LINEA -eq 1 ]; then
		IP_SER=$linea 
	fi

NUM_LINEA=$((NUM_LINEA+1))
done < $2

if [ $NUM_LINEA -ne 2 ]; then
	echo "Error 52: El número de lineas del fichero de configuracion debe de ser únicamente 2."
	exit 52
fi	

#Comprobar si el paquete esta instalado

#Comprueba si la ip pasada por argumentos es valida


if [[ "$IP_SER" =~ ^([0-9]{1,3})[.]([0-9]{1,3})[.]([0-9]{1,3})[.]([0-9]{1,3})$ ]]
then
    for (( i=1; i<${#BASH_REMATCH[@]}; ++i ))
    do
      (( ${BASH_REMATCH[$i]} <= 255 )) || { echo "Error: La IP del servidor NIS no es valida." >&2; exit 23; }
    done
else
      echo "Error: 53 La IP del servidor NIS no es valida." >&2
      exit 53;
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
#Actualizamos la dirección del servidor
echo "ypserver '$IP_SER'" | sudo tee /etc/yp.conf;
#Fijo un dominio de servidor nis
sudo /bin/nisdomainname '$DOM' ;
#Para comprobar que el el nombre del dominio es correcto, se puede hacer:
# sudo /bin/nisdomainname -v
sudo ypbind;' < /dev/null
