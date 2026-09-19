#!/usr/bin/env bash
# Genere des miniatures 296x164 pour une liste de fonds d'ecran.
#
# Usage: generate.sh <fichier_liste_chemins> <prefixe> <dossier_cache>
#
#   fichier_liste_chemins : un chemin source par ligne (texte brut
#                            UTF-8, pas de quoting ; ecrit par
#                            WallpaperPage.qml a partir de `find`).
#   prefixe                : "shipped" ou "user", pour nommer les
#                            fichiers de cache shipped-N.jpg / user-N.jpg
#                            (N = numero de ligne, 0-based).
#   dossier_cache           : ou ecrire les miniatures.
#
# Pourquoi un script separe plutot qu'une commande construite en QML :
# les fonds livres avec le shell peuvent peser plusieurs Mo en pleine
# resolution (jusqu'a 6400x3600). Qt doit decompresser l'integralite du
# fichier avant d'appliquer sourceSize, et decoder 20+ images de cette
# taille en meme temps sature le pool de threads de decodage asynchrone
# de Qt : la grille de selection reste grise un bon moment. On genere
# donc une fois de vraies miniatures legeres sur disque.
#
# Chaque chemin est lu directement depuis le fichier via `read`, jamais
# reinjecte dans une commande shell reconstruite en texte : ca evite
# tout risque de casse par quoting (espaces, parentheses) ou de
# corruption d'encodage (un essai precedent passait par un encodage
# base64 fait cote QML avec Qt.btoa, qui traite le texte en Latin1 et
# corrompt les caracteres non-ASCII comme les accents).
#
# Parallelisme via le job control bash natif (wait -n), pas xargs -I :
# xargs -I reinterpole chaque ligne dans une commande texte avant de
# l'executer, ce qui recreerait le meme risque de casse par quoting
# qu'on cherche justement a eviter ici.

set -euo pipefail

LIST_FILE="${1:?usage: generate.sh <fichier_liste> <prefixe> <dossier_cache>}"
PREFIX="${2:?usage: generate.sh <fichier_liste> <prefixe> <dossier_cache>}"
CACHE_DIR="${3:?usage: generate.sh <fichier_liste> <prefixe> <dossier_cache>}"

if command -v magick >/dev/null 2>&1; then
    CONV=magick
elif command -v convert >/dev/null 2>&1; then
    CONV=convert
else
    # Pas d'ImageMagick : rien a generer, WallpaperThumb.qml se rabat
    # sur l'original (plus lent au premier affichage, mais fonctionnel).
    exit 42
fi

mkdir -p "$CACHE_DIR"

convert_one() {
    local idx="$1" src="$2" dst tmp
    dst="$CACHE_DIR/$PREFIX-$idx.jpg"
    # Source disparue entre le scan et la generation (fichier supprime,
    # dossier change entre-temps) : on saute plutot que d'echouer.
    [ -f "$src" ] || return 0
    # Deja a jour : rien a faire. "-nt" est aussi vrai si dst n'existe
    # pas encore, donc ce test couvre les deux cas (absent ou perime).
    if [ -f "$dst" ] && [ ! "$src" -nt "$dst" ]; then
        return 0
    fi
    tmp="$dst.tmp.$$"
    if "$CONV" "$src" -resize 296x164^ -gravity center -extent 296x164 -quality 80 "$tmp"; then
        mv "$tmp" "$dst"
    else
        rm -f "$tmp"
    fi
}

# Au plus MAX_JOBS conversions ImageMagick en meme temps : un process
# par image sans limite reproduirait, cote CPU cette fois, le meme
# probleme de saturation que ce script cherche a resoudre cote decodage
# Qt. Degrade proprement sur une machine mono-coeur (l'attente sur
# "wait -n" ne bloque jamais plus d'une iteration dans ce cas).
MAX_JOBS=4
running=0
idx=0
while IFS= read -r src; do
    convert_one "$idx" "$src" &
    running=$((running + 1))
    idx=$((idx + 1))
    if [ "$running" -ge "$MAX_JOBS" ]; then
        wait -n
        running=$((running - 1))
    fi
done < "$LIST_FILE"
wait
