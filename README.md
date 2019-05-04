# SyncWalkman
This is a simple app to sync Walkman with iTunes.

You can transfer tracks and playlists to walkman from iTunes graphically.

Japanese language main.

language: swift 5, Xcode 10.2  
動作確認済Walkman: NW-A47

Requires: 

- /bin/rm
- /usr/bin/shasum (option)
- /usr/bin/ditto
- /usr/bin/iconv
<!--
- /usr/local/bin/nkf
    - you can install with brew.
-->
- ☑ Keep iTunes Media folder organized
<!--
- ☑ Share iTunes Library XML with other applications
-->

Recommends:

- ☑ Copy files to iTunes Media folder when adding to library

# How to use (gui version)
1. Select walkman root directory from picker. "選択" button.
1. Select the list (playlist) of songs to be sent from the pull-down to the right of "転送する曲のリスト".
1. Select playlists to be sent from the table below "転送するプレイリスト".
1. Push "転送" button to start send.

The log is displayed on the right.

![img](img/ss_ver2.png)

# How to use (cui version)
Please wait.

# comment
見た目が変わればメジャーアップデートします．
内部が変わっても，見た目が変わらなければマイナーアップデートです．
内部がめっちゃ変わるような大きなアップデートであれば，メジャーアップデートすることがあります．