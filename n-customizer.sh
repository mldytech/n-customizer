#!/bin/bash

# -----------------------------------------------------------------------------
# Script Name: n-customizer.sh
# Description: Simple script to preconfigure debian based linux systems for the lectures of the Faculty of Information Technology (N), University of Applied Sciences Mannheim
# Author: github.com/mldytech
# Date: 2024-10-28
# Version: 1.1
# License: MIT
# 
# Usage: ./n-customizer.sh [options]
# 
# Options:
#   -h, --help     Show the help menu
#   [...]
# 
# Example:
#   bash n-customizer.sh -help
# 
# Notes:
#   - As this is a new script, please feel free to add changes, enhancements and improvements. No claim to correctness.
# 
# Restrictions:
#   - Currently only works with debian based systems using the apt-package manager
#   - Some functions may be restricted to specific DE's (tested with debian + gnome)
#   - ZSH may not work
#
# Planned Features:
#   - Install and configure OpenConnect VPN (via. networkmanager)
#   - For GNOME: Configure some useful extensions
#   - More software via. wine (e. g. LTSpice, ARM Keil, ...)
#
# Credits:
#   - to openmensa.org for providing the canteens api
# -----------------------------------------------------------------------------


#function for printing red
print_red() {
    local RED_BOLD='\033[1;31m'
    local NC='\033[0m'
    echo -e "${RED_BOLD}$1${NC}"
}

#welcome message
echo "N - Customizer" | figlet

#exit script if error occurs
set -e

#check if distro uses apt
#if ! command -v apt &> /dev/null; then
#    print_red "Error: The system does not use the apt package manager."
#    exit 1
#fi

#wallpaper
#IMAGE_PATH="$(dirname -- "${BASH_SOURCE[0]}")/wallpaper.jpg"

#apt packages and flatpaks
GENERAL_PACKAGES=("figlet" "git" "vim" "curl" "wget" "jq" "ufw" "tldr" "x2goclient" "timeshift" "htop") 

OOP_PACKAGES=(
                "build-essential" "gcc" "g++" "valgrind" "gdb" "make" "cmake" "openjdk-17-jre" "openjdk-17-jdk" 
                "visualvm" "googletest" "libgtest-dev" "libsfml-dev" "libsdl2-dev")

HPS_PACKAGES=(
                "python3" "python3-dev" "python3-virtualenv" "python3-examples" "python3-tk" "python3-pip" "python3-numpy" 
                "python3-matplotlib" "python3-cffi" "python3-scipy" "ipython3" "python3-httplib2" "python3-netifaces" "python3-pandas" 
                "python3-bs4" "python3-requests" "python3-six" "python3-werkzeug" "python3-psycopg2" "python3-reportlab" 
                "python3-setuptools" "python3-pil" "python3-lxml" "python3-yaml")

SET_PACKAGES=("qtcreator" "libgl1-mesa-dev" "doxygen")
IOT_PACKAGES=("wireshark" "docker.io" "docker-compose")
MISC_PACKAGES=("docker.io" "docker-compose" "libreoffice" "thunderbird" "keepassxc" "wine" "vlc" "audacity" "xournalpp")
FLATPAKS=("com.emqx.MQTTX" "com.github.tchx84.Flatseal" "org.raspberrypi.rpi-imager" "com.jgraph.drawio.desktop")
ECLIPSE_URL="https://ftp.halifax.rwth-aachen.de/eclipse/technology/epp/downloads/release/2024-09/R/eclipse-cpp-2024-09-R-linux-gtk-x86_64.tar.gz"
LTSPICE_URL="https://ltspice.analog.com/software/LTspice64.msi"

show_help() {
    echo "Verwendung: $0 [OPTIONEN]"
    echo ""
    echo "OPTIONEN:"
    echo "  -all                    Führt alle Optionen (ohne Zusatzfunktionen) aus."
    echo "  -packages               Installiert die für die Vorlesungen benötigten Standardpakete."
    echo "  -morepackages           Installiert einige zusätzliche Pakete die das Leben erleichtern."
    echo "  -firewall               Installiert und aktiviert die Firewall (UFW)."
    echo "  -flatpak                Installiert Flatpak (Repo: Flathub) und einige relevanten Flatpaks"
    echo "  -eclipse                Installiert Eclipse IDE für C/C++"
    echo "  -vivado                 Installiert den Installer für Xilinx Vivado Design Suite (Spezifische Pakete werden dort ausgewählt)"
    echo "  -codium                 Installiert VS-Codium"
    echo "  -mensa                  Installiert ein Bash-Alias um die Hochschulmensa abzufragen"
    echo "  -help                   Zeigt dieses Hilfsmenü an."
    echo ""
    echo "ZUSATZFUNKTIONEN:"
    echo "  -ltspice                Installiert LTSPice (via. wine)"
}

#install apt packages
install_packages() {
    echo "Installing packages: ${GENERAL_PACKAGES[*]} ${OOP_PACKAGES[*]} ${SET_PACKAGES[*]} ${CN_PACKAGES[*]} ${HPS_PACKAGES[*]}"
    sudo apt update
    sudo apt install -y "${GENERAL_PACKAGES[@]}"
    sudo apt install -y "${OOP_PACKAGES[@]}"
    sudo apt install -y "${SET_PACKAGES[@]}"
    sudo apt install -y "${CN_PACKAGES[@]}"
    sudo apt install -y "${HPS_PACKAGES[@]}"
}

