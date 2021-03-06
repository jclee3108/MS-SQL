IF OBJECT_ID('DTI_SSLReceiptDelaySalesSuretyListQuery') IS NOT NULL   
    DROP PROC DTI_SSLReceiptDelaySalesSuretyListQuery  
GO  
/************************************************************        
 설  명 - 데이터-연체채권담보조회_DTI : 조회  
 작성일 - 2010-06-23 : CREATEd by  
 작성자 - 문태중  
************************************************************/        
CREATE PROC dbo.DTI_SSLReceiptDelaySalesSuretyListQuery  
     @xmlDocument    NVARCHAR(MAX) ,  
     @xmlFlags       INT  = 0,  
     @ServiceSeq     INT  = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT  = 1,  
     @LanguageSeq    INT  = 1,  
     @UserSeq        INT  = 0,  
     @PgmSeq         INT  = 0  
AS  
    DECLARE @docHandle      INT,  
            @CustSeq        INT,            -- 거래처  
            @OrderSeq       INT,  
            @BillSeq        INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
    
    SELECT @CustSeq        = ISNULL(CustSeq, 0),  
           @OrderSeq       = ISNULL(OrderSeq, 0),  
           @BillSeq        = ISNULL(BillSeq, 0)  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)        
      WITH (   
             CustSeq        INT,     -- 거래처  
             OrderSeq       INT,     -- 수주코드  
             BillSeq        INT      -- 세금계산서코드  
           )  
    
    SELECT  
         A.*,  
         (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SuretyDetail) AS SuretyDetailName  
     FROM  
     (  
    SELECT G.DeptName,  -- 부서  
           H.EmpName, -- 담당자  
           I.CustName, -- 거래처  
           I.BizNo, -- 사업자번호  
           J.MinorName AS UMSecuritiesKindName, -- 유가증권종류  
           K.MinorName AS UMRealtyKindName, -- 부동산종류  
           E.Sel, -- 선순위(금액)  
           E.MunicipalTax, -- 시세  
           A.Remark,   
           A.CustSeq           AS CustSeq,         -- 거래처코드  
           A.SMMortageKind     AS SMMortageKind,   -- 담보종류  
           A.SDate             AS SDate,           -- 담보시작일  
           A.EDate             AS EDate,           -- 담보종류일  
           A.CurrSeq           AS CurrSeq,         -- 통화  
           A.SpecCreditAmt     AS SuretyAmt,       -- 담보금액  
           (SELECT CurrName FROM _TDACurr WHERE CompanySeq = @CompanySeq AND CurrSeq = A.CurrSeq) AS CurrName, -- 통화  
           (CASE A.SMMortageKind WHEN 8501001 THEN D.UMSecuritiesKind 
                                 WHEN 8501002 THEN E.UMRealtyKind 
                                 ELSE F.UMCashEQKind 
                                 END) AS SuretyDetail,--담보상세  
           (CASE A.SMMortageKind WHEN '8501001' THEN '유가증권' WHEN '8501002' THEN '부동산' ELSE '현금등가물' END) AS SMMortageKindName -- 담보구분명  
                 
      FROM _TSLCustSpecCredit        AS A WITH(NOLOCK)    
      LEFT OUTER JOIN _TSLSecurities AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq AND D.SpecCreditSerl = A.SpecCreditSerl ) -- 유가증권  
      LEFT OUTER JOIN _TSLRealEstate AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.CustSeq AND E.SpecCreditSerl = A.SpecCreditSerl ) -- 부동산  
      LEFT OUTER JOIN _TSLCashEquivalent AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = A.CustSeq AND F.SpecCreditSerl = A.SpecCreditSerl ) -- 현금등가물  
      LEFT OUTER JOIN _TDADept     AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.DeptSeq = A.DeptSeq )   
      LEFT OUTER JOIN _TDAEmp      AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.EmpSeq = A.EmpSeq )   
      LEFT OUTER JOIN _TDACust     AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.CustSeq = A.CustSeq )  
      LEFT OUTER JOIN _TDAUMinor   AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = D.UMSecuritiesKind ) --유가증권종류이름  
      LEFT OUTER JOIN _TDAUMinor   AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = E.UMRealtyKind ) -- 부동산종류이름  
      LEFT OUTER JOIN _TDAUMinor   AS Z WITH(NOLOCK) ON ( Z.CompanySeq = @CompanySeq 
                                                      AND Z.MinorSeq = (CASE A.SMMortageKind WHEN 8501001 THEN D.UMSecuritiesKind 
                                                                                             WHEN 8501002 THEN E.UMRealtyKind 
                                                                                             ELSE F.UMCashEQKind 
                                                                                             END) 
                                                        )
     
     WHERE A.CompanySeq = @CompanySeq      
       AND (@CustSeq <> 0 OR @BillSeq <> 0 OR @OrderSeq <> 0)  
       AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)  
       AND (@BillSeq = 0 OR A.CustSeq IN (SELECT CustSeq FROM _TSLBill WHERE CompanySeq = @CompanySeq AND BillSeq = @BillSeq))  
       AND (@OrderSeq = 0 OR A.CustSeq IN (SELECT CustSeq FROM _TSLOrder WHERE CompanySeq = @CompanySeq AND OrderSeq = @OrderSeq))  
    ) AS A  
     ORDER BY A.SMMortageKind  
    
    RETURN
GO