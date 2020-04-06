#!/data/data/com.termux/files/usr/bin/bash
show_help(){
    printf "Launch Android Apps from Termux

    Syntax:
    $name [OPTION ] [PATTERN]
    Options:
    -u update app cache
    "
}

update_cache(){
    am broadcast --user 0 \
         --es com.termux.app.reload_style apps-cache \
         -a com.termux.app.reload_style com.termux > /dev/null
}

fixterm(){
#Some of the root commands cause weird shell glitches
stty sane 2>/dev/null ||:
return
}

name=$(basename $0)
OPTIND=1         # Reset in case getopts has been used previously in the shell.
# Initialize our own variables
update=false
cachefile="$HOME/.apps"
namefile="$HOME/.app_names"
while getopts "h?u" opt; do
    case "$opt" in
        h|\?)
            show_help
            exit 0
            ;;
        u)  update=true
            ;;
    esac
done

shift $((OPTIND-1))

pattern=$1

if $update;then
    update_cache
else
    if [ -f "$cachefile" ];then
        if [ -z "$pattern" ];then
            app=`cat $namefile | fzf | cut -d "|" -f1`
        else
            app=`cat $namefile | fzf -f "$pattern"|head -n 1 | cut -d "|" -f1`
        fi
        if [ -n "$app" ];then
            activity=$(cat $cachefile | grep "$app" | cut -d "|" -f2 )
            echo "launching $activity"
            # monkey messes with the rotation setting in android (why?), so we save it beforehand and restore it afterwards
            # This currently has a bug; if the user has locked the rotation to landscape running app will
            # Switch the rotation to portrait
            #disabling for non-root. maybe enable again with root check, or find non-root solution

            #accelerometer_rotation=`su -c settings get system accelerometer_rotation`

            #su -c "monkey -p $package_name -c android.intent.category.LAUNCHER 1" >/dev/null 2>&1

            am start -n "$activity" --user 0 > /dev/null 2>&1
fixterm
        else
            exit 1
        fi
    else
        echo "App cache is empty. Run \`$name -u\`."
    fi
fi
