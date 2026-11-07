---
name: bx-image
description: "Use this skill for image manipulation in BoxLang with the bx-image module: ImageNew, ImageRead, ImageWrite, ImageResize, ImageScaleToFit, ImageCrop, ImageRotate, ImageFlip, ImageGrayScale, ImageBlur, ImageSharpen, imageAddBorder, imageDrawText, hex colors, linear gradients (ImageSetDrawingGradient), text measurement (ImageMeasureText) and word wrapping, custom TTF/OTF fonts (ImageRegisterFont), the fluent BoxImage builder API, and the bx:image component."
---

# bx-image: Image Manipulation

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

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

// Draw text on image (text color is the drawing color, not a key in the struct)
ImageSetDrawingColor( img, "white" )
imageDrawText( img, "Copyright 2025", 10, 590, { font: "Arial", size: 14 } )
```

### Colors

Every color argument (`ImageNew`, `ImageSetDrawingColor`, `ImageSetBackgroundColor`, `ImageAddBorder`, gradient colors, `<bx:image action="border">`) takes a name or hex.

- Names: `black blue cyan darkgray gray green lightgray magenta orange pink red white yellow`
- Hex: `#RGB`, `#RRGGBB`, `#RRGGBBAA` (alpha **last**), with or without the `#`
- An unparseable color **throws**; it no longer silently draws black
- In a BoxLang string or template write `##` for a literal `#`

```javascript
img = ImageNew( "", 1200, 630, "rgb", "##0b161b" )
ImageSetDrawingColor( img, "##ff6a00" )
ImageSetDrawingColor( img, "##ff6a0080" )   // 50% alpha
ImageSetDrawingColor( img, "0b161b" )       // no # needed
```

### Linear Gradients

`ImageSetDrawingGradient( img, x1, y1, x2, y2, colors [, fractions] )` sets the paint for subsequent fills, strokes, lines and text. `ImageSetDrawingColor` goes back to a solid color.

```javascript
img.setDrawingGradient( 0, 0, 1200, 0, [ "##ff6a00", "##ee0979" ] )
img.drawRect( 0, 600, 1200, 30, true )          // gradient bar

img.setDrawingStroke( { width: 8 } )
img.drawOval( 900, 100, 200, 200, false )       // gradient ring

img.setDrawingGradient( 0, 0, 0, 630, [ "white", "##3366ff", "black" ], [ 0, 0.3, 1 ] )
img.drawText( "Title", 80, 300, { size: 96, style: "bold" } )  // gradient text

img.setDrawingColor( "white" )                  // back to solid
```

Throws for fewer than 2 colors, a bad color, identical start and end points, or fractions that are not one per color, within 0 to 1, strictly increasing. Gradient coordinates are in image pixels.

### Measuring Text (word wrap and shrink to fit)

`ImageMeasureText( img, str [, fontStruct] )` / `img.measureText( str, fontStruct )` returns `{ width, height, ascent, descent, leading }` in pixels using the same font struct and font resolution as `drawText`. `y` in `drawText` is the **baseline**. There is no built-in `wrapText`; build it on `measureText` (single line only, split on newlines yourself).

```javascript
function wrapLines( img, text, attrs, maxWidth ) {
    var lines = []
    var line  = ""
    for ( var word in text.listToArray( " " ) ) {
        var candidate = line.len() ? line & " " & word : word
        if ( line.len() && img.measureText( candidate, attrs ).width > maxWidth ) {
            lines.append( line )
            line = word
        } else {
            line = candidate
        }
    }
    if ( line.len() ) lines.append( line )
    return lines
}

attrs = { font: "SansSerif", size: 72, style: "bold" }
lines = wrapLines( img, title, attrs, 1000 )
while ( lines.len() > 3 && attrs.size > 24 ) {
    attrs.size -= 4
    lines = wrapLines( img, title, attrs, 1000 )
}
```

Do not name your function `wrap`; it collides with the `wrap` BIF.

### Custom Fonts

Use a bundled `.ttf` or `.otf` with the `file` key, or register it once and use the family name.

```javascript
img.drawText( "Brand", 50, 100, { file: "/app/fonts/Brand-Bold.ttf", size: 48 } )

family = ImageRegisterFont( "/app/fonts/Brand-Bold.ttf" )   // returns the family name
img.drawText( "Brand", 50, 100, { font: family, size: 48 } )
```

`file` is used instead of `font`; `size` defaults to 12. `measureText` accepts the same `file` key, so measuring and drawing agree. A missing, empty or invalid font file throws. Paths are not expanded: pass `expandPath()` for app-relative locations. Bold/italic on a single file font is synthetic; point `file` at the bold file for a real bold.

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
    ImageSetDrawingColor( img, "white" )
    imageDrawText(
        img,
        "© My Company",
        info.width - 200,
        info.height - 30,
        { font: "Arial", size: 16, style: "bold" }
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
- ❌ A bare `"#FF0000"` in a BoxLang string or template is an interpolation; write `"##FF0000"`
- ❌ `drawText` has no `color` key; set the color (or a gradient) with `ImageSetDrawingColor` / `ImageSetDrawingGradient` first
- ✅ Measure with `measureText` before drawing wrapped or centered text; do not guess widths
- ❌ Operating on very large images without resizing first will cause memory issues
