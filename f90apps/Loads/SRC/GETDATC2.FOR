        SUBROUTINE GETDAT_C(MESSFG,IUNIT,QNAME,QUNIT,PNAME,PUNIT,
     I                      CMUNIT,IPCODE,RBEGIN,REND,NREG,IREG,CMNAME,
     O                      ERRCOD,MESCOD)
C
C*** REVISION 94.07 7/13/94
C===================================================================
C
C       READ IN CALIBRATION DATA
C       DEFINE MODEL
C       PREPARE REGRESSION MATRICES
C
C       AUTHOR.........TIM COHN
C       DATE...........APRIL 22, 1992 (TAC)
C       MODIFIED.......JULY 28, 1992 (TAC & WGB)
C       MODIFIED.......AUGUST 6, 1992 (TAC & WGB)
C       MODIFIED.......NOVEMBER 23, 1992 (TAC)
C       MODIFIED.......JULY 13, 1994 (TAC)
C
C===================================================================

        INCLUDE 'estinclu.inc'

C===================================================================
C
        INTEGER        QUNIT,IUNIT,PUNIT,CMUNIT,IPCODE,NREG,IREG(200)
        INTEGER        ERRCOD,MESSFG,MESCOD
        REAL           RBEGIN,REND
        CHARACTER*100  QNAME,PNAME,CMNAME
C
        ERRCOD = 0
C
C       OPEN DAILY VALUES DATA FILE
C
        CALL GETDAT_E(MESSFG,QNAME,QUNIT,ISTAT_E,NDV,IY_E,IM_E,
     &                ID_E,FLOW_E,MESCOD)
        INDEX  =  NDAYS2( ID_E(1),IM_E(1),IY_E(1) )

C===================================================================
C
C       OPEN WATER QUALITY DATA FILE
C
        CALL READD (PNAME,PUNIT,CMUNIT,IPCODE,NRECS,IHEAD_C,NSIZE,
     1              DATA_C,THRESH_C,FLOW_C,MESSFG,CMNAME,
     O              ERRCOD,MESCOD)
        IF (ERRCOD.EQ.0) THEN
          WRITE(NAME(0),'(''P'',I5.5)') IPCODE

          IF(ISTAT_E .NE. ISTAT_C) THEN
C           estimation and calibration data sets differ
            ERRCOD = 1
          ENDIF
        END IF

C===================================================================
C
        IF (ERRCOD.EQ.0) THEN
C         CHOOSE WHICH FLOW VARIABLE TO USE IN THE REGRESSION
C         1.   UNIT VALUES ACCOMPANYING QW RECORDS
C         2.   DAILY VALUES
C
C         N.B.  THIS FEATURE DISABLED IN VERSION 92.11--TAC
C
          DO 25 I=1,NRECS
            I2         =  NDAYS2(ID_C(I),IM_C(I),IY_C(I)) - INDEX + 1
            IF(I2 .GT. 0 .AND. FLOW_E(I2) .GT. 0.D0) THEN
              FLOW_C(I)  =  FLOW_E(I2)
            ELSE
              MESCOD = 3
              IF (MESSFG .EQ. 1) THEN
                WRITE(*,'(A,4I6)') ' DV FLOW UNAVAILABLE FOR POINT',
     1                              I,IM_C(I),ID_C(I),IY_C(I)
              END IF
              FLOW_C(I)  =  -99.D0
            ENDIF
   25     CONTINUE
          WRITE(IUNIT,
     1      '(/,'' CALIBRATION FLOWS FROM DV FLOW FILE'',/)')
C
          BEGIN_C = RBEGIN
          END_C   = REND
C
C===================================================================
C
C         THE MODEL
C
C===================================================================
C
C         SET REGRESSOR VARIABLES
C
          NP = NREG
          DO 30 I=1,NP
            IVAR(I) = IREG(I)
            NAME(I) = VNAME(IREG(I))
   30     CONTINUE
