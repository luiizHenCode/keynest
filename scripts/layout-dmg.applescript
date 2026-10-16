on run argv
    set mountFolder to POSIX file (item 1 of argv) as alias
    tell application "Finder"
        open mountFolder
        set installWindow to front Finder window
        set current view of installWindow to icon view
        set toolbar visible of installWindow to false
        set statusbar visible of installWindow to false
        set bounds of installWindow to {180, 140, 780, 540}
        set opts to icon view options of installWindow
        set arrangement of opts to not arranged
        set icon size of opts to 96
        set text size of opts to 13
        -- Image bookmarks include the local account name. A solid color avoids that metadata.
        set background color of opts to {4800, 5600, 5200}
        set position of item "Keynest.app" of mountFolder to {165, 205}
        set position of item "Applications" of mountFolder to {435, 205}
        update mountFolder without registering applications
        delay 2
        close installWindow
    end tell
end run
