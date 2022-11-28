@echo off
@echo Command-line samples for PDF2Text
@echo Copyright 2001-2021 PDFTron Systems Inc.
@echo.
@echo Example 1):
pdf2text "PDFTron PDF2Text User Manual.pdf"
@echo.
@echo Example 2):
pdf2text -o test_out -a 1 -f wordlist --output_bbox "PDFTron PDF2Text User Manual.pdf"
@echo.
@echo Example 3):
pdf2text -o test_out -a 1 -f xml --output_bbox *.pdf
@echo.
