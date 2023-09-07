#!/bin/bash
#
# Usage
#
# One file
# ./watermark-rotate.sh input-file.jpg
#
# Save in folder
# ./watermark-rotate.sh input-file.jpg output-folder/
#
# Mass
# for i in *.jpg; do ./watermark-rotate.sh "$i" output/; done
#

inputFile="$1"
outputFolder="$2"
outputFile="${inputFile%%.*}-watermark.${inputFile##*.}"
width=$(identify -format "%w" $inputFile)
height=$(identify -format "%h" $inputFile)

pointSizeLarge=$(echo "$width / 10.75" | bc)
pointSizeSmall=$(( $width / 50 ))

if [ -z $outputFolder ]; then
  outputFolder="$PWD"
fi

outputFolder=$(echo "$outputFolder" | sed 's/\/$//g')
outputFile="${outputFolder}/$outputFile"

convert $inputFile \
  -size "${width}x$height" xc:none \
  -gravity center \
  -pointsize $pointSizeLarge -fill "rgba(255,255,255,0.3)" -weight bold -annotate 310x310-10-30 "MAIS VÍDEOS E FOTOS\nHTTPS://WWW.MY-SITE.APP" \
  -gravity South -pointsize $pointSizeSmall -fill white -annotate +20+20 "HTTPS://WWW.MY-SITE.APP" \
  $outputFile

echo "Processado: $inputFile -> $outputFile"
