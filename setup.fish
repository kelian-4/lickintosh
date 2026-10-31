#!/usr/bin/env fish

set -l repo (realpath (status dirname))
set -l qs_dst ~/.config/quickshell
set -l fonts_dst ~/.local/share/fonts/SF
set -l icons_dst ~/.icons
set -l hypr_dst ~/.config/hypr

set -l setup_only_assets fonts icons_desktop MacOS-Tahoe-Cursor config
set -l managed shell.qml settings.qml components services ui tools

argparse skip-deps no-launch -- $argv; or exit 1

if test (id -u) -eq 0
    echo "Ne lance pas setup.fish en root : les fichiers seraient installes pour root. Il demande sudo lui-meme quand il en a besoin." >&2
    exit 1
end

set -l shell_replaced 0
set -l blocking
set -l warnings

function ask --argument-names question
    read -l -P "$question [o/N] " reply; or return 1
    string match -qr '^(o|O|oui|Oui|y|Y|yes)$' -- $reply
end

function say
    echo "==> $argv"
end

function have_any
    for c in $argv
        command -q $c; and return 0
    end
    return 1
end

function version_ge --argument-names have want
    test -n "$have"; or return 1
    test (printf '%s\n%s\n' $want $have | sort -V | head -1) = $want
end

function as_root
    if command -q sudo
        sudo $argv
    else if command -q doas
        doas $argv
    else
        echo "    ni sudo ni doas : lance cette commande en root : $argv" >&2
        return 1
    end
end

function os_field --argument-names file key
    test -r $file; or return 0
    sed -n "s/^$key=//p" $file | head -1 | string replace -ar '["\']' '' | string lower
end

function detect_family --argument-names os_id os_like
    if test -e /run/ostree-booted
        echo ostree
        return
    end
    for id in $os_id (string split ' ' -- $os_like)
        switch $id
            case nixos
                echo nixos
                return
            case arch archarm cachyos endeavouros manjaro garuda artix
                echo arch
                return
            case debian ubuntu linuxmint pop raspbian elementary zorin neon kali
                echo debian
                return
            case fedora rhel centos rocky almalinux nobara
                echo fedora
                return
            case opensuse opensuse-leap opensuse-tumbleweed opensuse-slowroll sles suse
                echo suse
                return
            case void
                echo void
                return
            case alpine
                echo alpine
                return
            case gentoo
                echo gentoo
                return
        end
    end
    for pair in pacman:arch apt-get:debian dnf:fedora zypper:suse xbps-install:void apk:alpine emerge:gentoo
        set -l parts (string split : $pair)
        if command -q $parts[1]
            echo $parts[2]
            return
        end
    end
    echo unknown
end

function pkg_for --argument-names family item
    switch $item
        case mod_graphs
            switch $family
                case arch
                    echo qt6-graphs
                case debian
                    echo qml6-module-qtgraphs
                case fedora
                    echo qt6-qtgraphs
            end
        case mod_vectorimage
            switch $family
                case arch
                    echo qt6-svg
                case debian
                    echo qml6-module-qtquick-vectorimage
                case fedora
                    echo qt6-qtsvg
            end
        case mod_declarative
            switch $family
                case arch
                    echo qt6-declarative
                case debian
                    printf '%s\n' qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts qml6-module-qtquick-window qml6-module-qtquick-effects qml6-module-qtquick-shapes qml6-module-qtquick-templates qml6-module-qt-labs-folderlistmodel
                case fedora
                    echo qt6-qtdeclarative
            end
        case qt_wayland
            switch $family
                case fedora
                    echo qt6-qtwayland
                case '*'
                    echo qt6-wayland
            end
        case nmapplet
            switch $family
                case debian
                    echo network-manager-gnome
                case '*'
                    echo network-manager-applet
            end
        case imagemagick
            switch $family
                case fedora
                    echo ImageMagick
                case '*'
                    echo imagemagick
            end
        case pipewire
            switch $family
                case debian
                    echo pipewire-bin
                case fedora
                    echo pipewire-utils
                case '*'
                    echo pipewire
            end
        case networkmanager
            switch $family
                case debian
                    echo network-manager
                case fedora
                    echo NetworkManager
                case '*'
                    echo networkmanager
            end
        case bluez
            switch $family
                case arch
                    printf '%s\n' bluez bluez-utils
                case '*'
                    echo bluez
            end
        case '*'
            echo $item
    end
