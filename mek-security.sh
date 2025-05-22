#!/bin/bash
# MEK - Terminal Güvenlik Aracı (v2.0)

# === Renk Tanımları ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

# === Global PID ve Log Dosyaları ===
mitm_pid=""
tracking_pid=""
attacker_monitor_pid=""
CONFIG_FILE="$HOME/.mekos_config"
LOG_FILE="$HOME/.mekos_saldirganlar.log"

# === Dil Seçimi ===
choose_language() {
    echo -e "Please select language option.\nLütfen dil seçeneğinizi seçin."
    echo -e "[1] Türkçe\n[2] English"
    read -p "Seçiminiz / Your choice (1-2): " lang_choice
    case $lang_choice in
        1) lang="tr" ;;
        2) lang="en" ;;
        *) echo "Geçersiz seçim / Invalid choice. Defaulting to Turkish."; lang="tr" ;;
    esac
}

# === İlk Kurulum ve Ayar Yükleme ===
load_or_create_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${CYAN}E-posta uyarı sistemi aktif edilsin mi? (e/h): ${RESET}"
        read -r use_email
        if [[ "$use_email" == "e" ]]; then
            read -p "Gmail adresiniz: " gmail_address
            echo -e "${CYAN}Gmail şifresini gizlemek ister misiniz? (e/h): ${RESET}"
            read -r hide_pass
            if [[ "$hide_pass" == "e" ]]; then
                read -s -p "Gmail uygulama şifreniz (gizli): " gmail_password
                echo
            else
                read -p "Gmail uygulama şifreniz (gözükecek): " gmail_password
            fi
            read -p "Hedef e-posta adresi: " receiver_email
            echo "email_enabled=true" > "$CONFIG_FILE"
            echo "gmail_address=$gmail_address" >> "$CONFIG_FILE"
            echo "gmail_password=$(echo "$gmail_password" | base64)" >> "$CONFIG_FILE"
            echo "receiver_email=$receiver_email" >> "$CONFIG_FILE"
        else
            echo "email_enabled=false" > "$CONFIG_FILE"
        fi
        chmod 600 "$CONFIG_FILE"
    fi
    source "$CONFIG_FILE"
    gmail_password_decoded=$(echo "$gmail_password" | base64 --decode)
}
# === E-Posta Gönderme Fonksiyonu (Dil destekli) ===
send_email_alert() {
    if [[ "$email_enabled" != "true" ]]; then return; fi
    local subject body
    if [[ "$lang" == "tr" ]]; then
        subject="Saldırgan Tespit Edildi!"
        body="Cihazınızda M.I.T.M saldırısı tespit edildi ve engellendi.\nSaldırgan cihazın MAC adresi: $attacker_mac\nIP adresi: $attacker_ip\nİyi günler."
    else
        subject="Attacker Detected!"
        body="M.I.T.M attack detected and blocked on your device.\nAttacking device MAC address: $attacker_mac\nIP address: $attacker_ip\nHave a nice day."
    fi
    echo -e "Subject: $subject\n\n$body" | msmtp --host=smtp.gmail.com --port=587 \
        --auth=on --tls=on \
        --user="$gmail_address" \
        --from="$gmail_address" \
        --passwordeval="echo $gmail_password_decoded" \
        "$receiver_email"
}

# === Sistem Paneli ===
print_dashboard() {
    echo -e "${CYAN}--- Sistem Durum Paneli ---${RESET}"
    if sudo ufw status | grep -q 'Status: active'; then
        echo -e "${GREEN}Firewall: Aktif${RESET}"
    else
        echo -e "${RED}Firewall: Kapalı${RESET}"
    fi
    [[ -n "$mitm_pid" ]] && echo -e "MITM İzleme: ${GREEN}Aktif${RESET}" || echo -e "MITM İzleme: ${RED}Pasif${RESET}"
    [[ -n "$tracking_pid" ]] && echo -e "Paket İzleme: ${GREEN}Aktif${RESET}" || echo -e "Paket İzleme: ${RED}Pasif${RESET}"
    if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
        last_attacker=$(tail -n 1 "$LOG_FILE")
        echo -e "Son Saldırgan: ${YELLOW}$last_attacker${RESET}"
        echo -e "Toplam Kayıt: $(wc -l < "$LOG_FILE")"
    else
        echo "Henüz saldırgan tespit edilmedi."
    fi
    echo "-----------------------------"
}

# === Banner ===
big_welcome() {
    clear
    if command -v figlet >/dev/null 2>&1; then
        figlet "WELCOME TO MEK SECURITY"
    else
        echo "WELCOME TO MEK SECURITY"
    fi
    echo -e "${GREEN}MEK - Güvenlik Aracı v2.0${RESET}"
}

# === Ana Menü ===
main_menu() {
    while true; do
        big_welcome
        print_dashboard
        echo -e "${CYAN}1. Firewall\n2. MITM Attack\n3. Paket İzleme\n4. Tespit Edilen Saldırganlar\n5. Logları Temizle\n6. Manuel IP / MAC Engelle\n7. Sistem Durumu Güncelle\n8. E-Posta Ayarlarını Güncelle\n9. Çıkış${RESET}"
        read -p $'\nSeçiminizi yapın (1-9): ' choice
        case $choice in
            1) firewall_menu;;
            2) mitm_menu;;
            3) packet_tracking_menu;;
            4) show_attackers;;
            5) clear_logs;;
            6) manual_block_menu;;
            7) print_dashboard; read -p "Devam için Enter...";;
            8) update_email_config;;
            9) exit_program;;
            *) echo -e "${RED}Geçersiz seçim.${RESET}"; read -p "Devam için Enter...";;
        esac
    done
}
firewall_menu() {
    clear; big_welcome
    echo -e "${CYAN}1. Firewall Aç\n2. Firewall Kapat\n3. Geri${RESET}"
    read -p "Seçim: " fopt
    [[ "$fopt" == "1" ]] && sudo ufw enable
    [[ "$fopt" == "2" ]] && sudo ufw disable
    read -p "Ana menüye dönmek için Enter..."
}

