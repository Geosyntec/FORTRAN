c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c****| PeakFQ2EMA
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c    
c    this routine reads the standard output file from the USGS PEAKFQ
c    program, extracts the data and control information from that file,
c    solicits a small amount of additional user information, and then
c    calculates ema-based estimates of the frequency curves
c
c    this was prepared by tim cohn, us geological survey, to support 
c      development of an operational version of peakfq (bulletin 17b
c      implementation) which would include the expected moments
c      algorithm (ema; cohn et al. 1997; 2001)
c       
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c    development history
c
c    timothy a. cohn        21 may 2007
c      modified (tac)       06 jun 2007
c
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c   compiler options:
c     gfortran -fbounds-check -Wampersand 
c                       peakfq2emaXX.f 
c                       emafit027.f
c                       probfun.f 
c                       imslfake.f 
c
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
      program PeakFQ2EMA
      
      implicit none
      
      integer nmax,nqmax
      parameter (nmax=20000,nqmax=15)
      
      integer
     1  i,ic,j,ncases,nV,
     2  wyV(nmax)
     
      double precision
     1  reg_skewV,reg_mseV,
     2  qlV(nmax),quV(nmax),
     3  tlV(nmax),tuV(nmax),
     4  cmoms(3),pq(nqmax),yp(nqmax),ci_low(nqmax),ci_high(nqmax),
     5  gbthresh0
     
      character*80 input(1000),infile,outfile
      
      data gbthresh0/-99.d0/
      
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c   beginning of executable code
c
      write(*,*) 'enter the input filename'
      read(*,*) infile
      open(unit=11,file=infile,status='old')
      write(*,*) 'enter the output filename'
      read(*,*) outfile
      open(unit=12,file=outfile,status='new')

      do 10 ic=1,100
      
        call getdata01(nV,qlV,quV,tlV,tuv,reg_skewV,reg_mseV,
     1                     wyV,input)
     
          if(nV .eq. -99) goto 99

        call emafit(nV,qlV,quV,tlV,tuV,reg_skewV,reg_mseV,gbthresh0,   
     1              cmoms,pq,yp,ci_low,ci_high)
     
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c  describe run parameters
c
      write(12,2001) nV,reg_skewV,reg_mseV,
     1               sqrt(reg_mseV)
2001  format(//,t38,'EMA RESULTS',//,
     1  t30,'Record Length',   t50,i6,/,
     2  t30,'Generalized Skew',t50,f6.3,/,
     3  t30,'Gen. Skew MSE',   t50,f6.3,/,
     4  t30,'Gen. Skew SD',    t50,f6.3)
     
      write(12,2002) cmoms(1),sqrt(cmoms(2)),cmoms(3)
