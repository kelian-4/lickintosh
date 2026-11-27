#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Lanceur POSIX de setup.fish : installe fish s'il manque, puis lui passe la main.
# Tous les arguments sont transmis tels quels a setup.fish.

set -eu

repo=$(cd "$(dirname "$0")" && pwd -P)

lang=en
for v in "${LICKINTOSH_LANG:-}" "${LC_ALL:-}" "${LC_MESSAGES:-}" "${LANG:-}"; do
    [ -n "$v" ] || continue
    case $v in
        [Ff][Rr]*) lang=fr ;;
        [Ee][Ss]*) lang=es ;;
        *) lang=en ;;
    esac
    break
done

# t "francais" "english" "espanol"
t() {
    case $lang in
        fr) printf '%s\n' "$1" ;;
        es) printf '%s\n' "$3" ;;
        *) printf '%s\n' "$2" ;;
    esac
}

if [ ! -f "$repo/setup.fish" ]; then
    t "setup.fish introuvable dans $repo." \
      "setup.fish not found in $repo." \
      "No se encuentra setup.fish en $repo." >&2
    exit 1
fi

if command -v fish >/dev/null 2>&1; then
    exec fish "$repo/setup.fish" "$@"
fi

if [ "$(id -u)" -eq 0 ]; then
    t "Ne lance pas setup.sh en root : il demande sudo lui-meme quand il en a besoin." \
      "Don't run setup.sh as root: it asks for sudo itself when needed." \
      "No ejecutes setup.sh como root: pide sudo por si mismo cuando lo necesita." >&2
    exit 1
fi

assume_yes=0
for a in "$@"; do
    case $a in
        -y|--yes) assume_yes=1 ;;
    esac
done

as_root() {
    if [ -n "${LICKINTOSH_ROOT_CMD:-}" ]; then
        $LICKINTOSH_ROOT_CMD "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    elif command -v doas >/dev/null 2>&1; then
        doas "$@"
    else
        t "Ni sudo ni doas : lance cette commande en root : $*" \
          "Neither sudo nor doas: run this command as root: $*" \
          "Ni sudo ni doas: ejecuta este comando como root: $*" >&2
        return 1
    fi
}

install_cmd=
if [ -e /run/ostree-booted ]; then
    install_cmd=
elif command -v pacman >/dev/null 2>&1; then
    install_cmd="pacman -S --needed --noconfirm fish"
elif command -v apt-get >/dev/null 2>&1; then
    install_cmd="apt-get install -y fish"
elif command -v dnf >/dev/null 2>&1; then
    install_cmd="dnf install -y fish"
elif command -v zypper >/dev/null 2>&1; then
    install_cmd="zypper --non-interactive install fish"
elif command -v xbps-install >/dev/null 2>&1; then
    install_cmd="xbps-install -y fish-shell"
elif command -v apk >/dev/null 2>&1; then
    install_cmd="apk add fish"
elif command -v emerge >/dev/null 2>&1; then
    install_cmd="emerge --noreplace app-shells/fish"
fi

if [ -z "$install_cmd" ]; then
    t "fish est introuvable et aucun gestionnaire de paquets connu n'a ete detecte. Installe fish (https://fishshell.com), puis relance ./setup.sh." \
      "fish is missing and no known package manager was found. Install fish (https://fishshell.com), then run ./setup.sh again." \
      "fish no esta instalado y no se encontro ningun gestor de paquetes conocido. Instala fish (https://fishshell.com) y vuelve a ejecutar ./setup.sh." >&2
    exit 1
fi

t "L'installeur de lickintosh a besoin de fish, qui n'est pas installe." \
  "The lickintosh installer needs fish, which is not installed." \
  "El instalador de lickintosh necesita fish, que no esta instalado."
t "Commande : $install_cmd" "Command: $install_cmd" "Comando: $install_cmd"

if [ "$assume_yes" -ne 1 ]; then
    hint="y/N"
    [ "$lang" = fr ] && hint="o/N"
    [ "$lang" = es ] && hint="s/N"
    printf '%s [%s] ' "$(t "Installer fish maintenant ?" "Install fish now?" "Instalar fish ahora?")" "$hint"
    answer=
    read -r answer || answer=
    case $answer in
        [YyOoSs]*) ;;
        *)
            t "Annule. Installe fish, puis relance ./setup.sh." \
              "Cancelled. Install fish, then run ./setup.sh again." \
              "Cancelado. Instala fish y vuelve a ejecutar ./setup.sh." >&2
            exit 1
            ;;
    esac
fi

case $install_cmd in
    apt-get*) as_root apt-get update || true ;;
esac

# shellcheck disable=SC2086
if ! as_root $install_cmd || ! command -v fish >/dev/null 2>&1; then
    t "L'installation de fish a echoue. Installe-le a la main, puis relance ./setup.sh." \
      "Installing fish failed. Install it by hand, then run ./setup.sh again." \
      "La instalacion de fish fallo. Instalalo a mano y vuelve a ejecutar ./setup.sh." >&2
    exit 1
fi

exec fish "$repo/setup.fish" "$@"
