#!/bin/bash

# Kontrola, zda byl zadán port jako parametr
if [ -z "$1" ]; then
    echo "Použití: $0 <číslo_portu>"
    echo "Příklad: $0 80"
    exit 1
fi

# Uložení portu z parametru
PORT=$1

# Ověření, že je port číslo
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
    echo "Chyba: Port musí být číslo mezi 1 a 65535."
    exit 1
fi

echo "Kontrola omezení komunikace na port $PORT (TCP)..."
echo "----------------------------------------"

# 1. Kontrola firewalld
echo "1. Stav firewalld:"
if systemctl is-active firewalld >/dev/null 2>&1; then
    echo "firewalld běží."
    echo "Povolené služby a porty v aktivní zóně:"
    firewall-cmd --list-all
    if ! firewall-cmd --list-ports | grep -q "$PORT/tcp"; then
        echo "Port $PORT/tcp není explicitně povolen."
    else
        echo "Port $PORT/tcp je povolen."
    fi
else
    echo "firewalld není aktivní."
fi

# 2. Kontrola iptables
echo -e "\n2. Stav iptables:"
if command -v iptables >/dev/null 2>&1; then
    echo "Pravidla pro port $PORT:"
    iptables -L -n -v | grep -i "$PORT" || echo "Žádná pravidla pro port $PORT nenalezena."
else
    echo "iptables není nainstalován."
fi

# 3. Kontrola SELinux
echo -e "\n3. Stav SELinux:"
if command -v getenforce >/dev/null 2>&1; then
    echo "SELinux stav: $(getenforce)"
    echo "Porty povolené pro SELinux (hledám $PORT):"
    semanage port -l | grep -w "$PORT" || echo "Port $PORT není explicitně přiřazen žádné službě."
else
    echo "SELinux není nainstalován."
fi

# 4. Kontrola TCP Wrappers
echo -e "\n4. TCP Wrappers:"
echo "hosts.allow (hledám služby na portu $PORT):"
# Hledání podle běžných služeb, které mohou používat zadaný port (dynamicky omezené)
grep -E "ALL|$PORT" /etc/hosts.allow 2>/dev/null || echo "Žádné relevantní záznamy nenalezeny."
echo "hosts.deny:"
grep -E "ALL|$PORT" /etc/hosts.deny 2>/dev/null || echo "Žádné relevantní záznamy nenalezeny."

# 5. Kontrola naslouchání na portu
echo -e "\n5. Naslouchání na portu $PORT:"
ss -tuln | grep ":$PORT" || echo "Nic nenaslouchá na portu $PORT."

# 6. Detekce běžících služeb (dynamicky podle portu)
echo -e "\n6. Stav potenciálních služeb na portu $PORT:"
SERVICES=""
case $PORT in
    22) SERVICES="sshd" ;;
    80) SERVICES="httpd nginx" ;;
    443) SERVICES="httpd nginx" ;;
    21) SERVICES="vsftpd" ;;
    25) SERVICES="postfix" ;;
    *) echo "Není známa konkrétní služba pro port $PORT, přeskočení kontroly." ;;
esac

if [ -n "$SERVICES" ]; then
    for service in $SERVICES; do
        if systemctl is-active "$service" >/dev/null 2>&1; then
            echo "$service běží."
        else
            echo "$service neběží."
        fi
    done
fi

# 7. Test dostupnosti portu (lokálně)
echo -e "\n7. Test lokální dostupnosti portu $PORT:"
if nc -z -w 2 127.0.0.1 "$PORT" 2>/dev/null; then
    echo "Port $PORT je lokálně dostupný."
else
    echo "Port $PORT není lokálně dostupný (nic neposlouchá nebo je blokován)."
fi

echo -e "\nKontrola dokončena."
