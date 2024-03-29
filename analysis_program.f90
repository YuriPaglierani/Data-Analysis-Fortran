! Module for constants and kind

module modkind

	implicit none
	integer, parameter :: ik = selected_int_kind(8), rk = selected_real_kind(7)
	
end module

!-----------------------------------------------------------------------------------------------------------------------!

! My module for utility functions in data analysis and hypothesis test in this exercise

module utlfunc

	use modkind
	implicit none
	
	real(kind=kind(1.0d0)), parameter :: e = 2.71828182845904523536, pi = 3.14159265358
	
	contains

	pure function maxdata(vec) result(mymax)				! Find the max in an array			
	
		integer :: i
		real (kind = rk), intent (in), dimension(:) :: vec
		real(kind = rk) :: mymax
		mymax = -10000000
		
		do i=1, size(vec)
			if (mymax < vec(i)) then
				mymax = vec(i)
			end if
		end do
		
	end function maxdata

	
	pure function mindata(vec) result(mymin)				! Find the min in an array
	
		integer :: i
		real (kind = rk), intent (in), dimension(:) :: vec
		real(kind = rk) :: mymin
		mymin = 10000000
		do i=1, size(vec)
			if(mymin > vec(i)) then
				mymin = vec(i)
			end if
		end do
		
	end function mindata
	
	
	subroutine k_event(dataev, k, vec)					! Creates a new array with time for the study of k-th waiting time (for the experiment)				
		real (kind = rk), intent (in), dimension(:) :: dataev
		integer, intent(in) :: k
		real (kind = rk), intent (out), dimension(:) :: vec
		integer :: i, j
		vec = 0
		
		if (k*size(vec) > size(dataev)) then
			print*, "Errore on dimension of data (k_event)"
		else
			do i=1, size(vec)
				do j=0, k-1
					vec(i) = dataev(k*i-j) + vec(i)	
				end do
			end do
		end if
		
	end subroutine k_event

	
	pure function stirlapprox(n) result (logfatt)			! This function will not be used, anyway this is Stirling's formula for approx
	
		real(kind=rk), intent(in) :: n
		real(kind=rk) :: logfatt
		logfatt = log(2*pi*n)/2.0 + n*log(n) - n
		
	end function

	
	subroutine gen_random_seed()					! uniformly distributed rnd numbers between 0 and 1 (not used)
	
		integer :: so, di, clock
		integer, dimension(:), allocatable :: seed
		call random_seed(size = di)
		allocate(seed(di))
		call system_clock(count=clock)
		seed = clock + 37 * (/ (so - 1, so = 1, di) /)
		call random_seed(put=seed)
		deallocate(seed)
		
	end subroutine gen_random_seed


	recursive function fattoriale(N) result(var)			! factorial function (not used)
	
		integer(kind=ik), intent(in) :: N
		integer(kind=ik) :: var
		
		if(N==0) then
			var=1
		else
			var=N*fattoriale(N-1)
		end if
		
	end function fattoriale 

	
	subroutine xavgbinner(xvec, start, delta)			! Sub for 'binning' data
	
		integer :: i
		real (kind=rk), intent (in) :: start, delta
		real (kind=rk), intent(out), dimension(:) :: xvec
		do i=1, size(xvec)
			xvec(i) = start + delta/2.0+(i-1)*delta			
		end do
		
	end subroutine xavgbinner
	
	
	subroutine counteventbin(tvec, xvec, delta, counter)		! Sub for count the number of events in each bin
	
		integer :: i, j
		real (kind=rk), intent (in) :: delta
		integer (kind=ik), intent(out), dimension(:) :: counter
		real (kind=rk), intent(in), dimension(:) :: tvec, xvec
		
		do i=1, size(tvec)
			do j=1, size(xvec)
				if(xvec(j)-delta/2.0 <= tvec(i) .and.tvec(i) < xvec(j) + delta/2.0) then
					counter(j)=1+counter(j)
				end if
			end do
		end do
		
	end subroutine counteventbin
	
	
	pure function distr1(xval, stim) result(f1)		! Erlang's distribution function for k=1 
	
		real (kind=rk) :: f1
		real (kind=rk), intent(in) :: xval, stim
		f1 = (1./stim)*exp(-xval/(stim))
		
	end function distr1
	
	
	pure function distr2(xval, stim) result(f2)		! Erlang's distribution function for k=2
		real (kind=rk) :: f2
		real (kind=rk), intent(in) :: xval, stim
		f2 = (xval/(stim**2) * exp(-xval/stim))
	end function distr2
	
	
	pure function distr3(xval, stim) result(f3)		! Erlang's distribution function for k=3
	
		real (kind=rk) :: f3
		real (kind=rk), intent(in) :: xval, stim
		f3 = (xval**2/(stim**3)) * exp(-xval/stim)/2.
		
	end function distr3
	
	!---------------------------------------------------------------------------------------------------------------!
	
