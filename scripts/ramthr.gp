set terminal png
unset key
set title "Peak RAM usage"
set xlabel "number of threads"
set ylabel "peak RAM (gigabytes)"
set yrange [0:]
set offsets 0, 2, 0, 0

plot data