#install more apt packages
install_more_packages() {
    echo "Installing packages: ${MISC_PACKAGES[*]}"
    sudo apt update
    sudo apt install -y "${MISC_PACKAGES[@]}"
}

#configure flatpak (flathub) and install some flatpaks
install_flatpak() {
    sudo apt install -y flatpak
    if [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
        sudo apt install gnome-software-plugin-flatpak
    elif [[ "$XDG_CURRENT_DESKTOP" == "KDE" ]]; then
        sudo apt install plasma-discover-backend-flatpak
    else
        print_red "No Flatpak GUI plugin for desktop environment: $XDG_CURRENT_DESKTOP. You can still use the flatpak cli tool."
    fi    

    echo "Adding flathub remote.."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    echo "Installing some flatpaks:"
    
    for flatpak in "${FLATPAKS[@]}"; do
        flatpak install -y "$flatpak"
    done
}

#change wallpaper
#change_wallpaper() {
#    if [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
#         gsettings set org.gnome.desktop.background picture-uri "file:///$IMAGE_PATH"  
#         echo "Wallpaper successfully changed"
#    else
#        print_red "Changing wallpaper is only suported for the GNOME DE"
#    fi
#}

#configure and enable ufw
configure_firewall() {
    sudo apt install -y ufw
    sudo ufw enable
    echo "ufw installed and enabled"
}

#install vivado
install_vivado(){
    echo "installing vivado"
    if ! command -v flatpak &> /dev/null; then
        echo "Flatpak not installed. Restart the script using the flag -flatpak first"    
        exit 1;
    else
        flatpak install -y com.github.corna.Vivado
    fi
}

install_codium(){
    echo "installing vscodium"
    wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
    echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list
    sudo apt update && sudo apt install codium
}

#install eclipse
install_eclipse(){
    INSTALL_DIR="$HOME"
    TEMP_DIR=$(mktemp -d)
    wget -O "$TEMP_DIR/eclipse.tar.gz" "$ECLIPSE_URL"
    tar -xzf "$TEMP_DIR/eclipse.tar.gz" -C "$INSTALL_DIR" 2>/dev/null
    if ! grep -q "export PATH=\$PATH:$INSTALL_DIR" ~/.bashrc; then
        echo "Adding Eclipse to PATH"
        echo "export PATH=\$PATH:$INSTALL_DIR/eclipse" >> ~/.bashrc
    else
        print_red "Eclipse already existed in PATH"
    fi
    #cleanup
    rm -rf "$TEMP_DIR"
}

#install ltspice via. wine (not included in -all)
install_ltspice(){
    echo "coming soon"
    #TEMP_DIR=$(mktemp -d)
    #wget -O "$TEMP_DIR/LTSpice64.msi" "$LTSPICE_URL"
    #wine "$TEMP_DIR/LTSpice64.msi"
    #rm -rf "$TEMP_DIR"
}

mensa_alias(){
    ALIAS_TODAY='curl -X GET "https://openmensa.org/api/v2/canteens/289/days/$(date +%Y-%m-%d)/meals" 2>/dev/null | jq -r ".[] | select(.category == \"Menü 1\" or .category == \"Menü vegan\" or .category == \"MA(h)l was anderes\") | \"\(.category): \(.name) - Preis für Studenten: \(.prices.students)€\""'
    ALIAS_TODAY_NAME="mensa"

    #check if bash (not zsh)
    if [ "$SHELL" != "/bin/bash" ] && [ "$SHELL" != "/usr/bin/bash" ]; then
        print_red "Error: Only works with bash, not: $SHELL"
        exit 1
    fi    
    
    if ! grep -q "alias $ALIAS_TODAY_NAME" ~/.bashrc; then
        echo "Creating Mensa-Alias in .bashrc"
        echo "alias $ALIAS_TODAY_NAME='$ALIAS_TODAY'" >> ~/.bashrc
    else
        print_red "Mensa-Alias already existed."
    fi    
}

#check command line arguments
if [ "$#" -eq 0 ]; then
    show_help
else
    for arg in "$@"; do
        case $arg in
            -packages)
                print_red "Installing necessary packages.."
                install_packages
                ;;
            -more_packages)
                print_red "Installing more (useful) packages.."
                install_more_packages
                ;;                
            -firewall)
                print_red "Installing and enabling the firewall.."
                configure_firewall
                ;;
            -flatpak)
                print_red "Installing Flatpak.."
                install_flatpak
                ;;      
            -vivado)
                print_red "Installing the Vivado Design-Suite for FPGA Design.."
                install_vivado
                ;;             
            -eclipse)
                print_red "Installing the Eclipse IDE for C/C++.."
                install_eclipse
                ;;    
            -codium)
                print_red "Installing VS-Codium, an open-source fork of Visual Studio Code.."
                install_codium
                ;;            
            -mensa)
                print_red "Adding a mensa-alias to .bashrc. You can use \"mensa\" in the terminal to query to daily menu.."
                mensa_alias
                ;;                          
            -all)
                install_packages
                install_more_packages
                configure_firewall
                install_flatpak
                install_vivado
                install_eclipse
                install_codium
                mensa_alias
                ;; 
            -ltspice)
                print_red "Installing LTSpice through wine. Just click through the installer and keep the default settings."
                install_ltspice
                ;;                 
            -h|--help|-help)
                show_help
                ;;                                                                  
            *)
                print_red "Unknown Argument: $arg"
                show_help
                exit 1
                ;;
        esac
    done
fi
