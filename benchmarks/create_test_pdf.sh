#!/bin/bash

# Create a simple test PDF using macOS tools
echo "Creating test PDF..."

# Create a simple HTML file
cat > test.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>PDF22PNG Test Document</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .page { page-break-after: always; min-height: 800px; }
        .box { 
            width: 200px; 
            height: 200px; 
            margin: 20px;
            display: inline-block;
        }
        .red { background-color: rgba(255, 0, 0, 0.7); }
        .green { background-color: rgba(0, 255, 0, 0.7); }
        .blue { background-color: rgba(0, 0, 255, 0.7); }
        .gradient {
            background: linear-gradient(45deg, #ff0000, #00ff00, #0000ff);
        }
    </style>
</head>
<body>
    <div class="page">
        <h1>Page 1: PDF22PNG Benchmark Test</h1>
        <p>This is a test PDF document with multiple pages for benchmarking.</p>
        <div class="box red"></div>
        <div class="box green"></div>
        <div class="box blue"></div>
        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
    </div>
    
    <div class="page">
        <h1>Page 2: Transparency Test</h1>
        <p>This page tests transparency handling.</p>
        <div class="box gradient"></div>
        <p>The gradient box above has multiple colors that should blend smoothly.</p>
    </div>
    
    <div class="page">
        <h1>Page 3: Text Heavy Page</h1>
        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.</p>
        <p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
        <p>Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
    </div>
    
    <div class="page">
        <h1>Page 4: Graphics Test</h1>
        <svg width="400" height="400">
            <circle cx="200" cy="200" r="150" fill="rgba(100, 100, 255, 0.5)" stroke="black" stroke-width="2"/>
            <rect x="150" y="150" width="100" height="100" fill="rgba(255, 100, 100, 0.7)"/>
            <polygon points="200,100 250,200 150,200" fill="rgba(100, 255, 100, 0.6)"/>
        </svg>
    </div>
    
    <div class="page">
        <h1>Page 5: Final Page</h1>
        <p>This is the final page of the test document.</p>
        <div style="text-align: center; margin-top: 100px;">
            <h2>End of Document</h2>
            <p>Total Pages: 5</p>
        </div>
    </div>
</body>
</html>
EOF

# Convert HTML to PDF using macOS built-in tools
/usr/bin/cupsfilter test.html > sample.pdf 2>/dev/null

# Alternative method using wkhtmltopdf if available
if command -v wkhtmltopdf &> /dev/null; then
    wkhtmltopdf --page-size A4 test.html sample_alt.pdf
    echo "Created sample_alt.pdf using wkhtmltopdf"
fi

# Clean up
rm test.html

if [ -f sample.pdf ]; then
    echo "Test PDF created: sample.pdf"
    echo "PDF info:"
    echo "- Size: $(ls -lh sample.pdf | awk '{print $5}')"
    echo "- Pages: $(mdls -name kMDItemNumberOfPages sample.pdf | awk '{print $3}')"
else
    echo "Failed to create test PDF"
    exit 1
fi