#!/usr/bin/env python3

import os
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.units import inch

def create_test_pdf():
    """Create a test PDF with multiple pages for benchmarking."""
    
    filename = "sample.pdf"
    c = canvas.Canvas(filename, pagesize=letter)
    width, height = letter
    
    # Page 1: Text and basic shapes
    c.setFont("Helvetica-Bold", 24)
    c.drawString(100, height - 100, "PDF22PNG Benchmark Test")
    
    c.setFont("Helvetica", 12)
    c.drawString(100, height - 140, "This is a test PDF document for performance benchmarking.")
    
    # Draw some shapes
    c.setFillColor(colors.red)
    c.rect(100, height - 300, 100, 100, fill=1)
    
    c.setFillColor(colors.green)
    c.rect(220, height - 300, 100, 100, fill=1)
    
    c.setFillColor(colors.blue)
    c.rect(340, height - 300, 100, 100, fill=1)
    
    c.showPage()
    
    # Page 2: More complex graphics
    c.setFont("Helvetica-Bold", 20)
    c.drawString(100, height - 100, "Page 2: Graphics Test")
    
    # Draw a gradient-like effect with rectangles
    for i in range(20):
        gray = i / 20.0
        c.setFillColor(colors.Color(gray, gray, gray))
        c.rect(100 + i * 15, height - 300, 15, 100, fill=1)
    
    c.showPage()
    
    # Page 3: Text heavy
    c.setFont("Helvetica-Bold", 20)
    c.drawString(100, height - 100, "Page 3: Text Heavy")
    
    c.setFont("Helvetica", 10)
    y = height - 150
    text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 5
    
    for _ in range(20):
        c.drawString(100, y, text[:80])
        y -= 15
    
    c.showPage()
    
    # Page 4: Transparency test
    c.setFont("Helvetica-Bold", 20)
    c.drawString(100, height - 100, "Page 4: Transparency Test")
    
    # Draw overlapping transparent rectangles
    c.setFillColor(colors.Color(1, 0, 0, alpha=0.5))
    c.rect(150, height - 300, 150, 150, fill=1)
    
    c.setFillColor(colors.Color(0, 1, 0, alpha=0.5))
    c.rect(200, height - 350, 150, 150, fill=1)
    
    c.setFillColor(colors.Color(0, 0, 1, alpha=0.5))
    c.rect(250, height - 400, 150, 150, fill=1)
    
    c.showPage()
    
    # Page 5: Final page
    c.setFont("Helvetica-Bold", 20)
    c.drawString(100, height - 100, "Page 5: Final Page")
    
    c.setFont("Helvetica", 14)
    c.drawCentredString(width/2, height/2, "End of Test Document")
    c.drawCentredString(width/2, height/2 - 30, "Total Pages: 5")
    
    c.showPage()
    
    # Save the PDF
    c.save()
    
    print(f"Created {filename}")
    print(f"Size: {os.path.getsize(filename)} bytes")
    print("Pages: 5")

if __name__ == "__main__":
    try:
        create_test_pdf()
    except ImportError:
        print("Error: reportlab not installed")
        print("Install with: pip install reportlab")
        exit(1)