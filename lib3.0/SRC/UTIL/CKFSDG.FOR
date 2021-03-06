C
C
C
      SUBROUTINE   CKFSPC
     I                   (TLEN,TSTR,NAMLEN,NAMES,MXSTLN,FLNLEN,
     O                    OLEN,NFILES,STRMAT)
C
C     + + + PURPOSE + + +
C     Compare user-entered string for a file name with
C     any file specifications for the file field and
C     return all files which meet the criteria.
C
C     + + + DUMMY ARGUMENTS + + +
      INTEGER      TLEN,NAMLEN,MXSTLN,FLNLEN,OLEN,NFILES
      CHARACTER*1  STRMAT(MXSTLN)
      CHARACTER*78 TSTR
      CHARACTER*80 NAMES
C
C     + + + ARGUMENT DEFINITIONS + + +
C     TLEN   - length of user input string
C     TSTR   - user input string
C     NAMLEN - length of file name specifications
C     NAMES  - character string of file name specifications
C     MXSTLN - max length of string containing matching names
C     FLNLEN - available length for file names
C     OLEN   - output length of matching names string
C     NFILES - number of files matching criteria
C     STRMAT - character array containing matching names
C
C     + + + PARAMETERS + + +
      INTEGER      MAXFIL,    MAXLEN
      PARAMETER   (MAXFIL=200,MAXLEN=64)
C
C     + + + LOCAL VARIABLES + + +
      INTEGER      I,I64,J,IPOS,SMNFIL,UMNFIL,NFILE,ILEN,ISTAT,LLEN
      CHARACTER    UMFNMS(MAXLEN,MAXFIL),SMFNMS(MAXLEN,MAXFIL)
      CHARACTER*1  BLNK(1)
      CHARACTER*64 WRKDIR,IFNAME,SNAME
      CHARACTER*128 CMD
C
C     + + + FUNCTIONS + + +
      INTEGER      ZLNTXT, STRFND
C
C     + + + INTRINSICS + + +
      INTRINSIC    INDEX
C
C     + + + EXTERNALS + + +
      EXTERNAL     ZLNTXT, STRFND, QFDPRS, ZIPC, CVARAR, GETDIR, DIRLIS
C
C     + + + END SPECIFICATIONS + + +
C
      I64= 64
      BLNK(1)= ' '
C
C     init output arguments
      OLEN= 0
      NFILES= 0
      CALL ZIPC (MXSTLN,BLNK,STRMAT)
C
C     init number of files matching user string and spec string
      UMNFIL= 0
      SMNFIL= 0
C
      IF (TLEN.GT.0) THEN
C       user entered something in field, parse name/directory
        CALL QFDPRS (TSTR,
     O               WRKDIR,IFNAME)
        IF (WRKDIR .EQ. ' ') THEN
C         get the name of the current directory
          CALL GETDIR (I64,WRKDIR)
        END IF
        ILEN= ZLNTXT(IFNAME)
        LLEN= ZLNTXT(TSTR)
C       if actual string length (LLEN) is less than input string length (TLEN)
C       then the calling routine is looking for a unique match
        IF (LLEN.EQ.TLEN) THEN
C         not looking for a unique match, add wild card characters
          J= INDEX(IFNAME,'.')
          IF (J.GT.0) THEN
C           period separator in name, put * after it
            IFNAME(ILEN+1:ILEN+1)= '*'
          ELSE
C           add '*.*' to end
            IFNAME(ILEN+1:ILEN+3)= '*.*'
          END IF
        END IF
C       combine directory and input file name
        ILEN= ZLNTXT(WRKDIR)
        IF (WRKDIR(ILEN:ILEN).NE.'/') THEN
C         be sure to make a complete directory
          ILEN= ILEN+1
          WRKDIR(ILEN:ILEN)= '/'
        END IF
        CMD = WRKDIR(1:ILEN)//IFNAME
        ILEN= ZLNTXT(CMD)
C       get matches to user entered string
        UMNFIL= MAXFIL
        CALL DIRLIS (ILEN,CMD,MAXLEN,MAXFIL,
     O               UMFNMS,UMNFIL,ISTAT)
      ELSE
C       get the name of the current directory
        CALL GETDIR (I64,WRKDIR)
      END IF
C
      IF (NAMLEN.GT.0) THEN
C       get matches to message file specified string
        IPOS= 1
 20     CONTINUE
C         extract next name from string
          I= INDEX(NAMES(IPOS:NAMLEN),',')
          IF (I.GT.0) THEN
C           found comma separating names
            SNAME= NAMES(IPOS:I-1)
            IPOS = IPOS+ 1
          ELSE
C           no comma found, must be last name
            SNAME= NAMES(IPOS:NAMLEN)
            IPOS = NAMLEN
          END IF
C         combine directory and specified file name
          ILEN= ZLNTXT(WRKDIR)
          IF (WRKDIR(ILEN:ILEN).NE.'/') THEN
C           be sure to make a complete directory
            ILEN= ILEN+1
            WRKDIR(ILEN:ILEN)= '/'
          END IF
          CMD = WRKDIR(1:ILEN)//SNAME
          ILEN= ZLNTXT(CMD)
          CALL DIRLIS (ILEN,CMD,MAXLEN,MAXFIL-SMNFIL,
     O                 SMFNMS(1,SMNFIL+1),NFILE,ISTAT)
          SMNFIL= SMNFIL+ NFILE
        IF (IPOS.LT.NAMLEN) GO TO 20
      END IF
C
      IPOS= 1
      IF (UMNFIL.GT.0 .AND. SMNFIL.GT.0) THEN
C       files found matching both user entry and spec entry
        DO 100 I= 1,UMNFIL
C         loop through names matching user entry
          J= 0
 50       CONTINUE
C           loop through names matching spec entry
            J= J+ 1
            IF (STRFND(MAXLEN,UMFNMS(1,I),MAXLEN,SMFNMS(1,J)).GT.0) THEN
C             names match, put in output string
              IF (IPOS+MAXLEN-1.LE.MXSTLN) THEN
C               room in output string
                CALL CHRCHR (MAXLEN,UMFNMS(1,I),STRMAT(IPOS))
              END IF
              IPOS= IPOS+ FLNLEN
              NFILES= NFILES+ 1
              J= SMNFIL
            END IF
          IF (J.LT.SMNFIL) GO TO 50
 100    CONTINUE
      ELSE IF (TLEN.EQ.0 .AND. SMNFIL.GT.0) THEN
C       no user string, but found spec string matches
        DO 150 I= 1,SMNFIL
C         put names matching spec string into output array
          IF (IPOS+MAXLEN-1.LE.MXSTLN) THEN
C           room in output string
            CALL CHRCHR (MAXLEN,SMFNMS(1,I),STRMAT(IPOS))
          END IF
          IPOS= IPOS+ FLNLEN
 150    CONTINUE
        NFILES= SMNFIL
      ELSE IF (NAMLEN.EQ.0 .AND. UMNFIL.GT.0) THEN
C       no spec string, but found user string matches
        DO 200 I= 1,UMNFIL
C         put names matching user string into output array
          IF (IPOS+MAXLEN-1.LE.MXSTLN) THEN
C           room in output string
            CALL CHRCHR (MAXLEN,UMFNMS(1,I),STRMAT(IPOS))
          END IF
          IPOS= IPOS+ FLNLEN
 200    CONTINUE
        NFILES= UMNFIL
      END IF
      OLEN= IPOS- 1
C
      RETURN
      END
