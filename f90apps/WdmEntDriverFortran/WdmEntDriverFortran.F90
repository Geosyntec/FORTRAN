      Program WdmEntDriverFortran
      
!DEC$ ATTRIBUTES DLLIMPORT:: F90_WDMOPN, F90_WDMCLO, F90_WDBOPN, F90_WDCKDT, F90_WDDSNX, F90_WTFNDT, F90_WDTPUT
!DEC$ ATTRIBUTES DLLIMPORT:: F90_WDBSGI, F90_WDBSAI, F90_WDBSGR, F90_WDBSAR, F90_WDBSGC, F90_WDBSAC, F90_WDTGET
! F90_WDFLCL

!     local variables
      Integer*4    :: WDMSFL, RETCOD, DSN, DSNS(2), DSTYPE, I, OUTFL, IVAL(80)
      Integer*4    :: GPFLG, DSFRC, SDAT(6), EDAT(6), OVFG, SAIND, SALEN, SAVAL
      Integer*4    :: DATES(6), DELT, NVALS, TRAN, QUAL, TUNIT, RECSIZE
      Real*4       :: RVAL(10), RSAVAL
      Character*64 :: WDNAME, WDMNAMES(3)
      Character*80 :: CVAL

!     functions
      Logical*4    :: Find_Test_Folder
      Integer*4    :: F90_WDMOPN, F90_WDBOPN
      Integer*4    :: F90_WDMCLO, F90_WDCKDT
      !Integer*4    :: F90_WDFLCL

      Write(*,*) 'Start WdmEntDriverFortran'
      
      OUTFL = 8
      IF (Find_Test_Folder(OUTFL) .EQ. .TRUE.) THEN
        WDMNAMES(1) = 'test.wdm'
        WDMNAMES(2) = 'missing.wdm'
        WDMNAMES(3) = 'corrupt.wdm'
  
        DO I = 1, 1 !just testing with actual wdm
          WDNAME = WDMNAMES(I)
          Write(OUTFL,*) 'Testing ' // WDNAME
          WDMSFL = 40
          RETCOD = F90_WDMOPN(WDMSFL,WDNAME)
          Write(OUTFL,*) '  F90_WDMOPN Return Code ', RETCOD, ' Opening ', Trim(WDNAME)
          IF (RETCOD .GE. 0) THEN
            RETCOD = F90_WDMCLO(WDMSFL)
            Write(OUTFL,*) '  F90_WDMCLO Return Code ', RETCOD, ' Closing ',WDMSFL
          END IF 
        
          WDMSFL = F90_WDBOPN(0,WDNAME)
          IF (WDMSFL .LE. 0) THEN
            Write(OUTFL,*) '  F90_WDBOPN Return Code ', WDMSFL, ' Opening ', Trim(WDNAME)
          ELSE
            Write(OUTFL,*) '  F90_WDBOPN Return Code ', WDMSFL, ' Opening ', Trim(WDNAME)

            DSN = 39
            DSTYPE = F90_WDCKDT(WDMSFL, DSN)
            Write(OUTFL,*) '  F90_WDCKDT: DSN, TYPE: ', DSN, DSTYPE
            
            DSN = DSN + 1
            CALL F90_WDDSNX(WDMSFL, DSN) 
            Write(OUTFL,*) '  F90_WDDSNX: DSN: ', DSN
                    
            GPFLG = 1
            CALL F90_WTFNDT(WDMSFL, DSN, GPFLG, DSFRC, SDAT, EDAT, RETCOD)
            Write(OUTFL,*) '  F90_WTFNDT: DSN, SDAT, EDAT: ', DSN, SDAT(1), EDAT(1)
                    
            DELT = 1
            NVALS = 10
            TRAN = 0
            QUAL = 31
            TUNIT = 4
            DATES(1) = 1976 
            DATES(2) = 4 
            DATES(3) = 5 
            DATES(4) = 24 
            DATES(5) = 0 
            DATES(6) = 0 
            CALL F90_WDTGET(WDMSFL, DSN, DELT, DATES, NVALS, TRAN, QUAL, TUNIT, RVAL, RETCOD)
            Write(OUTFL,*) '  F90_WDTGET: DSN, RETCOD, RVAL: ', DSN, RETCOD, RVAL
            
            OVFG = 1
            RVAL(1) = 1.0
            RVAL(2) = 2.0
            RVAL(3) = 3.0
            QUAL = 1
            CALL F90_WDTPUT(WDMSFL, DSN, DELT, DATES, NVALS, OVFG, QUAL, TUNIT, RVAL, RETCOD)
            Write(OUTFL,*) '  F90_WDTPUT: DSN, RETCOD: ', DSN, RETCOD
            
            ! work with attributes
            ! have to open message wdm first
            MESSFL = F90_WDBOPN(1,"e:\respec\FORTRAN\lib3.0\hspfmsg.wdm")
            
            SAIND = 34   !tgroup
            SALEN = 1
            CALL F90_WDBSGI(WDMSFL, DSN, SAIND, SALEN, SAVAL, RETCOD)
            Write(OUTFL,*) '  F90_WDBSGI: SAVAL, RETCOD: ', SAVAL, RETCOD
            
            CALL F90_WDBSAI(WDMSFL, DSN, MESSFL, SAIND, SALEN, SAVAL, RETCOD)
            Write(OUTFL,*) '  F90_WDBSAI: SAVAL, RETCOD: ', SAVAL, RETCOD
            
            SAIND = 7   !elev
            SALEN = 1
            CALL F90_WDBSGR(WDMSFL, DSN, SAIND, SALEN, RSAVAL, RETCOD)
            Write(OUTFL,*) '  F90_WDBSGR: SAVAL, RETCOD: ', RSAVAL, RETCOD
            
            RSAVAL = 111.2
            CALL F90_WDBSAR(WDMSFL, DSN, MESSFL, SAIND, SALEN, RSAVAL, RETCOD)
            Write(OUTFL,*) '  F90_WDBSAR: SAVAL, RETCOD: ', RSAVAL, RETCOD  
            
            SAIND = 45  !stanam
            SALEN = 48
            CALL F90_WDBSGC (WDMSFL,DSN,SAIND,SALEN,IVAL)
            ! need to turn these integer values back into a character string
            Write(OUTFL,*) '  F90_WDBSGC: IVAL, RETCOD: ', IVAL

            CALL F90_WDBSGCX (WDMSFL,DSN,SAIND,SALEN,CVAL)
            Write(OUTFL,*) '  F90_WDBSGCX: CVAL, RETCOD: ', CVAL
            
            CVAL = 'Test Stanam'
            CALL F90_WDBSAC (WDMSFL,DSN,MESSFL,SAIND,SALEN,RETCOD,CVAL)
            Write(OUTFL,*) '  F90_WDBSAC: CVAL, RETCOD: ', CVAL, RETCOD  
                        
            CALL F90_WDBSGCX (WDMSFL,DSN,SAIND,SALEN,CVAL)
            Write(OUTFL,*) '  F90_WDBSGCX: CVAL, RETCOD: ', CVAL, RETCOD

            !leave open for multiple wdm test
            !RETCOD = F90_WDFLCL(WDMSFL)
            !Write(OUTFL,*) '  F90_WDFLCL Return Code ', RETCOD
          END IF
        END DO
        
        !TBW specific tests
        DSNS = (/ 9022, 231 /)
        WDNAME = 'divrsion.wdm'
        Write(OUTFL,*) 'Testing ' // WDNAME
        WDMSFL = F90_WDBOPN(0,WDNAME)
        IF (WDMSFL .LE. 0) THEN
          Write(OUTFL,*) '  F90_WDBOPN Return Code ', WDMSFL, ' Opening ', Trim(WDNAME)
        ELSE
          Write(OUTFL,*) '  F90_WDBOPN Return Code ', WDMSFL, ' Opening ', Trim(WDNAME)
          DO I = 1, 2
            DSN = DSNS(I)
            DSTYPE = F90_WDCKDT(WDMSFL, DSN)
            Write(OUTFL,*) '  F90_WDCKDT: DSN, TYPE: ', DSN, DSTYPE
            DELT = 1
            NVALS = 10
            TRAN = 0
            QUAL = 0
            TUNIT = 4
            DATES(1) = 1988
            DATES(2) = 1
            DATES(3) = 1 
            DATES(4) = 0 
            DATES(5) = 0 
            DATES(6) = 0 
            CALL F90_WDTGET(WDMSFL, DSN, DELT, DATES, NVALS, TRAN, QUAL, TUNIT, RVAL, RETCOD)
            Write(OUTFL,*) '  F90_WDTGET1: DSN, RETCOD, RVAL: ', DSN, RETCOD, RVAL
            RSAVAL = RVAL(1)
            
            OVFG = 1
            RVAL(1) = -2.97520661
            CALL F90_WDTPUT(WDMSFL, DSN, DELT, DATES, NVALS, OVFG, QUAL, TUNIT, RVAL, RETCOD)
            Write(OUTFL,*) '  F90_WDTPUT1: DSN, RETCOD: ', DSN, RETCOD

            CALL F90_WDTGET(WDMSFL, DSN, DELT, DATES, NVALS, TRAN, QUAL, TUNIT, RVAL, RETCOD)
            Write(OUTFL,*) '  F90_WDTGET2: DSN, RETCOD, RVAL: ', DSN, RETCOD, RVAL
            RVAL(1) = RSAVAL
            CALL F90_WDTPUT(WDMSFL, DSN, DELT, DATES, NVALS, OVFG, QUAL, TUNIT, RVAL, RETCOD)
            Write(OUTFL,*) '  F90_WDTPUT2: DSN, RETCOD: ', DSN, RETCOD
            CALL F90_WDTGET(WDMSFL, DSN, DELT, DATES, NVALS, TRAN, QUAL, TUNIT, RVAL, RETCOD)
            Write(OUTFL,*) '  F90_WDTGET3: DSN, RETCOD, RVAL: ', DSN, RETCOD, RVAL
          END DO
        END IF
        
      ELSE
        Write(*,*) 'Test Folder Not Found'
      END IF
      
      Write(*,*) 'End WdmEntDriverFortran'
      
      End Program
      
      Logical Function Find_Test_Folder(OUTFL)
      
      USE IFPORT

      Integer*4           :: OUTFL
      
      Integer*4           :: LEN
      Logical             :: RET
      Character($MAXPATH) :: DIR

      Find_Test_Folder = .FALSE.
      
      !  Get current directory
      LEN = GETDRIVEDIRQQ(DIR)
      IF (LEN .GT. 0) THEN  
          WRITE (*,*) 'Base directory is: ',DIR(1:LEN)
          DIR = DIR(1:LEN) // '\test'
          RET = CHANGEDIRQQ(DIR) 
          LEN = GETDRIVEDIRQQ(DIR)
          IF (LEN .GT. 0) THEN
            WRITE (*,*) 'Test directory is: ',DIR(1:LEN)
            
            ! need to get platform details for filename
            Open(Unit=OUTFL,Name='Results.out')    
            Find_Test_Folder = .TRUE.
          ELSE
            WRITE (*,*) 'Failed to set test directory'
          END IF
      ELSE  
          WRITE (*,*) 'Failed to get current directory'
      END IF      
      
      End Function