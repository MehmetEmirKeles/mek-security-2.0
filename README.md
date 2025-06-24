# MEK Security 2.0 🔒

A lightweight terminal-based network defense tool written in pure Bash.  
It detects MITM attacks, monitors suspicious traffic, enables/disables firewall, manages logs, and sends alerts via email.  
Supports both English and Turkish languages with an interactive terminal menu.



## 💡 Features

- 🧠 MITM attack detection  
- 📦 Packet monitoring  
- 🔥 Firewall control (enable/disable)  
- 📧 Email alerts via Gmail  
- 📜 Log file management  
- 🌐 Multilingual support: English / Turkish  
- 🧱 Simple and interactive terminal interface  

![image_alt](https://github.com/MehmetEmirKeles/mek-security-2.0/blob/main/eng.png?raw=true)

## 📦 Installation & Usage (English)

Run the following commands one by one:

```bash
git clone https://github.com/MehmetEmirKeles/mek-security-2.0.git
```
```
cd mek-security-2.0
```
```
chmod +x mek-security.sh
```
```
./mek-security.sh
```

### 📌 HOW TO GET A GMAIL APP PASSWORD? (OPTIONAL BUT REQUIRED TO USE GMAIL FEATURE)

1. Go to https://myaccount.google.com and sign in to your Google account.
2. Click the “Security” tab on the left menu.
3. Make sure “2-Step Verification” is turned ON.
4. Once enabled, you’ll see a new option called “App Passwords” on the same page.
5. Click on it and re-enter your password to confirm.
6. In the dropdown:
   - Select “Mail” as the app
   - Choose “Windows Computer” or "Linux" as the device
7. Click “Generate”.
8. A 16-character app password will appear. Copy it.
9. Use this app password in your program instead of your normal Gmail password.

📌 Note: This password is only for this specific app and is **not** your regular Gmail password!



# MEK Security 2.0 🔒
Bash ile yazılmış hafif ve terminal tabanlı bir ağ güvenlik aracıdır.
MITM saldırılarını algılar, şüpheli trafiği izler, güvenlik duvarını yönetir, logları temizler ve e-posta ile uyarı gönderir.
İngilizce ve Türkçe dillerini destekler, etkileşimli bir terminal menüsü içerir.

## 💡 Özellikler

🧠 MITM saldırı algılama

📦 Paket izleme

🔥 Güvenlik duvarı yönetimi (aktif/pasif)

📧 Gmail üzerinden e-posta uyarıları

📜 Log dosyası yönetimi

🌐 Çoklu dil desteği: Türkçe / İngilizce

🧱 Basit ve etkileşimli terminal arayüzü

![image_alt](https://github.com/MehmetEmirKeles/mek-security-2.0/blob/main/TR.png?raw=true)

## 📥 Kurulum ve Kullanım (Türkçe)
Aşağıdaki komutları sırasıyla çalıştır:

```
git clone https://github.com/MehmetEmirKeles/mek-security-2.0.git
```
```
cd mek-security-2.0
```
```
chmod +x mek-security.sh
```
```
./mek-security.sh
```
✅ Gereksinimler

### 🧱 1. İşletim Sistemi
Linux dağıtımı (test edilenler):

✅ Ubuntu 20.04+ / Debian 11+

✅ Arch Linux / Garuda Linux - Manjaro Linux - EndeavourOS

### 🔧 2. Temel Paketler ve Komutlar

| Gerekli Paket/Komut | Açıklama                                 | Ubuntu/Debian                  | Arch/Garuda                       |
| ------------------- | ---------------------------------------- | ------------------------------ | --------------------------------- |
| `bash`              | Script çalıştırma kabuğu                 | Varsayılan                     | Varsayılan                        |
| `coreutils`         | `base64` komutu için                     | Varsayılan                     | Varsayılan                        |
| `iproute2`          | `ip` komutu için                         | ✅ `sudo apt install iproute2`  | ✅ `sudo pacman -S iproute2`       |
| `net-tools`         | `arp`, `ifconfig` gibi eski komutlar     | ✅ `sudo apt install net-tools` | ✅ `sudo pacman -S net-tools`      |
| `dsniff`            | `arpspoof` aracı için                    | ✅ `sudo apt install dsniff`    | ✅ `yay -S dsniff`                 |
| `tcpdump`           | Ağ dinleme için (opsiyonel ama önerilir) | ✅ `sudo apt install tcpdump`   | ✅ `sudo pacman -S tcpdump`        |
| `iptables`          | Firewall yönetimi                        | ✅ `sudo apt install iptables`  | ✅ *`iptables-nft` yüklü kalmalı!* |
| `msmtp`             | Gmail SMTP ile e-posta göndermek için    | ✅ `sudo apt install msmtp`     | ✅ `sudo pacman -S msmtp`          |

### ✅ Kurulum Adımları (Örnek: Ubuntu)
```
sudo apt update
```
```
sudo apt install bash coreutils iproute2 net-tools dsniff tcpdump iptables msmtp
```
✅ Kurulum Adımları (Örnek: Arch/Garuda)
```
sudo pacman -S bash coreutils iproute2 net-tools tcpdump iptables msmtp
```
```
yay -S dsniff
```

### 📧 3. E-posta Bildirimi için Gerekli Bilgiler
- Gmail adresi

- Gmail uygulama şifresi (gizli olarak saklanır)

- Alıcı e-posta adresi


### 🔐 4. Yetki Gereksinimi
MEK Security, sistem düzeyinde ağ ve güvenlik kontrolü yaptığı için sudo yetkisi ile çalıştırılmalıdır:
```
sudo ./mek-security.sh
```

### 📌 GMAIL UYGULAMA PAROLASI NASIL ALINIR? (OPSIYONEL AMA GMAIL ÖZELLĞINI KULLANMAK IÇIN GEREKLI)

1. https://myaccount.google.com adresine gidin ve Google hesabınıza giriş yapın.
2. Sol menüden “Güvenlik” sekmesine tıklayın.
3. "2 Adımlı Doğrulama" aktif değilse, etkinleştirin.
4. Ardından aynı sayfada "Uygulama Parolaları" adlı yeni bir seçenek belirecek.
5. Bu bölüme girin ve şifrenizi yeniden girerek doğrulama yapın.
6. Açılan menüden:
   - Uygulama: “Mail” seçin
   - Cihaz: “Windows Bilgisayar” veya "Linux" seçin
7. “Oluştur” butonuna tıklayın.
8. Size özel 16 haneli bir uygulama parolası verilecek.
9. Bu parolayı kopyalayın ve uygulamanızda şifre yerine kullanın.

📌 Not: Bu parola sadece bu uygulama içindir, Gmail hesabınızın ana şifresi değildir!
