IF OBJECT_ID('KPXLS_SSLImpDelvSheetQuery') IS NOT NULL 
    DROP PROC KPXLS_SSLImpDelvSheetQuery
GO 

-- Ver.20140516
  /*********************************************************************************************************************      
     ȭ��� : ���Ը����Ʈ��ȸ      
     SP Name: _SSLImpDelvSheetQuery      
     �ۼ��� : 2008.12.17 : CREATEd by           
     ������ : 2013.11.28 Memo�÷� ��ȸ�߰�    by ������  
 ********************************************************************************************************************/      
 CREATE PROC KPXLS_SSLImpDelvSheetQuery        
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
             @DelvSerl     INT
   
     -- ���� ����Ÿ ��� ����      
     CREATE TABLE #TUIImpDelvItem (WorkingTag NCHAR(1) NULL)      
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TUIImpDelvItem'       
   
     SELECT @DelvSerl = DelvSerl
       FROM #TUIImpDelvItem
      -- ��õ���̺�  
     CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))          
   
     -- ��õ ������ ���̺�  
     CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,          
                                       Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))                
   
     -- ���� ������ ���̺�  
     CREATE TABLE #TUIImpDelv (IDX_NO  INT IDENTITY, DelvSeq INT, DelvSerl INT, PONo NVARCHAR(30) NULL, 
                               PaymentNo NVARCHAR(30) NULL, InvoiceNo NVARCHAR(30) NULL, BLNo NVARCHAR(30) NULL, PermitNo NVARCHAR(30) NULL,
                               POSeq INT NULL, PaymentSeq INT NULL, InvoiceSeq INT NULL, BLSeq INT NULL, PermitSeq INT NULL)   
      INSERT INTO #TUIImpDelv(DelvSeq, DelvSerl)
     SELECT A.DelvSeq, A.DelvSerl
       FROM #TUIImpDelvItem AS X   
             JOIN _TUIImpDelvItem AS A WITH(NOLOCK) ON X.DelvSeq = A.DelvSeq  
                                                     AND (@DelvSerl is null OR X.DelvSerl = A.DelvSerl)   
             JOIN _TUIImpDelv    AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq
                                                  AND A.DelvSeq    = F.DelvSeq 
      WHERE A.CompanySeq = @CompanySeq      
  
     -- ��õ���̺�  
     INSERT #TMP_SOURCETABLE    
     SELECT 1, '_TPUORDPOItem'       --����Order
     UNION
     SELECT 2, '_TSLImpPaymentItem'  --����Payment
     UNION
     SELECT 3, '_TUIImpInvoiceItem'  --����Invoice
     UNION
     SELECT 4, '_TUIImpBLItem'       --����BL
     UNION
     SELECT 5, '_TUIImpPermitItem'     --���ԽŰ�����
      --     ��õ������ ã�� (�ŷ����� ������)  
     EXEC _SCOMSourceTracking @CompanySeq, '_TUIImpDelvItem', '#TUIImpDelv', 'DelvSeq', 'DelvSerl', ''  
  
     UPDATE #TUIImpDelv
        SET PONo      = (SELECT PORefNo FROM _TSLImpOrder WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND POSeq = B.Seq),
            POSeq     = B.Seq
       FROM #TUIImpDelv AS A
            JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO
      WHERE B.IDOrder = '1'
      UPDATE #TUIImpDelv
        SET PaymentNo = (SELECT PaymentRefNo FROM _TSLImpPayment WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND PaymentSeq = B.Seq),
            PaymentSeq = B.Seq
       FROM #TUIImpDelv AS A
            JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO
      WHERE B.IDOrder = '2'
      UPDATE #TUIImpDelv
        SET InvoiceNo = (SELECT InvoiceRefNo FROM _TUIImpInvoice WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND InvoiceSeq = B.Seq),
            InvoiceSeq = B.Seq
       FROM #TUIImpDelv AS A
            JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO
      WHERE B.IDOrder = '3'
      UPDATE #TUIImpDelv
        SET BLNo      = (SELECT BLRefNo FROM _TUIImpBL WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BLSeq = B.Seq),
            BLSeq     = B.Seq
 FROM #TUIImpDelv AS A
            JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO
      WHERE B.IDOrder = '4'
      UPDATE #TUIImpDelv
        SET PermitNo  = (SELECT PermitRefNo FROM _TUIImpPermit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND PermitSeq = B.Seq),
            PermitSeq = B.Seq
       FROM #TUIImpDelv AS A
            JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO
      WHERE B.IDOrder = '5'
  /***********************************************************************************************************************************************/   
      
     SELECT A.DelvSeq AS DelvSeq,    -- Delv�ڵ�
            A.DelvSerl AS DelvSerl,    -- Delv����
            A.ItemSeq AS ItemSeq,    -- ǰ��
            A.UnitSeq AS UnitSeq,    -- ����
            --A.ItemSeq AS ItemSeq,    -- �ܰ�
            A.Qty AS Qty,    -- ����
            --A.Price AS Price, --��ȭ�ܰ�
            --CASE WHEN ISNULL(A.Qty,0) = 0 THEN 0 ELSE ISNULL(A.CurAmt,0) / ISNULL(A.Qty,0) END AS Price,    -- �ǸŴܰ� 
            CASE WHEN A.Price IS NOT NULL
                 THEN A.Price
                 ELSE (CASE WHEN ISNULL(A.Qty,0) = 0 THEN 0 ELSE ISNULL(A.CurAmt,0) / ISNULL(A.Qty,0) END) END AS Price,    -- �ǸŴܰ� 
             CASE WHEN ISNULL(A.Qty,0) = 0
                 THEN 0
                 ELSE (CASE WHEN ISNULL(M.BasicAmt,0) = 0
                            THEN (F.ExRate * A.Price)  
                            ELSE ((F.ExRate / M.BasicAmt) * A.Price) END) END AS DomPrice,  --��ȭ�ܰ�
             A.CurAmt AS CurAmt,    -- �ݾ�
            A.DomAmt AS DomAmt,    -- ��ȭ�ݾ�
      A.WHSeq AS WHSeq,
      A.LotNo AS LotNo,
      A.FromSerl AS FromSerlNo,
      A.ToSerl AS ToSerlNo,
      A.ProdDate AS ProdDate,
            ISNULL(A.STDUnitSeq,'0') AS STDUnitSeq,    -- ���ش���
            A.STDQty AS STDQty,    -- ���ش�������
            B.ItemName AS ItemName,    -- ǰ��
            B.ItemNo AS ItemNo,    -- ǰ��
            C.UnitName AS UnitName,    -- ������
            D.UnitName AS STDUnitName,    -- ���ش�����
            B.Spec AS Spec,    -- �԰�
      E.WHName AS WHName,
            CASE WHEN ISNULL(A.ItemSeq,0)  = 0 THEN '0' ELSE (SELECT ISNULL(IsQtyChange,'0') FROM _TDAItemStock WITH (NOLOCK)  
                                                    WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq) END AS IsQtyChange,    -- ���ش�����������  
            ISNULL(A.OKCurAmt,0) AS OKCurAmt,
            ISNULL(A.OKDomAmt,0) AS OKDomAmt,
            ISNULL(A.AccSeq,0) AS AccSeq,
            ISNULL(A.VATAccSeq,0) AS VATAccSeq,
            ISNULL(A.OppAccSeq,0) AS OppAccSeq,
            ISNULL(A.SlipSeq,0) AS SlipSeq,
            ISNULL(A.IsCostCalc,'') AS IsCostCalc,
            ISNULL((SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = A.AccSeq),'') AS AccName,
            ISNULL((SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = A.VATAccSeq),'') AS VATAccName,
            ISNULL((SELECT AccName FROM _TDAAccount WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = A.OppAccSeq),'') AS OppAccName,
            --ISNULL((SELECT SlipID FROM _TACSlipRow WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipSeq = A.SlipSeq),0) AS SlipSeq,
            X.IDX_NO         AS IDX_NO,
            A.PJTSeq         AS PJTSeq,
            P.PJTName        AS PJTName,
            P.PJTNo          AS PJTNo,
            A.WBSSeq         AS WBSSeq,
      A.MakerSeq       AS MakerSeq,
      (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.MakerSeq) AS MakerName,
            H.PONo           AS PONo,
            H.PaymentNo      AS PaymentNo,
            H.InvoiceNo      AS InvoiceNo,
            H.BLNo           AS BLNo,
            H.PermitNo       AS PermitNo,
            H.POSeq          AS POSeq,
            H.PaymentSeq     AS PaymentSeq,
            H.InvoiceSeq     AS InvoiceSeq,
            H.BLSeq          AS BLSeq,
            H.PermitSeq      AS PermitSeq, 
            A.Remark         AS Remark,
            A.Memo1          AS Memo1,  --By ������ 2013.11.28
            A.Memo2          AS Memo2,
            A.Memo3          AS Memo3,
            A.Memo4          AS Memo4,
            A.Memo5          AS Memo5,
            A.Memo6          AS Memo6,
            A.Memo7          AS Memo7,
            A.Memo8          AS Memo8,
            O.CCtrName       AS CCtrName,  -- ������(2014) Ȱ������ �߰� 2014-10-10       
            O.CCtrSeq        AS CCtrSeq, 
            K.OKQty, 
            K.BadQty, 
            L.TestDate AS QCDate, 
            CONVERT(NCHAR(8),L.CfmDateTime,112) AS CfmDate, 
            CONVERT(INT,0) AS SMTestResult, 
            CONVERT(NVARCHAR(200),'') AS SMTestResultName, 
            G.ReqSeq, 
            G.ReqSerl, 
            CASE WHEN G.CompanySeq IS NULL THEN '0' ELSE '1' END AS IsRequest 
       INTO #Result 
       FROM #TUIImpDelvItem AS X   
             JOIN _TUIImpDelvItem AS A WITH(NOLOCK) ON X.DelvSeq = A.DelvSeq  
                                                   AND (@DelvSerl is null OR X.DelvSerl = A.DelvSerl)   
             JOIN _TUIImpDelv     AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq
                                                   AND A.DelvSeq    = F.DelvSeq 
             JOIN #TUIImpDelv     AS H WITH(NOLOCK) ON A.DelvSeq    = H.DelvSeq
                                                   AND A.DelvSerl   = H.DelvSerl
         JOIN _TDAItem   AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq      
                                                         AND A.ItemSeq    = B.ItemSeq    
             LEFT OUTER JOIN _TDAUnit   AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq      
                                                         AND A.UnitSeq    = C.UnitSeq
             LEFT OUTER JOIN _TDAUnit   AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
                                                         AND A.STDUnitSeq = D.UnitSeq
            LEFT OUTER JOIN _TDAWH   AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq 
                                                         AND A.WHSeq = E.WHSeq 
             LEFT OUTER JOIN _TPJTProject AS P WITH(NOLOCK) ON A.CompanySeq = P.CompanySeq
                                                           AND A.PJTSeq  = P.PJTSeq
             LEFT OUTER JOIN _TDACurr AS M WITH(NOLOCK) ON M.CompanySeq = F.CompanySeq
                                                       AND F.CurrSeq    = M.CurrSeq
             LEFT OUTER JOIN _TDACCtr AS O WITH(NOLOCK) ON P.CompanySeq = O.CompanySeq    -- ������(2014) Ȱ������ �߰� 2014-10-10
                                                       AND P.CCtrSeq    = O.CCtrSeq 
        LEFT OUTER JOIN KPXLS_TQCRequestItem    AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.SourceSeq = A.DelvSeq AND G.SourceSerl = A.DelvSerl ) 
        LEFT OUTER JOIN KPXLS_TQCRequest        AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.ReqSeq = G.ReqSeq AND I.SMSourceType = 1000522007 AND I.PgmSeq = CASE WHEN A.Memo3 = '1' THEN 1027881 ELSE 1027845 END ) 
        LEFT OUTER JOIN KPX_TQCTestResult       AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.ReqSeq = G.ReqSeq AND K.ReqSerl = G.ReqSerl ) 
        LEFT OUTER JOIN KPXLS_TQCTestResultAdd  AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND K.QCSeq = L.QCSeq ) 
      WHERE A.CompanySeq = @CompanySeq      
    
    

    UPDATE A  
       SET A.SMTestResult    = 1010418004   --�̰˻�  
      FROM #Result AS A   
                                            LEFT OUTER JOIN KPX_TQCTestResult AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                               AND C.ReqSeq = A.ReqSeq  
                                                                                               AND C.ReqSerl    = A.ReqSerl  
                                            LEFT OUTER JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                               AND B.QCSeq      = C.QCSeq  
    WHERE ISNULL(B.CompanySeq,0) = 0    -- ��� ����       
    
    UPDATE A  
       SET A.SMTestResult    = 1010418002  
      FROM #Result AS A JOIN KPX_TQCTestResult AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                   AND C.ReqSeq      = A.ReqSeq  
                                                                                   AND C.ReqSerl        = A.ReqSerl  
                                            JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                        AND B.QCSeq      = C.QCSeq  
    WHERE ISNULL(A.SMTestResult,0) = 0  
      AND ISNULL(B.SMTestResult ,0) = 6035004   --���հ�  
      AND ISNULL(B.IsSpecial, '') <> '1'  
  
    UPDATE A  
       SET A.SMTestResult    = 1010418003   --Ưä  
      FROM #Result AS A JOIN KPX_TQCTestResult AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                   AND C.ReqSeq      = A.ReqSeq  
                                                                                   AND C.ReqSerl        = A.ReqSerl  
                                            JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                        AND B.QCSeq      = C.QCSeq  
    WHERE ISNULL(A.SMTestResult,0) = 0  
      AND ISNULL(B.IsSpecial, '') = '1'  
  
    
    UPDATE A  
       SET A.SMTestResult    = CASE B.SMTestResult WHEN 6035001 /*���˻�*/ THEN 1010418005 --���˻�  
                                                   WHEN 6035003            THEN 1010418001 END  
      FROM #Result AS A JOIN KPX_TQCTestResult AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                   AND C.ReqSeq      = A.ReqSeq  
                                                                                   AND C.ReqSerl        = A.ReqSerl  
                                            JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                        AND B.QCSeq      = C.QCSeq  
    WHERE ISNULL(A.SMTestResult,0) = 0  
  
    UPDATE A  
       SET A.SMTestResultName   = B.MinorName  
      FROM #Result AS A JOIN _TDAUMinor AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.SMTestResult = B.MinorSeq  
    
    SELECT * FROM #Result 
    
     RETURN
     go
     exec KPXLS_SSLImpDelvSheetQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <DelvSeq>1000182</DelvSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033909,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028083