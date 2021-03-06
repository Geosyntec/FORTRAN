C     from CILIG.INC   
C     IMPLND module common
C            IWTGAS section
      COMMON/SCRTCH/AIRTFG,SNOWFG,IWATFG,SLDFG,IWGFG,IQALFG,DUMZ,
     $              PFLAG,DUMY,PIVL,PYREND,IMPPFG,UUNITS,IUNITS,
     $              OUNITS,PUNIT,MESSU,MSGFL,LSNO,LSID,DELT,DELT60,
     $              DUMX,NDAY,NDAYS,DUMW,HRFG,DAYFG,STFG,EDAYFG,
     $              EMONFG,EPYRFG,YR,MON,DAY,HR,MIN,IVL,IVL1,PIVLNO,
     $              NXTMON,SPAFP,SPAKND,SPIVL,SPOPNO,SPOUT,SPNUND,
     $              DUMGEN,DUM1,AIRTMP,DUM2,AIRTFP,DUM3,SNCF1,DUM4,
     $              WYFP,DUM5,IWIF,DUM6,SLIFP,DUM7,CSNOFG,DUM8,IWCF1,
     $              DUM9,SOFP,DUM10,SLITMP,SLIDOX,SLICO2,SLITFP,
     $              SLDOFP,SLCOFP,WTFVFG,ELEVGC,AWTFM,BWTFM,LIFAC,
     $              AIRTC,SOTMP,SODOX,SOCO2,SOTFP,SODOFP,SOCDFP,AWTF,
     $              BWTF,IGCF1,SOHTFP,SODOMX,SOCDMX,DUMIMP
      INTEGER       AIRTFG,SNOWFG,IWATFG,SLDFG,IWGFG,IQALFG,DUMZ(7),
     $              PFLAG(6),DUMY(6),PIVL,PYREND,IMPPFG,UUNITS,IUNITS,
     $              OUNITS,PUNIT(2),MESSU,MSGFL,LSNO,LSID(5),DUMX(1),
     $              NDAY(12),NDAYS,DUMW(2),HRFG,DAYFG,STFG,EDAYFG,
     $              EMONFG,EPYRFG,YR,MON,DAY,HR,MIN,IVL,IVL1,PIVLNO,
     $              NXTMON,SPAFP,SPAKND,SPIVL,SPOPNO,SPOUT,SPNUND,
     $              DUMGEN(13),AIRTFP,WYFP,SLIFP,CSNOFG,SOFP,SLITFP,
     $              SLDOFP,SLCOFP,WTFVFG,SOTFP,SODOFP,SOCDFP,SOHTFP,
     $              SODOMX,SOCDMX
      REAL          DELT,DELT60,AIRTMP,SNCF1(5,5),IWIF(5),IWCF1(4,5),
     $              SLITMP,SLIDOX,SLICO2,ELEVGC,AWTFM(12),BWTFM(12),
     $              LIFAC(2),AIRTC,SOTMP,SODOX,SOCO2,AWTF,BWTF,
     $              IGCF1(3,5)
      INTEGER       DUM1(29),DUM2,DUM3(133),DUM4(14),DUM5(2),DUM6,
     $              DUM7,DUM8(51),DUM9(13),DUM10(49),DUMIMP(17496)
C
      EQUIVALENCE   (ASVEC,AIRTFG),(UNIT,UUNITS),(TIMFG,HRFG),
     $              (DATIM,YR),(WYIELD,SNCF1(4,1)),(SURLI,IWIF(1)),
     $              (SURO,IWCF1(2,1)),(IGST1,SOTMP),(IGST1X,SOTFP),
     $              (SOHT,IGCF1(1,1)),(SODOXM,IGCF1(2,1)),
     $              (SOCO2M,IGCF1(3,1)),(IGCF1X,SOHTFP)
      INTEGER       ASVEC(6),UNIT(5),TIMFG(6),DATIM(5),IGST1X(3),
     $              IGCF1X(3)
      REAL          WYIELD,SURLI,SURO,IGST1(3),SOHT,SODOXM,SOCO2M
C     end byte:  72000 word:18000