C
          IF (MESSFG.EQ.1) THEN
            WRITE(*,*) ' ** SETTING UP MATRICES **'
          END IF
C===================================================================
C
C         ASSEMBLE THE DATA SET
C         12/17/92  CHANGE FROM 0.0 TO 1.D-10 FOR REJECTION OF FLOW
C
          I2  =  0
          DO 40 I=1,NRECS
            DT  = DTIMEC(IY_C(I),IM_C(I),ID_C(I),IT_C(I))
            IF(DATA_C(I) .GT. 0.D0 .AND. FLOW_C(I) .GT. 1.D-10
     1        .AND. DT .GT. BEGIN_C .AND. DT .LT. END_C)  THEN
              I2   =  I2+1
              D_TIME_C(I2)  =  DT
              IY_C(I2)      =  IY_C(I)
              IM_C(I2)      =  IM_C(I)
              ID_C(I2)      =  ID_C(I)
              IT_C(I2)      =  IT_C(I)
              FLOW_C(I2)    =  FLOW_C(I)
              LOGQ_C(I2)    =  LOG(FLOW_C(I2))
              DATA_C(I2)    =  DATA_C(I)
              THRESH_C(I2)  =  THRESH_C(I)
            ENDIF
   40     CONTINUE
          NC     = I2

          WRITE(IUNIT,'('' USER SPECIFIED PERIOD: '',
     1           F7.2,''-'',F7.2,/)') BEGIN_C,END_C

          WRITE(IUNIT,'('' DATE OF FIRST OBS. USED IN CALIBRATION: '',
     1           I2.2,''/'',i2.2,''/'',I4)') IM_C(1),ID_C(1),IY_C(1)
          WRITE(IUNIT,'('' DATE OF LAST OBS. USED IN CALIBRATION:  '',
     1           I2.2,''/'',i2.2,''/'',I4)') IM_C(NC),ID_C(NC),IY_C(NC)
C
          WRITE(IUNIT,'('' STATION NUMBER:'',I9.8)') ISTAT_C
          WRITE(IUNIT,1002) NAME(0),NP
 1002     FORMAT(/,' REGRESSION OF ',A20,/,' ON ',I1,' REGRESSORS')

          CALL THRESH_REPAIR(NC,DATA_C(1),THRESH_C(1))

          LQCENT = CENT_MOM(LOGQ_C,NC,1)+
     1             CENT_MOM(LOGQ_C,NC,3)/(2.0*CENT_MOM(LOGQ_C,NC,2))
          DTCENT = CENT_MOM(D_TIME_C,NC,1)+
     1             CENT_MOM(D_TIME_C,NC,3)/(2.0*CENT_MOM(D_TIME_C,NC,2))

C===================================================================
C
C         BUILD REGRESSOR VARIABLE MATRIX
C         N.B.  CREATE RESPONSES AND THRESHOLDS FOR C AND L DATA
C
          NCENS         =      0
          DO 20 I=1,NC
            IF (ERRCOD.EQ.0) THEN
              C_Y_C(I)      =      LOG(DATA_C(I))
              C_YT_C(I)     =      LOG(THRESH_C(I))
              Y_C(I)        =   LOG(2.447*FLOW_C(I)*DATA_C(I))
              YT_C(I)       =      LOG(2.447*FLOW_C(I)*THRESH_C(I))
              IF(YT_C(I) .GT. Y_C(I)) NCENS      =      NCENS + 1
c====*===|====-====|====-====|====-====|====-====|====-====|====-====|==////////
              CALL CONVERT(FLOW_C(I),LQCENT,D_TIME_C(I),DTCENT,XVAR,
     O                     ERRCOD)
            END IF
            IF (ERRCOD.EQ.0) THEN
              DO 50 J=1,NP
                X_C(I,J)  =  XVAR(IVAR(J))
   50         CONTINUE
            END IF
   20     CONTINUE

          IF (ERRCOD.EQ.0) THEN
            DO 60 J=1,NP
              IF(IVAR(J) .EQ. 2 .OR. IVAR(J) .EQ. 3) THEN
                CENTER(J)   =  LQCENT
              ELSE IF(IVAR(J) .EQ. 5 .OR. IVAR(J) .EQ. 6) THEN
                CENTER(J)   =  DTCENT
              ELSE
                CENTER(J)   =  0.D0
              ENDIF
   60       CONTINUE
          END IF
        END IF

        RETURN
        END
