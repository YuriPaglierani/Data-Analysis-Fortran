# Data Analysis in Fortran

The data analysis program was written from scratch in Fortran during my Bachelor's. 

The objective is to analyze a car's waiting time on the highway. The 606 values have been collected by my patient friend Alessandro Namar, and they can be found in the section 'dati.txt' (they represent the waiting time for one event).

The hypothesis is that the waiting time for n events distributes following Erlang's distributions with k = n.

The program works but there are a lot of improvements that can be done, such as the search of max and min in the maximum likelihood and least-squares methods.

# Core points

- Chi squared Method

- Maximum Likelihood Method

- 3 Erlang distributions

- Hypothesis test

# Notes

Put the 'dati.txt' file and the program file in the same folder.

One example is on the following lines:

gfortran Name_file.f90 -o name_file.x

./name_file.x

gnuplot

plot "1_event.txt" using 1:2 with boxes, '' using 1:3 w l, '' using 1:4 wl