! Least squares method reduced algorithm for the estimation of tau (free parameter) and its variance

	subroutine MMQR(name_file, lenght_name, n_data, xvec, delta, counter, real_tau, taumin, n_unit)
	
		real (kind=rk) :: x2min = 1000000.0, x2, supp, tau_est, sigmax2
		real (kind=rk), intent (in) :: real_tau, delta
		real (kind=rk), intent (out) :: taumin
		real (kind=rk), intent (in), dimension(:) :: xvec
		integer, intent (in) :: n_unit, n_data, lenght_name
		character (len=lenght_name), intent (in) :: name_file
		integer (kind=ik), intent (in), dimension(:) :: counter
		integer :: j, i
		
		open(unit = n_unit, file = name_file)
		
		tau_est = 0.0
		print*, ""
		
		do j = 1, 10000								! one important optimization could be on the research of min for chi^2
			x2 = 0.
			tau_est = real_tau/2.0 + (real_tau/10000.0)*j
			do i = 1, size(xvec)
				if(counter(i) /= 0.0) then
					select case (n_unit)
						case (1)
							supp = n_data*delta*distr1(xvec(i), tau_est)
						case (2)
							supp = n_data*delta*distr2(xvec(i), tau_est)
						case (3)
							supp = n_data*delta*distr3(xvec(i), tau_est)
						case default
							print*, "Error, wrong distribution"
							exit
					end select
        				x2 = ((counter(i) - supp) **2)/supp + x2
				end if
			end do
	
			if (x2 < x2min)	then 		
				x2min = x2
				taumin = tau_est
			end if
	
			write(unit = n_unit, fmt =*) tau_est, x2
		end do	
		
		close (unit = n_unit)
		
		print*,"taumin of distribution ", n_unit, ":", taumin
		print*,"x2 min of distribution ", n_unit, ":", x2min
		
		do j = 1, 10000
			x2 = 0.
			tau_est = taumin + (taumin/10000)*j
			do i = 1, size(xvec) 	
				if(counter(i) /= 0.0) then
					select case (n_unit)
						case (1)
							supp = n_data*delta*distr1(xvec(i), tau_est)
						case (2)
							supp = n_data*delta*distr2(xvec(i), tau_est)
						case (3)
							supp = n_data*delta*distr3(xvec(i), tau_est)
						case default
							print*, "Error, wrong distribution"
							exit
					end select
					x2 = ((counter(i) - supp) **2)/supp + x2
				end if
			end do	
			if (x2-x2min > 1.) then 		
				sigmax2 = tau_est-taumin 
				print*, "sigma_x2 of distribution ", n_unit, ":", sigmax2
				exit
			end if
		end do
		
	end subroutine MMQR

	!---------------------------------------------------------------------------------------------------------------!
	
