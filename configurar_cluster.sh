#!/bin/bash
# ==============================================================================================================
# Autores:
# --------
# - Pablo Fernández Díaz, v130148
# - Víctor Viller Mori, t110010
# ==============================================================================================================
# Fichero: ./configurar_cluster.sh
# --------------------------------
# Fichero de ejecución principal. Primero ejecutará un bucle comprobando que todas las líneas cuentan con tres
#	"palabras": Una dirección IP, un nombre de servicio y un fichero de configuración. Un segundo bucle
#	comprobará que el formato de la IP proporcionada es correcto, que el nombre del servicio existe y que
#	el fichero de configuración existe y es legible. Una vez comprobado esto para todas las líneas, se
#	procederá a la ejecución de los servicios línea a línea.
# ==============================================================================================================

# Comprobacion de argumentos. Debe de ser 1 (./configurar_cluster.sh fichero)
if [ $# -ne 1 ]; then
	echo "Error 1: El número de argumentos de la ejecución a de ser únicamente 1."
	exit 1
fi

# Lectura linea a linea del fichero. Se descarta aquellas lineas que empiece por # o lineas en blanco
# Comprueba si el fichero existe y es legible
if [ ! -f $1 ]; then
	echo "Error 2: El fichero no existe."
	exit 2
elif [ -f $1 ] && [ ! -r $1 ]; then
	echo "Error 3: El fichero no es legible."
	exit 3
else
	# Lectura linea por linea del fichero. En este primer bucle se comprobará que por cada línea hay tres
	#	palabras. En caso de que una de las líneas no cumple con este requisito, la ejecución parará.
	numLinea=1;
	# Lectura del fichero de entrada
	while read linea; do
		# Instrucción que recoge el número de "palabras" que hay en esa línea. Debe de ser 3. (IP, 
		#	mandato y fichero de configuración)
		numeroPalabras=$(echo $linea | wc -w);
		# Se descarta las que empiece por comentario o sean saltos de líneas
		if [[ $linea == *"#"* ]]; then
			NUM_LINEA_FICH=$((NUM_LINEA_FICH+1));
			continue;
		elif [ $numeroPalabras -eq 0 ]; then
			NUM_LINEA_FICH=$((NUM_LINEA_FICH+1));
			continue;
		else
			# Comprobamos que la línea actual cuenta con tres "palabras" o mandatos.
			if [ $numeroPalabras -ne 3 ] && [ $numeroPalabras -gt 0 ]; then
				echo "Error 4: En la línea "$numLinea" del fichero no se cumple el formato: debe de ser 3 palabras."
				exit 4
			fi
			numLinea=$((numLinea+1))
		fi
	done < $1	# Fichero de entrada
fi

# Una vez sabemos que el número de argumentos del fichero de entrada es correcto, procedemos a 
#	comprobar que tienen un formato correcto
numLinea=1;
# Lectura del fichero de entrada
while read linea
do
	# Si es un comentario o un salto de línea, evitamos estas comprobaciones.
	numeroPalabras=$(echo $linea | wc -w);
	if [[ ! $linea == *"#"* ]] && [ $numeroPalabras -gt 0 ]; then
		numPalabra=1;
		for palabra in $linea; do
			# La primera "palabra" tiene que ser una dirección IP. Se llama a un script que lo compruebe.
			if [ $numPalabra -eq 1 ]; then
				./checks/ipaddress.sh $palabra $numLinea
			# La segunda comprobación tiene que ser un nombre de servicio válido y existente.
			elif [ $numPalabra -eq 2 ]; then
				if [ $palabra = "mount" ] || [ $palabra = "raid" ] || [ $palabra = "lvm" ] || [ $palabra = "nis_server" ] || 
					[ $palabra = "nis_client" ] || [ $palabra = "nfs_server" ] || [ $palabra = "nfs_client" ] || 
					[ $palabra = "backup_server" ] || [ $palabra = "backup_client" ]; then
					echo "Nombre de comando de la línea "$numLinea" correcto."
				else
					echo "Error 7: El nombre del comando especificado en la línea "$numLinea" no existe."
					exit 7
				fi
			# El último argumento es el fichero de configuración. Este tiene que existir y ser legible.
			else
				if [ ! -f $palabra ]; then
					echo "Error 8: El fichero de configuración de la línea "$numLinea" no existe."
					exit 8
				elif [ -f $palabra ] && [ ! -r $palabra ]; then
					echo "Error 9: El fichero de configuración de la línea "$numLinea" no es legible."
					exit 9
				else
					echo "Fichero especificado en la línea "$numLinea" es accesible y legible."
				fi
			fi
			numPalabra=$((numPalabra+1))
		done
	fi
	numLinea=$((numLinea+1))
done < $1	# Fichero de entrada

# El último paso es la ejecución de los servicios línea a línea. Se procede a volver a leer el fichero.
numLinea=1;
ipAddress='';		# Dirección IP
commandName='';		# Nombre del servicio
file='';		# Fichero de configuración
# Lectura del fichero de entrada
while read linea
do
	# Nos saltamos los comentarios y los saltos de línea.
	numeroPalabras=$(echo $linea | wc -w);
	if [[ $linea == *"#"* ]]; then
		NUM_LINEA_FICH=$((NUM_LINEA_FICH+1));
		continue;
	elif [ $numeroPalabras -eq 0 ]; then
		NUM_LINEA_FICH=$((NUM_LINEA_FICH+1));
		continue;
	else
		# Se asignan los parámetros IP, nombre del comando y fichero de configuración a variables para
		#	ser usadas en la ejecución de los servicios.
		numPalabra=1;
		for palabra in $linea; do
			if [ $numPalabra -eq 1 ]; then
				ipAddress=$palabra		# Dirección IP
			elif [ $numPalabra -eq 2 ]; then
				commandName=$palabra		# Nombre del servicio
			else
				file=$palabra			# Fichero de configuración
			fi
			numPalabra=$((numPalabra+1))
		done
		
		# Se llamará al servicio con la dirección IP proporcionada y el fichero de configuración.
		if [ "$commandName" = "mount" ]; then
		    ./services/mount.sh $ipAddress $file
		elif [ "$commandName" = "raid" ]; then
		    ./services/raid.sh $ipAddress $file
		elif [ "$commandName" = "lvm" ]; then
		    ./services/lvm.sh $ipAddress $file
		elif [ "$commandName" = "nis_server" ]; then
		    ./services/nis_server.sh $ipAddress $file
		elif [ "$commandName" = "nis_client" ]; then
		    ./services/nis_client.sh $ipAddress $file
		elif [ "$commandName" = "nfs_server" ]; then
			./services/nfs_server.sh $ipAddress $file
		elif [ "$commandName" = "nfs_client" ]; then
			./services/nfs_client.sh $ipAddress $file
		elif [ "$commandName" = "backup_server" ]; then
			./services/backup_server.sh $ipAddress $file
		elif [ "$commandName" = "backup_client" ]; then
			./services/backup_client.sh $ipAddress $file
		fi
	fi
done < $1 	# Fichero de entrada

# Fin del programa.
exit 0
