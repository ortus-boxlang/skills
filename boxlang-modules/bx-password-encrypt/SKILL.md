---
name: bx-password-encrypt
description: Use this skill for secure password hashing and verification in BoxLang with the bx-password-encrypt module: BCryptHash/BCryptVerify, ArgonHash/ArgonVerify, SCryptHash/SCryptVerify, PBKDF2Hash/PBKDF2Verify, and choosing the right algorithm for your use case.
---

# bx-password-encrypt: Secure Password Hashing

## Installation

```bash
install-bx-module bx-password-encrypt
# CommandBox
box install bx-password-encrypt
```

## Available Algorithms

| Algorithm | BIF (Hash) | BIF (Verify) | When to Use |
|-----------|-----------|--------------|-------------|
| BCrypt | `BCryptHash()` | `BCryptVerify()` | Default choice — battle-tested, widely supported |
| Argon2 | `ArgonHash()` | `ArgonVerify()` | Best for new apps — PHC winner, memory-hard |
| SCrypt | `SCryptHash()` | `SCryptVerify()` | Memory-hard, good GPU resistance |
| PBKDF2 | `PBKDF2Hash()` | `PBKDF2Verify()` | NIST-approved, compliance environments |

## BCrypt (Recommended Default)

```javascript
// Hash a password (default cost factor: 10)
hash = BCryptHash( "myPassword123" )

// Hash with custom cost factor (higher = slower = more secure; typical: 10-12)
hash = BCryptHash( "myPassword123", 12 )

// Verify
isValid = BCryptVerify( "myPassword123", hash )  // true
isValid = BCryptVerify( "wrongPassword", hash )   // false

// Aliases
hash    = GenerateBCryptHash( "myPassword123" )
isValid = VerifyBCryptHash( "myPassword123", hash )
```

## Argon2 (Best for New Applications)

```javascript
// Hash with defaults
hash = ArgonHash( "myPassword123" )

// Hash with custom parameters
hash = ArgonHash(
    "myPassword123",
    "",       // salt (auto-generated if empty)
    10,       // iterations
    65536,    // memory in KB
    4         // parallelism threads
)

// Verify
isValid = ArgonVerify( "myPassword123", hash )

// Aliases
hash    = GenerateArgon2Hash( "myPassword123" )
isValid = Argon2CheckHash( "myPassword123", hash )
```

## SCrypt

```javascript
// Hash with defaults
hash = SCryptHash( "myPassword123" )

// Hash with custom parameters
hash = SCryptHash(
    "myPassword123",
    16384,  // cpuCost
    8,      // memoryCost
    1       // parallelization
)

// Verify
isValid = SCryptVerify( "myPassword123", hash )

// Aliases
hash    = GenerateSCryptHash( "myPassword123" )
isValid = VerifySCryptHash( "myPassword123", hash )
```

## PBKDF2 (Compliance Environments)

```javascript
// Hash with PBKDF2
hash = PBKDF2Hash( "myPassword123" )

// With custom parameters
hash = PBKDF2Hash(
    "myPassword123",
    "",          // salt (auto-generated if empty)
    310000,      // iterations (NIST recommends 310,000+ for PBKDF2-SHA256)
    "SHA-256",   // algorithm
    32           // key length in bytes
)

// Verify
isValid = PBKDF2Verify( "myPassword123", hash )
```

## User Registration & Login Pattern

```javascript
class UserService {

    function register( username, plainPassword ) {
        // Always hash before storing
        var hashedPassword = BCryptHash( arguments.plainPassword )

        queryExecute(
            "INSERT INTO users (username, password_hash) VALUES (:u, :p)",
            { u: arguments.username, p: hashedPassword }
        )
    }

    function login( username, plainPassword ) {
        var user = queryExecute(
            "SELECT id, password_hash FROM users WHERE username = :u",
            { u: arguments.username },
            { returntype: "array" }
        )

        if ( !arrayLen( user ) ) return false              // User not found
        return BCryptVerify( arguments.plainPassword, user[1].password_hash )
    }

    function changePassword( userId, currentPassword, newPassword ) {
        var user = queryExecute(
            "SELECT password_hash FROM users WHERE id = :id",
            { id: userId },
            { returntype: "array" }
        )

        if ( !BCryptVerify( currentPassword, user[1].password_hash ) ) {
            throw( type: "Auth.InvalidPassword", message: "Current password is incorrect" )
        }

        var newHash = BCryptHash( newPassword, 12 )
        queryExecute(
            "UPDATE users SET password_hash = :h WHERE id = :id",
            { h: newHash, id: userId }
        )
    }
}
```

## Algorithm Selection Guide

- **New application**: Use **Argon2** (`ArgonHash`) — current PHC winner
- **Existing CFML migration / familiarity**: Use **BCrypt** (`BCryptHash`) — well-understood, compatible
- **Compliance (NIST/FIPS)**: Use **PBKDF2** (`PBKDF2Hash`)
- **GPU-resistance priority**: Use **SCrypt** or **Argon2**

## Common Pitfalls

- ❌ Never store plaintext passwords — always hash with one of these algorithms
- ❌ Never use MD5, SHA-1, or SHA-256 alone for password storage — too fast, vulnerable to brute force
- ✅ Each hash call generates a unique internal salt automatically — never store your own salt separately
- ✅ Increase the cost factor as hardware performance improves; target 100ms+ per hash for login operations
- ❌ Don't compare hashes with `==` — always use the verify BIFs (timing-safe comparison)
