# AdminSistemasInformaticos:

El objetivo principal de dicho proyecto consistía en crear una serie de scripts que fueran capaces de, a través de ficheros de configuración, gestionar una serie de máquinas conectadas a una red NAT

En script principal (configurar_cluster.sh) se encarga de ir llamando al resto de sub-scripts (mount.sh, raid.sh, lvm.sh, etc.) y controlar su salida en caso de tener que reportar algún error.
