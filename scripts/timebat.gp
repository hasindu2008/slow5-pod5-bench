set terminal png
unset key
set title "Time to get all reads"
set xlabel "size of the largest batch"
set ylabel "total time (sec)"
set yrange [0:]
set offsets 0, 2, 0, 0

plot data
