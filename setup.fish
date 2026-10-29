#!/usr/bin/env fish

set -l repo (realpath (status dirname))
set -l qs_dst ~/.config/quickshell
set -l fonts_dst ~/.local/share/fonts/SF
set -l icons_dst ~/.icons
set -l autostart ~/.config/hypr/hyprlua/autostart.lua
set -q LICKINTOSH_AUTOSTART; and set autostart $LICKINTOSH_AUTOSTART
set -l env_lua ~/.config/hypr/hyprlua/env.lua
set -q LICKINTOSH_ENV; and set env_lua $LICKINTOSH_ENV

set -l setup_only_assets fonts icons_desktop
set -l managed shell.qml settings.qml components services ui tools

function ask --argument-names question
    read -l -P "$question [o/N] " reply; or return 1
    string match -qr '^(o|O|oui|Oui|y|Y|yes)$' -- $reply
end

function say
    echo "==> $argv"
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
        echo "    Si le shell tourne deja, relancez-le completement (qs kill, puis qs)."
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

say "Shell : copie du shell du depot vers $qs_dst"
set -l present
for e in $managed assets
    test -e $qs_dst/$e; and set -a present $e
end

set -l do_shell 1
if test (count $present) -gt 0
    set -l backup $qs_dst.bak-(date +%Y%m%d-%H%M%S)
    echo "    Une version du shell est deja installee dans $qs_dst."
    echo "    Si vous continuez, elle est remplacee par la version de ce depot."
    echo "    L'ancienne version est d'abord copiee dans $backup."
    if ask "    Remplacer la version installee par celle du depot ?"
        mkdir -p $backup
        for e in $present
            cp -a $qs_dst/$e $backup/$e
            rm -rf $qs_dst/$e
        end
        echo "    ancienne version sauvegardee dans $backup"
    else
        set do_shell 0
        echo "    la version installee est conservee"
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
    echo "    shell installe dans $qs_dst"

    for d in $qs_dst/*/
        if test -f $d/shell.qml
            echo "    note : "(basename $d)" est une autre configuration Quickshell ; elle ne se lance plus avec qs -c "(basename $d)" mais avec qs -p $d"
        end
    end
    pgrep -x quickshell >/dev/null 2>&1; and echo "    Quickshell tourne deja : fermez-le (qs kill) puis relancez-le (qs) pour charger la nouvelle version."
end

say "Autostart ($autostart)"
set -l block 'hl.on("hyprland.start", function()
    hl.exec_cmd("qs")
end)'

if not test -f $autostart
    echo "    $autostart n'existe pas, rien n'a ete modifie. Ajoutez ce bloc dans votre configuration :"
    echo $block | sed 's/^/        /'
else if grep -qE 'exec_cmd\([[:space:]]*["'\''](qs|quickshell)\b' $autostart
    echo "    quickshell est deja lance dans autostart.lua, rien a faire"
else
    echo "    quickshell n'est pas dans autostart.lua. Bloc a ajouter a la fin du fichier :"
    echo $block | sed 's/^/        /'
    if ask "    L'ajouter ?"
        cp -a $autostart $autostart.bak
        printf '\n%s\n' $block >> $autostart
        echo "    ajoute (sauvegarde : $autostart.bak)"
    else
        echo "    autostart conserve tel quel"
    end
end

say "Applications GTK (dconf)"
if not command -q dconf
    echo "    dconf est introuvable, etape ignoree"
else
    set -l dconf_keys /org/gnome/desktop/interface/icon-theme /org/gnome/desktop/interface/color-scheme /org/gnome/desktop/interface/font-name /org/gnome/desktop/interface/document-font-name /org/gnome/desktop/wm/preferences/button-layout
    set -l dconf_vals "'MacTahoe-dark'" "'prefer-dark'" "'SF Pro Text 10'" "'SF Pro Text 10'" "'close,minimize,maximize:'"
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
command -q qt6ct; or echo "    qt6ct n'est pas installe (QT_QPA_PLATFORMTHEME=qt6ct est necessaire pour que ces reglages comptent)"
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

say "Variable QT_QPA_PLATFORMTHEME ($env_lua)"
set -l env_line 'hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")'
if not test -f $env_lua
    echo "    $env_lua n'existe pas, rien n'a ete modifie. Ajoutez cette ligne dans votre configuration :"
    echo "        $env_line"
else if grep -q 'QT_QPA_PLATFORMTHEME' $env_lua
    if grep -q 'QT_QPA_PLATFORMTHEME.*qt6ct' $env_lua
        echo "    deja defini sur qt6ct, rien a faire"
    else
        echo "    QT_QPA_PLATFORMTHEME est defini avec une autre valeur, non modifie :"
        grep 'QT_QPA_PLATFORMTHEME' $env_lua | sed 's/^/        /'
    end
else
    echo "    QT_QPA_PLATFORMTHEME n'est pas defini. Ligne a ajouter a la fin du fichier :"
    echo "        $env_line"
    if ask "    L'ajouter ?"
        backup $env_lua
        printf '\n%s\n' $env_line >> $env_lua
        echo "    ajoute"
    else
        echo "    env.lua conserve tel quel"
    end
end

say "Termine."
