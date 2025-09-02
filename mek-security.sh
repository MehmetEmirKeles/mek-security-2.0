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

# === İzleme Ayarları ===
LOCAL_ONLY="false"
WHITELIST_FILE="$HOME/.mekos_whitelist"
WHITELIST=()

# WHITELIST dosyası varsa oku
if [[ -f "$WHITELIST_FILE" ]]; then
    mapfile -t WHITELIST < "$WHITELIST_FILE"
fi


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

# === E-Posta Ayarlarını Güncelle ===
update_email_config() {
    if [[ "$lang" == "tr" ]]; then
        echo -e "${CYAN}E-posta uyarı sistemi aktif edilsin mi? (e/h): ${RESET}"
    else
        echo -e "${CYAN}Enable email alert system? (y/n): ${RESET}"
    fi
    read -r use_email

    if [[ "$use_email" == "e" || "$use_email" == "y" ]]; then
        if [[ "$lang" == "tr" ]]; then
            read -p "Gmail adresiniz: " gmail_address
            echo -e "${CYAN}Gmail şifresini gizlemek ister misiniz? (e/h): ${RESET}"
        else
            read -p "Your Gmail address: " gmail_address
            echo -e "${CYAN}Do you want to hide your Gmail password? (y/n): ${RESET}"
        fi
        read -r hide_pass

        if [[ "$hide_pass" == "e" || "$hide_pass" == "y" ]]; then
            if [[ "$lang" == "tr" ]]; then
                read -s -p "Gmail uygulama şifreniz (gizli): " gmail_password
                echo
            else
                read -s -p "Your Gmail app password (hidden): " gmail_password
                echo
            fi
        else
            if [[ "$lang" == "tr" ]]; then
                read -p "Gmail uygulama şifreniz (gözükecek): " gmail_password
            else
                read -p "Your Gmail app password (visible): " gmail_password
            fi
        fi

        if [[ "$lang" == "tr" ]]; then
            read -p "Hedef e-posta adresi: " receiver_email
        else
            read -p "Target email address: " receiver_email
        fi

        echo "email_enabled=true" > "$CONFIG_FILE"
        echo "gmail_address=$gmail_address" >> "$CONFIG_FILE"
        echo "gmail_password=$(echo "$gmail_password" | base64)" >> "$CONFIG_FILE"
        echo "receiver_email=$receiver_email" >> "$CONFIG_FILE"
    else
        echo "email_enabled=false" > "$CONFIG_FILE"
    fi

    chmod 600 "$CONFIG_FILE"
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
    gmail_password_decoded=$(echo "$gmail_password" | base64 --decode)

    if [[ "$lang" == "tr" ]]; then
        echo -e "${GREEN}Ayarlar güncellendi.${RESET}"
        read -p "Devam etmek için Enter..."
    else
        echo -e "${GREEN}Settings updated.${RESET}"
        read -p "Press Enter to continue..."
    fi
}

clear_logs() {
    if [[ "$lang" == "tr" ]]; then
        read -p "Logları temizlemek istediğine emin misin? (e/h): " first_confirm
        if [[ "$first_confirm" != "e" ]]; then
            echo -e "${YELLOW}İşlem iptal edildi.${RESET}"
            return
        fi
        read -p "Gerçekten emin misin? (e/h): " second_confirm
        if [[ "$second_confirm" != "e" ]]; then
            echo -e "${YELLOW}İşlem iptal edildi.${RESET}"
            return
        fi
        > "$LOG_FILE"
        echo -e "${GREEN}Log dosyası başarıyla temizlendi.${RESET}"
    else
        read -p "Are you sure you want to clear the logs? (y/n): " first_confirm
        if [[ "$first_confirm" != "y" ]]; then
            echo -e "${YELLOW}Operation cancelled.${RESET}"
            return
        fi
        read -p "Are you really sure? (y/n): " second_confirm
        if [[ "$second_confirm" != "y" ]]; then
            echo -e "${YELLOW}Operation cancelled.${RESET}"
            return
        fi
        > "$LOG_FILE"
        echo -e "${GREEN}Log file successfully cleared.${RESET}"
    fi
}

