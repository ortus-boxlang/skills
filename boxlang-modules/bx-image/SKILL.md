---
name: bx-image
description: Use this skill for image manipulation in BoxLang with the bx-image module: ImageNew, ImageRead, ImageWrite, ImageResize, ImageScaleToFit, ImageCrop, ImageRotate, ImageFlip, ImageGrayScale, ImageBlur, ImageSharpen, imageAddBorder, imageDrawText, the fluent BoxImage builder API, and the bx:image component.
---

# bx-image: Image Manipulation

## Installation

```bash
install-bx-module bx-image
# CommandBox
box install bx-image
```

## Three APIs

| API | Style | Best For |
|-----|-------|---------|
| **BIFs** | `ImageResize( img, 800 )` | Quick one-off operations |
| **Fluent BoxImage** | `ImageNew("path").resize(800).write()` | Chained multi-step processing |
| **`bx:image` component** | `<bx:image action="resize">` | Template-style code |

---

## BIF API

### Reading & Writing

```javascript
// Read from file
img = ImageRead( "/app/uploads/photo.jpg" )

// Read from URL
img = ImageRead( "https://example.com/image.png" )

// Create blank image
img = ImageNew( "", 800, 600, "rgb", "white" )

// Write to file
ImageWrite( img, "/app/output/result.jpg", 0.9 )  // quality 0-1 for JPG

// Get image info
info = ImageInfo( img )   // Returns: width, height, colormodel, source, ...
writeOutput( info.width & "x" & info.height )
```

### Resizing & Cropping

```javascript
// Resize to specific dimensions (may distort aspect ratio)
ImageResize( img, 800, 600 )

// Resize width only (height auto-scales)
ImageResize( img, 800, "" )

// Scale to fit within bounds (preserves aspect ratio, adds white bars)
ImageScaleToFit( img, 800, 600 )

// Crop to region (x, y, width, height)
ImageCrop( img, 100, 50, 400, 300 )
```

### Transformations

```javascript
// Rotate by degrees (positive = clockwise)
ImageRotate( img, 90 )

// Flip horizontally or vertically
ImageFlip( img, "horizontal" )   // "horizontal", "vertical"

// Grayscale
ImageGrayScale( img )

// Blur
ImageBlur( img, 3 )              // radius

// Sharpen
ImageSharpen( img )

// Add border
imageAddBorder( img, 5, "black" )

// Draw text on image
imageDrawText( img, "Copyright 2025", 10, 590, { font: "Arial", size: 14, color: "white" } )
```

### Copy & Paste

```javascript
// Copy a region
region = imageCopy( img, 0, 0, 400, 300 )

// Paste into a different image at position (x, y)
imagePaste( target, region, 100, 100 )
```

---

## Fluent BoxImage API

```javascript
// Chained processing pipeline
ImageNew( "/app/uploads/original.jpg" )
    .resize( 800, 600 )
    .rotate( 90 )
    .grayScale()
    .blur( 2 )
    .write( "/app/thumbnails/thumb.jpg", 0.85 )
```

### Fluent Thumbnailing

```javascript
function makeThumbnail( sourcePath, destPath ) {
    ImageNew( sourcePath )
        .scaleToFit( 200, 200 )
        .addBorder( 2, "##eeeeee" )
        .write( destPath )
}
```

---

## Component API

```html
<!-- Read -->
<bx:image action="read" source="/uploads/photo.jpg" name="myImage">

<!-- Resize -->
<bx:image action="resize" source="#myImage#" width="400" height="300">

<!-- Write -->
<bx:image action="write" source="#myImage#" destination="/thumbnails/thumb.jpg" quality="0.9">

<!-- One-step read, resize, write -->
<bx:image action="resize" source="/uploads/photo.jpg" destination="/thumbs/thumb.jpg" width="200" height="">

<!-- Send to browser -->
<bx:image action="writeToBrowser" source="#myImage#">
```

---

## Multi-Format Thumbnail Generator

```javascript
function processUpload( uploadPath, baseName ) {
    var sizes = [
        { name: "thumb",  w: 150, h: 150 },
        { name: "medium", w: 600, h: 0 },
        { name: "large",  w: 1200, h: 0 }
    ]

    for ( var size of sizes ) {
        var img = ImageRead( uploadPath )
        if ( size.h > 0 ) {
            ImageScaleToFit( img, size.w, size.h )
        } else {
            ImageResize( img, size.w, "" )
        }
        ImageWrite( img, "/app/images/#size.name#/#baseName#.jpg", 0.85 )
    }
}
```

## Watermarking

```javascript
function addWatermark( imagePath, outputPath ) {
    var img = ImageRead( imagePath )
    var info = ImageInfo( img )
    imageDrawText(
        img,
        "© My Company",
        info.width - 200,
        info.height - 30,
        { font: "Arial", size: 16, color: "white", style: "bold" }
    )
    ImageWrite( img, outputPath, 0.9 )
}
```

## Common Pitfalls

- ✅ `ImageResize()` modifies the image in-place — assign/use immediately after
- ❌ `ImageScaleToFit` adds padding; `ImageResize` may distort — choose based on need
- ✅ JPG quality is `0.0–1.0` (`1.0` = best quality, largest file)
- ❌ PNG doesn't support quality parameter (lossless format)
- ✅ Use `ImageNew("")` to create a blank canvas, then use draw functions
- ❌ Operating on very large images without resizing first will cause memory issues