! Maximum Likelihood method reduced algorithm for the estimation of tau (free parameter) and its variance

	subroutine MML(name_file, lenght_name, n_data, xvec, delta, counter, real_tau, taumax, n_unit)
	
		real (kind=rk) :: Lmax = -1000000.0, L1, L, supp, sigmaL, tau_est
		real (kind=rk), intent (in) :: real_tau, delta
		real (kind=rk), intent (out) :: taumax
		real (kind=rk), intent (in), dimension(:) :: xvec			! one important optimization could be on the research of max for Likelihood
		integer, intent (in) :: n_unit, n_data, lenght_name
		character (len=lenght_name), intent (in) :: name_file
		integer (kind=ik), intent (in), dimension(:) :: counter
		integer :: j, i, k
		
		open(unit = n_unit+9, file = name_file)
		
		tau_est = 0.0
		print*, ""
		
		do j=1,10000
			L1=0.
			L=0.
			tau_est= real_tau/2.0 + (real_tau/10000.0)*j
			do i = 1, size(xvec)	
				if(counter(i) /= 0.0) then
					select case (n_unit)
						case (1)
							supp = n_data*delta*distr1(xvec(i), tau_est)
						case (2)
							supp = n_data*delta*distr2(xvec(i), tau_est)
						case (3)
							supp = n_data*delta*distr3(xvec(i), tau_est)
						case default
							print*, "Error, wrong distribution"
							exit
					end select
					L1 = exp(-supp)
       				do k = 1, counter(i)   
						L1=L1*supp/(k*1.0) 
					end do		    
					L = log(L1) + L
				end if
			end do
			if (Lmax < L) then 		
				Lmax = L
				taumax = tau_est
			end if
			write(unit = n_unit+9, fmt =*) tau_est, L
		end do	
		
 		close (unit = n_unit+9)
 		
		print*,"taumax of distribution ", n_unit, ":", taumax
		print*,"ln(L_max) of distribution ", n_unit, ":", Lmax
		
		do j = 1,10000
			L1=0.
			L=0.
			tau_est = taumax + (taumax/10000)*j
			do i=1, size(xvec)
				if(counter(i) /= 0.0) then
					select case (n_unit)
						case (1)
							supp = n_data*delta*distr1(xvec(i), tau_est)
						case (2)
							supp = n_data*delta*distr2(xvec(i), tau_est)
						case (3)
							supp = n_data*delta*distr3(xvec(i), tau_est)
						case default
							print*, "Errore nella selezione della distribuzione"
							exit
					end select
 					L1 = exp(-supp)
      					do k = 1, counter(i)   
     						L1 = L1*(supp)/(1.0*k) 
        				end do		   
					L = log(L1) + L
				end if
	
			end do	
			if (Lmax-L > 0.5) then 		
				sigmaL = tau_est - taumax 
				print*,"sigmaL of distribution ", n_unit, ":", sigmaL
				exit
			end if
		end do
		
	end subroutine MML
	
	!---------------------------------------------------------------------------------------------------------------!

	subroutine count_eff(countstart, eff, threshold)
	
		real (kind=rk), intent(in), dimension(:) :: countstart
		integer (kind=ik), intent(out) :: eff
		integer (kind=ik), intent(in) :: threshold
		integer :: i
		eff = 0
		do i=1, size(countstart)
			if (countstart(i) >= threshold) then
				eff = eff+1 
			end if
		end do
		
	end subroutine count_eff
	
	!---------------------------------------------------------------------------------------------------------------!