# === Sistem Paneli ===
print_dashboard() {
    if [[ "$lang" == "tr" ]]; then
        echo -e "${CYAN}--- Sistem Durum Paneli ---${RESET}"
    else
        echo -e "${CYAN}--- System Status Panel ---${RESET}"
    fi

    # Firewall durumu
    if sudo ufw status | grep -q 'Status: active'; then
        [[ "$lang" == "tr" ]] && echo -e "${GREEN}Firewall: Aktif${RESET}" || echo -e "${GREEN}Firewall: Active${RESET}"
    else
        [[ "$lang" == "tr" ]] && echo -e "${RED}Firewall: Kapalı${RESET}" || echo -e "${RED}Firewall: Inactive${RESET}"
    fi

    # MITM ve Paket İzleme durumları
    if [[ -n "$mitm_pid" ]]; then
        [[ "$lang" == "tr" ]] && echo -e "MITM İzleme: ${GREEN}Aktif${RESET}" || echo -e "MITM Monitoring: ${GREEN}Active${RESET}"
    else
        [[ "$lang" == "tr" ]] && echo -e "MITM İzleme: ${RED}Pasif${RESET}" || echo -e "MITM Monitoring: ${RED}Inactive${RESET}"
    fi

    if [[ -n "$tracking_pid" ]]; then
        [[ "$lang" == "tr" ]] && echo -e "Paket İzleme: ${GREEN}Aktif${RESET}" || echo -e "Packet Monitoring: ${GREEN}Active${RESET}"
    else
        [[ "$lang" == "tr" ]] && echo -e "Paket İzleme: ${RED}Pasif${RESET}" || echo -e "Packet Monitoring: ${RED}Inactive${RESET}"
    fi

    # Son saldırgan
    if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
        last_attacker=$(tail -n 1 "$LOG_FILE")
        if [[ "$lang" == "tr" ]]; then
            echo -e "Son Saldırgan: ${YELLOW}$last_attacker${RESET}"
            echo -e "Toplam Kayıt: $(wc -l < "$LOG_FILE")"
        else
            echo -e "Last Attacker: ${YELLOW}$last_attacker${RESET}"
            echo -e "Total Logs: $(wc -l < "$LOG_FILE")"
        fi
    else
        [[ "$lang" == "tr" ]] && echo "Henüz saldırgan tespit edilmedi." || echo "No attackers detected yet."
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

    if [[ "$lang" == "tr" ]]; then
        echo -e "${GREEN}MEK - Güvenlik Aracı v2.0${RESET}"
    else
        echo -e "${GREEN}MEK - Security Tool v2.0${RESET}"
    fi
}


# === Ana Menü ===
main_menu() {
    while true; do
        big_welcome
        print_dashboard

        if [[ "$lang" == "tr" ]]; then
            echo -e "${CYAN}1. Firewall\n2. MITM Saldırısı\n3. Paket İzleme\n4. Tespit Edilen Saldırganlar\n5. Logları Temizle\n6. Manuel IP / MAC Engelle\n7. Sistem Durumu Güncelle\n8. E-Posta Ayarlarını Güncelle\n9. Çıkış${RESET}"
            read -p $'\nSeçiminizi yapın (1-9): ' choice
        else
            echo -e "${CYAN}1. Firewall\n2. MITM Attack\n3. Packet Monitoring\n4. Detected Attackers\n5. Clear Logs\n6. Block IP / MAC Manually\n7. Refresh System Status\n8. Update Email Settings\n9. Exit${RESET}"
            read -p $'\nChoose an option (1-9): ' choice
        fi

        case $choice in
            1) firewall_menu;;
            2) mitm_menu;;
            3) packet_tracking_menu;;
            4) show_attackers;;
            5) clear_logs;;
            6) manual_block_menu;;
            7) print_dashboard; [[ "$lang" == "tr" ]] && read -p "Devam etmek için Enter..." || read -p "Press Enter to continue...";;
            8) update_email_config;;
            9) exit_program;;
            *)
                if [[ "$lang" == "tr" ]]; then
                    echo -e "${RED}Geçersiz seçim.${RESET}"
                    read -p "Devam etmek için Enter..."
                else
                    echo -e "${RED}Invalid choice.${RESET}"
                    read -p "Press Enter to continue..."
                fi
                ;;
        esac
    done
}

firewall_menu() {
    clear; big_welcome
    echo -e "${CYAN}1. Firewall Aç\n2. Firewall Kapat\n3. Geri${RESET}"
    read -p "Seçim: " fopt
    [[ "$fopt" == "1" ]] && sudo ufw enable
    [[ "$fopt" == "2" ]] && sudo ufw disable
[[ "$lang" == "tr" ]] && read -p "Ana menüye dönmek için Enter..." || read -p "Press Enter to return to main menu..."
}

