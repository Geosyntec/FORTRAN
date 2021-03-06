      MODULE StationData

      PUBLIC StnDat

      TYPE StnDat
        CHARACTER (LEN=80) :: HEADER
        CHARACTER (LEN=5)  :: XQUAL(200)
        CHARACTER (LEN=4)  :: GBTYPE
        INTEGER            :: NPLOT
        INTEGER            :: NPKS
        INTEGER            :: NPKPLT
        INTEGER            :: NTHRESH
        INTEGER            :: NINTRVL
        INTEGER            :: HSTFLG
        INTEGER            :: IPKSEQ(200)
        INTEGER            :: THRSYR(20)
        INTEGER            :: THREYR(20)
        INTEGER            :: THRNOB(20)
        INTEGER            :: INTYR(200)
        INTEGER            :: NLOW
        INTEGER            :: NZERO
        INTEGER            :: NOBS
        REAL               :: WEIBA
        REAL               :: PKS(200)
        REAL               :: PKLOG(200)
        REAL               :: SYSPP(200)
        REAL               :: WRCPP(200)
        REAL               :: SYSRFC(32)
        REAL               :: WRCFC(32)
        REAL               :: TXPROB(32)
        REAL               :: CLIML(32)
        REAL               :: CLIMU(32)
        REAL               :: INTLWR(200)
        REAL               :: INTUPR(200)
        REAL               :: INTPPOS(200)
        REAL               :: THRLWR(20)
        REAL               :: THRUPR(20)
        REAL               :: THRPP(20)
        REAL               :: GBCRIT
        REAL               :: WRCSKW
        REAL               :: RMSEGS
        REAL               :: ALLPOS(10000)
        CHARACTER*80       :: THRCOM(20)
        CHARACTER*80       :: INTCOM(200)
      END TYPE

      TYPE (StnDat), ALLOCATABLE :: STNDATA(:)

      END
