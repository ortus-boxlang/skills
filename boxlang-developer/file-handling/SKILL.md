---
name: boxlang-file-handling
description: "Use this skill when reading, writing, copying, moving, or deleting files and directories in BoxLang: fileRead, fileWrite, fileCopy, fileMove, directoryList, directoryCreate, symbolic links (fileCreateSymlink, fileIsSymlink, fileReadSymlink, followLinks), fileUpload, streaming large files, or processing CSV/JSON files from disk."
---

# BoxLang File Handling

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

## Overview

BoxLang provides comprehensive file-system operations for reading, writing, and
managing files and directories. Supports text, binary, and streaming access with
configurable encoding.

## Reading Files

```boxlang
// Read entire file as string
var content = fileRead( "/path/to/file.txt" )

// Read with explicit encoding
var content = fileRead( "/path/to/file.txt", "UTF-8" )

// Read as array of lines
var lines = fileReadLines( "/path/to/file.txt" )
lines.each( ( line ) -> println( line ) )

// Read binary file
var bytes = fileReadBinary( "/path/to/image.jpg" )
```

### Streaming Large Files

```boxlang
function processLargeFile( filePath ) {
    var file = fileOpen( filePath, "read" )
    try {
        while ( !fileIsEOF( file ) ) {
            processLine( fileReadLine( file ) )
        }
    } finally {
        fileClose( file )
    }
}
```

## Writing Files

```boxlang
// Write (create or replace)
fileWrite( "/path/to/file.txt", "Hello World" )

// Write with encoding
fileWrite( "/path/to/file.txt", content, "UTF-8" )

// Append to file
fileWrite( "/path/to/file.txt", "New line\n", "UTF-8", true )

// Write binary
fileWriteBinary( "/path/to/image.jpg", binaryData )
```

### Buffered Write for Large Content

```boxlang
function writeLargeFile( filePath, lines ) {
    var file = fileOpen( filePath, "write" )
    try {
        lines.each( ( line ) -> fileWriteLine( file, line ) )
    } finally {
        fileClose( file )
    }
}
```

## Copy, Move, Delete

```boxlang
// Copy
fileCopy( "/source/file.txt", "/dest/file.txt" )
fileCopy( "/source/file.txt", "/dest/file.txt", true )  // overwrite

// Move / rename
fileMove( "/old/path/file.txt", "/new/path/file.txt" )

// Delete (check first)
if ( fileExists( "/path/to/file.txt" ) ) {
    fileDelete( "/path/to/file.txt" )
}
```

## Directory Operations

```boxlang
// List files
var files = directoryList( "/path/to/dir" )

// List with filter and full query
var result = directoryList(
    path: "/path/to/dir",
    filter: "*.txt",
    recurse: true,
    listInfo: "query"
)

// Create (including nested)
if ( !directoryExists( "/path/to/dir" ) ) {
    directoryCreate( path: "/path/to/dir", createPath: true )
}

// Copy directory
directoryCopy( source: "/source/dir", destination: "/dest/dir", recurse: true )

// Move / rename
directoryRename( "/old/path", "/new/path" )

// Delete recursively (the argument is "recursive", not "recurse")
if ( directoryExists( "/path/to/dir" ) ) {
    directoryDelete( path: "/path/to/dir", recursive: true )
}
```

