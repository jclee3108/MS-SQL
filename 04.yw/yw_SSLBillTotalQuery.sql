  
IF OBJECT_ID('yw_SSLBillTotalQuery') IS NOT NULL   
    DROP PROC yw_SSLBillTotalQuery  
GO  

 --v2013.08.26 
  
-- �Ǻ����ݰ�꼭 �������_YW(��ȸ) by����õ
 CREATE PROC yw_SSLBillTotalQuery        
     @xmlDocument    NVARCHAR(MAX),      
     @xmlFlags       INT = 0,      
     @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.      
     @WorkingTag     NVARCHAR(10)= '',      
     @CompanySeq     INT = 1,      
     @LanguageSeq    INT = 1,      
     @UserSeq        INT = 0,      
     @PgmSeq         INT = 0      
 AS             
     DECLARE @docHandle      INT,        
             @BizUnit        INT,       
             @InvoiceDateFr  NCHAR(8),       
             @InvoiceDateTo  NCHAR(8),       
             @SMExpKind      INT,       
             @UMOutKInd      INT,       
             @SMVatKind      INT,       
             @DeptSeq        INT,       
             @EmpSeq         INT,       
             @InvoiceCustSeq INT,  
             @CustSeq        INT,  
             @CurrSeq        INT,  
             @IsSalesWith    NCHAR(1),
             @UMChannel      INT, 
             @ItemKind       INT
  
  
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument       
       
     SELECT @BizUnit        = ISNULL(BizUnit,0),       
            @InvoiceDateFr  = ISNULL(InvoiceDateFr,''),       
            @InvoiceDateTo  = ISNULL(InvoiceDateTo,''),       
            @UMOutKind      = ISNULL(UMOutKind,0),       
            @SMExpKind      = ISNULL(SMExpKind,0),       
            @SMVatKind      = ISNULL(SMVatKind,0),       
            @DeptSeq        = ISNULL(DeptSeq,0),       
            @EmpSeq         = ISNULL(EmpSeq,0),       
            @InvoiceCustSeq = ISNULL(InvoiceCustSeq,0),  
            @CurrSeq        = ISNULL(CurrSeq,0),  
            @CustSeq        = ISNULL(CustSeq,0),
            @UMChannel      = ISNULL(UMChannel,0), 
            @ItemKind       = ISNULL(ItemKind,0)
       
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)           
       WITH (BizUnit        INT,      
             InvoiceDateFr  NCHAR(8),     
             InvoiceDateTo  NCHAR(8),     
             UMOutKind      INT,      
             SMExpKind      INT,  
             SMVatKind      INT,  
             DeptSeq        INT,           
             EmpSeq         INT,      
             InvoiceCustSeq INT,  
             CurrSeq        INT,  
             CustSeq        INT,
             UMChannel      INT, 
             ItemKind       INT
            )
                   
    IF @InvoiceDateTo = '' SELECT @InvoiceDateTo = '99991231'       
    
    -- ���⵿�ÿ���  
    SELECT @IsSalesWith = ISNULL(ValueText,'0')  
      FROM _TDAUMinorValue WITH(NOLOCK)   
     WHERE CompanySeq = @CompanySeq    
       AND MinorSeq   = @UMOutKind  
       AND Serl       = 2001    
   
   
 /*****************************************  �������  *****************************************************************************************/      
     CREATE TABLE #TmpInvoiceProg  
     (      
         IDX_NO INT IDENTITY,   
         InvoiceSeq INT,   
         InvoiceSerl INT,   
         SalesSeq INT,   
         SalesSerl INT,   
         Qty DECIMAL(19, 5),   
         STDQty DECIMAL(19, 5),   
         CurAmt DECIMAL(19, 5),   
         CurVAT DECIMAL(19, 5),     
         RemQty DECIMAL(19, 5),   
         RemSTDQty DECIMAL(19, 5),   
         RemAmt    DECIMAL(19, 5),   
         RemVAT    DECIMAL(19, 5),   
         RemDomAmt DECIMAL(19, 5),   
         RemDomVAT DECIMAL(19, 5),   
         IsExists INT,  
         CompleteCode INT,  
         SMSalesCrtKind INT,  
         AccSeq    INT, 
         ItemKind   INT
     )    
   
    INSERT #TmpInvoiceProg(
                            InvoiceSeq, InvoiceSerl, SalesSeq, SalesSerl, Qty, 
                            STDQty, CurAmt, CurVAT, RemQty, RemSTDQty, 
                            RemAmt, RemVAT, RemDomAmt, RemDomVAT, IsExists, 
                            CompleteCode, SMSalesCrtKind, AccSeq,ItemKind
                          )
    SELECT B.InvoiceSeq, B.InvoiceSerl, 0, 0, B.Qty, 
           B.STDQty, B.CurAmt, B.CurVAT, B.Qty, B.STDQty, 
           B.CurAmt, B.CurVAT, B.DomAmt, B.DomVAT, 0, 
           0, ISNULL(E.SMSalesPoint,8017002), ISNULL(H.AccSeq, 0), J.MngValSeq  
    
      FROM _TSLInvoice AS A WITH(NOLOCK)    
      JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.InvoiceSeq = B.InvoiceSeq ) 
      LEFT OUTER JOIN _TDACustGroup AS C WITH(NOLOCK) ON ( A.CompanySeq  = C.CompanySeq AND A.CustSeq = C.CustSeq AND C.UMCustGroup = 8014002 ) 
      LEFT OUTER JOIN _TDAItemSales AS D WITH(NOLOCK) ON ( B.CompanySeq = D.CompanySeq AND B.ItemSeq = D.ItemSeq ) 
      LEFT OUTER JOIN _TDACustSalesReceiptCond AS E WITH(NOLOCK) ON ( C.CompanySeq = E.CompanySeq AND C.UpperCustSeq = E.CustSeq ) 
      LEFT OUTER JOIN _TDASMinorValue AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND A.SMExpKind = F.MinorSeq AND F.Serl = 1004 ) 
      LEFT OUTER JOIN _TDAItem AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND B.ItemSeq = G.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemAssetAcc AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND G.AssetSeq = H.AssetSeq AND F.ValueSeq = H.AssetAccKindSeq ) 
      LEFT OUTER JOIN _TDACustClass AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND C.UpperCustSeq = I.CustSeq AND I.UMajorCustClass = 8004 ) 
      LEFT OUTER JOIN _TDAItemUserDefine AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.ItemSeq = G.ItemSeq AND J.MngSerl = 1000002 ) 
      
     WHERE A.CompanySeq = @CompanySeq    
       AND A.BizUnit = @BizUnit    
       AND A.InvoiceDate BETWEEN @InvoiceDateFr AND @InvoiceDateTo    
       AND (@UMOutKInd = 0 OR A.UMOutKInd = @UMOutKInd)    
       AND (@SMExpKind = 0 OR A.SMExpKind = @SMExpKind)    
       AND (@DeptSeq = 0   OR A.DeptSeq = @DeptSeq)    
       AND (@EmpSeq  = 0   OR A.EmpSeq  = @EmpSeq)     
       AND (@CurrSeq = 0   OR A.CurrSeq = @CurrSeq)    
       AND (@InvoiceCustSeq = 0 OR A.CustSeq = @InvoiceCustSeq)    
       AND (@CustSeq = 0   OR C.UpperCustSeq = @CustSeq)  
       AND (@SMVatKind = 0 OR D.SMVatKind = @SMVatKind)  
       AND A.IsDelvCfm = '1'    
       AND B.UMEtcOutKind = ''  
       AND ISNULL(E.SMReceiptMethod,0) <> 8016002 -- ��������� �ŷ�ó��  
       AND (@UMChannel = 0   OR I.UMCustClass = @UMChannel) 
       AND (@ItemKind = 0 OR @ItemKind = J.MngValSeq)
   
    UPDATE #TmpInvoiceProg
       SET SMSalesCrtKind = 8017002
     WHERE ISNULL(SMSalesCrtKind,0) = 0
    
    EXEC _SCOMProgStatus @CompanySeq, '_TSLInvoiceItem', 1036001, '#TmpInvoiceProg', 'InvoiceSeq', 'InvoiceSerl', '', 'RemQty', 'RemSTDQty', 'RemAmt', 'RemVAT','IsExists', 'CompleteCode', 1, 'Qty','STDQty','CurAmt','CurVAT','InvoiceSeq','InvoiceSerl','','', @PgmSeq    
   
 --     EXEC _SCOMProgStatus @CompanySeq, '_TSLOrderItem', 1036001, '#Tmp_OrderProg', 'OrderSeq', '', '', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', 'CurVAT', 'OrderSeq', 'OrderSerl', '', '_TSLOrder'            
 -- --   
 -- select * from #TmpInvoiceProg  
   
 -- select * from _TCOMProgRelativeTables where CompanySeq = 14  
 -- select * from _TComSourceDaily where FromSeq = 228236  
   
    DELETE #TmpInvoiceProg    
     WHERE CompleteCode = 40    
    
 --     IF @IsSalesWith = '1'  
 --     BEGIN  
    
         -- �����ȣ�������� 
    UPDATE #TmpInvoiceProg    
        SET SalesSeq  = ISNULL(Y.SalesSeq,0),  
            SalesSerl = ISNULL(Y.SalesSerl,0)  
       FROM #TmpInvoiceProg AS X  
            JOIN (SELECT InvoiceSeq, InvoiceSerl, SalesSeq, SalesSerl  
                  FROM (  
                      SELECT B.InvoiceSeq, B.InvoiceSerl, C.ToSeq AS SalesSeq, C.ToSerl AS SalesSerl, 1 AS ADD_DEL  
                        FROM #TmpInvoiceProg AS B   
                             JOIN _TCOMSource AS C WITH (NOLOCK) ON C.CompanySeq   = @CompanySeq  
                                                                     AND B.InvoiceSeq   = C.FromSeq  
                                                                     AND B.InvoiceSerl  = C.FromSerl  
                                                                     AND C.FromTableSeq = 18  
                                                                     AND C.ToTableSeq   = 20  
                     UNION ALL  
                      SELECT B.InvoiceSeq, B.InvoiceSerl, C.ToSeq AS SalesSeq, C.ToSerl AS SalesSerl, ADD_DEL  
                        FROM #TmpInvoiceProg AS B   
                             JOIN _TCOMSourceDaily AS C WITH (NOLOCK) ON C.CompanySeq   = @CompanySeq  
                                                                     AND B.InvoiceSeq   = C.FromSeq  
                                                                     AND B.InvoiceSerl  = C.FromSerl  
                                                                     AND C.FromTableSeq = 18  
                                                                     AND C.ToTableSeq   = 20  
                        ) AS K  
                 GROUP BY InvoiceSeq, InvoiceSerl, SalesSeq, SalesSerl  
                 HAVING SUM(ADD_DEL) = 1) AS Y ON X.InvoiceSeq  = Y.InvoiceSeq  
                                              AND X.InvoiceSerl = Y.InvoiceSerl  
      WHERE X.SMSalesCrtKind = 8017001  
   
   
     UPDATE #TmpInvoiceProg  
        SET RemAmt = X.RemAmt - ISNULL(Y.RemAmt,0),   
            RemVAT = X.RemVAT - ISNULL(Y.RemVAT,0),  
            RemDomAmt = X.RemDomAmt - ISNULL(Y.RemDomAmt,0),   
            RemDomVAT = X.RemDomVAT - ISNULL(Y.RemDomVAT,0)  
       FROM #TmpInvoiceProg AS X  
            JOIN (SELECT A.SalesSeq, A.SalesSerl, SUM(B.CurAmt) AS RemAmt, SUM(B.CurVAT) AS RemVAT,   
                         SUM(B.DomAmt) AS RemDomAmt, SUM(B.DomVAT) AS RemDomVAT  
                    FROM #TmpInvoiceProg AS A  
                         JOIN _TSLSalesBillRelation AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                      AND A.SalesSeq   = B.SalesSeq  
                                                                      AND A.SalesSerl  = B.SalesSerl  
                   GROUP BY A.SalesSeq, A.SalesSerl) AS Y ON X.SalesSeq  = Y.SalesSeq  
                                                         AND X.SalesSerl = Y.SalesSerl   
      WHERE X.SMSalesCrtKind = 8017001  
 --     END  
 --     ELSE  
 --     BEGIN  
   
 --     END    
   
 /***********************************************************************************************************************************************/      
     -- ����� ������� ��뿩�� �ϳ��� �����Ǳ� ������ �ּ�ó��
     --DECLARE @IsEmpCharge NCHAR(1), @IsDeptCharge NCHAR(1)
     --IF EXISTS(SELECT 1 FROM _TCOMENV where companyseq = @companyseq AND EnvSeq = 8001 AND EnvValue <> '1')
     --BEGIN
     --    SELECT @IsEmpCharge = '0', @IsDeptCharge = '0'
     --END
     --ELSE
     --BEGIN
     --    SELECT @IsDeptCharge = EnvValue FROM _TCOMENV where companyseq = @companyseq AND EnvSeq = 8002 
     --    SELECT @IsEmpCharge  = EnvValue FROM _TCOMENV where companyseq = @companyseq AND EnvSeq = 8003 
     --END
     
     --2013.02.15 �����غ���
    DECLARE @IsCharge NCHAR(1)
    EXEC @IsCharge = _SCOMEnvR @CompanySeq, 8001, @UserSeq, @@PROCID
    SELECT ISNULL((SELECT BizUnitName FROM _TDABizUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = B.BizUnit),'') AS BizUnitName,    
           B.BizUnit        AS BizUnit,    
           B.InvoiceSeq       AS InvoiceSeq,        --���ֳ��ι�ȣ      
           B.InvoiceNo        AS InvoiceNo,             
           A.InvoiceSerl      AS InvoiceSerl,       --���ּ���      
           B.InvoiceDate      AS InvoiceDate,    
           ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = B.SMExpKind),'') AS ExpKindName, -- ���ⱸ��    
           B.SMExpKind AS SMExpKind, -- ���ⱸ���ڵ�    
           ISNULL((SELECT MinorName FROM _TDAUMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = B.UMOutKind),'') AS OutKindName, --�����    
           B.UMOutKind AS UMOutKind, -- ���ֱ����ڵ�    
           ISNULL((SELECT DeptName FROM _TDADept WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = B.DeptSeq),'') AS  InvDeptName, -- �μ�    
           B.DeptSeq AS InvDeptSeq, -- �μ������ڵ�    
           ISNULL((SELECT EmpName FROM _TDAEmp WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = B.EmpSeq),'') AS  InvEmpName, -- �����    
           B.EmpSeq  AS InvEmpSeq, -- ������ڵ�  
             
           ISNULL((SELECT DeptName FROM _TDADept WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = 
                    --CASE WHEN @IsDeptCharge = '1' OR @IsEmpCharge = '1' THEN ISNULL(ISNULL(F.DeptSeq, G.DeptSeq), B.DeptSeq) ELSE B.DeptSeq END),'') AS  DeptName, -- ���ݰ�꼭�μ�    
                    -- 2013.02.15 �����غ���
                    CASE WHEN @IsCharge = '1' THEN ISNULL(ISNULL(F.DeptSeq, G.DeptSeq), B.DeptSeq) ELSE B.DeptSeq END),'') AS  DeptName, -- ���ݰ�꼭�μ�
           
           --CASE WHEN @IsDeptCharge = '1' OR @IsEmpCharge = '1' THEN ISNULL(ISNULL(F.DeptSeq, G.DeptSeq), B.DeptSeq) ELSE B.DeptSeq END AS DeptSeq, -- ���ݰ�꼭�μ������ڵ�    
           -- 2013.02.15 ������ ����
           CASE WHEN @IsCharge = '1' THEN ISNULL(ISNULL(F.DeptSeq, G.DeptSeq), B.DeptSeq) ELSE B.DeptSeq END AS DeptSeq, -- ���ݰ�꼭�μ������ڵ�    
           ISNULL((SELECT EmpName FROM _TDAEmp WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = 
                    --CASE WHEN @IsEmpCharge = '1' THEN ISNULL(ISNULL(F.EmpSeq, G.EmpSeq), B.EmpSeq) ELSE B.EmpSeq END),'') AS  EmpName, -- ���ݰ�꼭�����    
                    -- 2013.02.15 ������ ����
                    CASE WHEN @IsCharge = '1' THEN ISNULL(ISNULL(F.EmpSeq, G.EmpSeq), B.EmpSeq) ELSE B.EmpSeq END),'') AS  EmpName, -- ���ݰ�꼭�����                        
           --CASE WHEN @IsEmpCharge = '1' THEN ISNULL(ISNULL(F.EmpSeq, G.EmpSeq), B.EmpSeq) ELSE B.EmpSeq END  AS EmpSeq, -- ���ݰ�꼭������ڵ�  
           -- 2013.02.15 ������ ����  
           CASE WHEN @IsCharge = '1' THEN ISNULL(ISNULL(F.EmpSeq, G.EmpSeq), B.EmpSeq) ELSE B.EmpSeq END  AS EmpSeq, -- ���ݰ�꼭������ڵ�  
                        
           ISNULL((SELECT CustName FROM _TDACust WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = B.CustSeq),'') AS  InvoiceCustName, -- �ŷ�ó    
           ISNULL((SELECT CustNo FROM _TDACust WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = B.CustSeq),'') AS  CustNo, -- �ŷ�ó��ȣ    
           B.CustSeq AS InvoiceCustSeq, -- �ŷ�ó�����ڵ�    
           ISNULL((SELECT CustName FROM _TDACust WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = D.UpperCustSeq),'') AS  CustName, -- �ŷ�ó    
           D.UpperCustSeq AS CustSeq, -- �ŷ�ó�����ڵ�    
           ISNULL((SELECT CustName FROM _TDACust WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = B.BKCustSeq),'') AS  BKCustName, -- �߰���    
           B.BKCustSeq AS BKCustSeq, -- �߰����ڵ�    
           ISNULL((SELECT CurrName FROM _TDACurr WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CurrSeq = B.CurrSeq),'') AS  CurrName, -- ��ȭ    
           B.CurrSeq        AS CurrSeq, -- ��ȭ�����ڵ�    
           B.ExRate         AS ExRate, -- ȯ��    
           B.IsStockSales   AS IsStockSales, -- �Ǹ��� ��������    
           B.Remark         AS Remark, -- ���    
           B.Memo           AS Memo, -- �޸�    
           C.ItemName       AS ItemName,        --ǰ��      
           A.ItemSeq        AS ItemSeq,         --ǰ���ڵ�   
           C.ItemNo         AS ItemNo,          --ǰ��      
           C.Spec           AS Spec,            --�԰�      
           ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = A.UnitSeq),'') AS UnitName,        --�ǸŴ���      
           A.UnitSeq        AS UnitSeq,         --�ǸŴ����ڵ�      
           A.ItemPrice      AS ItemPrice,       --����      
           A.CustPrice      AS CustPrice,       --�Ǹű��ذ�      
 --          CASE WHEN ISNULL(A.Qty,0) = 0 THEN 0 ELSE (CASE WHEN A.IsInclusedVAT = '1' THEN (ISNULL(A.CurAmt,0) + ISNULL(A.CurVat,0)) / ISNULL(A.Qty,0)        
 --                                                                                     ELSE ISNULL(A.CurAmt,0) / ISNULL(A.Qty,0) END) END AS Price, -- �ǸŴܰ�    
            CASE WHEN A.Price IS NOT NULL
                 THEN A.Price
                 ELSE (CASE WHEN ISNULL(A.Qty,0) = 0 THEN 0 ELSE (CASE WHEN A.IsInclusedVAT = '1' THEN (ISNULL(A.CurAmt,0) + ISNULL(A.CurVat,0)) / ISNULL(A.Qty,0)        
                                                                                                  ELSE ISNULL(A.CurAmt,0) / ISNULL(A.Qty,0) END) END) END AS Price, -- �ǸŴܰ�    
  
           A.IsInclusedVAT  AS IsInclusedVAT,   --�ΰ�������      
           A.VATRate        AS VATRate,         --�ΰ�����  
           A.Qty            AS InvoiceQty,             --����      
           A.CurAmt         AS InvoiceCurAmt,          --�Ǹűݾ�      
           A.CurVAT         AS InvoiceCurVAT,     --�ΰ�����      
           ISNULL(A.CurAmt,0) + ISNULL(A.CurVAT,0) AS InvoiceCurAmtTotal,    
           A.DomAmt         AS InvoiceDomAmt,          --��ȭ�Ǹűݾ�      
           A.DomVAT         AS InvoiceDomVAT,          --��ȭ�ΰ�����      
           ISNULL(A.DomAmt,0) + ISNULL(A.DomVAT,0) AS InvoiceDomAmtTotal,        
           ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = A.STDUnitSeq),'') AS STDUnitName,     --���ش���      
           A.STDUnitSeq        AS STDUnitSeq,     --���ش����ڵ�      
           M.RemSTDQty      AS STDQty,            --���ش�������      
           M.RemQty         AS Qty,             --����      
           M.RemAmt         AS CurAmt,          --�Ǹűݾ�      
           M.RemVAT         AS CurVAT,     --�ΰ�����      
           ISNULL(M.RemAmt,0) + ISNULL(M.RemVAT,0) AS CurAmtTotal,    
           CASE WHEN A.Qty = M.RemQty THEN A.DomAmt ELSE M.RemAmt * B.ExRate END AS DomAmt,          --��ȭ�Ǹűݾ�      
           CASE WHEN A.Qty = M.RemQty THEN A.DomVAT ELSE M.RemVAT * B.ExRate END AS DomVAT,          --��ȭ�ΰ�����      
           CASE WHEN A.Qty = M.RemQty THEN A.DomAmt + A.DomVAT ELSE ISNULL(M.RemAmt * B.ExRate,0) + ISNULL(M.RemVAT * B.ExRate,0) END AS DomAmtTotal,    
           ISNULL((SELECT WHName FROM _TDAWH WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND WHSeq = A.WHSeq),'') AS WHName,          --â��      
           A.WHSeq          AS WHSeq,            --â���ڵ�      
           @IsSalesWith     AS IsSalesWith ,  
           M.SMSalesCrtKind AS SMSalesCrtKind,  
           ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = M.SMSalesCrtKind), '') AS SMSalesCrtKindName,  
           ISNULL((SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = M.AccSeq), '') AS AccName,  
           ISNULL(M.AccSeq, 0) AS AccSeq  ,
           A.LotNo          AS LotNo, 
           M.ItemKind 
    
      FROM #TmpInvoiceProg AS M    
      JOIN _TSLInvoiceItem AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND M.InvoiceSeq = A.InvoiceSeq AND M.InvoiceSerl = A.InvoiceSerl ) 
      JOIN _TSLInvoice     AS B WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.InvoiceSeq = B.InvoiceSeq ) 
      JOIN _TDAItem        AS C WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.ItemSeq = C.ItemSeq ) 
      JOIN _TDACustGroup   AS D WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = D.CustSeq AND D.UMCustGroup = 8014002 ) 
      LEFT OUTER JOIN _TDACustSalesReceiptCond AS E WITH (NOLOCK) ON ( D.CompanySeq = E.CompanySeq AND D.UpperCustSeq = E.CustSeq )  
      LEFT OUTER JOIN _TSLCustSalesEmp AS F WITH(NOLOCK) ON ( D.CompanySeq = F.CompanySeq AND D.UpperCustSeq = F.CustSeq AND F.SDate <= @InvoiceDateTo ) 
      LEFT OUTER JOIN _TSLCustSalesEmpHist AS G WITH(NOLOCK) ON ( D.CompanySeq = G.CompanySeq AND D.UpperCustSeq = G.CustSeq AND @InvoiceDateTo BETWEEN G.SDate AND G.EDate ) 
     
     WHERE ISNULL(E.SMReceiptMethod, 0) <> 8016002  
     ORDER BY B.InvoiceDate, B.InvoiceSeq, A.InvoiceSerl    
    
    DROP TABLE #TmpInvoiceProg    
    
    RETURN
    
GO
exec yw_SSLBillTotalQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BizUnit>1</BizUnit>
    <UMOutKind />
    <SMVatKind>2003001</SMVatKind>
    <SMExpKind>8009001</SMExpKind>
    <ItemKind>1008253001</ItemKind>
    <InvoiceDateFr>20130801</InvoiceDateFr>
    <InvoiceDateTo>20130823</InvoiceDateTo>
    <InvoiceCustSeq />
    <CustSeq />
    <CurrSeq />
    <DeptSeq />
    <EmpSeq />
    <UMChannel />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017309,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014801