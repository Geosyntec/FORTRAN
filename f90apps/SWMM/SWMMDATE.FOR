      SUBROUTINE SWMMDATE(MONTH,DAY,YEAR,HOUR,MINUTE,SECOND,MILLISEC)
C     GETS CURRENT DATE AND TIME
C     THIS WILL NEED TO BE CHANGED FOR SPECIFIC COMPILERS.
C
C     YEAR IS NOW FOUR DIGIT TO ELIMINATE MILLENNIUM PROBLEM.
C
C     Charles I. Moore  Camp Dresser & McKEE Annandale Va.
C
C   COMMENT OUT UNUSED CODE BELOW
C
c================================================================
C
C     THIS USES LAHEY f77l-EM32 DATE AND TIME FUNCTIONS
C
C     INTEGER MONTH,DAY,YEAR,HOUR,MINUTE,SECOND,MILLISEC
C     CHARACTER*11 SYSDAT, SYSTIM
C     Lahey date format: SYSDAT(MM/DD/YY)
C     Lahey time format: SYSTIM(HH:MM:SS:HH)
C     CALL DATE(SYSDAT)
C     CALL TIME(SYSTIM)
C   4 FORMAT(I2)
C     READ(SYSDAT(1:2),4) MONTH
C     READ(SYSDAT(4:5),4) DAY
C     READ(SYSDAT(7:8),4) YEAR
C     THIS NEXT STATEMENT ASSUMES THIS IS 1900
C     DON'T KNOW WHAT WILL HAPPEN IN 2000
C     YEAR  = YEAR + 1900
C     READ(SYSTIM(1:2),4) HOUR
C     READ(SYSTIM(4:5),4) MINUTE
C     READ(SYSTIM(7:8),4) SECOND
C     READ(SYSTIM(10:11),4) MILLISEC
C     MILLISEC = MILLISEC * 10.0
C     RETURN
C     END
C
C
C     THIS NEXT SET OF CODE WORKS FOR DIGITIAL VISUAL FORTRAN
C     C. MOORE
      INTEGER DATE_TIME (8)
      INTEGER MONTH,DAY,YEAR,HOUR,MINUTE,SECOND,MILLISEC
      CHARACTER (LEN=12) REAL_CLOCK(3)
      CALL DATE_AND_TIME (REAL_CLOCK(1),REAL_CLOCK(2),
     +REAL_CLOCK(3),DATE_TIME)
      MONTH    = DATE_TIME(2)
      DAY      = DATE_TIME(3)
      YEAR     = DATE_TIME(1)
      HOUR     = DATE_TIME(5)
      MINUTE   = DATE_TIME(6)
      SECOND   = DATE_TIME(7)
      MILLISEC = DATE_TIME(8)
      RETURN
      END