! Hypothesys test for 3 distributions applying chi^2's test
	
	subroutine tstar_test(tstar, cont1, cont2, cont3, xk, xk2, xk3, n, tau_est, delta, k)
	
		real (kind=rk), intent(out), dimension(:) :: tstar
		integer (kind=ik), intent(in), dimension(:) :: cont1, cont2, cont3, n
		real (kind=rk), intent(in), dimension(:) ::  tau_est, delta, xk, xk2, xk3
		real (kind=rk), intent(in) :: k
		real (kind=rk) :: supp
		integer :: i
		
		tstar = 0
		
		do i=1, size(cont1)
			if (cont1(i) >= k) then 
				supp = n(1)*delta(1)*distr1(xk(i), tau_est(1))
				tstar(1)=tstar(1)+ ((cont1(i)- supp)**2)/supp !!!!primo test tau=tau
			end if
		end do
		do i=1, size(cont2)
			if (cont2(i) >= k) then
				supp = n(2)*delta(2)*distr2(xk2(i), tau_est(2))
				tstar(2)=tstar(2)+ ((cont2(i)- supp)**2)/supp
			end if
		end do
		do i=1, size(cont3)
			if (cont3(i) >= k) then
				supp = n(3)*delta(3)*distr3(xk3(i), tau_est(3))
				tstar(3)=tstar(3)+ ((cont3(i)- supp)**2)/supp
			end if
		end do
		
	end subroutine tstar_test
	
	!---------------------------------------------------------------------------------------------------------------!
	
	subroutine sigma(cont, n, mysigma)				! sigma evaluation for each value of bin
	
		real (kind=rk), intent(in), dimension(:) :: cont
		integer (kind=ik), intent(in):: n
		integer :: i
		real (kind=rk), intent(out), dimension(:) :: mysigma
		
		do i = 1, size(cont)
			mysigma(i)=sqrt(cont(i)*(1-(cont(i)/(1.0*n)))) 	!errori sui conteggi
		end do
		
	end subroutine sigma
	
end module utlfunc

!-----------------------------------------------------------------------------------------------------------------------!

