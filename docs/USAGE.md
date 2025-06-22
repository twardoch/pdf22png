# pdf22png Usage

`pdf22png` is a command-line tool to convert PDF documents to PNG images on macOS.

## Synopsis

```bash
pdf22png [OPTIONS] <input.pdf> [output.png | output_format_%%d.png]
```

## Arguments

*   `<input.pdf>`: (Required) The path to the input PDF file. Use `-` to read from stdin.
*   `[output.png | output_format_%%d.png]`: (Optional) The name for the output PNG file.
    *   In single page mode: If specified, this is the exact output filename. If omitted and input is a file, it's an error. If omitted and input is stdin, output goes to stdout.
    *   In batch mode (`-a` or `-d`): This is treated as a filename prefix. Page numbers will be appended (e.g., `prefix-001.png`). If omitted, the prefix is derived from the input filename or defaults to "page".
    *   Use `-` for stdout in single page mode. Cannot be used with batch mode.

## Options

| Short | Long           | Argument        | Description                                                                                                | Default        |
|-------|----------------|-----------------|------------------------------------------------------------------------------------------------------------|----------------|
| `-p`  | `--page`       | `<n>`           | Convert a specific page number. Ignored if `-a` or `-d` is used.                                             | `1`            |
| `-a`  | `--all`        |                 | Convert all pages in the PDF. If `-d` is not given, output files are placed in the current directory.        | Disabled       |
| `-r`  | `--resolution` | `<dpi>`         | Set the output resolution in Dots Per Inch (e.g., `150`, `300dpi`).                                          | `144dpi`       |
| `-s`  | `--scale`      | `<spec>`        | Set the scaling for the output image. Overridden by `-r` if both specify numeric scaling. See syntax below.  | `1.0` or `100%`|
| `-t`  | `--transparent`|                 | Render the PNG with a transparent background instead of white.                                               | Disabled       |
| `-q`  | `--quality`    | `<n>`           | PNG compression quality (0-9). Higher is typically less compression. (Currently informational for PNG)     | `6`            |
| `-o`  | `--output`     | `<path/prefix>` | Specify the output file path or prefix for batch mode. Use `-` for stdout (single page only).                | Varies         |
| `-d`  | `--directory`  | `<dir>`         | Specify the output directory for batch mode. Implies `-a`.                                                   | Current dir    |
| `-v`  | `--verbose`    |                 | Enable verbose logging output to stderr.                                                                     | Disabled       |
| `-h`  | `--help`       |                 | Display the help message and exit.                                                                         |                |

### Scale Specification (`-s, --scale <spec>`)

The `<spec>` argument for the scale option can be:

*   **Percentage:** `NNN%` (e.g., `150%` for 1.5x scale, `50%` for 0.5x scale).
*   **Factor:** `N.N` (e.g., `2.0` for 2x scale, `0.75` for 0.75x scale).
*   **Dimensions:**
    *   `WxH`: Fit image within `W` pixels width AND `H` pixels height, maintaining aspect ratio (e.g., `800x600`).
    *   `Wx`: Fit image to `W` pixels width, height is auto-scaled (e.g., `1024x`).
    *   `xH`: Fit image to `H` pixels height, width is auto-scaled (e.g., `x768`).
*   **DPI (alternative to `-r`):** `NNNdpi` (e.g., `300dpi`). If both `-s NNNdpi` and `-r NNNdpi` are used, the last one parsed takes precedence. It's recommended to use `-r` for DPI settings for clarity.

### Default Behavior

*   If no input file is given and stdin is not a pipe, an error occurs.
*   If input is from stdin and no output is specified via `-o` or a positional argument, output goes to stdout (single page mode only).
*   If `-a` or `-d` is used (batch mode):
    *   All pages are converted.
    *   If `-d` is not specified, output is to the current directory.
    *   If `-o` is not specified, the output filename prefix is derived from the input PDF's name (e.g., `input.pdf` -> `input-`). If input is stdin, prefix is `page-`.
    *   Output filenames are formatted as `<prefix><page_number_padded_with_zeros>.png` (e.g., `mypdf-001.png`, `mypdf-002.png`).

See `EXAMPLES.md` for practical examples.
