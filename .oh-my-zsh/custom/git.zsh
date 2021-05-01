# Remove git alias

psrExclamation="!"
psrExclamationEscaped='\!'

for key in $(alias | grep git | cut -d"=" -f1); do
  unalias "${key/$psrExclamation/$psrExclamationEscaped}" 2> /dev/null
done
