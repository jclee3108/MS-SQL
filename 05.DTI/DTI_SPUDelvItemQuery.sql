
IF OBJECT_ID('DTI_SPUDelvItemQuery') IS NOT NULL
    DROP PROC DTI_SPUDelvItemQuery
    
GO
--v2013.06.12

-- ���ų�ǰ������ȸ_DTI (����ó/EndUser �߰�) By����õ
/*************************************************************************************************            
  ��  �� - ���ų�ǰ ��������ȸ      
  �ۼ��� - 2008.8.18 : CREATEd by �뿵��      
     
  ������ - 2010�� 10�� 21�� �̿���( MakerSeq, MakerName �߰�)  
           2011�� 02�� 10�� �̻�ȭ(����ι� �÷��߰�) 
  �������� :: ItemSeqOLD(����ǰ�ڵ�), LotNoOLD(LotNo) Select �߰�; LotNo ����(U) �ÿ� LotNoMaster�� ������Ʈ�� ���� �ʾƼ� 2011.5.11 �輼ȣ  
           :: 2011. 7. 4 hkim StdUnitQty ��� �Ǵ� �κ� ����
 *************************************************************************************************/            
CREATE PROC DTI_SPUDelvItemQuery      
    @xmlDocument    NVARCHAR(MAX),          
    @xmlFlags       INT = 0,          
    @ServiceSeq     INT = 0,          
    @WorkingTag     NVARCHAR(10)= '',          
    @CompanySeq     INT = 1,          
    @LanguageSeq    INT = 1,          
    @UserSeq        INT = 0,          
    @PgmSeq         INT = 0          
 AS 
                  
    DECLARE @docHandle INT,           
            @DelvSerl  INT,      
            @QCAutoIn  NCHAR(1)      
       
    -- ���� ����Ÿ ��� ����          
    CREATE TABLE #TPUDelvItem (WorkingTag NCHAR(1) NULL)          
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUDelvItem'         
      
    IF @@ERROR <> 0 RETURN          
          
    SELECT @DelvSerl = DelvSerl FROM #TPUDelvItem      
      
    CREATE TABLE #tem_QCData
        (      
            CompanySeq   INT,      
            DelvSeq      INT,      
            DelvSerl     INT,      
            TestEndDate  NCHAR(8),      
            Qty          DECIMAL(19,5),      
            PassedQty    DECIMAL(19,5),      
            ReqInQty     DECIMAL(19,5),      
            QCStdUnitQty DECIMAL(19,5)       
        )      
    
    -- ȯ�漳���� ��������  # ���˻�ǰ �ڵ��԰� ����      
    EXEC dbo._SCOMEnv @CompanySeq,6500,@UserSeq,@@PROCID,@QCAutoIn OUTPUT        
     
    SELECT @WorkingTag = WorkingTag FROM #TPUDelvItem      
    IF @WorkingTag = 'J'       
        GoTo Jump_Qry      
    ------------------------      
    --�԰��Ƿڼ���----------      
    ------------------------          
    INSERT INTO #tem_QCData(CompanySeq  ,DelvSeq,  DelvSerl,   TestEndDate,   Qty,     PassedQty,    ReqInQty ,QCStdUnitQty)      
         SELECT @CompanySeq,          
                B.SourceSeq,          
                B.SourceSerl,         
                SUBSTRING(TestEndDate,1,8) ,       
                A.Qty  ,      
                SUM(ISNULL(PassedQty,0)),      
                SUM(ISNULL(ReqInQty,0)),      
                SUM(ISNULL(CASE WHEN ISNULL(ConvDen,0) = 0 THEN 0 ELSE ISNULL(ReqInQty,0) * (ConvNum/ConvDen) END,0))      
           FROM #TPUDelvItem     AS A       
           JOIN _TPDQCTestReport AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq      
                                                  AND A.DelvSeq    = B.SourceSeq      
                                                  AND B.SourceType = '1'      
           JOIN _TPUDelvItem     AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq      
                                                  AND C.DelvSeq    = B.SourceSeq      
                                                  AND C.DelvSerl   = B.SourceSerl      
           LEFT OUTER JOIN _TDAItemUnit AS D WITH(NOLOCK) ON C.CompanySeq = D.CompanySeq      
                                                         AND C.ItemSeq    = D.ItemSeq      
                                                         AND C.UnitSeq    = D.UnitSeq      
            GROUP BY B.SourceSeq, B.SourceSerl,A.Qty,B.TestEndDate      
        
    ------------------------      
    --�԰��Ƿڼ��� END------      
    ------------------------      
     
    --------------        
    --��ȸ���  ���߿� �� ���� �����ϱ�(ȯ��Ȯ���ؾ���)      
    --------------        
    SELECT M.DelvNo                    AS DelvNo           ,      
           D.DelvSeq                   AS DelvSeq          ,      
           D.DelvSerl                  AS DelvSerl         ,      
           I.ItemName                  AS ItemName         ,     -- ǰ��        
           I.ItemNo                AS ItemNo           ,     -- ǰ��        
           I.Spec                      AS Spec             ,     -- �԰�        
           ISNULL(U.UnitName,'')       AS UnitName         ,     -- ����        
           ISNULL(D.Price,0)           AS Price            ,     -- �ܰ�        
           ISNULL(D.Qty,0)             AS Qty              ,     -- ��ȸ��ǰ����        
           ISNULL(D.CurAmt,0)          AS CurAmt           ,     -- �ݾ�        
           ISNULL(D.CurAmt,0) + ISNULL(D.CurVAT,0)        
                                       AS TotCurAmt        ,     -- �ݾ�        
           ISNULL(D.DomPrice,0)        AS DomPrice         ,     -- ��ȭ�ܰ�            
           ISNULL(D.DomAmt,0)          AS DomAmt           ,     -- ��ȭ�ݾ�        
           ISNULL(D.DomAmt,0) + ISNULL(D.DomVAT,0)            
                                       AS TotDomAmt        ,     -- ��ȭ�ݾ�        
           ISNULL(D.CurVAT,0)          AS CurVAT           ,     -- �ΰ���      
           ISNULL(D.DomVAT,0)          AS DomVAT           ,     -- ��ȭ�ΰ���        
           ISNULL(D.IsVAT,'')          AS IsVAT            ,     -- �ΰ������Կ���      
           --ISNULL(AA.VATRate,0)        AS VATRate          ,     -- �ΰ�����      
           CASE WHEN ISNULL(R.ValueText,'') <> '1' AND 
                     ISNULL(S.ValueText,'') <> '1' THEN (CASE V.SMVatKind WHEN 2003001 THEN ISNULL(Q.VatRate,0) ELSE 0 END)
                                                   ELSE 0 END AS VATRate, -- �ΰ�����
           ISNULL(L.WHName ,'')        AS WHName           ,     -- â��      
           ISNULL(D.WhSeq,0)           AS WHSeq            ,     -- ��ǰ���(â��)�ڵ�         
           K.CustName                  AS DelvCustName     ,     -- ��ǰó               
           ISNULL(D.DelvCustSeq, '')   AS DelvCustSeq      ,     -- ��ǰó�ڵ�                   
           --ISNULL(H.CustName , '')     AS SalesCustName    ,     -- �����ŷ�ó��           
           --ISNULL(D.SalesCustSeq, '')  AS SalesCustSeq     ,     -- �����ŷ�ó                 
           ''                          AS SMQcTypeName     ,     -- �˻籸��      
           ISNULL(D.SMQcType,'')       AS SMQcType         ,     -- �˻籸��      
           ISNULL(E.UnitName,'')       AS StdUnitName      ,     -- ����(������)        
           ISNULL(E.UnitSeq,'')        AS StdUnitSeq      ,     -- ����(������)        
           ISNULL(D.stdUnitQty,0)      AS StdUnitQty       ,     -- ����������        
           ( ISNULL(F.ConvNum,0)  / (CASE WHEN ISNULL(F.ConvDen,1) = 0 THEN 1 ELSE  ISNULL(F.ConvDen,1) END)) AS StdConvQty , -- ������ȯ�����      
           ISNULL(D.ItemSeq,'')        AS ItemSeq          ,     -- ǰ���ڵ�        
           ISNULL(D.UnitSeq,'')        AS UnitSeq          ,     -- �����ڵ�        
           ISNULL(D.LotNo,'')          AS LotNo            ,        
           ISNULL(D.FROMSerial,'')     AS FromSerial           ,        
           ISNULL(D.Toserial,'')       AS Toserial         ,              
           ISNULL(D.DelvSerl,'')       AS DelvSerl         ,     -- ��ǰ����        
           ISNULL(D.Remark,'')         AS Remark           ,        
           ISNULL(J.IsLotMng,'')       AS LotMngYN         ,      
           ISNULL(M.CurrSeq,0)         AS CurrSeq          ,     -- �����԰������� �ʿ�      
           ISNULL(M.ExRate,0)          AS ExRate           ,     -- �����԰������� �ʿ�      
           ISNULL(C.CurrName,'')       AS CurrName         ,     -- �����԰������� �ʿ�      
           Z.IDX_NO                    AS IDX_NO           ,      
           D.PJTSeq                    AS PJTSeq           ,     -- ������Ʈ�ڵ�      
           P.PJTName                   AS PJTName          ,     -- ������Ʈ      
           P.PJTNo                     AS PJTNo            ,      -- ������Ʈ��ȣ      
           D.WBSSeq                    AS WBSSeq           ,     -- WBS      
           ''                         AS WBS              ,      
           0                           AS QCCurAmt         ,     -- QC�ݾ�        
           CASE WHEN D.SMQcType = 6035001 THEN '' ELSE X.TestEndDate    END    AS QcDate           ,     -- �˻���  ,      
           CASE WHEN D.SMQcType = 6035001 THEN 0 ELSE X.ReqInQty       END    AS QCQty            ,     -- �԰��Ƿڼ���  ,      
           CASE WHEN D.SMQcType = 6035001 THEN 0 ELSE X.QCStdUnitQty   END    AS QCStdUnitQty  ,         -- �԰��Ƿڼ���(���ش���) ,      
           ISNULL(D.MakerSeq,0)       AS MakerSeq,              -- MakerSeq  �߰�  
           ISNULL(CC.CustName,'')     AS MakerName,             -- MakerName �߰�
           P.BizUnit       AS BizUnit,     -- ����ι��ڵ�    (�̻�ȭ �߰�)
           PP.BizUnitName      AS BizUnitName,    -- ������Ʈ����ι�(�̻�ȭ �߰�)
           D.ItemSeq                  AS ItemSeq_Old     ,      -- ����ǰ �ڵ� Lot No ������Ʈ�� LotMaster�� ������Ʈ �ȵǼ� �߰� 2011. 5. 11 �輼ȣ  
           D.LotNo                    AS LotNo_Old       ,      -- LotNo  Lot No ������Ʈ�� LotMaster�� ������Ʈ �ȵǼ� �߰� 2011. 5. 11 �輼ȣ
           D.IsFiction                AS IsFiction       ,      -- 2011. 12. 30 hkim �߰�
           D.FicRateNum               AS FicRateNum      ,      -- 2011. 12. 30 hkim �߰�
           D.FicRateDen               AS FicRateDen      ,      -- 2011. 12. 30 hkim �߰�
           D.EvidSeq                  AS EvidSeq         ,      -- 2011. 12. 30 hkim �߰�
           T.EvidName                 AS EvidName        ,       -- 2011. 12. 30 hkim �߰�
           D.Memo1                    AS SalesCustSeq    ,      -- ����ó�ڵ�
           D.Memo2                    AS EndUserSeq      ,      -- EndUser�ڵ�
           A.CustName                 AS SalesCustName   ,      -- ����ó
           B.CustName                 AS EndUserName            -- EndUser
      FROM #TPUDelvItem AS Z WITH(NOLOCK)       
      JOIN _TPUDelvItem AS D WITH(NOLOCK) ON D.companySeq = @CompanySeq      
                                         AND Z.DelvSeq = D.DelvSeq       
                                         AND (@DelvSerl IS NULL OR Z.DelvSerl = D.DelvSerl)      
      JOIN _TPUDelv        AS M   WITH(NOLOCK) ON D.CompanySeq  = M.CompanySeq      
                                              AND D.DelvSeq     = M.DelvSeq      
      LEFT OUTER JOIN _TDACust     AS CC  WITH(NOLOCK) ON D.CompanySeq  = CC.CompanySeq  
                                                      AND D.MakerSeq    = CC.CustSeq  
      LEFT OUTER JOIN _TDACurr     AS C   WITH(NOLOCK) ON M.CompanySeq  = C.CompanySeq      
                                                      AND M.CurrSeq     = C.CurrSeq      
      LEFT OUTER JOIN _TDAItem     AS I   WITH(NOLOCK) ON D.CompanySeq  = I.CompanySeq      
                                                      AND D.ItemSeq     = I.ItemSeq        
      LEFT OUTER JOIN _TDAUnit     AS U   WITH(NOLOCK) ON D.CompanySeq  = U.CompanySeq      
                                                      AND D.UnitSeq     = U.UnitSeq        
      LEFT OUTER JOIN _TDAItemUnit AS UU  WITH(NOLOCK) ON D.CompanySeq  = UU.CompanySeq      
                                                        AND D.ItemSeq     = UU.ItemSeq       
                                                        AND D.UnitSeq     = UU.UnitSeq        
      LEFT OUTER JOIN _TDAItemDefUnit AS DU  WITH(NOLOCK) ON D.CompanySeq  = DU.CompanySeq      
                                                         AND D.ItemSeq     = DU.ItemSeq       
                                                         AND DU.UMModuleSeq = '1003001'       -- ���ű⺻����      
      LEFT OUTER JOIN _TDAUnit        AS E   WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq     -- ���ش���(������)      
                                                         AND D.StdUnitSeq     = E.UnitSeq        
      LEFT OUTER JOIN _TDAItemUnit    AS F   WITH(NOLOCK) ON I.CompanySeq  = F.CompanySeq     --  ȯ�����(���ش���)      
                                                         AND I.ItemSeq     = F.ItemSeq       
                                                         AND I.UnitSeq     = F.UnitSeq       
      LEFT OUTER JOIN _TDACust        AS H   WITH(NOLOCK) ON D.CompanySeq  = H.CompanySeq     --  �����ŷ�ó      
                                                         AND D.SalesCustSeq= H.CustSeq       
      LEFT OUTER JOIN _TDAItemStock   AS J   WITH(NOLOCK) ON D.CompanySeq  = J.CompanySeq     --  �����ŷ�ó      
                                                         AND D.ItemSeq     = J.ItemSeq       
      LEFT OUTER JOIN _TDACust        AS K   WITH(NOLOCK) ON D.CompanySeq  = K.CompanySeq     --  �����ŷ�ó      
                                                         AND D.DelvCustSeq= K.CustSeq       
      LEFT OUTER JOIN _TDAWH          AS L   WITH(NOLOCK) ON D.CompanySeq  = L.CompanySeq     --  �����ŷ�ó      
                                                         AND D.WhSeq      = L.WHSeq   --  �����ŷ�ó      
      LEFT OUTER JOIN _TPJTProject    AS P   WITH(NOLOCK) ON D.CompanySeq  = P.CompanySeq     --  ������Ʈ      
                                                         AND D.PJTSeq      = P.PJTSeq      
      LEFT OUTER JOIN _TDABizUnit     AS PP  WITH(NOLOCK) ON P.CompanySeq  = PP.CompanySeq     -- ����ι� (�̻�ȭ �߰�)
               AND P.BizUnit  = PP.BizUnit
 --    LEFT OUTER JOIN _TPJTWBS        AS N   WITH(NOLOCK) ON D.CompanySeq  = N.CompanySeq     --  WBS      
 --                                                           AND D.PJTSeq      = N.PJTSeq      
 --                                                           AND D.WBSSeq      = N.WBSSeq      
      LEFT OUTER JOIN #tem_QCData    AS  X   WITH(NOLOCK) ON D.CompanySeq  = X.CompanySeq     -- �԰��Ƿڼ���      
                                                         AND D.DelvSeq     = X.DelvSeq      
                                                         AND D.DelvSerl    = X.DelvSerl      
      LEFT OUTER JOIN _TDAItemSales  AS V WITH(NOLOCK) ON D.CompanySeq = V.CompanySeq
                                                      AND D.ItemSeq   = V.ItemSeq
      LEFT OUTER JOIN _TDAVATRate   AS Q  WITH(NOLOCK) ON Q.CompanySeq = @CompanySeq
                                                      AND V.SMVatType  = Q.SMVatType
                                                      AND V.SMVatKind <> 2003002 -- �鼼 ����
                                                      AND M.DelvDate BETWEEN Q.SDate AND Q.EDate
      LEFT OUTER JOIN _TDASMinorValue  AS R WITH(NOLOCK) ON R.CompanySeq = @CompanySeq
                                                        AND M.SMImpType  = R.MinorSeq   
                                                        AND R.Serl       = 1002
      LEFT OUTER JOIN _TDASMinorValue  AS S WITH(NOLOCK) ON S.CompanySeq = @CompanySeq
                                                        AND M.SMImpType  = S.MinorSeq
                                                        AND S.Serl       = 1002
      LEFT OUTER JOIN _TDAEvid            AS T WITH(NOLOCK) ON D.CompanySeq = T.CompanySeq
                                                           AND D.EvidSeq    = T.EvidSeq   
      LEFT OUTER JOIN _TDACust        AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.CustSeq = D.Memo1 ) 
      LEFT OUTER JOIN _TDACust        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = D.Memo2 )                                                           
                                                   
       
     WHERE D.CompanySeq   = @CompanySeq      
 RETURN      
 --------------------------------------------------------------------------      
    Jump_Qry:      
    DECLARE @IsOver NCHAR(1)
  
    SELECT @IsOver = ISNULL(IsOverFlow, '0')
      FROM _TCOMProgRelativeTables 
     WHERE CompanySeq = @CompanySeq
       AND FromTableSeq = 10 
       AND ToTableSeq   = 9
       
    -- ���� ���� ��������      
    -------------------      --�԰����࿩��-----      
    -------------------      
    CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))          
        
    CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT)      
      
    CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))            

    CREATE TABLE #OrderTracking(IDX_NO INT, Qty DECIMAL(19,5), CurAmt DECIMAL(19,5), CurVAT DECIMAL(19, 5))      

    INSERT #TMP_PROGRESSTABLE           
    SELECT 1, '_TPUDelvInItem'               -- �����԰�      
       
    -- ���ų�ǰ          
    EXEC _SCOMProgressTracking @CompanySeq, '_TPUDelvItem', '#TPUDelvItem', 'DelvSeq', 'DelvSerl', ''             

    INSERT INTO #OrderTracking          
    SELECT IDX_NO,          
           SUM(CASE IDOrder WHEN 1 THEN Qty     ELSE 0 END),          
           SUM(CASE IDOrder WHEN 1 THEN Amt     ELSE 0 END),      
           SUM(CASE IDOrder WHEN 1 THEN VAT     ELSE 0 END)         
      FROM #TCOMProgressTracking          
     GROUP BY IDX_No          
      
    INSERT INTO #tem_QCData(CompanySeq  ,DelvSeq,  DelvSerl,   TestEndDate,   Qty,     PassedQty,    ReqInQty ,QCStdUnitQty)      
         SELECT @CompanySeq,          
                B.SourceSeq,          
                B.SourceSerl,         
                SUBSTRING(TestEndDate,1,8) ,       
                A.Qty  ,      
                SUM(ISNULL(PassedQty,0)),      
                SUM(ISNULL(ReqInQty,0)),      
                SUM(ISNULL(CASE WHEN ISNULL(ConvDen,0) = 0 THEN 0 ELSE ISNULL(ReqInQty,0) * (ConvNum/ConvDen) END,0))      
           FROM #TPUDelvItem             AS A       
           JOIN _TPDQCTestReport         AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq      
                                                          AND A.DelvSeq    = B.SourceSeq      
                                                          AND B.SourceType = '1'      
           JOIN _TPUDelvItem             AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq      
                                                          AND C.DelvSeq    = B.SourceSeq      
                                                          AND C.DelvSerl   = B.SourceSerl      
           LEFT OUTER JOIN _TDAItemUnit  AS D WITH(NOLOCK) ON C.CompanySeq = D.CompanySeq      
                                                          AND C.ItemSeq    = D.ItemSeq      
                                                          AND C.UnitSeq    = D.UnitSeq      
          GROUP BY B.SourceSeq, B.SourceSerl, A.Qty, B.TestEndDate      
       
     -- QC ���� - ���� ����(�̰˻�ǰ)      
    SELECT M.DelvNo          AS DelvNo           ,      
           D.DelvSeq                   AS DelvSeq          ,      
           D.DelvSerl                  AS DelvSerl         ,      
           I.ItemName                  AS ItemName         ,     -- ǰ��        
           I.ItemNo                    AS ItemNo           ,     -- ǰ��        
           I.Spec                      AS Spec             ,     -- �԰�        
           ISNULL(U.UnitName,'')       AS UnitName         ,     -- ����        
           ISNULL(D.Price,0)           AS Price            ,     -- �ܰ�        
           ISNULL(D.QCQty,0) - ISNULL(ZZ.Qty, 0) AS Qty              ,     -- ��ȸ��ǰ����        
           ISNULL(D.CurAmt,0)          AS CurAmt           ,     -- �ݾ�        
           ISNULL(D.CurAmt,0) + ISNULL(D.CurVAT,0)        
                                       AS TotCurAmt        ,     -- �ݾ�        
           ISNULL(D.DomPrice,0)        AS DomPrice         ,     -- ��ȭ�ܰ�            
           ISNULL(D.DomAmt,0)          AS DomAmt           ,     -- ��ȭ�ݾ�        
           ISNULL(D.DomAmt,0) + ISNULL(D.DomVAT,0)            
                                       AS TotDomAmt        ,     -- ��ȭ�ݾ�        
           ISNULL(D.CurVAT,0)          AS CurVAT           ,     -- �ΰ���      
           ISNULL(D.DomVAT,0)          AS DomVAT           ,     -- ��ȭ�ΰ���        
           ISNULL(D.IsVAT,'')          AS IsVAT            ,     -- �ΰ������Կ���      
           --ISNULL(AA.VATRate,0)        AS VATRate          ,     -- �ΰ�����      
           CASE WHEN ISNULL(R.ValueText,'') <> '1' AND 
                     ISNULL(S.ValueText,'') <> '1' THEN (CASE V.SMVatKind WHEN 2003001 THEN ISNULL(Q.VatRate,0) ELSE 0 END)
                                                   ELSE 0 END AS VATRate, -- �ΰ�����
           ISNULL(L.WHName ,'')        AS WHName           ,     -- â��      
           ISNULL(D.WhSeq,0)           AS WHSeq            ,     -- ��ǰ���(â��)�ڵ�         
           K.CustName                  AS DelvCustName     ,     -- ��ǰó               
           ISNULL(D.DelvCustSeq, '')   AS DelvCustSeq      ,     -- ��ǰó�ڵ�                   
           --ISNULL(H.CustName , '')     AS SalesCustName    ,     -- �����ŷ�ó��           
           --ISNULL(D.SalesCustSeq, '')  AS SalesCustSeq     ,     -- �����ŷ�ó                 
           ''                          AS SMQcTypeName     ,     -- �˻籸��      
           ISNULL(D.SMQcType,'')       AS SMQcType         ,     -- �˻籸��      
           ISNULL(E.UnitName,'')       AS StdUnitName      ,     -- ����(������)        
           ISNULL(E.UnitSeq,'')        AS StdUnitSeq      ,     -- ����(������)        
           --ISNULL(D.stdUnitQty,0)      AS StdUnitQty       ,     -- ����������        
           CASE ISNULL(F.ConvDen,0) WHEN 0 THEN 0 ELSE ISNULL(D.QCQty,0) - ISNULL(ZZ.Qty, 0) * ( ISNULL(F.ConvNum,0)/ISNULL(F.ConvDen,0)) END AS StdUnitQty ,            
           ( ISNULL(F.ConvNum,0)  / (CASE WHEN ISNULL(F.ConvDen,1) = 0 THEN 1 ELSE  ISNULL(F.ConvDen,1) END)) AS StdConvQty , -- ������ȯ�����      
           ISNULL(D.ItemSeq,'')        AS ItemSeq          ,     -- ǰ���ڵ�        
           ISNULL(D.UnitSeq,'')        AS UnitSeq          ,     -- �����ڵ�        
           ISNULL(D.LotNo,'')          AS LotNo            ,        
           ISNULL(D.FROMSerial,'')     AS FromSerial           ,        
           ISNULL(D.Toserial,'')       AS Toserial         ,              
           ISNULL(D.Remark,'')         AS Remark           ,        
           ISNULL(J.IsLotMng,'')       AS LotMngYN         ,      
           ISNULL(M.CurrSeq,0)         AS CurrSeq          ,     -- �����԰������� �ʿ�      
           ISNULL(M.ExRate,0)          AS ExRate           ,     -- �����԰������� �ʿ�      
           ISNULL(C.CurrName,'')       AS CurrName         ,     -- �����԰������� �ʿ�      
           Z.IDX_NO                    AS IDX_NO           ,      
           D.PJTSeq                    AS PJTSeq           ,     -- ������Ʈ�ڵ�      
           P.PJTName                   AS PJTName          ,     -- ������Ʈ      
           P.PJTNo                     AS PJTNo            ,     -- ������Ʈ��ȣ      
           D.WBSSeq                    AS WBSSeq           ,     -- WBS      
           N.WBSName                   AS WBS              ,      
           0                           AS QCCurAmt         ,     -- QC�ݾ�        
           CASE WHEN D.SMQcType = 6035001 THEN M.DelvDate  ELSE X.TestEndDate    END    AS QcDate           ,     -- �˻���  ,      
           CASE WHEN D.SMQcType = 6035001 THEN D.Qty       ELSE X.ReqInQty       END    AS QCQty            ,     -- �԰��Ƿڼ���  ,      
           CASE WHEN D.SMQcType = 6035001 THEN D.StdUnitQty ELSE X.QCStdUnitQty   END    AS QCStdUnitQty   ,        -- �԰��Ƿڼ���(���ش���) ,      
           ISNULL(D.MakerSeq,0)       AS MakerSeq,              -- MakerSeq  �߰�  
           ISNULL(CC.CustName,'')     AS MakerName,             -- MakerName �߰� 
           P.BizUnit       AS BizUnit,     -- ����ι��ڵ�    (�̻�ȭ �߰�)
           PP.BizUnitName      AS BizUnitName,    -- ������Ʈ����ι�(�̻�ȭ �߰�)
           D.ItemSeq                  AS ItemSeq_Old     ,      -- ����ǰ �ڵ� Lot No ������Ʈ�� LotMaster�� ������Ʈ �ȵǼ� �߰� 2011. 5. 11 �輼ȣ  
           D.LotNo                    AS LotNo_Old       ,      -- LotNo  Lot No ������Ʈ�� LotMaster�� ������Ʈ �ȵǼ� �߰� 2011. 5. 11 �輼ȣ
           D.IsFiction              AS IsFiction       ,      -- 2011. 12. 30 hkim �߰�
           D.FicRateNum               AS FicRateNum      ,      -- 2011. 12. 30 hkim �߰�
           D.FicRateDen               AS FicRateDen      ,      -- 2011. 12. 30 hkim �߰�
           D.EvidSeq                  AS EvidSeq         ,      -- 2011. 12. 30 hkim �߰�
           T.EvidName                 AS EvidName        ,      -- 2011. 12. 30 hkim �߰�
           D.Memo1                    AS SalesCustSeq    ,      -- ����ó�ڵ�
           D.Memo2                    AS EndUserSeq      ,      -- EndUser�ڵ�
           A.CustName                 AS SalesCustName   ,      -- ����ó
           B.CustName                 AS EndUserName            -- EndUser
           
      FROM #TPUDelvItem AS Z WITH(NOLOCK)       
      JOIN _TPUDelvItem AS D WITH(NOLOCK) ON D.companySeq = @CompanySeq      
                                         AND Z.DelvSeq = D.DelvSeq       
                                         AND (@DelvSerl IS NULL OR Z.DelvSerl = D.DelvSerl)      
      JOIN _TPUDelv        AS M   WITH(NOLOCK) ON D.CompanySeq  = M.CompanySeq      
                                                         AND D.DelvSeq     = M.DelvSeq      
      LEFT OUTER JOIN _TDACust        AS CC  WITH(NOLOCK) ON D.CompanySeq  = CC.CompanySeq  
                                                         AND D.MakerSeq    = CC.CustSeq  
      LEFT OUTER JOIN #OrderTracking  AS ZZ               ON Z.IDX_No     = ZZ.IDX_No      
      LEFT OUTER JOIN _TDACurr        AS C   WITH(NOLOCK) ON M.CompanySeq  = C.CompanySeq      
                                                         AND M.CurrSeq     = C.CurrSeq      
      LEFT OUTER JOIN _TDAItem        AS I   WITH(NOLOCK) ON D.CompanySeq  = I.CompanySeq      
                                                         AND D.ItemSeq     = I.ItemSeq        
      LEFT OUTER JOIN _TDAUnit        AS U   WITH(NOLOCK) ON D.CompanySeq  = U.CompanySeq      
                                                         AND D.UnitSeq     = U.UnitSeq        
      LEFT OUTER JOIN _TDAItemUnit    AS UU  WITH(NOLOCK) ON D.CompanySeq  = UU.CompanySeq      
                                                         AND D.ItemSeq     = UU.ItemSeq       
                                                         AND D.UnitSeq     = UU.UnitSeq        
      LEFT OUTER JOIN _TDAItemDefUnit AS DU  WITH(NOLOCK) ON D.CompanySeq  = DU.CompanySeq      
                                                         AND D.ItemSeq     = DU.ItemSeq       
                                                         AND DU.UMModuleSeq = '1003001'       -- ���ű⺻����      
      LEFT OUTER JOIN _TDAUnit        AS E   WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq     -- ���ش���(������)      
                                                         AND D.StdUnitSeq     = E.UnitSeq        
      LEFT OUTER JOIN _TDAItemUnit    AS F   WITH(NOLOCK) ON I.CompanySeq  = F.CompanySeq     --  ȯ�����(���ش���)      
                                                         AND I.ItemSeq     = F.ItemSeq       
                                                         AND I.UnitSeq     = F.UnitSeq       
      LEFT OUTER JOIN _TDACust        AS H   WITH(NOLOCK) ON D.CompanySeq  = H.CompanySeq     --  �����ŷ�ó      
                                                         AND D.SalesCustSeq= H.CustSeq       
      LEFT OUTER JOIN _TDAItemStock   AS J   WITH(NOLOCK) ON D.CompanySeq  = J.CompanySeq     --  �����ŷ�ó      
                                                         AND D.ItemSeq     = J.ItemSeq       
      LEFT OUTER JOIN _TDACust        AS K   WITH(NOLOCK) ON D.CompanySeq  = K.CompanySeq     --  �����ŷ�ó      
                                                         AND D.DelvCustSeq= K.CustSeq       
      LEFT OUTER JOIN _TDAWH          AS L   WITH(NOLOCK) ON D.CompanySeq  = L.CompanySeq     --  �����ŷ�ó      
                                                         AND D.WhSeq      = L.WHSeq     --  �����ŷ�ó      
      LEFT OUTER JOIN _TPJTProject    AS P   WITH(NOLOCK) ON D.CompanySeq  = P.CompanySeq     --  ������Ʈ      
                                                         AND D.PJTSeq      = P.PJTSeq      
      LEFT OUTER JOIN _TDABizUnit     AS PP  WITH(NOLOCK) ON P.CompanySeq  = PP.CompanySeq     -- ����ι� (�̻�ȭ �߰�)
                                                         AND P.BizUnit  = PP.BizUnit
      LEFT OUTER JOIN _TPJTWBS        AS N   WITH(NOLOCK) ON D.CompanySeq  = N.CompanySeq     --  WBS      
                                                         AND D.PJTSeq      = N.PJTSeq      
                                                         AND D.WBSSeq       = N.WBSSeq      
      LEFT OUTER JOIN #tem_QCData    AS  X   WITH(NOLOCK) ON D.CompanySeq  = X.CompanySeq     -- �԰��Ƿڼ���      
                                                         AND D.DelvSeq     = X.DelvSeq      
                                                         AND D.DelvSerl    = X.DelvSerl      
      LEFT OUTER JOIN _TDAItemSales  AS V WITH(NOLOCK) ON D.CompanySeq = V.CompanySeq
                                                      AND D.ItemSeq   = V.ItemSeq
      LEFT OUTER JOIN _TDAVATRate   AS Q  WITH(NOLOCK) ON Q.CompanySeq = @CompanySeq
                                                      AND V.SMVatType  = Q.SMVatType
                                                      AND V.SMVatKind <> 2003002 -- �鼼 ����
                                                      AND M.DelvDate BETWEEN Q.SDate AND Q.EDate
      LEFT OUTER JOIN _TDASMinorValue  AS R WITH(NOLOCK) ON R.CompanySeq = @CompanySeq
                                                        AND M.SMImpType  = R.MinorSeq   
                                                        AND R.Serl       = 1002
      LEFT OUTER JOIN _TDASMinorValue  AS S WITH(NOLOCK) ON S.CompanySeq = @CompanySeq
                                                        AND M.SMImpType  = S.MinorSeq
                                                        AND S.Serl       = 1002
      LEFT OUTER JOIN _TDAEvid            AS T WITH(NOLOCK) ON D.CompanySeq = T.CompanySeq
                                                          AND D.EvidSeq    = T.EvidSeq                                                             
      LEFT OUTER JOIN _TDACust        AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.CustSeq = D.Memo1 ) 
      LEFT OUTER JOIN _TDACust        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = D.Memo2 ) 
       
     WHERE D.CompanySeq   = @CompanySeq      
       AND ((@IsOver <> '1' AND (ISNULL(D.QCQty,0) - ISNULL(ZZ.Qty, 0)) <> 0) OR @IsOver = '1')        
       AND D.SMQCType    NOT IN (6035001)      
       
     UNION ALL      
     -- ������ - ���� ����(���˻�ǰ)      
    SELECT M.DelvNo                    AS DelvNo           ,      
           D.DelvSeq                   AS DelvSeq          ,      
           D.DelvSerl                  AS DelvSerl         ,      
           I.ItemName                  AS ItemName         ,     -- ǰ��        
           I.ItemNo                    AS ItemNo           ,     -- ǰ��        
           I.Spec                      AS Spec             ,     -- �԰�        
           ISNULL(U.UnitName,'')       AS UnitName         ,     -- ����        
           ISNULL(D.Price,0)           AS Price            ,    -- �ܰ�        
           ISNULL(D.Qty,0) - ISNULL(ZZ.Qty, 0) AS Qty              ,     -- ��ȸ��ǰ����        
           ISNULL(D.CurAmt,0)          AS CurAmt           ,     -- �ݾ�        
           ISNULL(D.CurAmt,0) + ISNULL(D.CurVAT,0)        
                                       AS TotCurAmt        ,     -- �ݾ�        
           ISNULL(D.DomPrice,0)        AS DomPrice         ,     -- ��ȭ�ܰ�            
           ISNULL(D.DomAmt,0)          AS DomAmt           ,     -- ��ȭ�ݾ�        
           ISNULL(D.DomAmt,0) + ISNULL(D.DomVAT,0)            
                                       AS TotDomAmt        ,     -- ��ȭ�ݾ�        
           ISNULL(D.CurVAT,0)          AS CurVAT           ,     -- �ΰ���      
           ISNULL(D.DomVAT,0)          AS DomVAT           ,     -- ��ȭ�ΰ���        
           ISNULL(D.IsVAT,'')          AS IsVAT            ,     -- �ΰ������Կ���      
           --ISNULL(AA.VATRate,0)        AS VATRate          ,     -- �ΰ�����      
           CASE WHEN ISNULL(R.ValueText,'') <> '1' AND 
                     ISNULL(S.ValueText,'') <> '1' THEN (CASE V.SMVatKind WHEN 2003001 THEN ISNULL(Q.VatRate,0) ELSE 0 END)
                                                   ELSE 0 END AS VATRate, -- �ΰ�����
           ISNULL(L.WHName ,'')        AS WHName           ,     -- â��      
           ISNULL(D.WhSeq,0)           AS WHSeq            ,     -- ��ǰ���(â��)�ڵ�         
           K.CustName                  AS DelvCustName     ,     -- ��ǰó               
           ISNULL(D.DelvCustSeq, '')   AS DelvCustSeq      ,     -- ��ǰó�ڵ�                   
           --ISNULL(H.CustName , '')     AS SalesCustName    ,     -- �����ŷ�ó��            
           --ISNULL(D.SalesCustSeq, '')  AS SalesCustSeq     ,     -- �����ŷ�ó                 
           ''                          AS SMQcTypeName     ,     -- �˻籸��      
           ISNULL(D.SMQcType,'')       AS SMQcType         ,     -- �˻籸��      
           ISNULL(E.UnitName,'')       AS StdUnitName      ,     -- ����(������)        
           ISNULL(E.UnitSeq,'')        AS StdUnitSeq      ,     -- ����(������)        
           CASE ISNULL(F.ConvDen,0) WHEN 0 THEN 0 ELSE ISNULL(D.Qty,0) - ISNULL(ZZ.Qty, 0) * ( ISNULL(F.ConvNum,0)/ISNULL(F.ConvDen,0)) END AS StdUnitQty ,            
           ( ISNULL(F.ConvNum,0)  / (CASE WHEN ISNULL(F.ConvDen,1) = 0 THEN 1 ELSE  ISNULL(F.ConvDen,1) END)) AS StdConvQty , -- ������ȯ�����      
           ISNULL(D.ItemSeq,'')        AS ItemSeq          ,     -- ǰ���ڵ�        
           ISNULL(D.UnitSeq,'')        AS UnitSeq          ,     -- �����ڵ�        
           ISNULL(D.LotNo,'')          AS LotNo            ,        
           ISNULL(D.FROMSerial,'')     AS FromSerial           ,        
           ISNULL(D.Toserial,'')       AS Toserial         ,              
           ISNULL(D.Remark,'')         AS Remark           ,        
           ISNULL(J.IsLotMng,'')       AS LotMngYN         ,      
           ISNULL(M.CurrSeq,0)         AS CurrSeq          ,     -- �����԰������� �ʿ�      
           ISNULL(M.ExRate,0)          AS ExRate           ,     -- �����԰������� �ʿ�      
           ISNULL(C.CurrName,'')       AS CurrName         ,     -- �����԰������� �ʿ�      
           Z.IDX_NO                    AS IDX_NO           ,      
           D.PJTSeq                    AS PJTSeq           ,     -- ������Ʈ�ڵ�      
           P.PJTName                   AS PJTName          ,     -- ������Ʈ      
           P.PJTNo                     AS PJTNo            ,     -- ������Ʈ��ȣ      
           D.WBSSeq                    AS WBSSeq           ,     -- WBS      
           N.WBSName                   AS WBS              ,      
           0                           AS QCCurAmt         ,     -- QC�ݾ�        
           CASE WHEN D.SMQcType = 6035001 THEN M.DelvDate  ELSE X.TestEndDate    END    AS QcDate           ,     -- �˻���  ,      
           CASE WHEN D.SMQcType = 6035001 THEN D.Qty       ELSE X.ReqInQty       END    AS QCQty            ,     -- �԰��Ƿڼ���  ,      
           CASE WHEN D.SMQcType = 6035001 THEN D.StdUnitQty ELSE X.QCStdUnitQty   END    AS QCStdUnitQty  ,         -- �԰��Ƿڼ���(���ش���) ,      
           ISNULL(D.MakerSeq,0)       AS MakerSeq,              -- MakerSeq  �߰�  
           ISNULL(CC.CustName,'')     AS MakerName,             -- MakerName �߰�
           P.BizUnit       AS BizUnit,     -- ����ι��ڵ�    (�̻�ȭ �߰�)
           PP.BizUnitName      AS BizUnitName,    -- ������Ʈ����ι�(�̻�ȭ �߰�)
           D.ItemSeq                  AS ItemSeq_Old     ,      -- ����ǰ �ڵ� Lot No ������Ʈ�� LotMaster�� ������Ʈ �ȵǼ� �߰� 2011. 5. 11 �輼ȣ  
           D.LotNo                    AS LotNo_Old       ,      -- LotNo  Lot No ������Ʈ�� LotMaster�� ������Ʈ �ȵǼ� �߰� 2011. 5. 11 �輼ȣ            
           D.IsFiction                AS IsFiction       ,      -- 2011. 12. 30 hkim �߰�
           D.FicRateNum               AS FicRateNum      ,      -- 2011. 12. 30 hkim �߰�
           D.FicRateDen               AS FicRateDen      ,      -- 2011. 12. 30 hkim �߰�
           D.EvidSeq                  AS EvidSeq         ,      -- 2011. 12. 30 hkim �߰�
           T.EvidName                 AS EvidName        ,      -- 2011. 12. 30 hkim �߰�
           D.Memo1                    AS SalesCustSeq    ,      -- ����ó�ڵ�
           D.Memo2                    AS EndUserSeq      ,      -- EndUser�ڵ�
           A.CustName                 AS SalesCustName   ,      -- ����ó
           B.CustName                 AS EndUserName            -- EndUser
           
                
      FROM #TPUDelvItem AS Z WITH(NOLOCK)       
      JOIN _TPUDelvItem AS D WITH(NOLOCK) ON D.companySeq = @CompanySeq      
                                         AND Z.DelvSeq = D.DelvSeq       
                                         AND (@DelvSerl IS NULL OR Z.DelvSerl = D.DelvSerl)      
      JOIN _TPUDelv     AS M   WITH(NOLOCK) ON D.CompanySeq  = M.CompanySeq      
                                           AND D.DelvSeq     = M.DelvSeq      
      LEFT OUTER JOIN _TDACust        AS CC  WITH(NOLOCK) ON D.CompanySeq  = CC.CompanySeq  
                                                         AND D.MakerSeq    = CC.CustSeq  
      LEFT OUTER JOIN #OrderTracking  AS ZZ               ON Z.IDX_No     = ZZ.IDX_No      
      LEFT OUTER JOIN _TDACurr        AS C   WITH(NOLOCK) ON M.CompanySeq  = C.CompanySeq      
                                                         AND M.CurrSeq     = C.CurrSeq      
      LEFT OUTER JOIN _TDAItem        AS I   WITH(NOLOCK) ON D.CompanySeq  = I.CompanySeq      
                                                         AND D.ItemSeq     = I.ItemSeq        
      LEFT OUTER JOIN _TDAUnit        AS U   WITH(NOLOCK) ON D.CompanySeq  = U.CompanySeq      
                                                         AND D.UnitSeq     = U.UnitSeq        
      LEFT OUTER JOIN _TDAItemUnit    AS UU  WITH(NOLOCK) ON D.CompanySeq  = UU.CompanySeq      
                                                         AND D.ItemSeq     = UU.ItemSeq       
                                                         AND D.UnitSeq     = UU.UnitSeq        
      LEFT OUTER JOIN _TDAItemDefUnit AS DU  WITH(NOLOCK) ON D.CompanySeq  = DU.CompanySeq      
                                                         AND D.ItemSeq     = DU.ItemSeq       
                                                         AND DU.UMModuleSeq = '1003001'       -- ���ű⺻����      
      LEFT OUTER JOIN _TDAUnit        AS E   WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq     -- ���ش���(������)      
                                                         AND D.StdUnitSeq     = E.UnitSeq        
      LEFT OUTER JOIN _TDAItemUnit    AS F   WITH(NOLOCK) ON I.CompanySeq  = F.CompanySeq     --  ȯ�����(���ش���)      
                                                         AND I.ItemSeq     = F.ItemSeq       
                                                         AND I.UnitSeq     = F.UnitSeq       
      LEFT OUTER JOIN _TDACust        AS H   WITH(NOLOCK) ON D.CompanySeq  = H.CompanySeq     --  �����ŷ�ó      
                                                         AND D.SalesCustSeq= H.CustSeq       
      LEFT OUTER JOIN _TDAItemStock   AS J   WITH(NOLOCK) ON D.CompanySeq  = J.CompanySeq     --  �����ŷ�ó      
                                                         AND D.ItemSeq     = J.ItemSeq       
      LEFT OUTER JOIN _TDACust        AS K   WITH(NOLOCK) ON D.CompanySeq  = K.CompanySeq     --  �����ŷ�ó      
                                                         AND D.DelvCustSeq= K.CustSeq       
      LEFT OUTER JOIN _TDAWH          AS L   WITH(NOLOCK) ON D.CompanySeq  = L.CompanySeq     --  �����ŷ�ó      
                                                         AND D.WhSeq      = L.WHSeq     --  �����ŷ�ó      
      LEFT OUTER JOIN _TPJTProject    AS P   WITH(NOLOCK) ON D.CompanySeq  = P.CompanySeq     --  ������Ʈ      
                                                         AND D.PJTSeq      = P.PJTSeq
      LEFT OUTER JOIN _TDABizUnit     AS PP  WITH(NOLOCK) ON P.CompanySeq  = PP.CompanySeq     -- ����ι� (�̻�ȭ �߰�)
                                                         AND P.BizUnit  = PP.BizUnit     
      LEFT OUTER JOIN _TPJTWBS        AS N   WITH(NOLOCK) ON D.CompanySeq  = N.CompanySeq     --  WBS      
                                                         AND D.PJTSeq      = N.PJTSeq      
                                                         AND D.WBSSeq      = N.WBSSeq      
      LEFT OUTER JOIN #tem_QCData    AS  X   WITH(NOLOCK) ON D.CompanySeq  = X.CompanySeq     -- �԰��Ƿڼ���      
                                                         AND D.DelvSeq     = X.DelvSeq      
                                                         AND D.DelvSerl    = X.DelvSerl      
      LEFT OUTER JOIN _TDAItemSales  AS V WITH(NOLOCK) ON D.CompanySeq = V.CompanySeq
                                                      AND D.ItemSeq   = V.ItemSeq
      LEFT OUTER JOIN _TDAVATRate   AS Q  WITH(NOLOCK) ON Q.CompanySeq = @CompanySeq
                                                      AND V.SMVatType  = Q.SMVatType
                                                      AND V.SMVatKind <> 2003002 -- �鼼 ����
                                                      AND M.DelvDate BETWEEN Q.SDate AND Q.EDate
      LEFT OUTER JOIN _TDASMinorValue  AS R WITH(NOLOCK) ON R.CompanySeq = @CompanySeq
                                                        AND M.SMImpType  = R.MinorSeq   
                                                        AND R.Serl       = 1002
      LEFT OUTER JOIN _TDASMinorValue  AS S WITH(NOLOCK) ON S.CompanySeq = @CompanySeq
                                                        AND M.SMImpType  = S.MinorSeq
                                                        AND S.Serl       = 1002
      LEFT OUTER JOIN _TDAEvid         AS T WITH(NOLOCK) ON D.CompanySeq = T.CompanySeq
                                                        AND D.EvidSeq    = T.EvidSeq     
      LEFT OUTER JOIN _TDACust        AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.CustSeq = D.Memo1 ) 
      LEFT OUTER JOIN _TDACust        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = D.Memo2 )                                                         
       
     WHERE D.CompanySeq   = @CompanySeq      
       AND ((@IsOver <> '1' AND (ISNULL(D.Qty,0) - ISNULL(ZZ.Qty, 0)) <> 0) OR (@IsOver = '1'))
       AND D.SMQCType IN( 6035001)      
       
       
 RETURN        
 GO
exec DTI_SPUDelvItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <DelvSeq>133707</DelvSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015948,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001553