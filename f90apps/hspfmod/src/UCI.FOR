      MODULE UCI

        IMPLICIT NONE

        PUBLIC :: UCI_NEW, UCI_INS, UCI_REP, UCI_GET, UCI_REA
        PUBLIC :: UCI_PRV, UCI_DEL, UCI_PRT, UCI_CLO
        PUBLIC :: UCI_PUT_DBG, UCI_GET_DBG, UCI_GET_MSG, UCI_GET_MES
        PUBLIC :: UCI_GET_END
        PUBLIC :: UCI_KEY_PUT, UCI_KEY_DEL, UCI_KEY_PRT, UCI_KEY_GET
        PRIVATE

        TYPE UREC
          CHARACTER (LEN=132)  :: TEXT           ! uci record
          INTEGER (KIND=2)     :: TYPE           ! type of uci record
          INTEGER (KIND=2)     :: RECID          ! record number
          INTEGER (KIND=2)     :: INDT           ! number of spaces line unindented
          TYPE (UREC), POINTER :: NEXT           ! pointer to next record
          TYPE (UREC), POINTER :: PREV           ! pointer to prev record
        END TYPE UREC

        TYPE UCIF
          TYPE (UREC), POINTER :: FIRST
        END TYPE UCIF
        TYPE (UCIF), SAVE      :: UCIFL          ! pointer to start of uci file

        TYPE UKWD
          CHARACTER (LEN=12)      :: TEXT        ! name of keyword
          INTEGER (KIND=2)        :: TYPE        ! type of keyword
          TYPE (UREC), POINTER    :: FIRST       ! first uci record with key
          TYPE (UREC), POINTER    :: LAST        ! uci record with assoc end key
          TYPE (UKWD), POINTER    :: MORE        ! pointer to more instances keyword
          TYPE (UKWD), POINTER    :: NEXT        ! pointer to next keyword
        END TYPE UKWD

        TYPE UKY
          TYPE (UKWD), POINTER    :: FIRST
        END TYPE UKY
        TYPE (UKY) :: UKEY

        CHARACTER (LEN=4)          :: UEND

        INTEGER          :: DBGLEV = 0            ! debug output level - start small
        INTEGER          :: UMSGFL = 0            ! message file
        INTEGER          :: UMESSU = 0            ! user output file
        LOGICAL          :: NXTFG, INITPOS

      CONTAINS

        SUBROUTINE UCI_NEW (MSGFL,MESSU,CEND)        ! set up new uci file
          INTEGER, OPTIONAL, INTENT(IN)      :: MSGFL
          INTEGER, OPTIONAL, INTENT(IN)      :: MESSU
          CHARACTER*4, OPTIONAL, INTENT(IN)  :: CEND

          IF (PRESENT(MSGFL)) UMSGFL = MSGFL
          IF (PRESENT(MESSU)) UMESSU = MESSU
          IF (PRESENT(CEND))  UEND   = CEND

          ALLOCATE (UCIFL%FIRST)                 ! space for first uci rec
          NULLIFY (UCIFL%FIRST%NEXT)             ! only one rec now
          UCIFL%FIRST%RECID = 1

          ALLOCATE (UKEY%FIRST)                  ! space for first key
          NULLIFY (UKEY%FIRST%NEXT)

          IF (DBGLEV > 5) THEN                   ! show its done
            CALL UCI_PRT_REC (UCIFL%FIRST,'NEW ')
          END IF

        END SUBROUTINE UCI_NEW


        SUBROUTINE UCI_PUT_DBG (LEV)              ! reset debug level
          INTEGER, INTENT(IN) :: LEV             ! new level

          IF (LEV > 3 .OR. DBGLEV > 3) THEN
            WRITE(*,*) 'UCI_DBG:change',DBGLEV,LEV
          END IF

          DBGLEV = LEV

        END SUBROUTINE UCI_PUT_DBG


        INTEGER FUNCTION UCI_GET_DBG() RESULT (LEV)  ! get debug level

          LEV = DBGLEV

        END FUNCTION UCI_GET_DBG


        INTEGER FUNCTION UCI_GET_MSG() RESULT (MSGFL)  ! get message file

          MSGFL = UMSGFL

        END FUNCTION UCI_GET_MSG


        INTEGER FUNCTION UCI_GET_MES() RESULT (MESSU)  ! get output file

          MESSU = UMESSU

        END FUNCTION UCI_GET_MES


        CHARACTER*4 FUNCTION UCI_GET_END() RESULT (CEND)  ! get end string

          CEND = UEND

        END FUNCTION UCI_GET_END


        SUBROUTINE UCI_REA (UCIFL)
          INTEGER, INTENT(IN)     :: UCIFL

          INTEGER                 :: CNT, TYPREC
          CHARACTER*132           :: TXT

          CNT= 2
          DO
            READ (UCIFL,'(A132)',END=100) TXT
            IF (LEN_TRIM(TXT) == 0) THEN                    ! blank
              TYPREC= -2
            ELSE IF (INDEX(TXT,'***') > 0) THEN            ! comment
