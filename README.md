# SyncWalkman
This is an intelligent app for synchronizing Walkman.

(作者は英語ができません。)

language: swift4.1  
walkman(動作確認済): NW-A47

Requires: 

- /bin/rm
- /usr/bin/shasum
- /usr/bin/ditto
- /usr/local/bin/nkf
    - you can install with brew.
- ☑ Keep iTunes Media folder organized
- ☑ Share iTunes Library XML with other applications

Recommends:

- ☑ Copy files to iTunes Media folder when adding to library

# How to Build

```
$ cd path/to/SyncWalkman
$ swiftc main.swift src/*.swift -o SyncWalkman
```

# Usage

```
Usage:      $ SyncWalkman [-s] [-p] [-u | -o] [-d] [-v | -v .found|.sent|.skipped|.del|.func] [-w /Volumes/WALKMAN] -f "/path/to/iTunes Library.xml"
        Show Version:
            $ SyncWalkman --version
        Show Help:
            $ SyncWalkman -h
Argments:   -f iTunes XML Path: Path to iTunes Library XML File
            -w Walkman Path:    Path to Walkman root
Options:    -s: send song
            -p: send playlists
            -u: send mode Update
            -o: send mode Overwrite
            -d: Delete songs that are not sent
            -v: Print a line of status
                Individual options for each situation.
                 .found
                 .sent
                 .skipped
                 .deleted
                 .func
            -n: dry do
```

## Example

```
$ SyncWalkman -spudv -f ~/Music/iTunes/iTunes\ Library.xml
$ SyncWalkman -pudn -v .sent.del -f ~/Music/iTunes/iTunes\ Library.xml -w /Volumes/WALKMAN
```

# Messages

## stderr

|メッセージ | 動作 |
|:------|:-----|
|"!Warning: ~" | 終了はしないが、警告 | 
|"!Error: ~" | エラー原因を表示して終了 |

## exit(n)

| n | 分類 |
|:---:|:-----|
| 0 | 通常終了 |
| 1 | ユーザー依存のエラー |
| 2 | システム依存のエラー |

# License
MIT License  
2018 原園征志

商用利用などする場合、強制ではないですがご連絡いただけると励みになります。
