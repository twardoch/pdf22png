# pdf22png / pdf21png Examples

All examples below show the Swift binary `pdf22png`.  If you prefer the Objective-C implementation simply replace the executable name with `pdf21png` – the flags and behaviour are identical.

This page shows common use cases and examples for the `pdf22png` command-line tool.

## Basic Conversions

**1. Convert the first page of a PDF to a PNG:**

```bash
pdf22png input.pdf output.png
```
*   Reads `input.pdf`.
*   Converts page 1.
*   Saves as `output.png` at default resolution (144 DPI).

**2. Convert a specific page (e.g., page 5):**

```bash
pdf22png -p 5 input.pdf page_5_output.png
```

**3. Read PDF from stdin, write PNG to stdout:**

```bash
cat input.pdf | pdf22png - - > output.png
# OR
pdf22png - - < input.pdf > output.png
```
*   Note: `-` is used for both input (stdin) and output (stdout).

## Resolution and Scaling

**4. Convert with a specific DPI (e.g., 300 DPI):**

```bash
pdf22png -r 300dpi input.pdf high_res_output.png
# or
pdf22png --resolution 300 input.pdf high_res_output.png
```

**5. Scale the output image by a factor (e.g., 2x larger):**

```bash
pdf22png -s 2.0 input.pdf large_output.png
# or by percentage
pdf22png -s 200% input.pdf large_output.png
```

**6. Fit output image to a specific width (e.g., 800px wide), maintaining aspect ratio:**

```bash
pdf22png -s 800x input.pdf width_800_output.png
```

**7. Fit output image to a specific height (e.g., 600px high), maintaining aspect ratio:**

```bash
pdf22png -s x600 input.pdf height_600_output.png
```

**8. Fit output image within specific dimensions (e.g., max 500px width and 500px height):**

```bash
pdf22png -s 500x500 input.pdf bounded_output.png
```

## Batch Conversion (All Pages)

**9. Convert all pages of a PDF, saving in the current directory:**
   Output files will be named `input-001.png`, `input-002.png`, etc. (assuming input file is `input.pdf`)

```bash
pdf22png -a input.pdf
```

**10. Convert all pages, specifying an output prefix:**
    Output files will be named `myprefix-001.png`, `myprefix-002.png`, etc.

```bash
pdf22png -a input.pdf myprefix
# or using -o for prefix
pdf22png -a -o myprefix input.pdf
```

**11. Convert all pages and save them into a specific directory:**
    Output files will be in `output_directory/input-001.png`, etc.

```bash
pdf22png -d ./output_directory input.pdf
```

**12. Convert all pages, save to a directory with a custom prefix:**
    Output files will be in `output_dir/custom_prefix-001.png`, etc.

```bash
pdf22png -d ./output_dir -o custom_prefix input.pdf
```

## Transparency and Quality

**13. Convert with a transparent background (if PDF page has transparency):**

```bash
pdf22png -t input.pdf transparent_output.png
```

**14. Specify PNG quality (0-9, informational for PNG):**

```bash
pdf22png -q 8 input.pdf quality_8_output.png
```
*   Note: PNG is a lossless format. This option is more relevant for formats like JPEG. For PNG, it might influence compression effort/speed in some libraries, but CoreGraphics offers limited direct control.

## Verbose Output

**15. Get detailed logs during conversion:**

```bash
pdf22png -v input.pdf output.png
```
*   Useful for debugging or understanding the conversion process.

## Combining Options

**16. Convert page 3 of `mydoc.pdf` to `page3_high_res.png` at 300 DPI with a transparent background:**

```bash
pdf22png -p 3 -r 300 -t mydoc.pdf page3_high_res.png
```

**17. Convert all pages of `report.pdf` to a subdirectory `report_images`, scaled to 50% size, with verbose output:**

```bash
pdf22png -a -s 50% -d ./report_images -v report.pdf
```