C
C
C
        SUBROUTINE CONVERT(FLOW,LQCENT,TIME,DTCENT,X,
     O                     ERRCOD)
C===================================================================
C
C       SUBROUTINE TO CREATE EXPLANATORY VARIABLES
C
C       FLOW        R*8    FLOW IN CFS (OR OTHER UNIT)
C       LQCENT      R*8    CENTERING VALUE FOR FLOW
C       TIME        R*8    DECIMAL TIME (E.G. 1978.334)
C       DTCENT      R*8    CENTERING VALUE FOR TIME
C       X(1)        R*8    CONSTANT (ALWAYS EQUAL TO 1.0)
C        (2)        R*8    LOG OF FLOW
C        (3)        R*8    (LOG OF FLOW-LQCENT)**2
C        (4)        R*8    SQRT OF FLOW
C        (5)        R*8    DECIMAL TIME
C        (6)        R*8    (DECIMAL TIME-DTCENT)**2
C        (7)        R*8    SIN(TIME)
C        (8)        R*8    COS(TIME)
C
C        AUTHOR       TIM COHN
C        DATE         MAY 7, 1992
C
C===================================================================

        IMPLICIT DOUBLE PRECISION (A-H,L-M,O-Z)
        DIMENSION X(200)
        INTEGER  ERRCOD

        CALL DSET(100,0.D0,X,1)
        IYEAR  =  TIME
        IMONTH =  12.D0*(TIME-IYEAR) + 1.D0
        IF(FLOW .LE. 0.D0) THEN
C         missing or negative flow value
          ERRCOD = 3
        ELSE
          X(1) =  1.D0
          X(2) =  LOG(FLOW)-LQCENT
          X(3) =  X(2)**2
          X(4) =  SQRT(FLOW)
          X(5) =  TIME-DTCENT
          X(6) =  X(5)**2
          ARG   = 2.D0*3.14159265*(TIME-IYEAR)
          X(7) =  SIN(ARG)
          X(8) =  COS(ARG)
          X(9) =  SIN(2.*ARG)
          X(10) =  COS(2.*ARG)
          X(11) =  SIN(3.*ARG)
          X(12) =  COS(3.*ARG)
          X(IMONTH+12)      =      1.D0
          KYEAR         =      IYEAR-1900
          IF(KYEAR .LE. 150 .AND. KYEAR .GT. 0) THEN
            X(KYEAR+24)      =      1.D0
          ELSE
C           bad year given
            ERRCOD = 4
          ENDIF
        END IF

        RETURN
        END
C
C
C
        BLOCK DATA
