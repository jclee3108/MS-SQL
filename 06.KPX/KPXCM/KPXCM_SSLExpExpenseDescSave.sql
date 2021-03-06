IF OBJECT_ID('KPXCM_SSLExpExpenseDescSave') IS NOT NULL 
    DROP PROC KPXCM_SSLExpExpenseDescSave
GO 

-- v2015.09.30 

-- 물품대상세 추가 by이재천 
/*********************************************************************************************************************
     화면명 : 수출비용_상세저장
     SP Name: _SSLExpExpenseDescSave
     작성일 : 2009. 3 : CREATEd by 김준모
     수정일 : 
  ALTER TABLE _TSLExpExpenseDesc ADD EvidSeq INT NULL 
 ALTER TABLE _TSLExpExpenseDescLog ADD EvidSeq INT NULL 
  ********************************************************************************************************************/
  CREATE PROCEDURE KPXCM_SSLExpExpenseDescSave  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS       
    DECLARE @docHandle      INT 
    CREATE TABLE #TSLExpExpenseDesc (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSLExpExpenseDesc' 
    
      -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TSLExpExpenseDesc', -- 원테이블명
                    '#TSLExpExpenseDesc', -- 템프테이블명
                    'ExpenseSeq,ExpenseSerl' , -- 키가 여러개일 경우는 , 로 연결한다. 
                    'CompanySeq,ExpenseSeq,ExpenseSerl,UMExpenseGroup,UMExpenseItem,CostCustSeq,CurrSeq,ExRate,IsVAT,IsInclusedVAT,VATRate,CurAmt,CurVAT,DomAmt,DomVAT,
                     Remark,RefBillNo,AccSeq,VATAccSeq,OppAccSeq,SlipSeq,CCtrSeq,CostDate,EtcKey,PayCustSeq, LastUserSeq,LastDateTime,PrePaymentDate'
    
    ------------------------------------------------------------
    -- 물품대 상세 ( 원천 품목 기준 ) 
    ------------------------------------------------------------
    DECLARE @ItemRemark NVARCHAR(MAX) 
    
    SELECT @ItemRemark = 
           CASE WHEN B.SMSourceType = 8215002 THEN C.ItemName 
                WHEN B.SMSourceType = 8215003 THEN E.ItemName  
                WHEN B.SMSourceType = 8215004 THEN D.ItemName  
                WHEN B.SMSourceType = 8215005 THEN G.ItemName  
                WHEN B.SMSourceType = 8215006 THEN F.ItemName  
                END + -- 품목명 
           CASE WHEN (
                        CASE WHEN B.SMSourceType = 8215002 THEN C.Cnt 
                             WHEN B.SMSourceType = 8215003 THEN E.Cnt  
                             WHEN B.SMSourceType = 8215004 THEN D.Cnt  
                             WHEN B.SMSourceType = 8215005 THEN G.Cnt  
                             WHEN B.SMSourceType = 8215006 THEN F.Cnt  
                             END
                     ) = 1 
                THEN '' 
                ELSE ' 외' + CONVERT(NVARCHAR(100),(CASE WHEN B.SMSourceType = 8215002 THEN C.Cnt 
                                                         WHEN B.SMSourceType = 8215003 THEN E.Cnt  
                                                         WHEN B.SMSourceType = 8215004 THEN D.Cnt  
                                                         WHEN B.SMSourceType = 8215005 THEN G.Cnt  
                                                         WHEN B.SMSourceType = 8215006 THEN F.Cnt  
                                                         END) - 1) + '건' -- 건수 
                END + 
           ' ' + CASE WHEN B.SMSourceType = 8215002 THEN dbo._FCOMNumberToStr(C.Qty,3) 
                      WHEN B.SMSourceType = 8215003 THEN dbo._FCOMNumberToStr(E.Qty,3) 
                      WHEN B.SMSourceType = 8215004 THEN dbo._FCOMNumberToStr(D.Qty,3) 
                      WHEN B.SMSourceType = 8215005 THEN dbo._FCOMNumberToStr(G.Qty,3) 
                      WHEN B.SMSourceType = 8215006 THEN dbo._FCOMNumberToStr(F.Qty,3) 
                      END + -- 수량 
           CASE WHEN B.SMSourceType = 8215002 THEN C.UnitName
                WHEN B.SMSourceType = 8215003 THEN E.UnitName
                WHEN B.SMSourceType = 8215004 THEN D.UnitName
                WHEN B.SMSourceType = 8215005 THEN G.UnitName
                WHEN B.SMSourceType = 8215006 THEN F.UnitName
                END  + -- 단위 
           ' ' + CASE WHEN B.SMSourceType = 8215002 THEN C.CurrName
                      WHEN B.SMSourceType = 8215003 THEN E.CurrName
                      WHEN B.SMSourceType = 8215004 THEN D.CurrName
                      WHEN B.SMSourceType = 8215005 THEN G.CurrName
                      WHEN B.SMSourceType = 8215006 THEN F.CurrName
                      END + -- 통화 
           ' ' + CASE WHEN B.SMSourceType = 8215002 THEN dbo._FCOMNumberToStr(C.CurAmt,3)
                      WHEN B.SMSourceType = 8215003 THEN dbo._FCOMNumberToStr(E.CurAmt,3) 
                      WHEN B.SMSourceType = 8215004 THEN dbo._FCOMNumberToStr(D.CurAmt,3) 
                      WHEN B.SMSourceType = 8215005 THEN dbo._FCOMNumberToStr(G.CurAmt,3) 
                      WHEN B.SMSourceType = 8215006 THEN dbo._FCOMNumberToStr(F.CurAmt,3) 
                      END -- 금액 
                       
                
      FROM #TSLExpExpenseDesc       AS A 
      JOIN _TSLExpExpense           AS B ON ( B.CompanySeq = @CompanySeq AND B.ExpenseSeq = A.ExpenseSeq ) 
      OUTER APPLY (SELECT TOP 1 Z.PaymentSeq, CASE WHEN Y.ItemSName = '' THEN Y.ItemName ELSE Y.ItemSName END ItemName, W.Cnt, W.Qty, W.UnitName, W.CurrName, W.CurAmt
                     FROM _TSLImpPaymentItem    AS Z 
                     LEFT OUTER JOIN _TDAItem   AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.ItemSeq = Z.ItemSeq ) 
                     OUTER APPLY (SELECT Count(1) Cnt, SUM(Qty) AS Qty, MAX(O.UnitName) AS UnitName, MAX(I.CurrName) AS CurrName, SUM(CurAmt) AS CurAmt
                                    FROM _TSLImpPaymentItem         AS P 
                                    LEFT OUTER JOIN _TSLImpPayment  AS U ON ( U.CompanySeq = @CompanySeq AND U.PaymentSeq = P.PaymentSeq ) 
                                    LEFT OUTER JOIN _TDAUnit        AS O ON ( O.CompanySeq = @CompanySeq AND O.UnitSeq = P.UnitSeq ) 
                                    LEFT OUTER JOIN _TDACurr        AS I ON ( I.CompanySeq = @CompanySeq AND I.CurrSeq = U.CurrSeq ) 
                                   WHERE P.CompanySeq = @CompanySeq 
                                     AND P.PaymentSeq = Z.PaymentSeq 
                                 ) AS W 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.PaymentSeq = B.SourceSeq
                      AND B.SMSourceType = 8215002 
                   ORDER BY Z.PaymentSerl 
                  ) AS C  -- 수입Payment 
      OUTER APPLY (SELECT TOP 1 Z.BLSeq, CASE WHEN Y.ItemSName = '' THEN Y.ItemName ELSE Y.ItemSName END ItemName, W.Cnt, W.Qty, W.UnitName, W.CurrName, W.CurAmt
                     FROM _TUIImpBLItem    AS Z 
                     LEFT OUTER JOIN _TDAItem   AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.ItemSeq = Z.ItemSeq ) 
                     OUTER APPLY (SELECT Count(1) Cnt, SUM(Qty) AS Qty, MAX(O.UnitName) AS UnitName, MAX(I.CurrName) AS CurrName, SUM(CurAmt) AS CurAmt
                                    FROM _TUIImpBLItem          AS P 
                                    LEFT OUTER JOIN _TUIImpBL   AS U ON ( U.CompanySeq = @CompanySeq AND U.BLSeq = P.BLSeq ) 
                                    LEFT OUTER JOIN _TDAUnit    AS O ON ( O.CompanySeq = @CompanySeq AND O.UnitSeq = P.UnitSeq ) 
                                    LEFT OUTER JOIN _TDACurr    AS I ON ( I.CompanySeq = @CompanySeq AND I.CurrSeq = U.CurrSeq ) 
                                   WHERE P.CompanySeq = @CompanySeq 
                                     AND P.BLSeq = Z.BLSeq 
                                 ) AS W 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.BLSeq = B.SourceSeq
                      AND B.SMSourceType = 8215004 
                   ORDER BY Z.BLSerl 
                  ) AS D -- 수입BL 
      OUTER APPLY (SELECT TOP 1 Z.InvoiceSeq, CASE WHEN Y.ItemSName = '' THEN Y.ItemName ELSE Y.ItemSName END ItemName, W.Cnt, W.Qty, W.UnitName, W.CurrName, W.CurAmt
                     FROM _TUIImpInvoiceItem    AS Z 
                     LEFT OUTER JOIN _TDAItem   AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.ItemSeq = Z.ItemSeq ) 
                     OUTER APPLY (SELECT Count(1) Cnt, SUM(Qty) AS Qty, MAX(O.UnitName) AS UnitName, MAX(I.CurrName) AS CurrName, SUM(CurAmt) AS CurAmt
                                    FROM _TUIImpInvoiceItem         AS P 
                                    LEFT OUTER JOIN _TUIImpInvoice  AS U ON ( U.CompanySeq = @CompanySeq AND U.InvoiceSeq = P.InvoiceSeq ) 
                                    LEFT OUTER JOIN _TDAUnit        AS O ON ( O.CompanySeq = @CompanySeq AND O.UnitSeq = P.UnitSeq ) 
                                    LEFT OUTER JOIN _TDACurr        AS I ON ( I.CompanySeq = @CompanySeq AND I.CurrSeq = U.CurrSeq ) 
                                   WHERE P.CompanySeq = @CompanySeq 
                                     AND P.InvoiceSeq = Z.InvoiceSeq 
                                 ) AS W 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.InvoiceSeq = B.SourceSeq
                      AND B.SMSourceType = 8215003
                   ORDER BY Z.InvoiceSerl 
                  ) AS E -- 수입Invoice 
      OUTER APPLY (SELECT TOP 1 Z.DelvSeq, CASE WHEN Y.ItemSName = '' THEN Y.ItemName ELSE Y.ItemSName END ItemName, W.Cnt, W.Qty, W.UnitName, W.CurrName, W.CurAmt
                     FROM _TUIImpDelvItem       AS Z 
                     LEFT OUTER JOIN _TDAItem   AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.ItemSeq = Z.ItemSeq ) 
                     OUTER APPLY (SELECT Count(1) Cnt, SUM(Qty) AS Qty, MAX(O.UnitName) AS UnitName, MAX(I.CurrName) AS CurrName, SUM(CurAmt) AS CurAmt
                                    FROM _TUIImpDelvItem            AS P 
                                    LEFT OUTER JOIN _TUIImpDelv     AS U ON ( U.CompanySeq = @CompanySeq AND U.DelvSeq = P.DelvSeq ) 
                                    LEFT OUTER JOIN _TDAUnit        AS O ON ( O.CompanySeq = @CompanySeq AND O.UnitSeq = P.UnitSeq ) 
                                    LEFT OUTER JOIN _TDACurr        AS I ON ( I.CompanySeq = @CompanySeq AND I.CurrSeq = U.CurrSeq ) 
                                   WHERE P.CompanySeq = @CompanySeq 
                                     AND P.DelvSeq = Z.DelvSeq 
                                 ) AS W 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.DelvSeq = B.SourceSeq
                      AND B.SMSourceType = 8215006
                   ORDER BY Z.DelvSerl 
                  ) AS F -- 수입입고 
      OUTER APPLY (SELECT TOP 1 Z.PermitSeq, CASE WHEN Y.ItemSName = '' THEN Y.ItemName ELSE Y.ItemSName END ItemName, W.Cnt, W.Qty, W.UnitName, W.CurrName, W.CurAmt
                     FROM _TUIImpPermitItem     AS Z 
                     LEFT OUTER JOIN _TDAItem   AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.ItemSeq = Z.ItemSeq ) 
                     OUTER APPLY (SELECT Count(1) Cnt, SUM(Qty) AS Qty, MAX(O.UnitName) AS UnitName, MAX(I.CurrName) AS CurrName, SUM(CurAmt) AS CurAmt
                                    FROM _TUIImpPermitItem          AS P 
                                    LEFT OUTER JOIN _TUIImpPermit   AS U ON ( U.CompanySeq = @CompanySeq AND U.PermitSeq = P.PermitSeq ) 
                                    LEFT OUTER JOIN _TDAUnit        AS O ON ( O.CompanySeq = @CompanySeq AND O.UnitSeq = P.UnitSeq ) 
                                    LEFT OUTER JOIN _TDACurr        AS I ON ( I.CompanySeq = @CompanySeq AND I.CurrSeq = U.CurrSeq ) 
                                   WHERE P.CompanySeq = @CompanySeq 
                                     AND P.PermitSeq = Z.PermitSeq 
                                 ) AS W 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.PermitSeq = B.SourceSeq
                      AND B.SMSourceType = 8215005
                   ORDER BY Z.PermitSerl 
                  ) AS G -- 수입면장 
    
    UPDATE A 
       SET ItemRemark = CASE WHEN A.UMExpenseGroup = 8211028 THEN @ItemRemark ELSE '' END 
      FROM #TSLExpExpenseDesc AS A 
    
    ------------------------------------------------------------
    -- 물품대 상세 ( 원천 품목 기준 ), END  
    ------------------------------------------------------------
    
    
     -- DELETE                                                                                                
     IF EXISTS (SELECT 1 FROM #TSLExpExpenseDesc WHERE WorkingTag = 'D' AND Status = 0 )  
     BEGIN  
         DELETE _TSLExpExpenseDesc  
           FROM _TSLExpExpenseDesc AS A
                  JOIN #TSLExpExpenseDesc AS B ON  A.ExpenseSeq = B.ExpenseSeq AND A.ExpenseSerl = B.ExpenseSerl
          WHERE A.CompanySeq = @CompanySeq
            AND B.WorkingTag = 'D' 
            AND B.Status = 0    
            
         DELETE KPXCM_TSLExpExpenseDesc  
           FROM KPXCM_TSLExpExpenseDesc AS A
                  JOIN #TSLExpExpenseDesc AS B ON  A.ExpenseSeq = B.ExpenseSeq AND A.ExpenseSerl = B.ExpenseSerl
          WHERE A.CompanySeq = @CompanySeq
            AND B.WorkingTag = 'D' 
            AND B.Status = 0    
     END   
      -- UPDATE                                                                                                 
     IF EXISTS (SELECT 1 FROM #TSLExpExpenseDesc WHERE WorkingTag = 'U' AND Status = 0 )  
     BEGIN   
         UPDATE _TSLExpExpenseDesc   
            SET  UMExpenseGroup = B.UMExpenseGroup,
                 UMExpenseItem  = B.UMExpenseItem,
                 CostDate       = B.CostDate,
                 CostCustSeq    = B.CostCustSeq,
                 CurrSeq        = B.CurrSeq,
                 ExRate         = B.ExRate,
                 IsVAT          = B.IsVAT,
                 IsInclusedVAT  = B.IsInclusedVAT,
                 VATRate        = B.VATRate,
                 CurAmt         = B.CurAmt,
                 CurVAT         = B.CurVAT,
                 DomAmt         = B.DomAmt,
                 DomVAT         = B.DomVAT,
                 Remark         = B.Remark,
                 RefBillNo      = B.RefBillNo,
                 AccSeq         = B.AccSeq,
                 VATAccSeq      = B.VATAccSeq,
                 OppAccSeq      = B.OppAccSeq,
                 CCtrSeq        = B.CCtrSeq,
                 EvidSeq        = B.EvidSeq,
                 PayCustSeq     = B.PayCustSeq,
                 LastUserSeq    = @UserSeq ,
                 LastDateTime   = GETDATE()  ,
                 PrePaymentDate = B.PrePaymentDate
           FROM _TSLExpExpenseDesc AS A 
                  JOIN #TSLExpExpenseDesc AS B ON A.ExpenseSeq = B.ExpenseSeq AND A.ExpenseSerl = B.ExpenseSerl
          WHERE B.WorkingTag = 'U' 
            AND B.Status = 0
            AND A.CompanySeq = @CompanySeq
   
         UPDATE KPXCM_TSLExpExpenseDesc   
            SET  ItemRemark     = B.ItemRemark, 
                 LastUserSeq    = @UserSeq ,
                 LastDateTime   = GETDATE(),
                 PgmSeq         = @PgmSeq
           FROM KPXCM_TSLExpExpenseDesc AS A 
                  JOIN #TSLExpExpenseDesc AS B ON A.ExpenseSeq = B.ExpenseSeq AND A.ExpenseSerl = B.ExpenseSerl
          WHERE B.WorkingTag = 'U' 
            AND B.Status = 0
            AND A.CompanySeq = @CompanySeq
        
        IF @@ERROR <> 0 RETURN  
    
     END 
      -- INSERT                                                                                                 
     IF EXISTS (SELECT 1 FROM #TSLExpExpenseDesc WHERE WorkingTag = 'A' AND Status = 0 )  
     BEGIN          
        -- 서비스 INSERT  
        INSERT INTO _TSLExpExpenseDesc (CompanySeq, ExpenseSeq, ExpenseSerl, UMExpenseGroup, UMExpenseItem,
                                         CostCustSeq,CurrSeq,    ExRate,      IsVAT,          IsInclusedVAT,  VATRate,
                                         CurAmt,     CurVAT,     DomAmt,      DomVAT,         Remark,
                                         RefBillNo,  AccSeq,     VATAccSeq,   OppAccSeq,      SlipSeq,
                                         CCtrSeq,    CostDate,   EtcKey,      EvidSeq,        PayCustSeq,
                                         LastUserSeq,LastDateTime,PrePaymentDate)    
        SELECT   @CompanySeq,ExpenseSeq, ExpenseSerl, UMExpenseGroup, UMExpenseItem,
                                         CostCustSeq,CurrSeq,    ExRate,      IsVAT,          IsInclusedVAT,  VATRate,
                                         CurAmt,     CurVAT,     DomAmt,      DomVAT,         Remark,
                                         RefBillNo,  AccSeq,     VATAccSeq,   OppAccSeq,      0,
                                         CCtrSeq,    CostDate,   EtcKey,      EvidSeq,        PayCustSeq,
                                         @UserSeq,   GETDATE(),  PrePaymentDate  
         FROM #TSLExpExpenseDesc  
        WHERE WorkingTag = 'A' 
          AND Status = 0  
        
        
        INSERT INTO KPXCM_TSLExpExpenseDesc 
        (
            CompanySeq, ExpenseSeq, ExpenseSerl, ItemRemark, LastUserSeq, 
            LastDateTime, PgmSeq
        ) 
        SELECT @CompanySeq, ExpenseSeq, ExpenseSerl, ItemRemark, @UserSeq, 
               GETDATE(), @PgmSeq
         FROM #TSLExpExpenseDesc  
        WHERE WorkingTag = 'A' 
          AND Status = 0  
        
        IF @@ERROR <> 0 RETURN     
    
    END     
    
    UPDATE #TSLExpExpenseDesc
       SET TaxName = ISNULL(D.TaxName, ''),
           TaxUnit = ISNULL(D.TaxUnit, 0)
      FROM #TSLExpExpenseDesc       AS A
      JOIN _TSLExpExpense           AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND A.ExpenseSeq = B.ExpenseSeq
      LEFT OUTER JOIN _TDADept      AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND B.DeptSeq = C.DeptSeq
      LEFT OUTER JOIN _TDATaxUnit   AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND C.TaxUnit = D.TaxUnit    
    
    SELECT * FROM #TSLExpExpenseDesc 
    
    RETURN 
go
 begin tran 
 exec KPXCM_SSLExpExpenseDescSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <ExpenseSeq>1000039</ExpenseSeq>
    <ExpenseSerl>1</ExpenseSerl>
    <UMExpenseGroupName>수입Payment</UMExpenseGroupName>
    <UMExpenseGroup>8211001</UMExpenseGroup>
    <UMExpenseItemName>L/C 개설수수료</UMExpenseItemName>
    <UMExpenseItem>8212001</UMExpenseItem>
    <CostCustName> ㈜농심1</CostCustName>
    <CostCustSeq>12358</CostCustSeq>
    <CurrName>kks</CurrName>
    <CurrSeq>32</CurrSeq>
    <ExRate>1.00000</ExRate>
    <IsVAT>0</IsVAT>
    <IsInclusedVAT>0</IsInclusedVAT>
    <VATRate>0.00000</VATRate>
    <CurAmt>2.00000</CurAmt>
    <CurVAT>0.00000</CurVAT>
    <DomAmt>2.00000</DomAmt>
    <DomVAT>0.00000</DomVAT>
    <Remark />
    <RefBillNo />
    <AccName />
    <AccSeq>0</AccSeq>
    <VATAccName />
    <VATAccSeq>0</VATAccSeq>
    <OppAccName>외화외상매입금</OppAccName>
    <OppAccSeq>210</OppAccSeq>
    <SlipID />
    <SlipSeq>0</SlipSeq>
    <CCtrName />
    <CCtrSeq>0</CCtrSeq>
    <TotDomAmt>2.00000</TotDomAmt>
    <IsGoodAmtItem>0</IsGoodAmtItem>
    <CostDate>20150901</CostDate>
    <EtcKey>00010000390000000001</EtcKey>
    <TaxName>(주)영림산업</TaxName>
    <TaxUnit>2</TaxUnit>
    <EvidName />
    <EvidSeq>0</EvidSeq>
    <PayCustSeq>0</PayCustSeq>
    <SMExpKind>8008004</SMExpKind>
    <PrePaymentDate xml:space="preserve">        </PrePaymentDate>
    <BizUnit>26</BizUnit>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031958,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=5070
rollback 