#!/bin/bash

# Define las placas de red
NIC_1="enp2s0"
NIC_2="wlp3s0"

# Define los perfiles de red
# "IP" "CIDR/MASK" "GATEWAY" "DNS_1,DNS_2"
NET_PROFILE_1=("192.168.1.100" "24" "192.168.1.1" "8.8.8.8,8.8.4.4")
NET_PROFILE_2=("192.168.2.100" "24" "192.168.2.1" "8.8.8.8,8.8.4.4")
NET_PROFILE_3=("192.168.3.100" "255.255.255.0" "192.168.3.1" "8.8.8.8,8.8.4.4")
NET_PROFILE_8=("dhcp")

# Muestra menú de interfaces
menu_nic() {
    echo "Seleccione la placa de red a configurar:"
    echo "1. $NIC_1"
    echo "2. $NIC_2"
    echo "9. Salir."
}

# Muestra menú de perfiles
menu_profile(){
    echo "Seleccione el perfil que quiere aplicar:"
    echo "1. IP:${NET_PROFILE_1[0]}/${NET_PROFILE_1[1]} GW:${NET_PROFILE_1[2]}"
    echo "2. IP:${NET_PROFILE_2[0]}/${NET_PROFILE_2[1]} GW:${NET_PROFILE_2[2]}"
    echo "3. IP:${NET_PROFILE_3[0]}/${NET_PROFILE_3[1]} GW:${NET_PROFILE_3[2]}"
    echo "8. DHCP"
    echo "9. Salir."
}

# Comprueba si el usuario tiene privilegios de root
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ser ejecutado como root." 
   echo "Ejecute 'sudo ipprofile'." 
   exit 1
fi

# Limpia el texto en pantalla
clear

# Muestra un menú para seleccionar la placa de red a configurar
while true; do
    menu_nic
    read -p "Opción: " select_nic

    # Verifica la opción seleccionada
    case $select_nic in
        1)
            nic="$NIC_1"
            break;;
        2)
            nic="$NIC_2"
            break;;
        9)
            echo "Saliendo..."
            exit
            break;;
        *)
            echo "Opción inválida."
            ;;
    esac
done

# Muestra un menú para seleccionar la configuración de red a aplicar
while true; do
    menu_profile
    read -p "Opción: " select_profile

    # Verifica la opción seleccionada
    case $select_profile in
        1)
            net_profile=("${NET_PROFILE_1[@]}")
            break;;
        2)
            net_profile=("${NET_PROFILE_2[@]}")
            break;;
        3)
            net_profile=("${NET_PROFILE_3[@]}")
            break;;
        8)
            net_profile=("${NET_PROFILE_8[@]}")
            break;;
        9)
            echo "Saliendo..."
            exit
            break;;
        *)
            echo "Opción inválida."
            ;;
    esac
done

# Configura la placa de red con el perfil seleccionado
if [ "${net_profile[0]}" = "dhcp" ]; then
    echo "Configurando la placa de red $nic en DHCP"
    dhclient $nic
    ifconfig $nic down && ifconfig $nic up
else
    echo "Configurando la placa de red $nic con la IP:${net_profile[0]}/${net_profile[1]} y GW:${net_profile[2]}"
    ip addr flush dev $nic
    ip addr add ${net_profile[0]}/${net_profile[1]} dev $nic
    ip route add default via ${net_profile[2]}
    echo -n > /etc/resolv.conf
    dns_array=(${net_profile[3]//[, ]/ })
    for dns_server in "${dns_array[@]}"; do
        echo "nameserver $dns_server" >> /etc/resolv.conf
    done
fi
echo "La configuración de red se ha aplicado correctamente."