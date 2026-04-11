---
name: bx-ftp
description: Use this skill when working with FTP, FTPS, or SFTP operations in BoxLang: connecting to servers, uploading/downloading files, managing remote directories, listing contents, SSH key authentication, named connection pooling, and using the bx:ftp component.
---

# bx-ftp: FTP / SFTP Module

## Installation

```bash
# OS runtime
install-bx-module bx-ftp
# CommandBox web server
box install bx-ftp
```

## Common `bx:ftp` Actions

| Action | Description |
|--------|-------------|
| `open` | Open a connection (creates named connection) |
| `close` | Close a named connection |
| `putFile` | Upload a local file to the server |
| `getFile` | Download a file from the server |
| `listDir` | List directory contents |
| `createDir` | Create a remote directory |
| `deleteDir` | Delete a remote directory |
| `remove` | Delete a remote file |
| `rename` | Rename/move a remote file or directory |
| `changeDir` | Change the current remote directory |
| `getCurrentDir` | Get the current remote working directory |
| `existsDir` | Check if a remote directory exists |
| `existsFile` | Check if a remote file exists |

## FTP Connection

```javascript
// Open a named FTP connection
bx:ftp
    action="open"
    connection="myFTP"
    server="ftp.example.com"
    port=21
    username="user"
    password="secret"
    passive=true

// Upload a file
bx:ftp
    action="putFile"
    connection="myFTP"
    localFile="/local/path/report.pdf"
    remoteFile="/uploads/report.pdf"
    result="ftpResult"

if ( ftpResult.succeeded ) {
    println( "Uploaded successfully" )
}

// Download a file
bx:ftp
    action="getFile"
    connection="myFTP"
    remoteFile="/uploads/report.pdf"
    localFile="/local/downloads/report.pdf"

// List directory
bx:ftp
    action="listDir"
    connection="myFTP"
    directory="/uploads"
    result="dirList"
    returnType="query"   // "query" (default) or "array"

for ( row in dirList ) {
    println( "#row.name# (#row.type#) - #row.size# bytes" )
}

// Close connection
bx:ftp
    action="close"
    connection="myFTP"
```

## SFTP with Username/Password

```javascript
bx:ftp
    action="open"
    connection="mySFTP"
    server="sftp.example.com"
    port=22
    username="sftpuser"
    password="secret"
    protocol="sftp"
```

## SFTP with SSH Key Authentication

```javascript
bx:ftp
    action="open"
    connection="secureSFTP"
    server="sftp.example.com"
    port=22
    username="deployuser"
    privateKeyFile="/home/app/.ssh/id_rsa"
    privateKeyPassphrase=""     // Optional — leave empty if key has no passphrase
    protocol="sftp"
```

## FTPS (FTP over SSL/TLS)

```javascript
bx:ftp
    action="open"
    connection="secureFTP"
    server="ftp.example.com"
    port=990
    username="user"
    password="secret"
    secure=true     // Enable FTPS
    passive=true
```

## Directory Operations

```javascript
// Create a directory
bx:ftp action="createDir" connection="myFTP" directory="/uploads/2026"

// Check if directory exists
bx:ftp action="existsDir" connection="myFTP" directory="/uploads/2026" result="exists"
if ( !exists.value ) {
    bx:ftp action="createDir" connection="myFTP" directory="/uploads/2026"
}

// Delete a directory
bx:ftp action="deleteDir" connection="myFTP" directory="/uploads/old"
```

## Result Struct

Every action populates a `result` struct with:

| Key | Description |
|-----|-------------|
| `succeeded` | Boolean — operation succeeded |
| `errorCode` | FTP error code on failure |
| `errorText` | Error message on failure |
| `returnValue` | Action-specific return (e.g., current directory) |

## Common Pitfalls

- ✅ Always close connections with `action="close"` in a `finally` block
- ❌ Don't mix connection protocols — `passive=true` only applies to FTP, not SFTP
- ✅ Use named connections (`connection="myFTP"`) across multiple operations for efficiency
- ❌ Hardcoding credentials — read them from environment variables or config files
- ✅ Check `result.succeeded` before assuming an operation worked