end

function pkg_available --argument-names family pkg
    switch $family
        case arch
            pacman -Si $pkg >/dev/null 2>&1
        case debian
            set -l cand (apt-cache policy $pkg 2>/dev/null | string match -r 'Candidate: (\S+)')[2]
            test -n "$cand"; and test "$cand" != "(none)"
        case fedora
            dnf -q info $pkg >/dev/null 2>&1
        case '*'
            return 1
    end
end

function pkg_installed --argument-names family pkg
    switch $family
        case arch
            pacman -Qi $pkg >/dev/null 2>&1
        case debian
            dpkg-query -W -f='${Status}' $pkg 2>/dev/null | grep -q 'install ok installed'
        case fedora
            rpm -q $pkg >/dev/null 2>&1
        case '*'
            return 1
    end
end

function pkg_install --argument-names family
    set -l pkgs $argv[2..-1]
    switch $family
        case arch
            as_root pacman -S --needed --noconfirm $pkgs
        case debian
            as_root apt-get install -y $pkgs
        case fedora
            as_root dnf install -y $pkgs
        case '*'
            return 1
    end
end

function install_quickshell --argument-names family os_id os_like
    switch $family
        case arch
            as_root pacman -S --needed --noconfirm quickshell
        case debian
            if pkg_available debian quickshell
                as_root apt-get install -y quickshell
            else if contains -- ubuntu $os_id (string split ' ' -- $os_like)
                echo "    quickshell n'est pas dans les depots de cette version. Le guide officiel indique le PPA ppa:avengemedia/danklinux."
                ask "    Ajouter ce PPA (depot tiers) puis installer quickshell ?"; or return 1
                as_root apt-get install -y software-properties-common; or return 1
                as_root add-apt-repository -y ppa:avengemedia/danklinux; or return 1
                as_root apt-get update; or return 1
                as_root apt-get install -y quickshell
            else
                echo "    quickshell n'est pas dans les depots de cette version de Debian (seulement testing et unstable)."
                return 1
            end
        case fedora
            if pkg_available fedora quickshell
                as_root dnf install -y quickshell
            else
                echo "    quickshell n'est pas dans les depots actifs. Le guide officiel indique le COPR errornointernet/quickshell."
                ask "    Activer ce COPR (depot tiers) puis installer quickshell ?"; or return 1
                as_root dnf copr enable -y errornointernet/quickshell; or return 1
                as_root dnf install -y quickshell
            end
        case '*'
            return 1
    end
end

function quickshell_hint --argument-names family
    switch $family
        case suse
            echo "    openSUSE : depot Open Build Service home:AvengeMedia:danklinux (paquet quickshell), voir https://quickshell.org/docs/v0.3.0/guide/install-setup"
        case gentoo
            echo "    Gentoo (en root) : emerge eselect-repository ; eselect repository enable guru ; emerge --sync guru ; emerge gui-apps/quickshell"
        case nixos
            echo "    NixOS : ajoute quickshell (nixpkgs) a ta configuration ou a ton profil"
        case ostree
            echo "    Systeme immuable : installe quickshell dans une couche (rpm-ostree) ou une boite, puis relance setup.fish"
        case '*'
            echo "    Installe Quickshell 0.2 ou plus avec le gestionnaire de ta distribution ou depuis les sources : https://quickshell.org/docs/v0.3.0/guide/install-setup"
    end
end

function missing_items
    for pair in $argv
        set -l parts (string split -m1 : $pair)
        have_any (string split '|' $parts[1]); or echo $parts[2]
    end
end

function refresh_index --argument-names family
    set -q __idx_refreshed; and return 0
    set -g __idx_refreshed 1
    test $family = debian; and as_root apt-get update
    return 0
