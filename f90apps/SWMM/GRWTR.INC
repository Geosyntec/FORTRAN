      CHARACTER    KMSUB*10,KGWTOG*10
      COMMON/GRWTR/GWFLOW(NGW),BELEV(NGW),GRELEV(NGW),STG(NGW),
     1             BC(NGW),TW(NGW),A1(NGW),B1(NGW),A2(NGW),
     2             B2(NGW),POR(NGW),WP(NGW),FC(NGW),HKSAT(NGW),
     3             TH1(NGW),HCO(NGW),PCO(NGW),CET(NGW),XTRENF(NGW),
cim  change dimension of NMSUB FROM NGW to NW.     
     6             A3(NGW),DP(NGW),DET(NGW),NMSUB(NW),KMSUB(NGW),
     4             NSCSFG(NGW),NGWGW(NGW),KGWTOG(NGW),NGWTOG(NGW),
     5             ETU,ETD,STBPAR,ENFIL,NGWGF,NSVGW,DEPPRC,NOGWSC,IRFLAG