mitm_menu() {
    if [[ -z "$mitm_pid" ]]; then
        start_mitm_monitoring
    else
        stop_mitm_monitoring
    fi
[[ "$lang" == "tr" ]] && read -p "Devam etmek için Enter..." || read -p "Press Enter to continue..."
}

packet_tracking_menu() {
    if [[ -z "$tracking_pid" ]]; then
        start_packet_tracking
    else
        stop_packet_tracking
    fi
[[ "$lang" == "tr" ]] && read -p "Devam etmek için Enter..." || read -p "Press Enter to continue..."
}

start_mitm_monitoring() {
    if [[ "$lang" == "tr" ]]; then
        echo -e "${CYAN}Sadece yerel ağdaki IP'leri takip etmek ister misiniz? (e/h): ${RESET}"
    else
        echo -e "${CYAN}Do you want to monitor only local (LAN) IPs? (y/n): ${RESET}"
    fi

    read -r local_choice

    if [[ "$local_choice" == "e" || "$local_choice" == "y" ]]; then
        LOCAL_ONLY="true"
    else
        LOCAL_ONLY="false"
    fi

    mitm_loop &
    mitm_pid=$!
    monitor_attacker &
    attacker_monitor_pid=$!

    if [[ "$lang" == "tr" ]]; then
        echo -e "${GREEN}MITM izleme başlatıldı.${RESET}"
    else
        echo -e "${GREEN}MITM monitoring started.${RESET}"
    fi
}

stop_mitm_monitoring() {
    kill "$mitm_pid" 2>/dev/null; mitm_pid=""
    [[ -n "$attacker_monitor_pid" ]] && kill "$attacker_monitor_pid" 2>/dev/null; attacker_monitor_pid=""
    if [[ "$lang" == "tr" ]]; then
        echo -e "${RED}MITM izleme durduruldu.${RESET}"
    else
        echo -e "${RED}MITM monitoring stopped.${RESET}"
    fi
}

start_packet_tracking() {
    tracking_loop &
    tracking_pid=$!
    monitor_attacker &
    attacker_monitor_pid=$!
if [[ "$lang" == "tr" ]]; then
    echo -e "${GREEN}Paket izleme başlatıldı.${RESET}"
else
    echo -e "${GREEN}Packet tracking started.${RESET}"
fi
}

stop_packet_tracking() {
    kill "$tracking_pid" 2>/dev/null; tracking_pid=""
    [[ -n "$attacker_monitor_pid" ]] && kill "$attacker_monitor_pid" 2>/dev/null; attacker_monitor_pid=""
    if [[ "$lang" == "tr" ]]; then
        echo -e "${RED}Paket izleme durduruldu.${RESET}"
    else
        echo -e "${RED}Packet tracking stopped.${RESET}"
    fi
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

        # WHITELIST kontrolü (önce)
        for safe_ip in "${WHITELIST[@]}"; do
            if [[ "$attacker_ip" == "$safe_ip" ]]; then
                if [[ "$lang" == "tr" ]]; then
                    echo -e "${YELLOW}Beyaz listedeki IP tespit edildi: $attacker_ip — atlanıyor.${RESET}"
                else
                    echo -e "${YELLOW}Whitelisted IP detected: $attacker_ip — skipping.${RESET}"
                fi
                continue 2
            fi
        done

        # LOCAL_ONLY kontrolü (sonra)
        if [[ "$LOCAL_ONLY" == "true" ]]; then
            if ! [[ "$attacker_ip" =~ ^(192\.168|10\.|172\.(1[6-9]|2[0-9]|3[0-1])) ]]; then
                if [[ "$lang" == "tr" ]]; then
                    echo -e "${YELLOW}Yerel dışı IP atlandı: $attacker_ip${RESET}"
                else
                    echo -e "${YELLOW}Non-local IP skipped: $attacker_ip${RESET}"
                fi
                continue
            fi
        fi

        # Kendi IP'sini görmezden gel
        [[ "$attacker_ip" == "$self_ip" ]] && continue

        attacker_mac=$(arp -n | grep "$attacker_ip" | awk '{print $3}' | head -n 1)
        [ -z "$attacker_mac" ] && attacker_mac="MAC not found"

        if [[ "$lang" == "tr" ]]; then
            echo -e "${MAGENTA}Saldırgan bulundu ve sisteme erişimi engellendi: IP: $attacker_ip, MAC: $attacker_mac${RESET}"
        else
            echo -e "${MAGENTA}Attacker detected and blocked: IP: $attacker_ip, MAC: $attacker_mac${RESET}"
        fi

        echo "[$(date)] IP: $attacker_ip | MAC: $attacker_mac" >> "$LOG_FILE"
        send_email_alert
        sudo iptables -A INPUT -s "$attacker_ip" -j DROP
    done
}

