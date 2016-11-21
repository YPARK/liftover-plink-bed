#!/bin/bash

# Plnik can generate basic statistics, such as the number of counts/freqs per allele.
# The output format is a little messed up and this script converts that to csv (for easy reading into e.g. R)
#
# Example:
#
# plink_freq_count_to_csv.bash < input.freq.counts > output.csv
#
# The freq count file is created like this:
# 
# plink --bfile <filename-prefix> --freq counts --out <filename-prefix> 
sed 's/^\s\+//g' - | sed 's/\s\+/,/g'
