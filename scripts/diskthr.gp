set terminal png
unset key
set title "Time to get all reads from memory"
set xlabel "number of threads"
set ylabel "total disk time (sec)"
set yrange [0:]
set offsets 0, 2, 0, 0

plot data