mitm_menu() {
    if [[ -z "$mitm_pid" ]]; then
        start_mitm_monitoring
    else
        stop_mitm_monitoring
    fi
    read -p "Devam etmek için Enter..."
}

packet_tracking_menu() {
    if [[ -z "$tracking_pid" ]]; then
        start_packet_tracking
    else
        stop_packet_tracking
    fi
    read -p "Devam etmek için Enter..."
}

start_mitm_monitoring() {
    mitm_loop &
    mitm_pid=$!
    monitor_attacker &
    attacker_monitor_pid=$!
    echo -e "${GREEN}MITM monitoring başlatıldı.${RESET}"
}

stop_mitm_monitoring() {
    kill "$mitm_pid" 2>/dev/null; mitm_pid=""
    [[ -n "$attacker_monitor_pid" ]] && kill "$attacker_monitor_pid" 2>/dev/null; attacker_monitor_pid=""
    echo -e "${RED}MITM monitoring durduruldu.${RESET}"
}

start_packet_tracking() {
    tracking_loop &
    tracking_pid=$!
    monitor_attacker &
    attacker_monitor_pid=$!
    echo -e "${GREEN}Packet tracking başlatıldı.${RESET}"
}

stop_packet_tracking() {
    kill "$tracking_pid" 2>/dev/null; tracking_pid=""
    [[ -n "$attacker_monitor_pid" ]] && kill "$attacker_monitor_pid" 2>/dev/null; attacker_monitor_pid=""
    echo -e "${RED}Packet tracking durduruldu.${RESET}"
}

mitm_loop() {
    while true; do sleep 10; done
}

tracking_loop() {
    while true; do ping -c 1 8.8.8.8 >/dev/null 2>&1; sleep 10; done
}

monitor_attacker() {
    iface=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
    self_ip=$(ip -4 addr show "$iface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
    while true; do
        packet=$(sudo timeout 10 tcpdump -nn -i "$iface" 'tcp[tcpflags] & tcp-syn != 0' 2>/dev/null | head -n 1)
        [ -z "$packet" ] && continue
        attacker_ip=$(echo "$packet" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)
        [[ "$attacker_ip" == "$self_ip" ]] && continue
        attacker_mac=$(arp -n | grep "$attacker_ip" | awk '{print $3}' | head -n 1)
        [ -z "$attacker_mac" ] && attacker_mac="MAC not found"
        echo -e "${MAGENTA}Saldırgan bulundu ve sisteme erişimi engellendi: IP: $attacker_ip, MAC: $attacker_mac${RESET}"
        echo "[$(date)] IP: $attacker_ip | MAC: $attacker_mac" >> "$LOG_FILE"
        send_email_alert
        sudo iptables -A INPUT -s "$attacker_ip" -j DROP
    done
}

show_attackers() {
    clear; echo -e "${YELLOW}Tespit Edilen Saldırganlar:${RESET}"
    if [ -f "$LOG_FILE" ]; then
        cat "$LOG_FILE"
    else
        echo "Kayıt yok."
    fi
    read -p "Devam etmek için Enter..."
}

clear_logs() {
    echo -e "${YELLOW}Saldırgan logları silinecek. Emin misiniz? (e/h): ${RESET}"
    read -r c1
    [[ "$c1" != "e" ]] && echo "İptal edildi." && return
    read -p "İkinci kez emin misiniz? (e/h): " c2
    [[ "$c2" == "e" ]] && rm -f "$LOG_FILE" && echo "Silindi." || echo "İptal edildi."
    read -p "Devam etmek için Enter..."
}

manual_block_menu() {
    clear
    echo -e "${CYAN}Manuel Engelleme${RESET}"
    echo -e "1. IP Engelle"
    echo -e "2. MAC Adresi Engelle"
    echo -e "3. Geri Dön"
    read -p "Seçiminiz: " block_choice
    case $block_choice in
        1)
            read -p "Engellemek istediğiniz IP: " ip
            sudo iptables -A INPUT -s "$ip" -j DROP
            echo "[$(date)] Manuel IP Engelleme: $ip" >> "$LOG_FILE"
            echo -e "${GREEN}$ip adresi engellendi.${RESET}"
            ;;
        2)
            read -p "Engellemek istediğiniz MAC: " mac
            sudo iptables -A INPUT -m mac --mac-source "$mac" -j DROP
            echo "[$(date)] Manuel MAC Engelleme: $mac" >> "$LOG_FILE"
            echo -e "${GREEN}$mac adresi engellendi.${RESET}"
            ;;
        3)
            return ;;
        *)
            echo -e "${RED}Geçersiz seçim.${RESET}" ;;
    esac
    read -p "Devam etmek için Enter..."
}

exit_program() {
    [[ -n "$mitm_pid" ]] && kill "$mitm_pid" 2>/dev/null
    [[ -n "$tracking_pid" ]] && kill "$tracking_pid" 2>/dev/null
    [[ -n "$attacker_monitor_pid" ]] && kill "$attacker_monitor_pid" 2>/dev/null
    echo -e "${RED}Çıkış yapılıyor...${RESET}"; exit 0
}

# === Başlat ===
choose_language
load_or_create_config
main_menu