`directoryList`, `directoryCopy` and `directoryDelete` take a `followLinks` argument that defaults to `false`.
Symbolic links are never followed unless you ask. See [Symbolic Links](#symbolic-links).

A call is either all positional or all named. BoxLang does not allow `directoryDelete( "/dir", recursive: true )`, so name every argument or none.

## File Information and Paths

```boxlang
// File attributes
if ( fileExists( "/path/to/file.txt" ) ) {
    var info = getFileInfo( "/path/to/file.txt" )
    // info.name, info.size, info.lastModified, info.mode, info.type
    // info.isLink, info.linkTarget (empty string when the path is not a link)
}

// Path utilities
var absolute = expandPath( "/uploads/file.txt" )
var dir      = getDirectoryFromPath( "/path/to/file.txt" )  // /path/to/
var name     = getFileFromPath( "/path/to/file.txt" )       // file.txt
var ext      = listLast( name, "." )                        // txt
```

## Symbolic Links

```boxlang
// Create a link. The target is stored exactly as given, so a relative target
// is relative to the folder that holds the link.
fileCreateSymlink( "/app/current", "/app/releases/v2" )
fileCreateSymlink( link: "/app/current", target: "/app/releases/v3", overwrite: true )  // replace a file or link

fileIsSymlink( "/app/current" )                       // true, also true for a dangling link
fileReadSymlink( "/app/current" )                     // the stored target
fileReadSymlink( path: "/app/rel", resolve: true )   // absolute, normalized target

// Link details are also in fileInfo() / getFileInfo() and in the directoryList query
var info = fileInfo( "/app/current" )                 // info.isLink, info.linkTarget
var q    = directoryList( "/app", false, "query" )    // q.isLink, q.linkTarget

// List only the links
var links = directoryList( path: "/app", listInfo: "name", filter: ( path ) => fileIsSymlink( path ) )
```

Rules to remember:

- `fileCreateSymlink()` throws if the path already exists (unless `overwrite: true`, which never replaces a folder) or if the operating system will not create the link.
- `directoryDelete( path: dir, recursive: true )` removes links as links and never empties the folder a link points to. A link given as the path is only removed as a link, even with `followLinks`.
- `directoryDelete( path: dir, recursive: true, followLinks: true )` also deletes the contents of the folders that links inside `path` point to. A link that leads back into the tree, or to a folder above it, is still removed as a link.
- `directoryCopy()` copies links as links. `followLinks: true` copies what they point to instead. A shallow copy takes files and links but not real sub folders.
- `directoryList( recurse: true )` lists a link but does not descend into it. Use `followLinks: true` to descend. A link given as the path is always resolved.
- `type: "dir"` still counts a link to a folder as a directory. Use `fileIsSymlink()` in a `filter` to find links.
- `directoryDelete()` used to follow links and empty their targets. Code that relied on that now needs `followLinks: true`.

## File Upload

```boxlang
function uploadFile( fileField, destination ) {
    if ( !form.keyExists( fileField ) ) {
        return { success: false, message: "No file uploaded" }
    }

    try {
        if ( !directoryExists( destination ) ) {
            directoryCreate( path: destination, createPath: true )
        }

        var upload = fileUpload(
            destination: destination,
            fileField: fileField,
            nameConflict: "makeUnique",
            accept: "image/jpeg,image/png,image/gif"
        )

        return {
            success: true,
            serverFile: upload.serverFile,
            clientFile: upload.clientFile,
            fileSize: upload.fileSize
        }
    } catch ( any e ) {
        return { success: false, message: "Upload failed: #e.message#" }
    }
}
```

## JSON and CSV Helpers

```boxlang
// JSON file round-trip
function readJSON( filePath ) {
    return jsonDeserialize( fileRead( filePath ) )
}

function writeJSON( filePath, data ) {
    fileWrite( filePath, jsonSerialize( data ) )
}

// CSV reader
function readCSV( filePath ) {
    var lines   = fileReadLines( filePath )
    var headers = listToArray( lines[1], "," )
    var data    = []

    lines.each( ( line, i ) -> {
        if ( i == 1 ) return
        var cols = listToArray( line, "," )
        var row  = {}
        cols.each( ( val, j ) -> { row[ headers[j] ] = val } )
        data.append( row )
    } )

    return data
}
```

## Best Practices

- Always use `try/finally` to close open file handles
- Validate uploads: check MIME type and file size before saving
- Use `expandPath()` to produce absolute paths; never string-concatenate user input directly into paths
- For path traversal safety, sanitize file names with `getFileFromPath()` before building destination paths
- Specify encoding (`"UTF-8"`) explicitly when text content matters
- Clean up temporary files in a `finally` block
- Leave `followLinks` at its default of `false` for any folder you did not create yourself. `followLinks: true` on `directoryDelete()` deletes outside the folder you named

## Security Patterns

```boxlang
// ✅ Safe: sanitize upload file name
var safeName = getFileFromPath( form.fileName )
var dest     = expandPath( "/uploads" ) & "/" & safeName
fileRead( dest )

// ❌ Unsafe: direct user input in path
fileRead( "/uploads/#form.fileName#" )  // Path traversal risk
```

## Log Rotation

```boxlang
function rotateLogFile( logFile, maxBytes = 10485760 ) {
    if ( !fileExists( logFile ) ) return

    if ( getFileInfo( logFile ).size > maxBytes ) {
        var backup = logFile & "." & dateFormat( now(), "yyyymmdd_HHnnss" )
        fileMove( logFile, backup )
        fileWrite( logFile, "" )
    }
}
```
