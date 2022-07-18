drop trigger T_HIST_CORPCD_USE_INSERT_Clt_KPX
go 
CREATE trigger T_HIST_CORPCD_USE_INSERT_Clt_KPX on HIST_CORPCD_USE_KPX              
For insert                
AS 

/*
-- ���� �и� �� ó�� ���� -- 

1. ���� �и� �� KPXERP DB���� HIST_CORPCD_BUY �����Ϳ� ����� ���� 
2. KPXERP DB���� HIST_CORPCD_USE_KPX �����층���� �� 
3. HIST_CORPCD_USE_KPX Ʈ���ŷ� ��� DB�� ���� (���� Ʈ����) 
*/

/*******************************************************************************************************************
-- KPX�� Ʈ���� ���� by ����õ 

���� : 
1. ��Ű�� ����ī�� ���̺��� HIST_CORPCD_USE ���̺��� �����
2. KPX�� HIST_CORPCD_BUY�� �����͸� ����Ͽ� ��ǥó���� 
3. �׷��� HIST_CORPCD_BUY�� �����͸� HIST_CORPCD_USE�� ������ �����층���� �۾��� 
4. �׷� �� ��Ű�� HIST_CORPCD_USE�� Ʈ���Ÿ� �����
5. �׷���.. KPX���������� HIST_CORPCD_USE �����Ϳ� HIST_CORPCD_BUY �����͸� ��� Ȯ�� �� �� �ֵ��� ��û��

��å : 
1. HIST_CORPCD_USE_KPX ���̺��� ����
2. HIST_CORPCD_BUY ���̺��� �����͸� HIST_CORPCD_USE_KPX ���̺� �����층���� �־���
3. HIST_CORPCD_USE_KPX ���̺� Ʈ���Ÿ� �����Ͽ� ERP ���̺� �־��� (���� trigger)

*******************************************************************************************************************/

declare @vResults varchar(200)        
declare @ISAppr   NCHAR(1), @CompanySeq INT      
            
SELECT @CompanySeq = CompanySeq      
FROM _TDACard      
            