2002  format(//,t1,'ANNUAL FREQUENCY CURVE PARAMETERS ',
     1   ' -- LOG-PEARSON TYPE III',//,3f10.6)

      write(12,2003)
2003  format(//,t35,'EMA FREQUENCY ESTIMATES',//,80('-'),/,
     2  'Annual Exceedance Prob.',t25,'EMA Estimate',t48,'Ci-Low',
     1  t68,'CI-High',/)
     
      do 410 i=1,nqmax
        write(12,2004) 1.d0-pq(i),10**yp(i),10**ci_low(i),10**ci_high(i)
2004    format(t5,f6.4,t20,3f20.1)
410   continue
      write(12,'(///,80(''*''),//,''1'')') 

10    continue

99    continue
        write(*,*) 'Finished Processing'
      stop
      end
      
      
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
      subroutine getdata01(nV,qlV,quV,tlV,tuV,
     1                     reg_skewV,reg_mseV,
     2                     wyV,input)
      
      implicit none
      
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c   declaration of parameters
c
      integer nmax,nthresh,nqmax
      double precision infinity,Missing
      parameter (nmax=20000,nthresh=10,Infinity=1.d20,
     1           Missing=-10.0d0,nqmax=15)
      
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c   declaration of external functions
c
      logical ifany
      
      integer ivmin,ivmax
      
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c   declaration of arrays and variables
c
      integer
     1  nV,wyV(nmax),nsh
     
      double precision
     1  qlV(nmax),quV(nmax),tlV(nmax),tuV(nmax),
     2                     reg_skewV,reg_mseV
      
      integer
     1  i,i2,j,ict,k,
     2  n_peak,n_not_used,n_sys,n_historic,n_hist_period,
     3  ihalf,wy(nmax),
     2  nt,wybeg(nthresh),wyend(nthresh),wymin,wymax
     
      double precision
     1  gen_skew,gen_skew_sd,gage_base_q,user_supp_hot,user_supp_lot,
     2  a_plot,
     3  q(nmax),
     4  tl(nthresh),tu(nthresh),
     4  cmoms(3),pq(nqmax),yp(nqmax),ci_low(nqmax),ci_high(nqmax)
     
      double precision vmax

     
      
      character*80 input(500),line,station
      
      character*11 skew_option
      
      character*10 codes(nmax)
      
      logical
     1  lprint(nmax)
     
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c   beginning of executable code
c     start by grabbing what we can from the input file
c
        do 20 i = 3, 500
            read(11,'(a80)',end=99) input(i)
            write(12,'(a80)') input(i)
        if(ifany('Station -',input(i))) then
          station = input(i)
        else if(input(i)(17:31) .eq. 'Number of peaks') then
          read(input(i)(58:63),'(i7)') n_peak
        else if(input(i)(17:31) .eq. 'Peaks not used ') then
          read(input(i)(58:63),'(i7)') n_not_used
        else if(input(i)(17:31) .eq. 'Systematic peak') then
          read(input(i)(58:63),'(i7)') n_sys
        else if(input(i)(17:31) .eq. 'Historic peaks ') then
          read(input(i)(58:63),'(i7)') n_historic
        else if(input(i)(17:31) .eq. 'Years of histor') then
          read(input(i)(58:63),'(i7)') n_hist_period
        else if(input(i)(17:31) .eq. 'Generalized ske') then
          read(input(i)(58:63),'(f7.3)') gen_skew
        else if(input(i)(17:31) .eq. 'Standard error ') then
          read(input(i)(58:63),'(f7.3)') gen_skew_sd
        else if(input(i)(17:31) .eq. 'Skew option    ') then
          read(input(i)(57:67),'(a11)') skew_option
        else if(input(i)(17:31) .eq. 'Gage base disch') then
          read(input(i)(58:63),'(f7.1)') gage_base_q
        else if(input(i)(17:31) .eq. 'User supplied h') then
          if(input(i)(58:59) .eq. '--') then
            user_supp_hot = 0.d0
          else
            read(input(i)(58:63),'(f7.0)') user_supp_hot
          endif
        else if(input(i)(17:31) .eq. 'User supplied l') then
          if(input(i)(58:59) .eq. '--') then
            user_supp_lot = 0.d0
          else
            read(input(i)(58:63),'(f7.0)') user_supp_lot
          endif
        else if(input(i)(17:31) .eq. 'Plotting positi') then
          read(input(i)(58:63),'(f7.2)') a_plot
        else if(input(i)(24:42) .eq. 'I N P U T   D A T A') then
          do 40 i2=i+1,i+4
            read(11,'(a80)',end=99) input(i2)
            write(12,'(a80)') input(i2)
40        continue
              ict   = i2
              ihalf = (n_peak+1)/2
          do 50 i2=ict+1,ict+ihalf
              j  = i2-ict
            read(11,'(a80)',end=99) input(i2)
            write(12,'(a80)') input(i2)
            read(input(i2),'(2(i12,f15.1,a9,1x))') 
     1          wy(j),q(j),codes(j),
     1          wy(j+ihalf),q(j+ihalf),codes(j+ihalf)
50        continue
        else if(i .gt. 100 .and. 
     1            ifany('U. S. GEOLOGICAL SURVEY',input(i))) then
            backspace(11) !  Save last line to print with next record
            backspace(12)
          goto 30
        endif
20      continue

30    continue


c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c   set up the regional skew
c     note that setting the mse of the regional skew to a small number
c     forces the skew to be the regional value (without error (!!))
c
           reg_skewV = gen_skew          ! regional skew info
            if(ifany('WEIGHTED',skew_option)) then
              reg_mseV  = gen_skew_sd**2
            else if(ifany('GENERALIZED',skew_option)) then
              reg_mseV  = 1.0d-20
            endif
            
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c   begin output of results
c
      write(12,'(///,80(''*''),//)') 
      write(12,'(t35,a12)') 'EMA ANALYSIS'
      write(12,'(/,80(''*''),//)') 
      write(12,'(a80)') station
      write(12,*)

c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c
c   here's where the real work gets done
c
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c     compute the default thresholds
c     these are given by 
c           (tl,tu) = (0,Infinity) for systematic data
c           (tl,tu) = (Min{historic floods},Infinity) for historic period
c
c     N.B. Negative discharges indicate peaks not used in analysis (convention?)
c
         
          nt = 1
          tl(1)     =  0.d0           ! systematic data
          tu(1)     =  Infinity
          wybeg(1)  =  999999       ! non-informative prior
          wybeg(2)  =  999999
          wyend(1)  = -999999

c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c  Historical Data:  Set threshold at smallest historical flood
c                    Set historical period to begin at minimum of 
c                      date of earliest historic flood or last record
c                      minus length of historical period
c                    User can over-ride this
c
          tl(2)     =  Infinity       ! historical data
          tu(2)     =  Infinity
        do 90 k=1,n_peak
              wy(k) =  abs(wy(k))     !  hist floods id'd by negative wy
          if(q(k) .ge. 0.0) then
            if(ifany('H',codes(k))) then
              nt    = 2
              wybeg(2) = min(wybeg(2),wy(k),wy(n_peak)-n_hist_period+1) 
              tl(2)    = min(tl(2),q(k))
            else
              wybeg(1) = min(wybeg(1),wy(k))
              wyend(1) = max(wyend(1),wy(k))
            endif
          endif
90      continue

c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c  Correction for a high outlier.  This assumes data are neatly ordered
c    User may have to enter individual thresholds if record has discontinuities
c
      if((n_hist_period .gt. n_sys) .and. (nt .eq. 1)) then
            nt  =  2
            wybeg(2) = wy(n_peak)-n_hist_period+1
            tl(2)    = vmax(n_sys,q(n_peak-n_sys+1))
      endif
            wyend(2) = wybeg(1)-1

      write(*,'(///)') 
      write(*,*) ' Enter censoring thresholds corresponding to:'
      write(*,*) 
      write(*,'(a80)') station
      write(*,*) 
      write(*,*) ' Default values computed to be:'
      write(*,*) 
      write(*,1002)
1002    format(' T',t9,'Beg. Year',t24,'End Year',
     1         t38,'T_low',t53,'T_up',/,60('-'))
      write(*,1001) 1,wybeg(1),wyend(1),tl(1),tu(1)
1001    format(i2,1x,2i14,1p,2d15.5,0p)
      if(nt .eq. 2)  write(*,1001) 2,wybeg(2),wyend(2),tl(2),tu(2)
      write(*,*)
      write(*,*) ' Enter blank line to accept defaults'
      write(*,*) ' To change thresholds, enter desired thresholds'
      write(*,*) ' beginning year, ending year, threshold pair'
      write(*,*) '          (wybeg, wyend, tl, tu)'
      write(*,*)  
      do 92 j=nt+1,10
      read(*,'(a80)') line
      if(line .eq. '') then
        nt = j-1
        goto 95
      else
        read(line,*) wybeg(j),wyend(j),tl(j),tu(j)
      endif
92    continue
95    continue
      write(12,'('' Number of peaks'',t25,i9)') n_peak
      write(12,'('' Peaks not used'',t25,i9)') n_not_used
      write(12,'('' Systematic peak'',t25,i9)') n_sys
      write(12,'('' Historic peaks'',t25,i9)') n_historic
      write(12,'('' Years of historic record'',t25,i9)') n_hist_period
      write(12,'('' Generalized skew'',t25,f9.2)') gen_skew
      write(12,'('' Standard error'',t25,f9.4)') gen_skew_sd
      write(12,'('' Skew option'',t25,a11)') skew_option
      write(12,'('' Gage base discharge'',t25,f9.1)') gage_base_q
      write(12,'(/,''PERCEPTION THRESHOLDS FOR EMA'',/,30(''-''),/)') 
      write(12,1002)
      do 98 j=1,nt
        write(12,1001) j,wybeg(j),wyend(j),tl(j),tu(j)
98    continue
            wymin  =  ivmin(nt,wybeg) 
            wymax  =  ivmax(nt,wyend)
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c  Set all annual thresholds to Missing (implies no knowledge)
c
      do 200 k=wymin,wymax
          i = k-wymin+1
          wyV(i) =  k
          tlV(i) =  Missing
          tuV(i) =  Missing
          qlV(i) =  Missing    ! Flag initially as missing values
          quV(i) =  Missing
200   continue

c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c  Fill in known threshold values
c   N.B. If gage base discharge is greater than zero, this provides a lower
c        bound on the observation threshold corresponding to all flows
c
      do 210 j=1,nt
        do 210 k=wybeg(j),wyend(j)
          i = k-wymin+1
            tuV(i) = tu(j)
          if(gage_base_q .gt. 0.d0) then
            tlV(i) = max(log(gage_base_q),tl(j))
          else
            tlV(i) = tl(j)
          endif          
210   continue

c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c  Fill in measured peaks
c
      do 220 j=1,n_peak
        if(q(j) .le. Missing) goto 220
          i = wy(j)-wymin+1
          if(tlV(i) .eq. Missing) then  ! this should never occur
            write(*,*) ' *** Problem ***'
            write(*,*) ' Water Year ',wy(j),' has peak without tl, tu'
          endif
            qlV(i) = q(j)
            quV(i) = q(j)
220   continue

c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c  For years without peaks, assume peak is less than threshold tl
c
      do 230 k=wymin,wymax
          i = k-wymin+1
          if(qlV(i) .eq. Missing) then  ! no peak for this year
            if(tlV(i) .gt. 0.d0) then
              qlV(i) = 0.d0
              quV(i) = tlV(i)
            endif
          endif
230   continue

c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c  collapse the data set, eliminating any periods of missing record
c
          i  =  0
      do 240 j=1,wymax-wymin+1
        if(qlV(j) .ne. Missing) then
          i = i+1
          tlV(i) = tlV(j)
          tuV(i) = tuV(j)
          qlV(i) = qlV(j)
          quV(i) = quV(j) 
          wyV(i) = wyV(j)
        endif
240   continue
          nsh = i
          nV  = nsh

c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c  accept edits to existing flood peaks
c
        write(12,'(//,t38,''EMA REPRESENTATION OF DATA'',/)')
        write(12,'(a80,/)') station
        write(12,1004)
1004      format(t13,'Year',t25,'Q_low',
     1         t41,'Q_up',t53,'T_low',t69,'T_up')
      do 300 i=1,nsh
        if(i .eq. 1 .or. i .eq. nsh) then
          lprint(i) = .TRUE.
        else if(qlV(i) .ne. qlV(i-1)) then
          lprint(i) = .TRUE.
        else if(quV(i) .ne. quv(i-1)) then
          lprint(i) = .TRUE.
        else if(tlV(i) .ne. tlV(i-1)) then
          lprint(i) = .TRUE.
        else if(tuV(i) .ne. tuV(i-1)) then
          lprint(i) = .TRUE.
        else if(wyV(i) .ne. wyV(i-1)+1) then
          lprint(i) = .TRUE.
        else 
          lprint(i) = .FALSE.
        endif
300   continue
c
      do 310 i=1,nsh
        if(lprint(i)) then
          write(12,1003) wyV(i),qlV(i),quV(i),
     1                  tlV(i),tuV(i)
1003        format(1x,i15,1p,2f15.1,2d15.5)
        else if(lprint(i+1)) then
          write(12,1003) wyV(i),qlV(i),quV(i),
     1                  tlV(i),tuV(i)
        else if(lprint(i-1)) then
          write(12,'(t35,''  . . .'')')
        endif
310   continue

       do 400 j=1,nV
         qlV(j) = log10(max(1.d-10,qlV(j)))
         quV(j) = log10(max(1.d-10,quV(j)))
         tlV(j) = log10(max(1.d-10,tlV(j)))
         tuV(j) = log10(max(1.d-10,tuV(j)))
400    continue
       return

c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c  finished reading the input file
c    return with -99 observations to indicate end-of-file
c
99    continue
       nV  = -99
      return
      end
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c  function to check if a string y contains string x
c    -- used to check if particular remark code is present
c
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
c    development history
c
c    timothy a. cohn        21 may 2007
c
c****|===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
c
      logical function ifany(x,y)
      character*(*) x,y

        ifany = .FALSE.
      do 10 i=1,len(y)-len(x)+1
        if(x .eq. y(i:i+len(x)-1)) ifany = .TRUE.
10    continue
      return
      end
      