program Data_analysis
	use utlfunc
	use modkind
	implicit none
	
	integer :: n_of_dist, i, j, k
	real(kind=rk) :: tau, maxt, mint, supp
	real(kind=rk), dimension (:), allocatable :: xk, xk2, xk3, varia
	real(kind=rk), dimension(:), allocatable :: error1, error2, error3, delta, tmax, tmin, tau_est_chi, tau_est_lik
	integer(kind=ik), dimension(:), allocatable :: n, cont1, cont2, cont3, contsuff, b
	real(kind=rk),dimension(:), allocatable :: t, t2, t3, tstar_chi, tstar_lik
	
	n_of_dist=3
	
	allocate(n(n_of_dist), b(n_of_dist), delta(n_of_dist), tmax(n_of_dist), tmin(n_of_dist))
	allocate(tau_est_chi(n_of_dist), tau_est_lik(n_of_dist), contsuff(n_of_dist), tstar_chi(n_of_dist), tstar_lik(n_of_dist))
	n=(/606, 303, 202/)
	b=(/24, 18, 18/)
		
	allocate(t(n(1)), t2(n(2)), t3(n(3)))
	
	open (unit = 0, file = 'dati.txt', form = 'formatted', status = 'old', action = 'read')	! reading data from file
	do i = 1, n(1)										
		read (unit = 0, fmt = *) t(i)
	end do
	close (unit = 0)
	
	tau = sum(t)/n(1)				! analytical estimation of tau
	print*,"il tuo tau è", tau
	
	call k_event(t, 2, t2)
	call k_event(t, 3, t3)
	
	tmax(1) = maxdata(t)
	tmax(2) = maxdata(t2)
	tmax(3) = maxdata(t3)
	tmin(1) = mindata(t)
	tmin(2) = mindata(t2)
	tmin(3) = mindata(t3)
		
	do i=1, n_of_dist
		delta(i)=(tmax(i)-tmin(i))/(1.0*b(i))
	end do
	
	allocate(error1(b(1)),cont1(b(1)),xk(b(1)), cont2(b(2)), cont3(b(3)))
	allocate(varia(b(1)), xk2(b(2)), xk3(b(3)))
	allocate(error2(b(2)), error3(b(3)))
	
	cont1 = 0
	cont2 = 0
	cont3 = 0
	
	print*, ""
	print*,"Ampiezza intervalli"
	do i = 1, n_of_dist
		print*,i, ":", delta(i)
	end do
	
	!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!/////////////////// 

	call xavgbinner(xk, tmin(1), delta(1))
	call xavgbinner(xk2, tmin(2), delta(2))
	call xavgbinner(xk3, tmin(3), delta(3))

	call counteventbin(t, xk, delta(1), cont1)
	call counteventbin(t2, xk2, delta(2), cont2)
	call counteventbin(t3, xk3, delta(3), cont3)
		
	!!!!!!!!!!!!!!!!!!!!!////////////////////// Least squares 1, 2 and 3
	
	call MMQR('min1.txt', len('min1.txt'), n(1), xk, delta(1), cont1, tau, tau_est_chi(1), 1)
	
	call MMQR('min2.txt', len('min2.txt'), n(2), xk2, delta(2), cont2, tau, tau_est_chi(2), 2)
	
	call MMQR('min3.txt', len('min3.txt'), n(3), xk3, delta(3), cont3, tau, tau_est_chi(3), 3)
	
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! likelihood 1, 2 and 3

	call MML('max1.txt', len('max1.txt'), n(1), xk, delta(1), cont1, tau, tau_est_lik(1), 1)
	
	call MML('max2.txt', len('max2.txt'), n(2), xk2, delta(2), cont2, tau, tau_est_lik(2), 2)
	
	call MML('max3.txt', len('max3.txt'), n(3), xk3, delta(3), cont3, tau, tau_est_lik(3), 3)
	
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!/////////////////// Hypothesis test
	
	call count_eff(1.0_rk*cont1, contsuff(1), 10)
	call count_eff(1.0_rk*cont2, contsuff(2), 10)
	call count_eff(1.0_rk*cont3, contsuff(3), 10)
	
	print*,"conteggi maggiori di 10", contsuff(1), contsuff(2), contsuff(3)
	
	call tstar_test(tstar_chi, cont1, cont2, cont3, xk, xk2, xk3, n, tau_est_chi, delta, 10.0_rk)
	call tstar_test(tstar_lik, cont1, cont2, cont3, xk, xk2, xk3, n, tau_est_lik, delta, 10.0_rk)
	
	print*, ""
	print*, "Hypothesys test for chi^2 tau estimation"
	print*,"t-alpha 1 expected: 17.28","	obtained: ", tstar_chi(1)
	print*,"t-alpha 2 expected: 12.02","	obtained: ", tstar_chi(2)
	print*,"t-alpha 3 expected: 12.02","	obtained: ", tstar_chi(3)
	
	print*, ""
	print*, "Hypothesis test for Maximum Likelihood tau estimation"
	print*,"t-alpha 1 expected: 17.28","	obtained: ", tstar_lik(1)
	print*,"t-alpha 2 expected: 12.02","	obtained: ", tstar_lik(2)
	print*,"t-alpha 3 expected: 12.02","	obtained: ", tstar_lik(3)
	
	call sigma(1.0_rk*cont1, n(1), error1)
	call sigma(1.0_rk*cont2, n(2), error2)
	call sigma(1.0_rk*cont3, n(3), error3)
	
	open(unit = 17, file = '1_event.txt')
	do i=1,b(1)
		write(unit=17,fmt=*) xk(i), cont1(i), n(1)*delta(1)*distr1(xk(i), tau_est_chi(1)), n(1)*delta(1)*distr1(xk(i), tau_est_lik(1))
	end do
	close (unit=17)
	
	open(unit = 18, file = '2_events.txt')
	do i=1,b(2)
		write(unit=18,fmt=*) xk2(i), cont2(i), n(2)*delta(2)*distr2(xk2(i), tau_est_chi(2)), n(2)*delta(2)*distr2(xk2(i), tau_est_lik(2))
	end do
	close (unit=18)
	
	open(unit = 19, file = '3_events.txt')
	do i=1,b(3)
		write(unit=19,fmt=*) xk3(i), cont3(i), n(1)*delta(3)*distr3(xk3(i), tau_est_chi(3)), n(3)*delta(3)*distr3(xk3(i), tau_est_lik(3))
	end do
	close (unit=19)
	
end program
