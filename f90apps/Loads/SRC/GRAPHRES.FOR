        SUBROUTINE GRAPHRES
     1  (IUNIT,NS,IMO,LOGQ,DTIME,YC,YTC,S,RES,PRED)
C*** REVISION 95.01 1/6/95
C=======================================================================
C
C       SUBROUTINE TO GRAPH THE RESIDUALS FROM A REGRESSION
C       AGAINST APPROPRIATE EXPLANATORY VARIABLES
C
C       DEFINITION OF VARIABLES
C
C         IUNIT     I*4     UNIT NUMBER FOR OUTPUT
C         NS        I*4     NUMBER OF OBSERVATIONS TO PLOT
C         IMO(NS)   I*8     COLUMN VECTOR OF MONTHS (1-12)
C         LOGQ(NS)  I*4     COLUMN VECTOR OF LOGARITHMS OF FLOWS
C         DTIME(NS) R*8     COLUMN VECOTR OF TIME
C         RES(NS)   R*8     COLUMN VECOTR OF RESIDUALS
C
C       AUTHOR........TIM COHN
C       DATE..........NOVEMBER 7, 1988
C       MODIFIED....MAY 10, 1992 (TAC)
C       MODIFIED....AUGUST 6, 1992 (TAC & WGB)
C       MODIFIED....JANUARY 6, 1995 (TAC)
C
C
C=======================================================================

        IMPLICIT DOUBLE PRECISION (A-H,O-Z)
        PARAMETER (NSIZE=5000)

        CHARACTER*80   TITLE,CAP1,CAP2

        double precision logq

        DIMENSION IMO(NS),LOGQ(NS),DTIME(NS),RES(NS),PRED(NS),
     1  YC(NS),YTC(NS)

        DIMENSION RANGE(4),NI(12),NCUM(12),PPROB(NSIZE),RES_SRT(NSIZE)
        DIMENSION DATA(NSIZE,2)

        dimension data_y(nsize,2)

        DATA RANGE/4*0.D0/,INC/1/

C=======================================================================
C
C       SET UP THE IMSL CALLS
C
        NPLOTS  =  1
        DO 5 I=1,NS
          DATA(I,1)   =      RES(I)
c         DATA(I,2)   =      (YTC(I)-PRED(I))/S
          data(i,2)     =      ytc(i) - pred(i)
          data_y(i,1)   =      res(i) + pred(i) - logq(i) - log(2.447)
          data_y(i,2)   =      ytc(i) - logq(i) - log(2.447)
c         IF(DATA(I,1) .LT. DATA(I,2)) THEN
          if(data_y(i,1) .lt. data_y(i,2)) then
            NPLOTS =      2
          ENDIF
5       CONTINUE

        CALL PAGE(-1,120)
        CALL PAGE(-2,58)

        CALL UMACH(2,IUNIT_O)
        CALL UMACH(-2,IUNIT)

        TITLE = 'BOXPLOTS OF RESIDUALS AGAINST MONTH'
        CALL BOXPIT(NS,RES,IMO,TITLE)

        DO 10 I=1,NS
          PPROB(I)  =  DNORIN(I/(NS+1.D0))
   10   CONTINUE

        CALL DSVRGN(NS,RES,RES_SRT)

        CORREL = CORR(NS,PPROB,RES_SRT)

        CAP1  = 'Z-SCORES'
        CAP2  = 'RESIDUALS'
        TITLE = 'PLOT OF RESIDUALS AGAINST THEIR Z-SCORES'
        CALL DPLOTP(NS,1,PPROB,RES_SRT,NSIZE,INC,RANGE,'*.3456789+',
     1              CAP1,CAP2,TITLE)

       WRITE(IUNIT,'(/,''   PPCC CORRELATION     = '',F8.5)') CORREL

        CAP1  = 'TIME'
        CAP2  = 'OBSERVED CONCENTRATIONS'
        TITLE = 'PLOT OF OBSERVED CONCENTRATIONS AGAINST TIME'
        CALL DPLOTP(NS,NPLOTS,DTIME,DATA_Y,NSIZE,INC,RANGE,'*.3456789+',
     1              CAP1,CAP2,TITLE)

        CAP1  = 'PREDICTED VALUES'
        CAP2  = 'RESIDUALS'
        TITLE = 'PLOT OF RESIDUALS AGAINST PREDICTED VALUES'
        CALL DPLOTP(NS,NPLOTS,PRED,DATA,NSIZE,INC,RANGE,'*.3456789+',
     1              CAP1,CAP2,TITLE)

        CAP1  = 'LOG OF FLOW'
        CAP2  = 'RESIDUALS'
        TITLE = 'PLOT OF RESIDUALS AGAINST FLOW'
        CALL DPLOTP(NS,NPLOTS,LOGQ,DATA,NSIZE,INC,RANGE,'*.3456789+',
     1              CAP1,CAP2,TITLE)

        CAP1  = 'TIME'
        CAP2  = 'RESIDUALS'
        TITLE = 'PLOT OF RESIDUALS AGAINST TIME'
        CALL DPLOTP(NS,NPLOTS,DTIME,DATA,NSIZE,INC,RANGE,'*.3456789+',
     1              CAP1,CAP2,TITLE)

        CALL UMACH(-2,IUNIT_O)

        RETURN
        END
