#!/bin/bash

cond_mkdir()
{
    d="$1"
    shift

    if ! [ -d "$d" ] ; then
        mkdir "$d"
    fi
}

cond_mkdir "generated"

base="$(pwd)"

if ! [ -d templates ]; then
    echo "Cannot find the 'templates' directory" 1>&2
    exit -1
fi

pushd templates

"$base"/bin/render_events.pl
"$base"/bin/send_email_and_tweets.pl "$HOME"/amsterdamx_conf.yaml

pages_list="about events"

for page in $pages_list; do
    echo "Creating $page..."
    tpage --define page="$page" "$page".tt > "$base"/generated/"$page".html

    if [ "$?" -ne "0" ]; then
        echo "Failed"
        exit 1
    fi
done

popd

cp -rv img/ css.css js.js generated/

exit 0;

