Project Gutenberg eBook Cover Generator
================

Built with [Processing](http://processing.org)

Read about this in more detail in [this blog post](http://www.nypl.org/blog/2014/09/03/generative-ebook-covers).

## Requirements

You can add these libraries via the Processing package manager:

`Sketch ⟶ Import Library ⟶ Add Library…`

- **[OpenCV for Processing](https://github.com/atduskgreg/opencv-processing) for face recognition** for framing in a way inspired by the [work of Chris Marker and Jason Simon](http://www.lightindustry.org/simon_marker.jpg).
- **[ControlP5](http://www.sojamo.de/libraries/controlP5/)** for parameter testing/control.

## Command-line use
You can run this program in an arbitrary book as long as you properly describe it as shown in `test-book.json`. The JSON file must be only one line.

**Usage**

Export the stand-alone **Linux** (32 or 64-bit) application from Processing via `File > Export Application` and run the resulting binary using:

`./imagecoverp5tint /path/to/images/with/trailing/slash/ /path/to/output/folder/with/trailing/slash/ /path/to/book.json title_font_file-size.vlw author_font_file-size.vlw`

The VLW font files must conform to the specified `name-size.vlw` convention so that the application knows what size to apply when running. You create your own fonts via the `Tools > Create Font...` dialog.

Generated covers are output to the provided folder creating a `book-id/` subfolder and putting the covers there in PNG format.

## Example output

![Example](https://github.com/mgiraldo/imagecoverp5tint/blob/master/output/example1.png)
![Example](https://github.com/mgiraldo/imagecoverp5tint/blob/master/output/example7.png)
![Example](https://github.com/mgiraldo/imagecoverp5tint/blob/master/output/example8.png)
![Example](https://github.com/mgiraldo/imagecoverp5tint/blob/master/output/example2.png)
![Example](https://github.com/mgiraldo/imagecoverp5tint/blob/master/output/example3.png)
![Example](https://github.com/mgiraldo/imagecoverp5tint/blob/master/output/example4.png)
![Example](https://github.com/mgiraldo/imagecoverp5tint/blob/master/output/example5.png)
![Example](https://github.com/mgiraldo/imagecoverp5tint/blob/master/output/example6.png)
![Example](https://github.com/mgiraldo/imagecoverp5tint/blob/master/output/example9.png)

## License

Adobe Caslon™ is copyright [Adobe Systems Incorporated](http://www.adobe.com/). Avenir® Next is copyright [Monotype GmbH](https://www.linotype.com/).

Original code in this repository is released under [Creative Commons CC0 1.0 License](http://creativecommons.org/publicdomain/zero/1.0).
