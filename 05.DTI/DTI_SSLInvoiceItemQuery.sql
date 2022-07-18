
IF OBJECT_ID('DTI_SSLInvoiceItemQuery') IS NOT NULL 
    DROP PROC DTI_SSLInvoiceItemQuery 
GO 

-- v2014.01.22 

-- Copy by����õ

-- Ver.20130710
  /*********************************************************************************************************************    
     ȭ��� : �ŷ�����_������ȸ    
     SP Name: DTI_SSLInvoiceItemQuery    
     �ۼ��� : 2008.08.13 : CREATEd by ������        
     ������ : 2011.12.10 : Price �߰� modify by ������
 ********************************************************************************************************************/    
  -- �ŷ������Է� - ��ȸ 
 CREATE PROC DTI_SSLInvoiceItemQuery      
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.    
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS           
     DECLARE @docHandle    INT,      
             @InvoiceSerl  INT,
             @CustSeq      INT
      -- ���� ����Ÿ ��� ����    
     CREATE TABLE #TSLInvoiceItem (WorkingTag NCHAR(1) NULL)    
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSLInvoiceItem'     
      SELECT @InvoiceSerl = InvoiceSerl
       FROM #TSLInvoiceItem
     
     -- �ŷ�óǰ���Ī�� ������������ �ŷ�ó�ڵ� ��ȸ
     SELECT @CustSeq = B.CustSeq
       FROM #TSLInvoiceItem AS A 
             LEFT OUTER JOIN _TSLInvoice AS B WITH(NOLOCK) ON B.CompanySeq   = @CompanySeq
                                                          AND A.InvoiceSeq   = B.InvoiceSeq
     
     -- ȯ�漳�� �� 
     DECLARE @EnvValue1 INT, @EnvValue2 INT, @EnvValue3 INT 
     
     -- �ڱ���ȭ�ݾ� �Ҽ��� �ڸ���, ��ȭ �Ҽ��� �ڸ���  
     SELECT @EnvValue1 = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 15  
     
     -- ��ȭ�ΰ����Ҽ���ó��(�Ǹ�)  
     SELECT @EnvValue2 = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8040 -- 1003001(�ݿø�), 1003002(����), 1003003(�ø�)  
       
     -- ��ȭ�ݾ׼Ҽ���ó��(�Ǹ�)  
     SELECT @EnvValue3 = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8041  
     --select * from #TSLInvoiceItem 
     --return 
     SELECT B.InvoiceSeq             AS InvoiceSeq,      --�ŷ�������ȣ    
            B.InvoiceSerl            AS InvoiceSerl,     --�ŷ���������    
            C.ItemName               AS ItemName,        --ǰ��    
            B.ItemSeq                AS ItemSeq,         --ǰ���ڵ�    
            C.ItemNo                 AS ItemNo,          --ǰ��    
            C.Spec                   AS Spec,            --�԰�    
            B.ItemPrice              AS ItemPrice,       --ǰ��ܰ�    
            B.CustPrice              AS CustPrice,       --ȸ��ܰ�    
            D.UnitName               AS UnitName,        --�ǸŴ���    
            B.UnitSeq                AS UnitSeq,         --�ǸŴ����ڵ�    
            ISNULL(B.Qty, 0)         AS Qty,             --����    
            B.IsInclusedVAT          AS IsInclusedVAT,   --�ΰ�������    
            ISNULL(B.VATRate, 0)     AS VATRate,         --�ΰ�����    
            ISNULL(B.CurAmt, 0)      AS CurAmt,          --�Ǹűݾ�    
            ISNULL(B.CurVAT, 0)      AS CurVAT,          --�ΰ�����    
            ISNULL(B.CurAmt, 0) + ISNULL(B.CurVAT, 0) AS TotAmt,          --�հ�ݾ�    
            
            --ISNULL(B.DomAmt, 0)      AS DomAmt,          --��ȭ�Ǹűݾ�    
            --ISNULL(B.DomVAT, 0)      AS DomVAT,          --��ȭ�ΰ�����    
            --ISNULL(B.DomAmt, 0) + ISNULL(B.DomVAT, 0) AS TotDomAmt,  --��ȭ�Ǹűݾװ�    
            CASE @EnvValue3 WHEN 1003001 THEN ROUND( B.DomAmt, @EnvValue1 )  
                            WHEN 1003002 THEN ROUND( B.DomAmt, @EnvValue1, 1 )  
                            WHEN 1003003 THEN CEILING( CASE @EnvValue1 WHEN 0 THEN B.DomAmt ELSE B.DomAmt*POWER(10,@EnvValue1) END )  
                            END AS DomAmt,
            CASE @EnvValue2 WHEN 1003001 THEN ROUND( B.DomVAT, @EnvValue1 )  
                            WHEN 1003002 THEN ROUND( B.DomVAT, @EnvValue1, 1 )  
                            WHEN 1003003 THEN CEILING( CASE @EnvValue1 WHEN 0 THEN B.DomVAT ELSE B.DomVAT*POWER(10,@EnvValue1) END )  
                END AS DomVAT,
            (CASE @EnvValue3 WHEN 1003001 THEN ROUND( B.DomAmt, @EnvValue1 )  
                             WHEN 1003002 THEN ROUND( B.DomAmt, @EnvValue1, 1 )  
                             WHEN 1003003 THEN CEILING( CASE @EnvValue1 WHEN 0 THEN B.DomAmt ELSE B.DomAmt*POWER(10,@EnvValue1) END )  
                             END) 
            +
            (CASE @EnvValue2 WHEN 1003001 THEN ROUND( B.DomVAT, @EnvValue1 )  
                             WHEN 1003002 THEN ROUND( B.DomVAT, @EnvValue1, 1 )  
                             WHEN 1003003 THEN CEILING( CASE @EnvValue1 WHEN 0 THEN B.DomVAT ELSE B.DomVAT*POWER(10,@EnvValue1) END )  
                             END) AS TotDomAmt,
            CONVERT(DECIMAL(19, 5), (
            CASE WHEN B.Price IS NOT NULL
                 THEN B.Price
                 ELSE (CASE WHEN ISNULL(B.Qty,0) = 0 THEN 0 ELSE (CASE WHEN B.IsInclusedVAT = '1' THEN (ISNULL(B.CurAmt,0) + ISNULL(B.CurVat,0)) / ISNULL(B.Qty,0)      
                                                                                       ELSE ISNULL(B.CurAmt,0) / ISNULL(B.Qty,0) END) END) END)
                                                                                                                                                 ) AS Price, -- �ǸŴܰ�      
            CASE WHEN ISNULL(B.ItemSeq,0)  = 0 THEN '0' ELSE (SELECT ISNULL(IsQtyChange,'0') FROM _TDAItemStock WITH (NOLOCK)      
                                                    WHERE CompanySeq = @CompanySeq AND ItemSeq = B.ItemSeq) END AS IsQtyChange, -- ���ش�����������      
            ISNULL(B.CurAmt, 0) + ISNULL(B.CurVAT, 0) AS CurAmtTotal,  --�Ǹűݾװ�    
            
            --ISNULL(B.DomAmt, 0) + ISNULL(B.DomVAT, 0) AS DomAmtTotal,  --��ȭ�Ǹűݾװ� 
            (CASE @EnvValue3 WHEN 1003001 THEN ROUND( B.DomAmt, @EnvValue1 )  
                             WHEN 1003002 THEN ROUND( B.DomAmt, @EnvValue1, 1 )  
                             WHEN 1003003 THEN CEILING( CASE @EnvValue1 WHEN 0 THEN B.DomAmt ELSE B.DomAmt*POWER(10,@EnvValue1) END )  
                             END) 
            +
            (CASE @EnvValue2 WHEN 1003001 THEN ROUND( B.DomVAT, @EnvValue1 )  
                             WHEN 1003002 THEN ROUND( B.DomVAT, @EnvValue1, 1 )  
                             WHEN 1003003 THEN CEILING( CASE @EnvValue1 WHEN 0 THEN B.DomVAT ELSE B.DomVAT*POWER(10,@EnvValue1) END )  
                             END) AS DomAmtTotal,
            
            E.UnitName               AS STDUnitName,        --���ش���    
            B.STDUnitSeq             AS STDUnitSeq,      --���ش����ڵ�    
            ISNULL(B.STDQty, 0)      AS STDQty,          --���ش�������    
            F.WHName                 AS WHName,          --â��    
            B.WHSeq                  AS WHSeq,           --â���ڵ�    
            B.Remark                 AS Remark,          --���    
            B.UMEtcOutKind           AS UMEtcOutKind,    --��Ÿ������ڵ�    
            H.MinorName              AS UMEtcOutKindName,--��Ÿ�����    
            B.TrustCustSeq           AS TrustCustSeq,     
            G.CustName               AS TrustCustName,     
            B.LotNo                  AS LotNo,     
            B.SerialNo               AS SerialNo,    
            S.AccSeq                 AS AccSeq,  
            ISNULL((SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = S.AccSeq),'') AS AccName , 
            B.PJTSeq                 AS PJTSeq,
            B.WBSSeq                 AS WBSSeq,
            P.PJTName                AS PJTName,
            P.PJTNo                  AS PJTNo,
            W.WBSName                AS WBSName,
            ISNULL((SELECT CCtrName FROM _TDACCtr WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CCtrSeq = B.CCtrSeq), '') AS CCtrName,
            B.CCtrSeq                AS CCtrSeq,
            L.ValiDate               AS ValiDate,
            N.CustName               AS Manufacture, -- ����ó
            A.IDX_NO                 AS IDX_NO,
            ISNULL(CASE ISNULL(M.CustItemName, '')   
                   WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                           ELSE ISNULL(M.CustItemName, '') END, '')  AS CustItemName, -- �ŷ�óǰ��  
            ISNULL(CASE ISNULL(M.CustItemNo, '')   
                   WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                           ELSE ISNULL(M.CustItemNo, '') END, '')        AS CustItemNo,   -- �ŷ�óǰ��  
            ISNULL(CASE ISNULL(M.CustItemSpec, '')   
                   WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                   ELSE ISNULL(M.CustItemSpec, '') END, '')  AS CustItemSpec,  -- �ŷ�óǰ��԰�  
            --ISNULL(M.CustItemName, '')  AS CustItemName, -- �ŷ�óǰ��
            --ISNULL(M.CustItemNo, '')    AS CustItemNo,   -- �ŷ�óǰ��
            --ISNULL(M.CustItemSpec, '')  AS CustItemSpec  -- �ŷ�óǰ��԰�
            B.Dummy1,
            B.Dummy2,
            B.Dummy3,
            B.Dummy4,
            B.Dummy5,
            B.Dummy6,
            B.Dummy7,
            B.Dummy8,
            B.Dummy9,
            B.Dummy10, 
            CASE WHEN EXISTS (SELECT 1 
                                FROM #TSLInvoiceItem AS A 
                                JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq ) -- AND B.InvoiceSerl = A.InvoiceSerl ) 
                                JOIN _TSLOrderItem   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.OrderSeq = B.ProgFromSeq AND C.OrderSerl = B.ProgFromSerl ) 
                                JOIN DTI_TSLContractMngItem AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ContractSeq = CONVERT(INT,C.Dummy6) AND D.Contractserl = CONVERT(INT,C.Dummy7) )
                             )
                 THEN '1' 
                 ELSE '0'
                 END AS IsContract 
                                        
       FROM #TSLInvoiceItem AS A 
             JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON A.InvoiceSeq = B.InvoiceSeq
                                                   AND (@InvoiceSerl IS NULL OR A.InvoiceSerl = B.InvoiceSerl)
             JOIN _TSLInvoice     AS J WITH(NOLOCK) ON J.CompanySeq = @CompanySeq
                                                   AND B.InvoiceSeq = J.InvoiceSeq
             JOIN _TDAItem        AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq    
                                                   AND B.ItemSeq    = C.ItemSeq    
             LEFT OUTER JOIN _TDAUnit   AS D WITH(NOLOCK) ON B.CompanySeq = D.CompanySeq    
                                                         AND B.UnitSeq    = D.UnitSeq    
             LEFT OUTER JOIN _TDAUnit   AS E WITH(NOLOCK) ON B.CompanySeq = E.CompanySeq    
                                                         AND B.STDUnitSeq = E.UnitSeq    
             LEFT OUTER JOIN _TDAWH     AS F WITH(NOLOCK) ON B.CompanySeq = F.CompanySeq    
                                                         AND B.WHSeq      = F.WHSeq    
             LEFT OUTER JOIN _TDACust   AS G WITH(NOLOCK) ON B.CompanySeq   = G.CompanySeq    
                                                         AND B.TrustCustSeq = G.CustSeq    
             LEFT OUTER JOIN _TDAUMinor AS H WITH(NOLOCK) ON B.CompanySeq   = H.CompanySeq    
                                                         AND B.UMEtcOutKind = H.MinorSeq    
             LEFT OUTER JOIN _TDASMinorValue AS K WITH (NOLOCK) ON K.CompanySeq = @CompanySeq
                                                               AND J.SMExpKind  = K.MinorSeq
                                                               AND K.Serl       = 1004
             LEFT OUTER JOIN _TDAItemAssetAcc AS S WITH (NOLOCK) ON C.CompanySeq = S.CompanySeq  
                                                                AND C.AssetSeq   = S.AssetSeq  
                                                                AND K.ValueSeq   = S.AssetAccKindSeq
             LEFT OUTER JOIN _TPJTProject AS P WITH (NOLOCK) ON B.CompanySeq = P.CompanySeq
                                                            AND B.PJTSeq     = P.PJTSeq
             LEFT OUTER JOIN _TPJTWBS AS W WITH (NOLOCK) ON B.CompanySeq = W.CompanySeq
                                                        AND B.PJTSeq     = W.PJTSeq
                                                        AND B.WBSSeq     = W.WBSSeq
             LEFT OUTER JOIN _TLGLotMaster AS L WITH(NOLOCK) ON L.CompanySeq = @CompanySeq
                                                            AND B.LotNo      = L.LotNo
                                                            AND B.ItemSeq    = L.ItemSeq
             LEFT OUTER JOIN _TDACust   AS N WITH(NOLOCK) ON L.CompanySeq   = N.CompanySeq    
                                                         AND L.CustSeq = N.CustSeq    
             LEFT OUTER JOIN _TSLCustItem  AS M WITH(NOLOCK) ON B.CompanySeq = M.CompanySeq
                                                            AND B.ItemSeq    = M.ItemSeq
                                                            AND M.CustSeq    = @CustSeq
                                                            AND B.UnitSeq    = M.UnitSeq
             
      WHERE B.CompanySeq = @CompanySeq
      ORDER BY B.InvoiceSerl
              
     RETURN
GO
exec DTI_SSLInvoiceItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <InvoiceSeq>1001222</InvoiceSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016111,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001633