show_attackers() {
    clear

    if [[ "$lang" == "tr" ]]; then
        echo -e "${YELLOW}Tespit Edilen Saldırganlar:${RESET}"
    else
        echo -e "${YELLOW}Detected Attackers:${RESET}"
    fi

    if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
        cat "$LOG_FILE"
    else
        if [[ "$lang" == "tr" ]]; then
            echo "Kayıt yok."
        else
            echo "No logs found."
        fi
    fi

    if [[ "$lang" == "tr" ]]; then
        read -p "Devam etmek için Enter..."
    else
        read -p "Press Enter to continue..."
    fi
}

manual_block_menu() {
    clear

    # Menü başlığı ve seçim alma
    if [[ "$lang" == "tr" ]]; then
        echo -e "${CYAN}Manuel Engelleme${RESET}"
        echo -e "1. IP Engelle"
        echo -e "2. MAC Adresi Engelle"
        echo -e "3. Geri Dön"
        read -p "Seçiminiz: " block_choice
    else
        echo -e "${CYAN}Manual Block${RESET}"
        echo -e "1. Block IP"
        echo -e "2. Block MAC Address"
        echo -e "3. Go Back"
        read -p "Your choice: " block_choice
    fi

    case $block_choice in
        1)
            if [[ "$lang" == "tr" ]]; then
                read -p "Engellemek istediğiniz IP: " ip
                sudo iptables -A INPUT -s "$ip" -j DROP
                echo "[$(date)] Manuel IP Engelleme: $ip" >> "$LOG_FILE"
                echo -e "${GREEN}$ip adresi engellendi.${RESET}"
            else
                read -p "IP to block: " ip
                sudo iptables -A INPUT -s "$ip" -j DROP
                echo "[$(date)] Manual IP Blocked: $ip" >> "$LOG_FILE"
                echo -e "${GREEN}$ip has been blocked.${RESET}"
            fi
            ;;
        2)
            if [[ "$lang" == "tr" ]]; then
                read -p "Engellemek istediğiniz MAC: " mac
                sudo iptables -A INPUT -m mac --mac-source "$mac" -j DROP
                echo "[$(date)] Manuel MAC Engelleme: $mac" >> "$LOG_FILE"
                echo -e "${GREEN}$mac adresi engellendi.${RESET}"
            else
                read -p "MAC address to block: " mac
                sudo iptables -A INPUT -m mac --mac-source "$mac" -j DROP
                echo "[$(date)] Manual MAC Blocked: $mac" >> "$LOG_FILE"
                echo -e "${GREEN}$mac address has been blocked.${RESET}"
            fi
            ;;
        3)
            return
            ;;
        *)
            if [[ "$lang" == "tr" ]]; then
                echo -e "${RED}Geçersiz seçim.${RESET}"
            else
                echo -e "${RED}Invalid choice.${RESET}"
            fi
            ;;
    esac

    # Devam promptu
    if [[ "$lang" == "tr" ]]; then
        read -p "Devam etmek için Enter..."
    else
        read -p "Press Enter to continue..."
    fi
}

exit_program() {
    [[ -n "$mitm_pid" ]] && kill "$mitm_pid" 2>/dev/null
    [[ -n "$tracking_pid" ]] && kill "$tracking_pid" 2>/dev/null
    [[ -n "$attacker_monitor_pid" ]] && kill "$attacker_monitor_pid" 2>/dev/null

    if [[ "$lang" == "tr" ]]; then
        echo -e "${RED}Çıkış yapılıyor...${RESET}"
    else
        echo -e "${RED}Exiting...${RESET}"
    fi

    exit 0
}

# === Script Başlatılıyor ===
choose_language
load_or_create_config
main_menu