C             see if this is a comment line
              TYPREC= -1
            ELSE                                           ! unknown
              TYPREC= 0
            END IF
C           save the record
            CALL UCI_INS (CNT, TXT, TYPREC)
            CNT= CNT+ 1
          END DO
100       CONTINUE

          IF (DBGLEV > 4) THEN
            CALL UCI_PRT
          END IF

        END SUBROUTINE UCI_REA


        TYPE (UREC) FUNCTION UCI_POS (NREC,FOUND) RESULT (POS_PTR)
           POINTER                               :: POS_PTR
           INTEGER,             INTENT (IN)      :: NREC
           LOGICAL, OPTIONAL,   INTENT (OUT)     :: FOUND

           IF (.NOT. ASSOCIATED(UCIFL%FIRST)) THEN
             WRITE(*,*) 'UCI_POS:FATAL:uci file not open!!!'
             STOP
           ELSE
             POS_PTR => UCIFL%FIRST

             DO
               IF (DBGLEV > 6) THEN
                 WRITE(*,*) 'UCI_POS:check',POS_PTR%RECID,NREC,
     $                                      ASSOCIATED(POS_PTR%NEXT)
               END IF
               IF (NREC == POS_PTR%RECID) THEN
                  IF (DBGLEV > 9) THEN
                    WRITE(*,*) 'UCI_POS:found',NREC
                  END IF
                  IF (.NOT. NXTFG) THEN  ! start type looking here
                    IF (PRESENT(FOUND)) FOUND = .TRUE.
                  ELSE IF (ASSOCIATED (POS_PTR%NEXT)) THEN ! start with next
                    IF (PRESENT(FOUND)) FOUND = .TRUE.
                    POS_PTR => POS_PTR%NEXT
                  ELSE  ! nothing follows
                    IF (PRESENT(FOUND)) FOUND = .FALSE.
                    IF (DBGLEV > 5) THEN
                      WRITE(*,*) 'UCI_POS:fail no next record '
                    END IF
                  END IF
                  EXIT
               ELSE IF (NREC < POS_PTR%RECID) THEN     ! past it
                  IF (PRESENT(FOUND)) FOUND = .FALSE.
                  POS_PTR => POS_PTR%PREV
                  IF (DBGLEV > 5) THEN
                    WRITE(*,*) 'UCI_POS:past ',POS_PTR%RECID
                    CALL UCI_PRT_REC (POS_PTR,'POS:')
                  END IF
                  IF (.NOT. ASSOCIATED(POS_PTR%PREV)) THEN
                    IF (DBGLEV > 6) THEN
                      WRITE(*,*) 'UCI_POS:start position'
                    END IF
                    INITPOS = .TRUE.
                  END IF
                  EXIT
               ELSE IF (ASSOCIATED (POS_PTR%NEXT)) THEN  ! keep looking
                  POS_PTR => POS_PTR%NEXT
                  INITPOS = .FALSE.
                  IF (DBGLEV > 9) THEN
                    WRITE(*,*) 'UCI_POS:next ',POS_PTR%RECID
                  END IF
               ELSE   ! never found record number desired
                  IF (DBGLEV > 5) THEN
                    WRITE(*,*) 'UCI_POS:fail record not found'
                  END IF
                  IF (PRESENT(FOUND)) FOUND = .FALSE.
                  EXIT
               END IF
             END DO
           END IF
        END FUNCTION UCI_POS


        SUBROUTINE UCI_INS (NREC, BUFF, TYP)
           INTEGER,          INTENT (IN) :: NREC
           INTEGER,          INTENT (IN) :: TYP
           CHARACTER(LEN=*), INTENT (IN) :: BUFF

           TYPE (UREC), POINTER          :: NXT_PTR, PRV_PTR

           IF (DBGLEV > 5) THEN
             WRITE(*,*) 'UCI_INS:entry',NREC,TYP
           END IF

           PRV_PTR => UCI_POS (NREC)

           IF (ASSOCIATED (PRV_PTR%NEXT)) THEN
             IF (DBGLEV > 6) THEN
               WRITE(*,*) 'UCI_INS:onext',POINTER(PRV_PTR%NEXT)
             END IF
             NXT_PTR => PRV_PTR%NEXT
           ELSE
             IF (DBGLEV > 6) THEN
               WRITE(*,*) 'UCI_INS:nonxt'
             END IF
           END IF

           ALLOCATE (PRV_PTR%NEXT)
           IF (DBGLEV > 6) THEN
             WRITE(*,*) 'UCI_INS:alloc',POINTER(NXT_PTR)
           END IF
           IF (INITPOS) THEN                      ! save initial record
             IF (DBGLEV > 6) THEN
               WRITE(*,*) 'UCI_INS:newfn',POINTER(PRV_PTR%NEXT)
             END IF
             UCIFL%FIRST%NEXT => PRV_PTR%NEXT
           END IF

           PRV_PTR%NEXT%TYPE= TYP
           PRV_PTR%NEXT%TEXT  = BUFF
           PRV_PTR%NEXT%RECID = NREC
           PRV_PTR%NEXT%PREV  => PRV_PTR
           PRV_PTR%NEXT       => PRV_PTR%NEXT
           IF (ASSOCIATED (NXT_PTR)) THEN
             PRV_PTR%NEXT%NEXT => NXT_PTR
             NXT_PTR%PREV      => PRV_PTR%NEXT
           END IF
           IF (DBGLEV > 5) THEN
              CALL UCI_PRT_REC (PRV_PTR,'INS>')
              CALL UCI_PRT_REC (PRV_PTR%NEXT,'INS:')
           END IF

        END SUBROUTINE UCI_INS


        SUBROUTINE UCI_REP (NUMBER, BUFF, TYP)

           INTEGER,          INTENT (IN)     :: NUMBER, TYP
           CHARACTER(LEN=*), INTENT (IN)     :: BUFF

           OPTIONAL          BUFF, TYP

           LOGICAL                     :: FOUND
           TYPE (UREC), POINTER        :: REP_PTR

           NXTFG  = .FALSE.

           REP_PTR => UCI_POS (NUMBER,FOUND)

           IF (DBGLEV > 5) THEN
             WRITE(*,*) 'UCI_REP:found',FOUND,NUMBER
           END IF

           IF (FOUND) THEN
              IF (PRESENT(BUFF)) THEN
                 REP_PTR%TEXT = BUFF
              END IF
              IF (PRESENT(TYP)) THEN
                 REP_PTR%TYPE = TYP
              END IF
           END IF
        END SUBROUTINE UCI_REP


        SUBROUTINE UCI_GET (LTYPRC, NUMBER, FOUND, UCIBUF)

           INTEGER,     INTENT (IN)    :: LTYPRC
           INTEGER,     INTENT (INOUT) :: NUMBER
           LOGICAL,     INTENT (OUT)   :: FOUND
           CHARACTER*80,INTENT (OUT)   :: UCIBUF

           TYPE (UREC),  POINTER        :: GET_PTR

           IF (NUMBER < 0) THEN
             NXTFG  = .FALSE.
             NUMBER = -NUMBER
           ELSE
             NXTFG = .TRUE.
           END IF

           GET_PTR => UCI_POS (NUMBER,FOUND)

           IF (DBGLEV > 5) THEN
             WRITE(*,*) 'UCI_GET:entry',NUMBER,GET_PTR%RECID,LTYPRC,
     $                                  NXTFG,FOUND,ASSOCIATED(GET_PTR)
           END IF

           IF (FOUND) THEN     ! look for type match
              DO
                 IF (LTYPRC <= GET_PTR%TYPE) THEN ! got it
                    FOUND  = .TRUE.
                    NUMBER = GET_PTR%RECID
                    IF (DBGLEV > 5) THEN
                      WRITE(*,*) 'UCI_GET:ctype',NUMBER,
     $                           LTYPRC,GET_PTR%TYPE
                    END IF
                    EXIT
                 ELSE IF (.NOT. ASSOCIATED (GET_PTR%NEXT)) THEN ! no match
                    FOUND = .FALSE.
                    IF (DBGLEV > 5) THEN
                      WRITE(*,*) 'UCI_GET:fail type not found '
                    END IF
                    EXIT
                 ELSE  ! keep looking
                    GET_PTR => GET_PTR%NEXT
                    IF (DBGLEV > 6) THEN
                      WRITE(*,*) 'UCI_GET:lookt',LTYPRC,GET_PTR%RECID
                    END IF
                 END IF
              END DO
           END IF

           IF (FOUND) THEN    !  match type
             IF (DBGLEV > 5) THEN
               WRITE(*,*) 'UCI_GET:found',NUMBER
             END IF
             UCIBUF = GET_PTR%TEXT(1:80)
           ELSE               !  none of this type
             UCIBUF = ' '
             NUMBER = 0
           END IF

        END SUBROUTINE UCI_GET


        SUBROUTINE UCI_PRV (NUMBER, FOUND)

           INTEGER,     INTENT (INOUT) :: NUMBER
           LOGICAL,     INTENT (OUT)   :: FOUND

           TYPE (UREC), POINTER :: PRV_PTR

           PRV_PTR => UCI_POS(NUMBER,FOUND)

           IF (DBGLEV > 5) THEN
              WRITE(*,*) 'UCI_PRV:posit',NUMBER,FOUND
           END IF

           IF (FOUND) THEN
              NUMBER = PRV_PTR%PREV%RECID
           END IF

        END SUBROUTINE UCI_PRV


        SUBROUTINE UCI_DEL (NUMBER, FOUND)
           INTEGER,     INTENT (IN)    :: NUMBER
           LOGICAL,     INTENT (OUT)   :: FOUND

           TYPE (UREC), POINTER        :: DEL_PTR

           NXTFG = .FALSE.

           IF (DBGLEV > 5) THEN
             WRITE(*,*) 'UCI_DEL:look ',NUMBER
           END IF

           DEL_PTR => UCI_POS (NUMBER,FOUND)

           IF (DBGLEV > 5) THEN
              WRITE(*,*) 'UCI_DEL:posit',NUMBER,FOUND
           END IF

           IF (FOUND) THEN
              IF (ASSOCIATED (DEL_PTR%NEXT)) THEN
                IF (DBGLEV > 6) THEN
                  WRITE(*,*)'UCI_DEL:fixpn',POINTER(DEL_PTR%NEXT)
                END IF
                DEL_PTR%PREV%NEXT => DEL_PTR%NEXT
              ELSE
                IF (DBGLEV > 6) THEN
                  WRITE(*,*) 'UCI_DEL:nulpn',
     $                        POINTER(DEL_PTR%PREV%NEXT)
                END IF
                NULLIFY (DEL_PTR%PREV%NEXT)
              END IF
              IF (ASSOCIATED (DEL_PTR%PREV)) THEN
                IF (ASSOCIATED (DEL_PTR%NEXT)) THEN
                  IF (DBGLEV > 6) THEN
                    WRITE(*,*)'UCI_DEL:fixnp',POINTER(DEL_PTR%PREV)
                  END IF
                  DEL_PTR%NEXT%PREV => DEL_PTR%PREV
                ELSE
                  IF (DBGLEV > 6) THEN
                    WRITE(*,*)'UCI_DEL:nulnx'
                  END IF
                END IF
              ELSE
                IF (DBGLEV > 6) THEN
                  WRITE(*,*) 'UCI_DEL:nulnp',
     $                        POINTER(DEL_PTR%NEXT%PREV)
                END IF
                NULLIFY (DEL_PTR%NEXT%PREV)
              END IF
              DEALLOCATE (DEL_PTR)
           END IF

        END SUBROUTINE UCI_DEL


        SUBROUTINE UCI_CLO

           INTEGER              :: NCUR, NNXT
           LOGICAL              :: FOUND
           TYPE(UREC), POINTER  :: CLO_PTR

           CLO_PTR => UCIFL%FIRST%NEXT

           IF (ASSOCIATED(CLO_PTR)) THEN

             CALL UCI_KEY_DEL(0)

             NCUR = CLO_PTR%RECID
             DO
                IF (ASSOCIATED(CLO_PTR%NEXT)) THEN
                   NNXT = CLO_PTR%NEXT%RECID
                   CLO_PTR => CLO_PTR%NEXT
                ELSE
                   NNXT = -1
                END IF

                CALL UCI_DEL (NCUR, FOUND)

                IF (.NOT. FOUND) THEN
                   WRITE(*,*) 'UCI_CLO:not found',NCUR
                END IF

                IF (NNXT >= 0) THEN
                   NCUR = NNXT
                ELSE
                   DEALLOCATE (UCIFL%FIRST)        ! all traces removed
                   EXIT
                END IF
             END DO
             IF (DBGLEV > 5) THEN
               WRITE(*,*) 'UCI_CLO:uci closed, space freed'
             END IF
           END IF

        END SUBROUTINE UCI_CLO


        SUBROUTINE UCI_PRT (FREC, LREC, FMT, PUN)
           INTEGER, OPTIONAL, INTENT(IN)   :: FREC
           INTEGER, OPTIONAL, INTENT(IN)   :: LREC
           INTEGER, OPTIONAL, INTENT(IN)   :: FMT
           INTEGER, OPTIONAL, INTENT(IN)   :: PUN

           TYPE(UREC), POINTER  :: PRT_PTR
           INTEGER              :: TREC

           IF (DBGLEV > 7) THEN
             WRITE(*,*) 'UCI_PRT:entry',PRESENT(FREC), PRESENT(LREC),
     $                                  PRESENT(FMT), PRESENT(PUN)
           END IF

           IF (PRESENT(FREC)) THEN              ! start where specified
             IF (FREC < 0) THEN
               TREC  = -FREC
               PRT_PTR => UCI_POS(TREC)
               PRT_PTR => PRT_PTR%PREV
             ELSE
               PRT_PTR => UCI_POS(FREC)
             END IF
             IF (DBGLEV > 6) THEN
               WRITE(*,*) 'UCI_PRT:start at',PRT_PTR%RECID,FREC
             END IF
           ELSE                                 ! start at beginning
             PRT_PTR => UCIFL%FIRST%NEXT
             IF (DBGLEV > 6) THEN
               WRITE(*,*) 'UCI_PRT:start at begin'
             END IF
           END IF

           DO
              IF (.NOT. ASSOCIATED (PRT_PTR)) THEN
                IF (DBGLEV > 6) THEN
                  WRITE(*,*) 'UCI_PRT:end of list'
                END IF
                EXIT
              END IF

              CALL UCI_PRT_REC(PRT_PTR,'PRNT',PUN=PUN,FMT=FMT)

              IF (PRESENT(LREC)) THEN
                IF (PRT_PTR%RECID == LREC) THEN
                  IF (DBGLEV > 6) THEN
                    WRITE(*,*) 'UCI_PRT:last rec printed'
                  END IF
                  EXIT
                END IF
              END IF

              PRT_PTR => PRT_PTR%NEXT

           END DO

        END SUBROUTINE UCI_PRT


        SUBROUTINE UCI_PRT_REC(N,BUFF,PUN,FMT)
           TYPE (UREC), INTENT (IN)          :: N
           CHARACTER (LEN = *), INTENT (IN)  :: BUFF
           INTEGER, OPTIONAL, INTENT (IN)    :: PUN
           INTEGER, OPTIONAL, INTENT (IN)    :: FMT

           INTEGER               :: I,J,K,L,M
           CHARACTER (LEN = 132) :: S,F

           S = N%TEXT

           IF (PRESENT(FMT)) THEN
             F= '(5X,A132)'
             IF (PRESENT(PUN)) THEN
               WRITE(PUN,FMT=F) S
             ELSE
               WRITE(*,FMT=F) S
             END IF
           ELSE
             F= '(A10,5(2X,A1,I8),2X,A1,1X,A132)'
             I= POINTER(N)
             IF (ASSOCIATED(N%NEXT)) THEN
               J= POINTER(N%NEXT)
             ELSE
               J= 0
             END IF
             IF (ASSOCIATED(N%PREV)) THEN
               K= POINTER(N%PREV)
             ELSE
               K= 0
             END IF
             L = N%RECID
             M = N%TYPE
             IF (PRESENT(PUN)) THEN
               WRITE(PUN,FMT=F)BUFF,'V',L,'C',I,'N',J,'P',K,'T',M,'S',S
             ELSE
               WRITE(*,FMT=F) BUFF,'V',L,'C',I,'N',J,'P',K,'T',M,'S',S
             END IF
           END IF

        END SUBROUTINE UCI_PRT_REC


        SUBROUTINE UCI_KEY_PUT (KNAME,KDIM,KTYP,SREC,EREC,RETCOD)
          CHARACTER*12, INTENT(IN)    :: KNAME
          INTEGER, INTENT(IN)         :: KDIM
          INTEGER, INTENT(IN)         :: KTYP
          INTEGER, INTENT(IN)         :: SREC
          INTEGER, INTENT(IN)         :: EREC
          INTEGER, INTENT(OUT)        :: RETCOD

          TYPE (UREC), POINTER        :: U_PTR
          TYPE (UKWD), POINTER        :: K_PTR
          INTEGER                     :: CNT,STRT,INDT
          CHARACTER*132               :: LTXT

          IF (DBGLEV > 6) THEN
            WRITE(*,*) 'UCI_KEY_PUT:',KNAME,KDIM,KTYP,SREC,EREC
          END IF
          IF (.NOT. ASSOCIATED(UKEY%FIRST)) THEN
            WRITE(*,*) 'UCI_KEY_PUT:FATAL:uci file not open!!!'
            STOP
          ELSE
            K_PTR => UKEY%FIRST
            IF (ASSOCIATED(K_PTR%NEXT)) THEN
              INITPOS = .FALSE.
            ELSE
              INITPOS = .TRUE.
            END IF
            OUTER: DO
              IF ((K_PTR%TEXT == KNAME .OR. KTYP == 100 ) .AND.
     $             K_PTR%TYPE == KTYP) THEN
                CNT = 1
                DO
                  IF (.NOT. ASSOCIATED(K_PTR%MORE)) THEN
                    IF (DBGLEV > 7) THEN
                      WRITE(*,*) 'UCI_KEY_PUT:end of more',CNT
                    END IF
                    IF (CNT < KDIM .OR. KTYP == 100) THEN
                      IF (DBGLEV > 7) THEN
                        WRITE(*,*) 'UCI_KEY_PUT:alloc',CNT,KNAME,KTYP
                      END IF
                      ALLOCATE (K_PTR%MORE)
                      K_PTR%MORE%TEXT  = KNAME
                      K_PTR%MORE%TYPE  = KTYP
                      NXTFG = .FALSE.
                      U_PTR => UCI_POS(SREC)
                      K_PTR%MORE%FIRST => U_PTR
                      U_PTR => UCI_POS(EREC)
                      K_PTR%MORE%LAST  => U_PTR
                      RETCOD = 0
                    ELSE
                      WRITE(*,*) 'UCI_KEY_PUT:too many',CNT,KDIM
                      RETCOD = 1                   ! too many
                    END IF
                    EXIT OUTER
                  ELSE
                    CNT = CNT+ 1
                    K_PTR => K_PTR%MORE
                  END IF
                END DO
              ELSE IF (.NOT. ASSOCIATED(K_PTR%NEXT)) THEN
                ALLOCATE (K_PTR%NEXT)
                IF (DBGLEV > 6) THEN
                  WRITE(*,*) 'UCI_KEY_PUT:alloc first ',KNAME,KTYP,
     $                        POINTER(K_PTR%NEXT)
                END IF
                IF (INITPOS) THEN
                  IF (DBGLEV > 6) THEN
                    WRITE(*,*) 'UCI_KEY_PUT:very first'
                  END IF
                  UKEY%FIRST%NEXT => K_PTR%NEXT
                END IF
                K_PTR%NEXT%TEXT  = KNAME
                K_PTR%NEXT%TYPE  = KTYP
                NXTFG = .FALSE.
                U_PTR => UCI_POS(SREC)
                K_PTR%NEXT%FIRST => U_PTR
                U_PTR => UCI_POS(EREC)
                K_PTR%NEXT%LAST  => U_PTR
                RETCOD = 0
                EXIT
              ELSE
                K_PTR => K_PTR%NEXT
              END IF
            END DO OUTER
          END IF

          IF (KNAME == 'SPEC-ACTIONS') THEN
            WRITE(99,*) 'UCI_KEY_PUT:unindent spec acts',SREC,EREC
            U_PTR => UCI_POS(SREC)
            DO
              IF (U_PTR%TYPE >= 0) THEN
                LTXT = U_PTR%TEXT
                STRT = 1
                DO
                  IF (LTXT(STRT:STRT) == ' ') THEN
                    STRT = STRT+ 1
                  ELSE
                    EXIT
                  END IF
                END DO
                IF (STRT > 3) THEN                 ! move to third character
                  U_PTR%TEXT = ' '
                  U_PTR%TEXT = LTXT(STRT-2:132)
                  INDT= STRT - 3
                  IF (INDT > 52) THEN              ! not more than max
                    INDT = 52
                  END IF
                  U_PTR%INDT= INDT
                END IF
              END IF
              IF (ASSOCIATED(U_PTR%NEXT)) THEN
                U_PTR => U_PTR%NEXT
                IF (U_PTR%RECID == EREC) THEN
                  WRITE(99,*) 'UCI_KEY_PUT:done spec acts'
                  EXIT
                END IF
              ELSE
                WRITE(99,*) 'UCI_KEY_PUT:out of recs'
                EXIT
              END IF
            END DO
          END IF
        END SUBROUTINE UCI_KEY_PUT


        SUBROUTINE   UCI_KEY_GET (KTYP,KRPT,TEXT,SREC,EREC)
          INTEGER, INTENT(IN)                 :: KTYP
          INTEGER, INTENT(IN)                 :: KRPT
          CHARACTER*12, OPTIONAL, INTENT(OUT) :: TEXT
          INTEGER, OPTIONAL, INTENT(OUT)      :: SREC
          INTEGER, OPTIONAL, INTENT(OUT)      :: EREC

          TYPE (UKWD), POINTER        :: K_PTR
          TYPE (UREC), POINTER        :: F_PTR, L_PTR
          INTEGER                     :: CNT

          IF (.NOT. ASSOCIATED(UKEY%FIRST)) THEN
            WRITE(*,*) 'UCI_KEY_GET:FATAL:uci file not open!!!'
            STOP
          ELSE
            IF (PRESENT(TEXT)) TEXT= ' '
            IF (PRESENT(SREC)) SREC= 0
            IF (PRESENT(EREC)) EREC= 0

            K_PTR => UKEY%FIRST%NEXT
            CNT = 1

            DO
              IF (K_PTR%TYPE == KTYP) THEN
                IF (CNT == KRPT) THEN
                  F_PTR => K_PTR%FIRST
                  L_PTR => K_PTR%LAST
                  IF (PRESENT(TEXT)) TEXT= K_PTR%TEXT
                  IF (PRESENT(SREC)) SREC= F_PTR%RECID
                  IF (PRESENT(EREC)) EREC= L_PTR%RECID
                  IF (DBGLEV > 7) THEN
                    WRITE(*,*) 'UCI_KEY_GET:found ',
     $                   K_PTR%TEXT,F_PTR%RECID,L_PTR%RECID
                  END IF
                  EXIT
                ELSE IF (ASSOCIATED(K_PTR%MORE)) THEN
                  K_PTR => K_PTR%MORE
                  CNT = CNT+ 1
                ELSE
                  IF (DBGLEV > 8) THEN
                    WRITE(*,*) 'UCI_KEY_GET:no type',KTYP,CNT,KRPT
                  END IF
                  EXIT
                END IF
              ELSE IF (ASSOCIATED(K_PTR%NEXT)) THEN
                K_PTR => K_PTR%NEXT
              ELSE
                IF (DBGLEV > 7) THEN
                  WRITE(*,*) 'UCI_KEY_GET:no type',KTYP
                END IF
                EXIT
              END IF
            END DO
          END IF

        END SUBROUTINE UCI_KEY_GET


        SUBROUTINE   UCI_KEY_DEL (KTYP)
          INTEGER, INTENT(IN)   :: KTYP

          TYPE (UKWD), POINTER  :: K_PTR, P_PTR, M_PTR
          INTEGER               :: CNT

          IF (.NOT. ASSOCIATED(UKEY%FIRST)) THEN
            WRITE(*,*) 'UCI_KEY_DEL:FATAL:uci file not open!!!'
            STOP
          ELSE
            K_PTR => UKEY%FIRST
            P_PTR => K_PTR

            DO
              IF (.NOT. ASSOCIATED(P_PTR%NEXT)) THEN
                IF (KTYP > 0) THEN
                  WRITE(*,*) 'UCI_KEY_DEL:type not found',KTYP
                ELSE IF (DBGLEV > 3) THEN
                  WRITE(*,*) 'UCI_KEY_DEL:all keys deleted'
                END IF
                EXIT
              ELSE
                K_PTR => P_PTR%NEXT
                IF (K_PTR%TYPE == KTYP .OR. KTYP == 0) THEN
                  P_PTR%NEXT => K_PTR%NEXT
                  IF (DBGLEV > 6) THEN
                    WRITE(*,*) 'UCI_KEY_DEL: ',K_PTR%TEXT
                  END IF
                  DO
                    CNT = 1
                    IF (ASSOCIATED(K_PTR%MORE)) THEN
                      M_PTR => K_PTR%MORE
                      IF (DBGLEV > 6) THEN
                        WRITE(*,*) 'UCI_KEY_DEL:',M_PTR%TEXT,CNT
                      END IF
                      CNT = CNT+ 1
                      K_PTR%MORE => K_PTR%MORE%MORE
                      DEALLOCATE(M_PTR)
                    ELSE
                      EXIT
                    END IF
                  END DO
                  DEALLOCATE(K_PTR)
                  IF (KTYP > 0) THEN
                    EXIT
                  END IF
                END IF
              END IF
            END DO
          END IF

        END SUBROUTINE UCI_KEY_DEL


        SUBROUTINE UCI_KEY_PRT

          TYPE (UKWD), POINTER        :: K_PTR, M_PTR
          TYPE (UREC), POINTER        :: F_PTR, L_PTR
          INTEGER                     :: I,J

          IF (.NOT. ASSOCIATED(UKEY%FIRST)) THEN
            WRITE(*,*) 'UCI_KEY_PRT:FATAL:uci file not open!!!'
            STOP
          ELSE
            K_PTR => UKEY%FIRST%NEXT
            I = 0
            DO
              I= I+ 1
              J= 1
              F_PTR => K_PTR%FIRST
              L_PTR => K_PTR%LAST
              WRITE(*,'(I4,2X,A12,4I8)') I,K_PTR%TEXT,K_PTR%TYPE,
     $                                   J,F_PTR%RECID,L_PTR%RECID
              IF (ASSOCIATED(K_PTR%MORE)) THEN
                DO
                  J= J+ 1
                  M_PTR => K_PTR%MORE
                  F_PTR => M_PTR%FIRST
                  L_PTR => M_PTR%LAST
                  WRITE(*,'(26X,3I8)') J,F_PTR%RECID,L_PTR%RECID
                  IF (.NOT. ASSOCIATED(M_PTR%MORE)) THEN
                    EXIT
                  ELSE
                    M_PTR => M_PTR%MORE
                  END IF
                END DO
              END IF
              IF (.NOT. ASSOCIATED(K_PTR%NEXT)) THEN
                EXIT
              ELSE
                K_PTR => K_PTR%NEXT
              END IF
            END DO
          END IF
        END SUBROUTINE UCI_KEY_PRT

      END MODULE UCI