SELECT @ISAppr = EnvValue  from _TCOMEnv where CompanySeq = @CompanySeq AND EnvSeq = 8923                    
                    
   SELECT --ISNULL(B.CompanySeq,1) AS CompanySeq,                  
           A.*,                   
           ROW_NUMBER() OVER(PARTITION BY A.CARD_NO, A.AUTH_DD, A.AUTH_NO ORDER BY A.AUTH_NO ASC) AS Seq                  
      INTO #TEMP                  
      FROM INSERTED AS A                  
           --LEFT OUTER JOIN (SELECT Z.CardNo, Z.CompanySeq 
           --                   FROM KPXERP.dbo._TDACard AS Z 
           --                  WHERE Z.CompanySeq = 1 
                            
           --                 UNION 
                            
           --                 SELECT Z.CardNo, Z.CompanySeq 
           --                   FROM KPXCM.dbo._TDACard AS Z 
           --                  WHERE Z.CompanySeq = 2 
           --                 ) as B on A.CARD_No = replace(B.CardNO,'-','')       
     WHERE ((@ISAppr = '1' AND A.BUY_STS IN('03', '04', '06')          --���Ա���  6���� ���Կ� ���� ȯ��    
        OR @ISAppr <> '1' AND A.BUY_STS IN('01', '02')))  --���α���                          
    
    
	-- KPXERP(KPXGC)
    INSERT INTO _TSIAFebCardCfm(CompanySeq,     CARD_CD,        APPR_DATE,      APPR_SEQ,                    
                                BANK_CD,        APPR_NO,        CHAIN_NM,       CHAIN_ID,                    
                                CHAIN_CD,       APPR_AMT,       APPR_TAX,       HALBU,                    
                                CANCEL_YN,      BUYING_DIST,    USE_DETAIL,     STAT_CD,                    
                                DEDUCT_YN,      CHAIN_TYPE,     TAX_CD,         USE_CD,                    
                                RETURN_MSG,     RECO_USE_FEE,   RECO_HALBU_NO,  INS_DATETIME,                    
                                MOD_DATETIME,   CURRCD,         SupplyAmt,      CardSeq,                    
                                MASTER,         MERCHZIPCODE,   MERCHADDR1,     MERCHADDR2,                    
                                MCCNAME,        MCCCODE,        PURDATE,        TIP_AMT,              
                                CURAMT,         LastDateTime,   Dummy1 
                                      )                    
                         
    SELECT 1,               A.CARD_NO,          A.AUTH_DD,      ISNULL(B.APPR_SEQ,0) + A.Seq,                    
           '00',            A.AUTH_NO,          A.MER_NM,       A.MER_BIZNO,                    
           '',              CASE WHEN A.CARD_COM_CD = '07' AND A.BUY_STS = '04' THEN ISNULL(A.BUY_WON_CVTRATE,0) 
                                 ELSE ( CASE WHEN A.FORE_USEGB = '2' AND ISNULL(C.BUY_WON_CVTRATE,0) <> 0 THEN ISNULL(C.BUY_WON_CVTRATE,0)  
                                             WHEN A.FORE_USEGB = '2' AND ISNULL(A.BUY_WON_CVTRATE,0) <> 0 THEN ISNULL(A.BUY_WON_CVTRATE,0) ELSE A.AUTH_AMT 
                                             END 
                                      )
                                 END,         A.SURTAX,       '',                     
           CASE WHEN SUBSTRING(A.BUY_STS,2,1) IN ('2', '4', '6') THEN '3' ELSE '1' END ,             A.BUY_STS,                 '',             '',                    
           '',              A.MER_CLOSE,        '',             A.FORE_USEGB,                    
           '',              0,                  0,              '',                    
           '',              A.TRAN_CURCD,       CASE WHEN A.FORE_USEGB = '2' AND ISNULL(C.BUY_WON_CVTRATE,0) <> 0 THEN ISNULL(C.BUY_WON_CVTRATE,0)  
                                                     WHEN A.FORE_USEGB = '2' AND ISNULL(A.BUY_WON_CVTRATE,0) <> 0 THEN ISNULL(A.BUY_WON_CVTRATE,0) ELSE A.SUPP_PRICE END,   0,                    
           A.MER_CEONM,     A.MER_ZIPNO,        A.MER_ADR1,     A.MER_ADR2,                    
           A.BIZTYPE_NM,    A.BIZTYPE_CD,       A.BUY_DD,       A.SVC_AMT,              
           A.BUY_USD_CVTRATE,                   GETDATE(),      A.BUY_CLT_NO 
                                              
                                                                             
      FROM #TEMP         AS A                     
             LEFT OUTER JOIN (SELECT CARD_CD, APPR_DATE, APPR_NO, MAX(APPR_SEQ) AS APPR_SEQ                  
                              FROM _TSIAFebCardCfm 
                             WHERE CompanySeq = 1 
                             GROUP BY CARD_CD, APPR_DATE, APPR_NO)   AS B ON A.CARD_NO      = B.CARD_CD                  
                                                                         AND A.AUTH_DD      = B.APPR_DATE     
                                                                         AND A.AUTH_NO      = B.APPR_NO          
     LEFT OUTER JOIN HIST_CORPCD_Use_KPX AS C ON     
            A.CARD_COM_CD = C.CARD_COM_CD    
            AND A.CARD_NO = C.CARD_NO     
            --AND A.AUTH_DD = C.AUTH_DD     
            AND A.MER_BIZNO = C.MER_BIZNO    
            AND A.AUTH_NO = C.AUTH_NO     
            AND C.BUY_STS = '03'        --�ؿܻ���(���԰�)    
            --AND C.AUTH_AMT = 0    
            AND A.BUY_USD_CVTRATE <> 0  
     WHERE NOT EXISTS (SELECT 1 FROM _TSIAFebCardCfm WHERE CompanySeq = 1 AND Dummy1 = A.BUY_CLT_NO)
	
	
	
	-- KPXCM 
    INSERT INTO KPXCM.DBO._TSIAFebCardCfm(CompanySeq,     CARD_CD,        APPR_DATE,      APPR_SEQ,                    
                                BANK_CD,        APPR_NO,        CHAIN_NM,       CHAIN_ID,                    
                                CHAIN_CD,       APPR_AMT,       APPR_TAX,       HALBU,                    
                                CANCEL_YN,      BUYING_DIST,    USE_DETAIL,     STAT_CD,                    
                                DEDUCT_YN,      CHAIN_TYPE,     TAX_CD,         USE_CD,                    
                                RETURN_MSG,     RECO_USE_FEE,   RECO_HALBU_NO,  INS_DATETIME,                    
                                MOD_DATETIME,   CURRCD,         SupplyAmt,      CardSeq,                    
                                MASTER,         MERCHZIPCODE,   MERCHADDR1,     MERCHADDR2,                    
                                MCCNAME,        MCCCODE,        PURDATE,        TIP_AMT,              
                                CURAMT,         LastDateTime,   Dummy1 
                            
                    
                                                    
                                      )                    
                         
    SELECT 2,               A.CARD_NO,          A.AUTH_DD,      ISNULL(B.APPR_SEQ,0) + A.Seq,                    
           '00',            A.AUTH_NO,          A.MER_NM,       A.MER_BIZNO,                    
           '',              CASE WHEN A.CARD_COM_CD = '07' AND A.BUY_STS = '04' THEN ISNULL(A.BUY_WON_CVTRATE,0) 
                                 ELSE ( CASE WHEN A.FORE_USEGB = '2' AND ISNULL(C.BUY_WON_CVTRATE,0) <> 0 THEN ISNULL(C.BUY_WON_CVTRATE,0)  
                                             WHEN A.FORE_USEGB = '2' AND ISNULL(A.BUY_WON_CVTRATE,0) <> 0 THEN ISNULL(A.BUY_WON_CVTRATE,0) ELSE A.AUTH_AMT 
                                             END 
                                      )
                                 END,         A.SURTAX,       '',                     
           CASE WHEN SUBSTRING(A.BUY_STS,2,1) IN ('2', '4', '6') THEN '3' ELSE '1' END ,             A.BUY_STS,                 '',             '',                    
           '',              A.MER_CLOSE,        '',             A.FORE_USEGB,                    
           '',              0,                  0,              '',                    
           '',              A.TRAN_CURCD,       CASE WHEN A.FORE_USEGB = '2' AND ISNULL(C.BUY_WON_CVTRATE,0) <> 0 THEN ISNULL(C.BUY_WON_CVTRATE,0)  
                                                     WHEN A.FORE_USEGB = '2' AND ISNULL(A.BUY_WON_CVTRATE,0) <> 0 THEN ISNULL(A.BUY_WON_CVTRATE,0) ELSE A.SUPP_PRICE END,   0,                    
           A.MER_CEONM,     A.MER_ZIPNO,        A.MER_ADR1,     A.MER_ADR2,                    
           A.BIZTYPE_NM,    A.BIZTYPE_CD,       A.BUY_DD,       A.SVC_AMT,              
           A.BUY_USD_CVTRATE,                   GETDATE(),      A.BUY_CLT_NO 
                                              
                                                                             
      FROM #TEMP         AS A                     
             LEFT OUTER JOIN (SELECT CARD_CD, APPR_DATE, APPR_NO, MAX(APPR_SEQ) AS APPR_SEQ                  
                              FROM KPXCM.DBO._TSIAFebCardCfm 
                             WHERE CompanySeq = 2 
                             GROUP BY CARD_CD, APPR_DATE, APPR_NO)   AS B ON A.CARD_NO      = B.CARD_CD                  
                                                                         AND A.AUTH_DD      = B.APPR_DATE     
                                                                         AND A.AUTH_NO      = B.APPR_NO       
     LEFT OUTER JOIN HIST_CORPCD_Use_KPX AS C ON     
            A.CARD_COM_CD = C.CARD_COM_CD    
            AND A.CARD_NO = C.CARD_NO     
            --AND A.AUTH_DD = C.AUTH_DD     
            AND A.MER_BIZNO = C.MER_BIZNO    
            AND A.AUTH_NO = C.AUTH_NO     
            AND C.BUY_STS = '03'        --�ؿܻ���(���԰�)    
            --AND C.AUTH_AMT = 0    
            AND A.BUY_USD_CVTRATE <> 0  
     WHERE NOT EXISTS (SELECT 1 FROM KPXCM.DBO._TSIAFebCardCfm WHERE CompanySeq = 2 AND Dummy1 = A.BUY_CLT_NO)
    
    return 