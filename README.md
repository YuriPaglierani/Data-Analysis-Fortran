# Data Analysis in Fortran

Data analysis on car's waiting time in highway, the 606 values can be found in the section 'dati.txt' and they represent the waiting time for 1-event.

The analysis is made on the distributions of the data, in the program are used Erlang's distributions for 1, 2 and 3 events.

The program is complete but there are some parts of code that can be optimized, like the search of max and min in the maximum likelihood and least squares methods.

# Core points

- Chi squared Method

- Maximum Likelihood Method

- 3 Erlang distributions

- Hypotesis test

# Notes

Put the 'data.txt' file and the program file in the same folder.

One example is on the following lines:

gfortran Name_file.f90 -o name_file.x

./name_file.x

gnuplot

plot "1_event.txt" using 1:2 with boxes, '' using 1:3 w l, '' using 1:4 wl

