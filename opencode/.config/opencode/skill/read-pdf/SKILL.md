---
name: read-pdf
description: Extract text, tables, and structured content from PDF files. Use when working with PDF files, asked to summarize or analyze a PDF, or when a user provides a .pdf path or attachment.
---

# Reading PDFs

## Overview

Claude Code's `Read` tool natively supports PDF files - it renders them as file attachments and extracts their content. Use it first. Fall back to CLI tools for edge cases.

## Primary Method: Read Tool

```
Read("/path/to/file.pdf")
```

This works for most PDFs. The tool extracts text content and returns it with line numbers like any other file.

**Use this when:**
- User provides a path to a `.pdf`
- You need to read the contents before summarizing, analyzing, or extracting data
- The PDF contains primarily text or mixed text/images

## Fallback: CLI Tools

When the Read tool fails or returns garbled output (scanned PDFs, encrypted files, complex layouts), use CLI tools.

**Install if needed:**
```bash
pip install pdfplumber  # best for tables and structured text
# or
brew install poppler    # provides pdftotext
```

**pdfplumber (Python) - best for tables:**
```python
import pdfplumber

with pdfplumber.open("file.pdf") as pdf:
    for page in pdf.pages:
        print(page.extract_text())
        # For tables:
        tables = page.extract_tables()
```

**pdftotext (CLI) - quick full-text extraction:**
```bash
pdftotext file.pdf -      # prints to stdout
pdftotext file.pdf out.txt
```

## Decision Flow

```
PDF to read?
  → Try Read tool first
  → Garbled/empty output? → Is it scanned/image-only?
      → Yes: needs OCR → use pytesseract + pdf2image
      → No: try pdfplumber or pdftotext
```

## OCR for Scanned PDFs

```bash
pip install pdf2image pytesseract
# Also: brew install tesseract
```

```python
from pdf2image import convert_from_path
import pytesseract

pages = convert_from_path("scanned.pdf")
for page in pages:
    text = pytesseract.image_to_string(page)
    print(text)
```

## Common Mistakes

- **Don't use `cat` on a PDF** - binary output is useless
- **Don't assume Read tool fails** - try it first, it handles most cases
- **Don't skip page iteration** - pdfplumber requires looping over `pdf.pages`