end

function install_items --argument-names family
    set -l pkgs
    for item in $argv[2..-1]
        for p in (pkg_for $family $item)
            pkg_installed $family $p; and continue
            if pkg_available $family $p
                contains -- $p $pkgs; or set -a pkgs $p
            else
                echo "    indisponible : $p" >&2
            end
        end
    end
    test (count $pkgs) -eq 0; and return 0
    echo "    installation : $pkgs"
    pkg_install $family $pkgs
end

function module_item --argument-names mod
    switch $mod
        case QtGraphs
            echo mod_graphs
        case QtQuick.VectorImage
            echo mod_vectorimage
        case 'Quickshell*'
            echo quickshell
        case '*'
            echo mod_declarative
    end
end

function qml_missing --argument-names bin
    set -l dir (mktemp -d)
    set -l i 0
    for m in $argv[2..-1]
        set i (math $i + 1)
        if test $m = Quickshell
            printf 'import Quickshell\nShellRoot { Component.onCompleted: Qt.quit() }\n' > $dir/$i.qml
        else
            printf 'import %s\nimport Quickshell\nShellRoot { Component.onCompleted: Qt.quit() }\n' $m > $dir/$i.qml
        end
        env QT_QPA_PLATFORM=offscreen timeout 10 $bin -p $dir/$i.qml --no-color > $dir/$i.log 2>&1 &
    end
    wait
    set i 0
    for m in $argv[2..-1]
        set i (math $i + 1)
        grep -qF "module \"$m\"" $dir/$i.log; and echo $m
    end
    rm -rf $dir
end

function backup --argument-names file
    test -e $file; and cp -a $file $file.bak-(date +%Y%m%d-%H%M%S)
end

function ini_get --argument-names file section key
    test -f $file; or return 0
    awk -F= -v s="[$section]" -v k="$key" '$0==s{f=1;next} /^\[/{f=0} f&&$1==k{sub(/^[^=]*=/,"");print;exit}' $file
end

function ini_set --argument-names file section key value
    set -l tmp (mktemp)
    if test -f $file
        awk -v s="[$section]" -v k="$key" -v v="$value" 'BEGIN{FS="="} { if ($0==s) {insec=1; print; next} if ($0 ~ /^\[/) { if (insec && !done) {print k"="v; done=1}; insec=0 } if (insec && $1==k) { if (!done) {print k"="v; done=1}; next } print } END { if (insec && !done) print k"="v; else if (!done) {print ""; print s; print k"="v} }' $file > $tmp
    else
        printf '[%s]\n%s=%s\n' $section $key $value > $tmp
    end
    mkdir -p (dirname $file)
    cat $tmp > $file
    rm -f $tmp
end

if not test -f $repo/shell.qml
    echo "shell.qml introuvable dans $repo : setup.fish doit rester a la racine du depot." >&2
    exit 1
end

say "Prerequis"
set -l family unknown
set -l auto 0
set -l qs_bin

if set -q _flag_skip_deps
    echo "    ignores"
    for c in qs quickshell
        if command -q $c
            set qs_bin $c
            break
        end
    end