C===================================================================
C
C       INITIALIZATION OF VARIABLE NAMES
C
C       AUTHOR.........TIM COHN
C       DATE...........NOVEMBER 16, 1988
C
C===================================================================

        INCLUDE 'estinclu.inc'

        DATA VNAME/
     1    'CONSTANT', 'LOG-FLOW','LOG-FLOW SQUARED','SQRT FLOW',
     2    'DEC_TIME', 'DEC_TIME SQUARED','SIN(2*PI*T)','COS(2*PI*T)',
     *    'SIN(4*PI*T)','COS(4*PI*T)','SIN(6*PI*T)','COS(6*PI*T)',
     *    'I-JAN', 'I-FEB', 'I-MAR', 'I-APR', 'I-MAY', 'I-JUN',
     *    'I-JUL', 'I-AUG', 'I-SEP', 'I-OCT', 'I-NOV', 'I-DEC',
     *    'I-1901', 'I-1902', 'I-1903', 'I-1904', 'I-1905',
     *    'I-1906', 'I-1907', 'I-1908', 'I-1909', 'I-1910',
     *    'I-1911', 'I-1912', 'I-1913', 'I-1914', 'I-1915',
     *    'I-1916', 'I-1917', 'I-1918', 'I-1919', 'I-1920',
     *    'I-1921', 'I-1922', 'I-1923', 'I-1924', 'I-1925',
     *    'I-1926', 'I-1927', 'I-1928', 'I-1929', 'I-1930',
     *    'I-1931', 'I-1932', 'I-1933', 'I-1934', 'I-1935',
     *    'I-1936', 'I-1937', 'I-1938', 'I-1939', 'I-2040',
     *    'I-1941', 'I-1942', 'I-1943', 'I-1944', 'I-1945',
     *    'I-1946', 'I-1947', 'I-1948', 'I-1949', 'I-1950',
     *    'I-1951', 'I-1952', 'I-1953', 'I-1954', 'I-1955',
     *    'I-1956', 'I-1957', 'I-1958', 'I-1959', 'I-1960',
     *    'I-1961', 'I-1962', 'I-1963', 'I-1964', 'I-1965',
     *    'I-1966', 'I-1967', 'I-1968', 'I-1969', 'I-1970',
     *    'I-1971', 'I-1972', 'I-1973', 'I-1974', 'I-1975',
     *    'I-1976', 'I-1977', 'I-1978', 'I-1979', 'I-1980',
     *    'I-1981', 'I-1982', 'I-1983', 'I-1984', 'I-1985',
     *    'I-1986', 'I-1987', 'I-1988', 'I-1989', 'I-1990',
     *    'I-1991', 'I-1992', 'I-1993', 'I-1994', 'I-1995',
     *    'I-1996', 'I-1997', 'I-1998', 'I-1999', 'I-2000',
     *    'I-2001', 'I-2002', 'I-2003', 'I-2004', 'I-2005',
     *    'I-2006', 'I-2007', 'I-2008', 'I-2009', 'I-2010',
     *    'I-2011', 'I-2012', 'I-2013', 'I-2014', 'I-2015',
     *    'I-2016', 'I-2017', 'I-2018', 'I-2019', 'I-2020',
     *    'I-2021', 'I-2022', 'I-2023', 'I-2024', 'I-2025',
     *    'I-2026', 'I-2027', 'I-2028', 'I-2029', 'I-2030',
     *    'I-2031', 'I-2032', 'I-2033', 'I-2034', 'I-2035',
     *    'I-2036', 'I-2037', 'I-2038', 'I-2039', 'I-2040',
     *    'I-2041', 'I-2042', 'I-2043', 'I-2044', 'I-2045',
     *    'I-2046', 'I-2047', 'I-2048', 'I-2049', 'I-2050',
     *    26*'NOTHING'/

        DATA NPVARS/174/,IEASY/0/

        END
C
C
C
        SUBROUTINE THRESH_REPAIR(NC,Y,YT)
C===================================================================
C
C       INVENT THRESHOLDS FOR THE DATA
C
C       AUTHOR.........TIM COHN
C       DATE...........MAY 4, 1992
C
C===================================================================

        IMPLICIT DOUBLE PRECISION (A-H,O-Z)
        DIMENSION Y(*),YT(*)
C
        DO 10 I=1,NC
          IF(YT(I) .GT. 0.D0) THEN
            YTEMP = YT(I)
            GOTO 11
          ENDIF
10      CONTINUE
          YTEMP  =      1.D-25
11      CONTINUE

        DO 20 I=1,NC
          IF(YT(I) .GT. 0.D0) THEN
            YTEMP  =      YT(I)
          ELSE
            YTEMP  =      MIN(Y(I),YTEMP)
            YT(I)  =      YTEMP
          ENDIF
20      CONTINUE
C
        RETURN
        END
