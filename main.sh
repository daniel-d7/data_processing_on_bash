#!/bin/bash

# Exit on error
set -e

# Setting up environment to ensure script can be excutable anywhere
SCRIPT_DIR=$(dirname "$0")
TEMP_DIR="$SCRIPT_DIR/temp"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Data processing using bash only
echo "Data processing sequence started!"
sleep 2

# Create folder for temporary files
[ ! -d "$TEMP_DIR" ] && mkdir "$TEMP_DIR"

# Check if output folder has presented, else create one
[ ! -d "$OUTPUT_DIR" ] && mkdir "$OUTPUT_DIR"

echo "Creating temporary file!"
echo "Step 1"
awk -v RS='\r' '{gsub(/\n/,"")}1' $SCRIPT_DIR/raw_files/tmdb-movies.csv >$TEMP_DIR/temp1.csv
echo "Step 2"
sed -r ':a;s/("\s*[^",]*[^"]*)""([^"]*"\s*,)/\1####\2/g;ta' $TEMP_DIR/temp1.csv >$TEMP_DIR/temp2.csv
echo "Step 3"
sed -r ':a;s/(,"[^"]*),([^"]*",)/\1###\2/;ta' $TEMP_DIR/temp2.csv >$TEMP_DIR/temp.csv
sleep 5

# Create 3 new columns to separate day, month, year
awk -F',' 'BEGIN {OFS=","} {if (NR == 1) print $0 ",Month,Day,Year"; else {split($16, d, "/"); print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,d[1],d[2],d[3];}}' $TEMP_DIR/temp.csv >$TEMP_DIR/splited_date_temp.csv
sleep 5

# Split mm/dd/yy to month, date, year. Sorting based on $19, $22, $23 then remove $22, $23, $24 and replace ### back to comma
echo "Sorting and writing to a new file!"
head -n 1 $SCRIPT_DIR/raw_files/tmdb-movies.csv >$OUTPUT_DIR/tmdb-movies_sorted.csv
tail -n +2 $TEMP_DIR/splited_date_temp.csv | sort -t"," -k19,19 -k22,22 -k23,23 -r | awk -F"," '{OFS=","; $22=""; $23=""; $24=""; print $0}' | sed 's/,,,//g' | sed 's/###/,/g' | sed 's/####/""/g' >>$OUTPUT_DIR/tmdb-movies_sorted.csv
sleep 5

# Filter movies that have rating over 7.5
echo "Filtering movies that have rating over 7.5 and export to file!"
awk -F',' 'NR == 1 || ($18+0) >= 7.5' OFS=',' $TEMP_DIR/temp.csv | sed 's/###/,/g' | sed 's/####/""/g' >$OUTPUT_DIR/movies_over_7dot5.csv
sleep 5

# Movie name with highest revenue_adj
echo "Export movie with highest revenue to file!"
awk -F',' 'NR == 1 {next} NR == 2 {max = $21; movies = $6 "," $21} {if ($21 > max) {max = $21; movies = $6 "," $21} else if ($21 == max) {movies = movies (movies == "" ? "" : "\n") $6 "," $21}} END {print movies}' $TEMP_DIR/temp.csv >$OUTPUT_DIR/highest_revenue.csv
sleep 5

# Movie name with lowest revenue_adj
echo "Export movie name with lowest revenue to file!"
awk -F',' 'NR == 1 {next} NR == 2 {min = $21; movies = $6 "," $21} {if ($21 < min) {min = $21; movies = $6 "," $21} else if ($21 == min) {movies = movies (movies == "" ? "" : "\n") $6 "," $21}} END {print movies}' $TEMP_DIR/temp.csv >$OUTPUT_DIR/lowest_revenue.csv
sleep 5

echo ""
# Total revenue
awk -F',' 'NR > 1 {sum += $21} END {print "Total revenue:", sum/1000000000, "Billion"}' $TEMP_DIR/temp.csv
sleep 5

# Top 10 in profit
echo ""
echo "Top 10 profit"
awk -F',' -v OFS=',' 'BEGIN{OFMT="%.3f"} NR==1 {print $0, "profit_adj"; next} {print $0, $21 - $20}' $TEMP_DIR/temp.csv >$TEMP_DIR/profit_adj.csv
sort -t',' -k22,22 | awk -F',' 'NR <=11 {print $6, " - ", $20, $21, $22}' $TEMP_DIR/profit_adj.csv >$OUTPUT_DIR/top_10_profit.csv

echo "Sequence completed!"
exit 0