else
    set -l os_id (os_field /etc/os-release ID)
    set -l os_like (os_field /etc/os-release ID_LIKE)
    set family (detect_family "$os_id" "$os_like")
    contains -- $family arch debian fedora; and set auto 1
    echo "    distribution : $family"

    set -l req 'magick|convert:imagemagick' brightnessctl:brightnessctl playerctl:playerctl wl-copy:wl-clipboard grim:grim slurp:slurp hyprpicker:hyprpicker jq:jq curl:curl xdg-open:xdg-utils xdg-user-dir:xdg-user-dirs pw-dump:pipewire wpctl:wireplumber nmcli:networkmanager bluetoothctl:bluez upower:upower powerprofilesctl:power-profiles-daemon
    set -l missing_req (missing_items $req)

    if test $auto -eq 1
        if test (count $missing_req) -gt 0
            echo "    outils requis manquants : $missing_req"
            if ask "    Les installer ?"
                refresh_index $family
                install_items $family $missing_req
            else
                set -a warnings "outils requis manquants : $missing_req"
            end
        end
    else
        test (count $missing_req) -gt 0; and set -a warnings "outils requis manquants : $missing_req"
    end

    for c in qs quickshell
        if command -q $c
            set qs_bin $c
            break
        end
    end
    set -l qs_ver
    set -l qs_ok 1
    if test -z "$qs_bin"
        set qs_ok 0
        echo "    Quickshell absent"
    else
        set qs_ver ($qs_bin --version 2>/dev/null | head -1 | string match -r '\d+\.\d+\.\d+')
        if test -n "$qs_ver"; and not version_ge $qs_ver 0.2.0
            set qs_ok 0
            echo "    Quickshell $qs_ver trop ancien : le shell demande 0.2.0 ou plus"
        end
    end
    if test $qs_ok -eq 0
        if test $auto -eq 1; and ask "    Installer ou mettre a jour quickshell ?"
            refresh_index $family
            install_quickshell $family "$os_id" "$os_like"
        else
            quickshell_hint $family
        end
        set qs_bin
        for c in qs quickshell
            if command -q $c
                set qs_bin $c
                break
            end
        end
        set qs_ver
        test -n "$qs_bin"; and set qs_ver ($qs_bin --version 2>/dev/null | head -1 | string match -r '\d+\.\d+\.\d+')
        if test -z "$qs_bin"; or begin; test -n "$qs_ver"; and not version_ge $qs_ver 0.2.0; end
            set -a blocking "quickshell 0.2 ou plus est requis"
        end
    end

    if test -n "$qs_bin"; and not contains -- "quickshell 0.2 ou plus est requis" $blocking
        echo "    Quickshell $qs_ver ok"
        if test "$qs_bin" != qs
            set -a warnings "la commande qs est absente (seulement $qs_bin)"
        end
        set -l mods QtQuick Quickshell QtQuick.Layouts QtQuick.Controls QtQuick.VectorImage QtQuick.Effects QtQuick.Window QtQuick.Shapes QtGraphs Qt.labs.folderlistmodel Quickshell.Io Quickshell.Wayland Quickshell.Hyprland Quickshell.Widgets Quickshell.Services.UPower Quickshell.Bluetooth Quickshell.Services.Pipewire Quickshell.Services.Notifications Quickshell.Services.SystemTray Quickshell.Services.Pam Quickshell.Services.Mpris
        set -l missing_mods (qml_missing $qs_bin $mods)
        if test (count $missing_mods) -gt 0
            echo "    modules QML manquants : $missing_mods"
            set -l items
            set -l builtin
            for m in $missing_mods
                set -l it (module_item $m)
                if test $it = quickshell
                    set -a builtin $m
                else
                    contains -- $it $items; or set -a items $it
                end
            end
            test (count $builtin) -gt 0; and set -a blocking "ton Quickshell est compile sans : $builtin"
            if test (count $items) -gt 0
                if test $auto -eq 1; and ask "    Installer les paquets Qt correspondants ?"
                    refresh_index $family
                    install_items $family $items
                else
                    echo "    paquets manquants : "(for i in $items; pkg_for $family $i; end)
                end
                set -l still
                for m in (qml_missing $qs_bin $mods)
                    contains -- $m $builtin; or set -a still $m
                end
                if test (count $still) -gt 0
                    set -a blocking "modules QML toujours manquants : $still (Qt 6.8 ou plus est necessaire pour QtGraphs et VectorImage)"
                end
            end
        else
            echo "    modules QML : tous presents"
        end
    end

    if test -d /run/systemd/system; and command -q systemctl
        if test $family != nixos
            set -l sys_off
            for u in NetworkManager bluetooth upower power-profiles-daemon
                systemctl cat $u.service >/dev/null 2>&1; or continue
                systemctl is-active --quiet $u.service; or set -a sys_off $u.service
            end
            if test (count $sys_off) -gt 0
                echo "    services systeme inactifs : $sys_off"
                if ask "    Les activer maintenant ?"
                    as_root systemctl enable --now $sys_off
                else
                    set -a warnings "services inactifs : $sys_off"
                end
            end
            set -l usr_off
            for u in pipewire.socket wireplumber.service
                systemctl --user cat $u >/dev/null 2>&1; or continue
                systemctl --user is-active --quiet $u; or set -a usr_off $u
            end
            if test (count $usr_off) -gt 0
                echo "    services utilisateur inactifs : $usr_off"
                if ask "    Les activer maintenant ?"
                    systemctl --user enable --now $usr_off
                else
                    set -a warnings "services utilisateur inactifs : $usr_off"
                end
            end
        end
    end

    set -l hv
    command -q Hyprland; and set hv (Hyprland --version 2>/dev/null | head -1 | string match -r '\d+\.\d+\.\d+')
    if test -z "$hv"
        if command -q Hyprland
            echo "    version de Hyprland illisible"
        else
            set -a warnings "Hyprland est introuvable (la config hyprlua demande 0.57 ou plus)"
        end
    else if version_ge $hv 0.57.0
        echo "    Hyprland $hv ok"
    else
        set -a warnings "Hyprland $hv : la config hyprlua (Lua) demande 0.57 ou plus"
    end
