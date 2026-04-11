---
name: boxlang-zip
description: Use this skill when creating, extracting, listing, or modifying ZIP archives in BoxLang using the bx:zip component: compressing directories or files, filtering entries, reading archive contents, downloading files as a ZIP, or building backup/restore workflows.
---

# BoxLang ZIP Archives

## Overview

BoxLang provides the `bx:zip` component for creating, extracting, listing, and
modifying ZIP archives. Supports compression levels, entry filtering, encryption,
and reading individual entries without full extraction.

## Creating Archives

```boxlang
// Create from directory
zip action="zip"
    file="#expandPath( '/temp/archive.zip' )#"
    source="#expandPath( '/files/documents' )#"

// Overwrite existing
zip action="zip"
    file="#expandPath( '/temp/archive.zip' )#"
    source="#expandPath( '/files' )#"
    overwrite="true"

// Multiple sources with prefixes
zip action="zip" file="#expandPath( '/temp/backup.zip' )#" {
    zipparam source="#expandPath( '/app' )#"    prefix="app"
    zipparam source="#expandPath( '/config' )#" prefix="config"
    zipparam source="#expandPath( '/uploads' )#" prefix="uploads"
}

// Filter by pattern
zip action="zip"
    file="#expandPath( '/temp/pdfs.zip' )#"
    source="#expandPath( '/documents' )#"
    filter="*.pdf"
    recurse="true"

// Compression level (0 = store, 9 = maximum)
zip action="zip"
    file="#expandPath( '/temp/compressed.zip' )#"
    source="#expandPath( '/files' )#"
    compressionLevel="9"
```

## Extracting Archives

```boxlang
// Extract all
zip action="unzip"
    file="#expandPath( '/temp/archive.zip' )#"
    destination="#expandPath( '/extracted' )#"
    overwrite="true"

// Extract specific entry
zip action="unzip"
    file="#expandPath( '/temp/archive.zip' )#"
    destination="#expandPath( '/extracted' )#"
    entryPath="docs/report.pdf"

// Extract filtered subset
zip action="unzip"
    file="#expandPath( '/temp/archive.zip' )#"
    destination="#expandPath( '/pdfs' )#"
    filter="*.pdf"
```

## Listing Contents

```boxlang
// List all entries into a query
zip action="list"
    file="#expandPath( '/temp/archive.zip' )#"
    name="local.zipContents"

for ( var row in zipContents ) {
    println( "#row.name# - #row.size# bytes" )
}

// Read a single file without extracting
zip action="read"
    file="#expandPath( '/temp/archive.zip' )#"
    entryPath="config.json"
    variable="local.configContent"

var config = deserializeJSON( configContent )
```

## Modifying Archives

```boxlang
// Append file to existing archive
zip action="zip" file="#expandPath( '/temp/archive.zip' )#" {
    zipparam source="#expandPath( '/newfile.txt' )#"
}

// Delete entry
zip action="delete"
    file="#expandPath( '/temp/archive.zip' )#"
    entryPath="oldfile.txt"

// Delete multiple entries
zip action="delete" file="#expandPath( '/temp/archive.zip' )#" {
    zipparam entryPath="temp/*"
    zipparam entryPath="logs/*.log"
}
```

## Encryption

```boxlang
// Create encrypted archive
zip action="zip"
    file="#expandPath( '/temp/secure.zip' )#"
    source="#expandPath( '/sensitive' )#"
    password="SecurePassword123"

// Extract encrypted archive
zip action="unzip"
    file="#expandPath( '/temp/secure.zip' )#"
    destination="#expandPath( '/extracted' )#"
    password="SecurePassword123"
```

## ZIP Service Pattern

```boxlang
class singleton {

    function create( required zipFile, required source, overwrite = false, filter = "*" ) {
        if ( !overwrite && fileExists( zipFile ) ) {
            throw( "ZIP file already exists: #zipFile#" )
        }
        zip action="zip" file="#zipFile#" source="#source#" overwrite="#overwrite#" filter="#filter#"
        return getFileInfo( zipFile )
    }

    function extract( required zipFile, required destination, overwrite = false ) {
        if ( !fileExists( zipFile ) ) {
            throw( "ZIP file not found: #zipFile#" )
        }
        if ( !directoryExists( destination ) ) {
            directoryCreate( destination, createPath: true )
        }
        zip action="unzip" file="#zipFile#" destination="#destination#" overwrite="#overwrite#"
    }

    function list( required zipFile, filter = "*" ) {
        zip action="list" file="#zipFile#" filter="#filter#" name="local.contents"
        var files = []
        for ( var row in contents ) {
            files.append( { name: row.name, size: row.size, modified: row.dateLastModified } )
        }
        return files
    }

    function readEntry( required zipFile, required entryPath ) {
        zip action="read" file="#zipFile#" entryPath="#entryPath#" variable="local.content"
        return content
    }

    function hasEntry( required zipFile, required entryPath ) {
        return list( zipFile ).some( ( e ) -> e.name == entryPath )
    }
}
```

## Application Backup Pattern

```boxlang
function createBackup() {
    var timestamp  = dateFormat( now(), "yyyymmdd_HHnnss" )
    var backupFile = expandPath( "/backups/app_#timestamp#.zip" )
    var backupDir  = getDirectoryFromPath( backupFile )

    if ( !directoryExists( backupDir ) ) {
        directoryCreate( backupDir )
    }

    zip action="zip" file="#backupFile#" {
        zipparam source="#expandPath( '/app' )#"    prefix="app"
        zipparam source="#expandPath( '/config' )#" prefix="config"
        zipparam source="#expandPath( '/uploads' )#" prefix="uploads"
    }

    return { file: backupFile, size: getFileInfo( backupFile ).size, created: now() }
}
```

## Best Practices

- Always wrap ZIP operations in `try/catch` — archives can be corrupt or locked
- Use temp files for processing; clean up in a `finally` block
- Validate that source/archive paths exist before operating
- Use `getTempFile()` for dynamically named temporary archives
- Store encryption passwords in environment variables, never hardcoded
- Check archive size after creation for very large source directories

```boxlang
// ✅ Cleanup pattern
var tempZip = getTempFile( getTempDirectory(), "archive" ) & ".zip"
try {
    zip action="zip" file="#tempZip#" source="#source#"
    // use tempZip...
} catch ( any e ) {
    writeLog( "ZIP failed: #e.message#" )
} finally {
    if ( fileExists( tempZip ) ) {
        fileDelete( tempZip )
    }
}
```
