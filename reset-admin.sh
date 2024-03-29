#!/bin/bash

# ensure start9 directory exists if action is run before first run of service
mkdir /media/start9
export PASS=$(cat /dev/urandom | base64 | head -c 16)
echo 'version: 2' > /media/start9/stats.yaml
echo 'data:' >> /media/start9/stats.yaml
echo '  Default Username:' >> /media/start9/stats.yaml
echo '    type: string' >> /media/start9/stats.yaml
echo '    value: admin' >> /media/start9/stats.yaml
echo '    description: "Default useraname for Photoview. While it is not necessary, you may change it inside your Photoview application. That change, however will not be reflected here"' >> /media/start9/stats.yaml
echo '    copyable: true' >> /media/start9/stats.yaml
echo '    qr: false' >> /media/start9/stats.yaml
echo '    masked: false' >> /media/start9/stats.yaml
echo '  Default Password:' >> /media/start9/stats.yaml
echo '    type: string' >> /media/start9/stats.yaml
echo '    value: "'"$PASS"'"' >> /media/start9/stats.yaml
echo '    description: This is your randomly-generated, default password. While it is not necessary, you may change it inside your Photoview application. That change, however, will not be reflected here.' >> /media/start9/stats.yaml
echo '    copyable: true' >> /media/start9/stats.yaml
echo '    masked: true' >> /media/start9/stats.yaml
echo '    qr: false' >> /media/start9/stats.yaml

export PASS_HASH=$(htpasswd -bnBC 12 "" $PASS | tr -d ':\n' | sed 's/$2y/$2a/')
export PHOTOVIEW_SQLITE_PATH="/media/photoview.db"

USERS=$(sqlite3 $PHOTOVIEW_SQLITE_PATH "select * from users where id = 1;")
if [ -z $USERS ]; then
  sqlite3 $PHOTOVIEW_SQLITE_PATH "insert into users (id, created_at, updated_at, username, password, admin) values (1, datetime('now'), datetime('now'), 'admin', '$PASS_HASH', true);"
  PATH_MD5=$(echo -n /mnt/filebrowser | md5sum | head -c 32)
  sqlite3 $PHOTOVIEW_SQLITE_PATH "insert or ignore into albums (id, created_at, updated_at, title, parent_album_id, path, path_hash) values (1, datetime('now'), datetime('now'), 'filebrowser', NULL, '/mnt/filebrowser', '$PATH_MD5');"
  sqlite3 $PHOTOVIEW_SQLITE_PATH "insert or ignore into user_albums (album_id, user_id) values (1,1);"
  sqlite3 $PHOTOVIEW_SQLITE_PATH "update site_info set initial_setup = false;"
fi
sqlite3 $PHOTOVIEW_SQLITE_PATH "update users set password = '$PASS_HASH', username = 'admin' where id = 1;"
action_result="    {
    \"version\": \"0\",
    \"message\": \"Here is your new password. This will also be reflected in the Properties page for this service.\",
    \"value\": \"$PASS\",
    \"copyable\": true,
    \"qr\": false
}"
echo $action_result
exit 0