end

say "Polices"
set -l fonts (find $repo/assets/fonts -type f \( -iname '*.otf' -o -iname '*.ttf' \) 2>/dev/null | sort)
if test (count $fonts) -eq 0
    echo "    aucune police dans assets/fonts, etape ignoree"
else
    set -l conflicts
    for f in $fonts
        test -e $fonts_dst/(basename $f); and set -a conflicts (basename $f)
    end
    set -l overwrite 0
    if test (count $conflicts) -gt 0
        echo "    "(count $conflicts)" police(s) existent deja dans $fonts_dst"
        ask "    Ecraser les polices existantes ?"; and set overwrite 1
    end
    mkdir -p $fonts_dst
    set -l installed 0
    for f in $fonts
        set -l name (basename $f)
        if test -e $fonts_dst/$name; and test $overwrite -eq 0
            continue
        end
        cp -f $f $fonts_dst/$name; and set installed (math $installed + 1)
    end
    echo "    $installed police(s) installee(s), "(math (count $fonts) - $installed)" ignoree(s)"
    if test $installed -gt 0
        command -q fc-cache; and fc-cache -f $fonts_dst
    end
end

say "Icones"
set -l themes (find $repo/assets/icons_desktop -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
if test (count $themes) -eq 0
    echo "    aucun theme dans assets/icons_desktop, etape ignoree"
else
    mkdir -p $icons_dst
    for t in $themes
        set -l name (basename $t)
        if test -e $icons_dst/$name; or test -L $icons_dst/$name
            if ask "    $icons_dst/$name existe deja. Le remplacer ?"
                rm -rf $icons_dst/$name
            else
                echo "    $name conserve"
                continue
            end
        end
        cp -a $t $icons_dst/$name; and echo "    $name installe"
        command -q gtk-update-icon-cache; and gtk-update-icon-cache -f -q $icons_dst/$name 2>/dev/null
    end
end

say "Curseur"
set -l cursor_src $repo/assets/MacOS-Tahoe-Cursor
if not test -d $cursor_src
    echo "    assets/MacOS-Tahoe-Cursor est absent, etape ignoree"
else
    test -d $cursor_src/cursors; or echo "    attention : $cursor_src ne contient pas de dossier cursors"
    set -l cursor_install 1
    if test -e $icons_dst/MacOS-Tahoe-Cursor; or test -L $icons_dst/MacOS-Tahoe-Cursor
        if ask "    $icons_dst/MacOS-Tahoe-Cursor existe deja. Le remplacer ?"
            rm -rf $icons_dst/MacOS-Tahoe-Cursor
        else
            set cursor_install 0
            echo "    MacOS-Tahoe-Cursor conserve"
        end
    end
    if test $cursor_install -eq 1
        mkdir -p $icons_dst
        cp -a $cursor_src $icons_dst/MacOS-Tahoe-Cursor; and echo "    MacOS-Tahoe-Cursor installe"
    end
end

say "Shell Quickshell ($qs_dst)"
set -l present
for e in $managed assets
    test -e $qs_dst/$e; and set -a present $e
end

set -l do_shell 1
if test (count $present) -gt 0
    echo "    deja present : $present"
        if ask "    Remplacer le code du shell ? Une sauvegarde est faite avant."
        set -l backup $qs_dst.bak-(date +%Y%m%d-%H%M%S)
        mkdir -p $backup
        for e in $present
            cp -a $qs_dst/$e $backup/$e
            rm -rf $qs_dst/$e
        end
        echo "    sauvegarde : $backup"
    else
        set do_shell 0
        echo "    shell conserve tel quel"
    end
end

if test $do_shell -eq 1
    mkdir -p $qs_dst
    for e in $managed
        test -e $repo/$e; and cp -r $repo/$e $qs_dst/$e
    end
    mkdir -p $qs_dst/assets
    for d in $repo/assets/*
        test -d $d; or continue
        contains -- (basename $d) $setup_only_assets; and continue
        rm -rf $qs_dst/assets/(basename $d)
        cp -r $d $qs_dst/assets/(basename $d)
    end
    for f in $repo/assets/*
        test -f $f; and cp -f $f $qs_dst/assets/
    end
    echo "    shell copie dans $qs_dst"
    set shell_replaced 1

    for d in $qs_dst/*/
        if test -f $d/shell.qml
            echo "    note : "(basename $d)" contient un shell.qml ; qs -c "(basename $d)" ne le trouvera plus (qs -p $d reste possible)"
        end
    end
    pgrep -x quickshell >/dev/null 2>&1; and echo "    Quickshell tourne deja : relance-le completement pour charger la nouvelle copie."
end

say "Configuration Hyprland ($hypr_dst)"
set -l hypr_src $repo/assets/config/hypr
set -l hypr_files (find $hypr_src -type f 2>/dev/null | sort)
if test (count $hypr_files) -eq 0
    echo "    assets/config/hypr est absent, etape ignoree"
else
    set -l hypr_copied 0
    for f in $hypr_files
        set -l rel (string replace -- "$hypr_src/" "" $f)
        set -l dst $hypr_dst/$rel
        test -f $dst; and cmp -s $f $dst; and continue
        backup $dst
        mkdir -p (dirname $dst)
        cp -f $f $dst; and set hypr_copied (math $hypr_copied + 1)
    end
    echo "    $hypr_copied fichier(s) installe(s)"
end

say "Applications GTK (dconf)"
if not command -q dconf
    echo "    dconf est introuvable, etape ignoree"
else
    set -l dconf_keys /org/gnome/desktop/interface/icon-theme /org/gnome/desktop/interface/color-scheme /org/gnome/desktop/interface/font-name /org/gnome/desktop/interface/document-font-name /org/gnome/desktop/wm/preferences/button-layout /org/gnome/desktop/interface/cursor-theme /org/gnome/desktop/interface/cursor-size
    set -l dconf_vals "'MacTahoe-dark'" "'prefer-dark'" "'SF Pro Text 10'" "'SF Pro Text 10'" "'close,minimize,maximize:'" "'MacOS-Tahoe-Cursor'" 24
    set -l pending
    for i in (seq (count $dconf_keys))
        set -l cur (dconf read $dconf_keys[$i])
        if test "$cur" != "$dconf_vals[$i]"
            set -a pending $i
            echo "    $dconf_keys[$i] : "(test -n "$cur"; and echo $cur; or echo "(non defini)")" -> $dconf_vals[$i]"
        end
    end
    if test (count $pending) -eq 0
        echo "    deja a jour"
    else if ask "    Appliquer ?"
        for i in $pending
            dconf write $dconf_keys[$i] $dconf_vals[$i]
        end
        echo "    applique"
    else
        echo "    non modifie"
    end
end

say "Applications Qt (qt6ct, kdeglobals)"
command -q qt6ct; or echo "    qt6ct n'est pas installe"
set -l qt_files ~/.config/qt6ct/qt6ct.conf ~/.config/qt6ct/qt6ct.conf ~/.config/kdeglobals
set -l qt_sections Appearance Fonts Icons
set -l qt_keys icon_theme general Theme
set -l qt_values MacTahoe-dark '"SF Pro Text,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"' MacTahoe-dark
set -l qt_pending
for i in (seq (count $qt_files))
    set -l cur (ini_get $qt_files[$i] $qt_sections[$i] $qt_keys[$i])
    if test "$cur" != "$qt_values[$i]"
        set -a qt_pending $i
        echo "    $qt_files[$i] [$qt_sections[$i]] $qt_keys[$i] : '$cur' -> '$qt_values[$i]'"
    end
end
if test (count $qt_pending) -eq 0
    echo "    deja a jour"
else if ask "    Appliquer ?"
    set -l saved
    for i in $qt_pending
        set -l f $qt_files[$i]
        if not contains -- $f $saved
            backup $f
            set -a saved $f
        end
        ini_set $f $qt_sections[$i] $qt_keys[$i] $qt_values[$i]
    end
    echo "    applique"
else
    echo "    non modifie"
end

say "Polices par defaut (fontconfig)"
set -l fc_file ~/.config/fontconfig/fonts.conf
set -l fc_tmp (mktemp)
printf '%s\n' '<?xml version="1.0"?>' '<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">' '<fontconfig>' '  <alias binding="same"><family>sans-serif</family><prefer><family>SF Pro Text</family></prefer></alias>' '  <alias binding="same"><family>system-ui</family><prefer><family>SF Pro Text</family></prefer></alias>' '</fontconfig>' > $fc_tmp
if test -f $fc_file; and cmp -s $fc_file $fc_tmp
    echo "    deja a jour"
else
    if test -f $fc_file
        echo "    $fc_file existe et differe :"
        diff -u $fc_file $fc_tmp | sed 's/^/        /'
    else
        echo "    $fc_file sera cree : sans-serif et system-ui pointent sur SF Pro Text"
    end
    if ask "    Appliquer ?"
        backup $fc_file
        mkdir -p (dirname $fc_file)
        cat $fc_tmp > $fc_file
        command -q fc-cache; and fc-cache -f
        echo "    applique"
    else
        echo "    non modifie"
    end
end
rm -f $fc_tmp

say "Termine."

if test (count $warnings) -gt 0
    echo "    a regarder :"
    for w in $warnings
        echo "      - $w"
    end
end

say "Lancement du shell"
if set -q _flag_no_launch
    echo "    ignore"
else if test -z "$qs_bin"
    echo "    quickshell est introuvable : shell non lance"
else if test (count $blocking) -gt 0
    echo "    shell non lance, il manque :"
    for b in $blocking
        echo "      - $b"
    end
else if test -z "$HYPRLAND_INSTANCE_SIGNATURE"
    echo "    pas dans une session Hyprland : lance $qs_bin -d -n"
else
    set -l running 0
    pgrep -x quickshell >/dev/null 2>&1; and set running 1
    if test $running -eq 1; and test $shell_replaced -eq 0
        echo "    Quickshell tourne deja et son code n'a pas change"
    else
        if test $running -eq 1
            $qs_bin kill >/dev/null 2>&1
            for n in 1 2 3 4 5 6
                pgrep -x quickshell >/dev/null 2>&1; or break
                sleep 0.5
            end
            pgrep -x quickshell >/dev/null 2>&1; and pkill -x quickshell
            sleep 0.5
        end
        $qs_bin -d -n
        sleep 2
        if pgrep -x quickshell >/dev/null 2>&1
            echo "    Quickshell lance"
        else
            echo "    Quickshell s'est arrete juste apres le lancement : lis $qs_bin log" >&2
        end
    end
end
