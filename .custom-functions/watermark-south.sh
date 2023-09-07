#!/bin/bash
#
# Usage
#
# One file
# ./watermark-south.sh input-file.jpg
#
# Save in folder
# ./watermark-south.sh input-file.jpg output-folder/
#
# Mass
# for i in *.jpg; do ./watermark-south.sh "$i" output/; done
#

#!/bin/bash

inputFile="$1"
outputFolder="$2"
outputFile="${inputFile%%.*}-watermark.${inputFile##*.}"
width=$(identify -format "%w" $inputFile)
height=$(identify -format "%h" $inputFile)

pointSizeLarge=$(echo "$width / 18.75" | bc)

if [ -n $outputFolder ]; then
  outputFolder=$(echo "$outputFolder" | sed 's/\/$//g')
  outputFile="${outputFolder}/$outputFile"
fi

convert $inputFile \
  -size "${width}x$height" xc:none \
  -gravity SouthEast -pointsize $pointSizeLarge -fill "rgba(255,255,255,0.3)" -weight bold -annotate +20+20 "MAIS VÍDEOS E FOTOS\nHTTPS://WWW.MY-SITE.APP" \
  $outputFile

echo "Processado: $inputFile -> $outputFile"
