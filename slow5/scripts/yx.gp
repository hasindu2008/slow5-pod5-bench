set terminal png
set title TITLE
set xlabel XLABEL
set ylabel YLABEL
set yrange [0:]
set offsets 0, 2, 0, 0

data(n) = word(DATA,n)
name(n) = word(NAME,n)
plot for [i=1:words(DATA)] data(i) title name(i) noenhanced
