IF OBJECT_ID('KPXCM_SSLImpBLItemListQuery') IS NOT NULL 
    DROP PROC KPXCM_SSLImpBLItemListQuery
GO 

-- v2016.05.11 

/************************************************************

    Ver.20140630

 ��  �� - ������-����BL(��ȸ) : ǰ����Ȳ��ȸ
 �ۼ��� - 20090525
 �ۼ��� - �̼���
 ������ - 2009.08.28 BY �۰��
         :: ��ȸ����(������Ʈ, ������Ʈ��ȣ) �߰�, �÷�(������Ʈ, ������Ʈ��ȣ)�߰�
          2009.12.02 BY �ڼҿ�
         :: ��õ����(SourceTable)/��õ������ȣ(SourceNo)/��õ��ȣ(SourceRefNo) ��ȸ ���� �߰� �� Field�߰�
          2011.03.11 BY �̻�ȭ
         :: ��ȸ����(�԰�) �߰�
************************************************************/

CREATE PROC KPXCM_SSLImpBLItemListQuery
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
    DECLARE @docHandle           INT,
            @BLNo                NVARCHAR(100),
            @BLRefNo             NVARCHAR(100),
            @BLDateFr            NCHAR(8),
            @BLDateTo            NCHAR(8),
            @BizUnit             INT,
            @SMImpType           INT,
            @DeptSeq             INT,
            @CustSeq             INT,
            @EmpSeq              INT,
            @UMPriceTerms        INT,
            @UMPayment1          INT,
            @UMPayment2          INT,
            @SMProgressType      INT, 
            @ItemName            NVARCHAR(100),
            @ItemNo              NVARCHAR(100),
            @PJTName             NVARCHAR(100) ,   -- ������Ʈ��
            @PJTNo               NVARCHAR(100),    -- ������Ʈ��ȣ    
            @UMSupplyType        INT            ,    
            @TopUnitName         NVARCHAR(200)  ,    
            @TopUnitNo           NVARCHAR(200)  ,
            @Spec				 NVARCHAR(100)    -- �԰� (20110311 �̻�ȭ �߰�)   

    -- �߰����� 20091202 �ڼҿ� 
    DECLARE @SourceTableSeq INT,  
            @SourceNo       NVARCHAR(30),  
            @SourceRefNo    NVARCHAR(30),  
            @TableName      NVARCHAR(100),  
            @TableSeq       INT,  
            @SQL            NVARCHAR(MAX) 

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument 

    SELECT @BLNo            = ISNULL(BLNo,''),
           @BLRefNo         = ISNULL(BLRefNo,''),
           @BLDateFr        = ISNULL(BLDateFr,''),
           @BLDateTo        = ISNULL(BLDateTo,''),
           @BizUnit         = ISNULL(BizUnit,0),
           @SMImpType       = ISNULL(SMImpType,0),
           @DeptSeq         = ISNULL(DeptSeq,0),
           @CustSeq         = ISNULL(CustSeq,0),
           @EmpSeq          = ISNULL(EmpSeq,0),
           @UMPriceTerms    = ISNULL(UMPriceTerms,0),
           @UMPayment1      = ISNULL(UMPayment1,0),
           @UMPayment2      = ISNULL(UMPayment2,0),
           @SMProgressType  = ISNULL(SMProgressType, 0),
           @ItemName        = ISNULL(ItemName,''),
           @ItemNo          = ISNULL(ItemNo,''),
           @PJTName         = ISNULL(PJTName,  '') ,                        
           @PJTNo           = ISNULL(PJTNo,  ''),  
           @SourceTableSeq  = ISNULL(SourceTableSeq, 0),  -- �߰� 20091202 �ڼҿ� 
           @SourceNo        = ISNULL(SourceNo, ''),       -- �߰� 20091202 �ڼҿ� 
           @SourceRefNo     = ISNULL(SourceRefNo, ''),    -- �߰� 20091202 �ڼҿ� 
           @UMSupplyType    = ISNULL(UMSupplyType ,  0),    
           @TopUnitName     = ISNULL(TopUnitName  , ''),                        
           @TopUnitNo       = ISNULL(TopUnitNo    , ''),
           @Spec			= ISNULL(Spec		  , '')   -- �԰� (20110311 �̻�ȭ �߰�)     
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
    WITH (  BLNo                NVARCHAR(100),
            BLRefNo             NVARCHAR(100),
            BLDateFr            NCHAR(8),
            BLDateTo            NCHAR(8),
            BizUnit             INT,
            SMImpType           INT,
DeptSeq             INT,
            CustSeq             INT,
            EmpSeq              INT,
            UMPriceTerms        INT,
            UMPayment1          INT,
            UMPayment2          INT,
            SMProgressType      INT, 
            ItemName            NVARCHAR(100),
            ItemNo              NVARCHAR(100),
            PJTName             NVARCHAR(100),
            PJTNo               NVARCHAR(100),  
            SourceTableSeq      INT,            -- �߰� 20091202 �ڼҿ� 
            SourceNo            NVARCHAR(30),   -- �߰� 20091202 �ڼҿ� 
            SourceRefNo         NVARCHAR(30),   -- �߰� 20091202 �ڼҿ�
            UMSupplyType        INT          ,    
            TopUnitName         NVARCHAR(200),    
            TopUnitNo           NVARCHAR(200),
            Spec				NVARCHAR(100))  -- �԰� (20110311 �̻�ȭ �߰�) 

    IF @BLDateFr = '' SELECT @BLDateFr = '00010101'
    IF @BLDateTo = '' SELECT @BLDateTo = '99991231'

    -- ���ʵ��������̺�
    CREATE TABLE #TEMP_TUIImpBLItem(IDX_NO  INT IDENTITY, CompanySeq INT,  BLSeq  INT, BLSerl INT)

    --  ���� ���̺�  
    CREATE TABLE #TEMPTUIImpBLProg(IDX_NO INT IDENTITY, CompanySeq INT, BLSeq INT, BLSerl INT, CompleteCHECK INT, SMProgressType INT, IsStop NCHAR(1))   

--    -- ��õ���̺�
--    CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))        

--    -- ��õ ������ ���̺�
--    CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,        
--                                      Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))        


--------------------------------------------------------------------------------------------------------------------------------------------------------
    -- ���ʵ�����
    INSERT INTO #TEMP_TUIImpBLItem(CompanySeq, BLSeq, BLSerl)
    SELECT A.CompanySeq, A.BLSeq, B.BLSerl
      FROM _TUIImpBL AS A WITH(NOLOCK)
            JOIN _TUIImpBLItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq 
                                                AND A.BLSeq = B.BLSeq
            LEFT OUTER JOIN _TDAItem       AS L WITH(NOLOCK) ON A.CompanySeq = L.CompanySeq AND B.ItemSeq = L.ItemSeq
            LEFT OUTER JOIN _TPJTProject   AS Y WITH(NOLOCK) ON A.CompanySeq = Y.CompanySeq AND B.PJTSeq = Y.PJTSeq

     WHERE A.CompanySeq = @CompanySeq
       AND (@BLNo = '' OR A.BLNo LIKE '%' + @BLNo + '%')
       AND (@BLRefNo = '' OR A.BLRefNo LIKE '%' + @BLRefNo + '%')
       AND (@BizUnit = 0 OR @BizUnit = A.BizUnit)
       AND (@SMImpType = 0 OR @SMImpType = A.SMImpKind)
       AND (@DeptSeq = 0 OR @DeptSeq = A.DeptSeq)
       AND (@CustSeq = 0 OR @CustSeq = A.CustSeq)
       AND (@EmpSeq = 0 OR @EmpSeq = A.EmpSeq)
       AND (@UMPayment1 = 0 OR @UMPayment1 = A.UMPayment1)
       AND (@UMPayment2 = 0 OR @UMPayment2 = A.UMPayment2)
       AND (@UMPriceTerms = 0 OR @UMPriceTerms = A.UMPriceTerms)
       AND (A.BLDate BETWEEN @BLDateFr AND @BLDateTo)
       AND (L.ItemName = '' OR L.ItemName LIKE '%' + @ItemName + '%')
       AND (L.ItemNo = '' OR L.ItemNo LIKE '%' + @ItemNo + '%')
       AND (@PJTName = '' OR Y.PJTName LIKE  @PJTName + '%')
       AND (@PJTNo = ''   OR Y.PJTNo LIKE  @PJTNo + '%')
       AND (@Spec = ''    OR L.Spec  LIKE  @Spec  + '%') -- �԰� (�̻�ȭ 20110311 �߰�)


    -- ���൥����
    INSERT INTO #TEMPTUIImpBLProg(CompanySeq, BLSeq, BLSerl, CompleteCHECK, IsStop)    
    SELECT A.CompanySeq, A.BLSeq, A.BLSerl, -1, NULL  
      FROM #TEMP_TUIImpBLItem  AS A 

    EXEC _SCOMProgStatus @CompanySeq, '_TUIImpBLItem', 1036002, '#TEMPTUIImpBLProg', 'BLSeq', 'BLSerl', '', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', '', 'BLSeq', 'BLSerl', '', '_TUIImpBL', @PgmSeq
  
    UPDATE #TEMPTUIImpBLProg     
       SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037008 --�����ߴ�    
                    WHEN B.MinorSeq = 1037009 THEN 1037009 -- �Ϸ�    
                                         WHEN A.IsStop = '1' THEN 1037005       -- �ߴ�    
                                         WHEN A.CompleteCHECK = 1 THEN 1037003  -- Ȯ��(����)  
                                         ELSE B.MinorSeq END)    
      FROM #TEMPTUIImpBLProg AS A WITH(NOLOCK)    
          LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                      AND B.MajorSeq = 1037    
                                                      AND A.CompleteCHECK = B.Minorvalue  


    /****** ���԰� ������ ���ϱ� ���� ���� ��ȸ :: 20130625 �ڼ�ȣ �߰� ***/
    
    -- ����üũ ���̺� �� ���̺� CREATE & INSERT      
    CREATE TABLE #TMP_PROGRESSTABLE (  
        IDOrder   INT,   
        TABLENAME NVARCHAR(100))
      
    INSERT #TMP_PROGRESSTABLE         
    SELECT 1, '_TUIImpDelvItem' -- �����԰�

    -- ���� ���� SP OUTPUT TABLE      
    CREATE TABLE #TCOMProgressTracking (  
        IDX_NO  INT			  ,   
        IDOrder INT			  ,   
        Seq     INT			  ,   
        Serl    INT			  ,   
        SubSerl INT			  ,      
        Qty     DECIMAL(19, 5),   
        StdQty  DECIMAL(19, 5),   
        Amt     DECIMAL(19, 5),   
        VAT     DECIMAL(19, 5))
  
    -- ���� ���� SP ����  
    EXEC _SCOMProgressTracking @CompanySeq            = @CompanySeq         ,   
                               @TableName             = '_TUIImpBLItem'     ,   
                               @TempTableName         = '#TEMP_TUIImpBLItem',   
                               @TempSeqColumnName     = 'BLSeq'             ,   
                               @TempSerlColumnName    = 'BLSerl'            ,   
                               @TempSubSerlColumnName = ''
    
    -- ���� SUM �� ������ ���̺� CREATE & INSERT
    CREATE TABLE #BL_Prog (  
        IDX_NO    INT			,  
        DelvQty   DECIMAL(19, 5))

    INSERT INTO #BL_Prog(IDX_NO, DelvQty)
    SELECT A.IDX_NO, SUM(CASE WHEN IDOrder = 1 THEN A.Qty ELSE 0 END) AS 'DelvQty'
      FROM #TCOMProgressTracking AS A
     GROUP BY A.IDX_NO

    -- �� �԰���� SELECT
    SELECT A.CompanySeq, A.BLSeq, A.BLSerl, B.DelvQty
      INTO #TEMP_DelvQty
      FROM #TEMP_TUIImpBLItem AS A
           JOIN #BL_Prog      AS B ON A.IDX_NO = B.IDX_NO

    /*******************************************************************/

    -------------------------------------------        
    -- ��õ���� ��ȸ   20091202 �ڼҿ� �߰�
    -------------------------------------------     
    CREATE TABLE #TempResult  
    (  
        InOutSeq  INT,  -- ���೻�ι�ȣ  
        InOutSerl  INT,  -- �������  
        InOutSubSerl    INT,  
        SourceRefNo     NVARCHAR(30),  
        SourceNo        NVARCHAR(30)  
    )  
  
    IF ISNULL(@SourceTableSeq, 0) <> 0  
    BEGIN  
        CREATE TABLE #TMP_SOURCETABLE        
        (        
            IDOrder INT IDENTITY,        
            TABLENAME   NVARCHAR(100)        
        )        
          
        CREATE TABLE #TCOMSourceTracking        
        (         
            IDX_NO      INT,        
            IDOrder     INT,        
            Seq         INT,        
            Serl        INT,        
            SubSerl     INT,        
            Qty         DECIMAL(19, 5),        
            STDQty      DECIMAL(19, 5),        
            Amt         DECIMAL(19, 5),        
            VAT         DECIMAL(19, 5)        
        )        
          
        CREATE TABLE #TMP_SOURCEITEM  
        (        
            IDX_NO        INT IDENTITY,        
            SourceSeq     INT,        
            SourceSerl    INT,        
            SourceSubSerl INT  
        )           
  
  
        IF ISNULL(@TableName, '') <> ''  
        BEGIN  
            SELECT @TableSeq = ProgTableSeq      
              FROM _TCOMProgTable WITH(NOLOCK)--���������̺�      
             WHERE ProgTableName = @TableName    
        END  
  
        IF ISNULL(@TableSeq,0) = 0  
        BEGIN  
            SELECT @TableSeq = ISNULL(ProgTableSeq, 0)  
              FROM _TCAPgmDev  
             WHERE PgmSeq = @PgmSeq  
  
            SELECT @TableName = ISNULL(ProgTableName, '')  
              FROM _TCOMProgTable  
             WHERE ProgTableSeq = @TableSeq  
        END  
  
        INSERT INTO #TMP_SOURCETABLE(TABLENAME)      
        SELECT ISNULL(ProgTableName,'')  
          FROM _TCOMProgTable  
         WHERE ProgTableSeq = @SourceTableSeq  
  
        -- ����  
        INSERT INTO #TMP_SOURCEITEM(SourceSeq, SourceSerl, SourceSubSerl) -- IsNext=1(����), 2(������)      
        SELECT  A.BLSeq, A.BLSerl, 0      
          FROM #TEMPTUIImpBLProg     AS A WITH(NOLOCK)           
  

        EXEC _SCOMSourceTracking @CompanySeq, @TableName, '#TMP_SOURCEITEM', 'SourceSeq', 'SourceSerl', ''        
 
-- ��������
        SELECT @SQL = 'INSERT INTO #TempResult '
        SELECT @SQL = @SQL + 'SELECT C.SourceSeq, C.SourceSerl, C.SourceSubSerl, ' +
                             CASE WHEN ISNULL(A.ProgMasterTableName,'') = '' THEN ''''' AS InOutRefNo, '''' AS InOutNo ' 
                                                                             ELSE (CASE WHEN ISNULL(A.ProgTableRefNoColumn,'') = '' THEN ''''' AS InOutNo, ' ELSE 'ISNULL((SELECT ' + ISNULL(A.ProgTableRefNoColumn,'') + ' FROM ' + ISNULL(A.ProgMasterTableName,'') + ' WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ' + A.ProgTableSeqColumn + ' = A.Seq), '''') AS InOutNo, ' END) +
                                                                                  (CASE WHEN ISNULL(A.ProgTableNoColumn,'') = '' THEN ''''' AS InOutRefNo ' ELSE (CASE WHEN ISNULL(A.ProgMasterSubTableName,'') = '' THEN 'ISNULL((SELECT ' + ISNULL(A.ProgTableNoColumn,'') + ' FROM ' + ISNULL(A.ProgMasterTableName,'') + ' WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ' + A.ProgTableSeqColumn + ' = A.Seq), '''') AS InOutRefNo '                                                                                                                                                                                                                          
                                                                                                                                                                                                                   ELSE 'ISNULL((SELECT ' + ISNULL(A.ProgTableNoColumn,'') + ' FROM ' + ISNULL(A.ProgMasterSubTableName,'') + ' WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ' + A.ProgTableSeqColumn + ' = A.Seq), '''') AS InOutRefNo  ' END) END) END + 
                            ' FROM #TCOMSourceTracking AS A  ' +
                            ' JOIN #TMP_SOURCETABLE AS B ON A.IDOrder = B.IDOrder ' +
                            ' JOIN #TMP_SOURCEITEM AS  C ON A.IDX_NO  = C.IDX_NO ' +
                            ' JOIN _TCOMProgTable AS D WITH(NOLOCK) ON B.TableName = D.ProgTableName  '
          FROM _TCOMProgTable AS A WITH(NOLOCK) 
         WHERE A.ProgTableSeq = @SourceTableSeq
-- ��������
        EXEC SP_EXECUTESQL @SQL, N'@CompanySeq INT', @CompanySeq  
  
        SELECT @SQL = ''
    END
/************************************************************************************************************************************************************************/

/**********************************************************
    ������ȸ������                                         
**********************************************************/
    SELECT A.BizUnit           AS BizUnit,          --����ι��ڵ�
           A.SMImpKind         AS SMImpKind,        --���Ա����ڵ�
           A.BLNo              AS BLNo,             --BL��ȣ
           A.BLDate            AS BLDate,           --BL����
           A.BLRefNo           AS BLRefNo,          --BL������ȣ
           A.DeptSeq           AS DeptSeq,          --�μ��ڵ�
           A.EmpSeq            AS EmpSeq,           --����ڵ�
           A.CustSeq           AS CustSeq,          --�ŷ�ó�ڵ�
           A.CurrSeq           AS CurrSeq,          --��ȭ�ڵ�
           A.ExRate            AS ExRate,           --ȯ��
           A.UMPriceTerms      AS UMPriceTerms,     --���������ڵ�
           A.UMPayment1        AS UMPayment1,       --��������ڵ�
           A.UMPayment2        AS UMPayment2,       --�����ñ��ڵ�
           B.BLSeq             AS BLSeq,
           B.BLSerl            AS BLSerl,
           B.ItemSeq           AS ItemSeq,          --ǰ���ڵ�
           B.UnitSeq           AS UnitSeq,          --�����ڵ�
           B.Price             AS Price,            --����
           B.Qty               AS Qty,              --����
           B.CurAmt            AS CurAmt,           --�ݾ�
           B.DomAmt            AS DomAmt,           --��ȭ�ݾ�
           B.ShipDate          AS ShipDate,         --����������
           B.STDUnitSeq        AS STDUnitSeq,       --���ش����ڵ�
           B.STDQty            AS STDQty,           --���ش�������

           (SELECT BizUnitName FROM _TDABizUnit WHERE CompanySeq = @CompanySeq AND A.BizUnit   = BizUnit)       AS BizUnitName,         --����ι�
           (SELECT MinorName   FROM _TDASMinor  WHERE CompanySeq = @CompanySeq AND A.SMImpKind = MinorSeq)      AS SMImpTypeName,       --���Ա���
           (SELECT DeptName    FROM _TDADept    WHERE CompanySeq = @CompanySeq AND A.DeptSeq   = DeptSeq)       AS DeptName,            --�μ�
           (SELECT EmpName     FROM _TDAEmp     WHERE CompanySeq = @CompanySeq AND A.EmpSeq    = EmpSeq)        AS EmpName,             --���
           (SELECT CustName    FROM _TDACust    WHERE CompanySeq = @CompanySeq AND A.CustSeq   = CustSeq)       AS CustName,            --�ŷ�ó  
           (SELECT CurrName    FROM _TDACurr    WHERE CompanySeq = @CompanySeq AND A.CurrSeq   = CurrSeq)       AS CurrName,            --��ȭ
           (SELECT MinorName   FROM _TDAUMinor  WHERE CompanySeq = @CompanySeq AND A.UMPriceTerms = MinorSeq)   AS UMPriceTermsName,    --��������
           (SELECT MinorName   FROM _TDAUMinor  WHERE CompanySeq = @CompanySeq AND A.UMPayment1 = MinorSeq)     AS UMPayment1Name,      --�������
           (SELECT MinorName   FROM _TDAUMinor  WHERE CompanySeq = @CompanySeq AND A.UMPayment2 = MinorSeq)     AS UMPayment2Name,      --�����ñ�
           L.ItemNo            AS ItemNo,              --ǰ���ȣ
           L.ItemName          AS ItemName,            --ǰ���
           L.Spec              AS Spec,                --�԰�
           (SELECT UnitName    FROM _TDAUnit  WHERE CompanySeq = @CompanySeq AND B.UnitSeq = UnitSeq)           AS UnitName,            --����
           (SELECT UnitName    FROM _TDAUnit  WHERE CompanySeq = @CompanySeq AND B.STDUnitSeq = UnitSeq)        AS STDUnitName,         --���ش���
           Y.PJTName           AS PJTName,             --������Ʈ��
           Y.PJTNo             AS PJTNo,               -- ������Ʈ��ȣ
           Y.PJTSeq            AS PJTSeq,              -- ������Ʈ�ڵ�
           A.IsPJT             AS IsPJT,
           (SELECT MinorName   FROM _TDASMinor  WHERE CompanySeq = @CompanySeq AND Z.SMProgressType = MinorSeq) AS SMProgressTypeName,  -- �������           
           B.Remark            AS Remark,              -- ���
           B.LotNo             AS LotNo,               -- LotNo
           ISNULL(AW.SourceNo,'')     AS SourceNo,         -- �߰� 20091201 �ڼҿ� 
           ISNULL(AW.SourceRefNo, '') AS SourceRefNo,   -- �߰� 20091201 �ڼҿ�
           M2.ItemNo            AS UpperUnitNo,   
           M2.ItemName          AS UpperUnitName,     
           M4.ItemName          AS TopUnitName,   
           M4.ItemNo            AS TopUnitNo,
           M5.UMMatQuality      AS UMMatQuality,
           M6.MinorName         AS UMMatQualityName,
           (B.Qty - ISNULL(DQ.DelvQty, 0)) AS NotDelvQty, -- 20130625 �ڼ�ȣ �߰�
           A.PrePaymentDate -- ��Ÿ���� ����������

      FROM #TEMP_TUIImpBLItem   AS BL 
            JOIN _TUIImpBL      AS A WITH(NOLOCK) ON BL.CompanySeq = A.CompanySeq 
                                                 AND BL.BLSeq      = A.BLSeq
            JOIN _TUIImpBLItem  AS B WITH(NOLOCK) ON BL.CompanySeq = B.CompanySeq 
                                                 AND BL.BLSeq      = B.BLSeq
                                                 AND BL.BLSerl     = B.BLSerl
            JOIN #TEMPTUIImpBLProg AS Z WITH(NOLOCK) ON BL.BLSeq   = Z.BLSeq
                                                    AND BL.BLSerl  = Z.BLSerl
            LEFT OUTER JOIN _TDAItem       AS L WITH(NOLOCK) ON A.CompanySeq = L.CompanySeq 
                                                            AND B.ItemSeq    = L.ItemSeq
            LEFT OUTER JOIN _TPJTProject   AS Y WITH(NOLOCK) ON A.CompanySeq = Y.CompanySeq 
                                                            AND B.PJTSeq     = Y.PJTSeq
            LEFT OUTER JOIN #TempResult AS AW WITH(NOLOCK) ON A.CompanySeq = @CompanySeq  -- �߰� 20091202 �ڼҿ� 
                                                          AND B.BLSeq = AW.InOutSeq     -- �߰� 20091202 �ڼҿ� 
                                                          AND B.BLSerl = AW.InOutSerl   -- �߰� 20091202 �ڼҿ�
           LEFT OUTER JOIN _TPJTBOM       AS M5 WITH(NOLOCK) ON A.CompanySeq = M5.CompanySEq    
                                                           AND B.PJTSeq = M5.PJTSeq    
                                                           AND B.WBSSeq = M5.BOMSerl    
           LEFT OUTER JOIN _TPJTBOM       AS M1 WITH(NOLOCK) ON B.CompanySeq = M1.CompanySeq    
                                                           AND B.PJTSeq = M1.PJTSeq AND M1.BOMSerl <> -1 AND M5.UpperBOMSerl = M1.BOMSerl AND ISNULL(M1.BeforeBOMSerl,0) = 0 -- ���� BOM    
           LEFT OUTER JOIN _TDAItem       AS M2 WITH(NOLOCK) ON B.CompanySEq = M2.CompanySeq    
                                                           AND M1.ItemSeq = M2.ItemSeq    
           LEFT OUTER JOIN _TPJTBOM       AS M3 WITH(NOLOCK) ON B.CompanySeq = M3.CompanySeq    
                                                           AND B.PJTSeq = M3.PJTSeq    
                                                           AND M3.BOMSerl <> -1    
                                                           AND ISNULL(M3.BeforeBOMSerl,0) = 0    
                                                           AND SUBSTRING(M1.TreeCode,1,6) = M3.TreeCode     -- �ֻ���    
                                                           AND ISNUMERIC(REPLACE(M3.BOMLevel,'.','/')) = 1 
           LEFT OUTER JOIN _TDAItem       AS M4 WITH(NOLOCK) ON B.CompanySeq = M4.CompanySeq    
                                                           AND M3.ItemSeq = M4.ItemSeq   
           LEFT OUTER JOIN _TDAUMinor     AS M6 WITH(NOLOCK) ON B.CompanySeq = M6.CompanySeq
                                                            AND M5.UMMatQuality = M6.MinorSeq
           LEFT OUTER JOIN #TEMP_DelvQty  AS DQ WITH(NOLOCK) ON B.CompanySeq = DQ.CompanySeq
                                                            AND B.BLSeq      = DQ.BLSeq
                                                            AND B.BLSerl     = DQ.BLSerl

    WHERE --(@SMProgressType = 0 OR Z.SMProgressType = @SMProgressType) 
	      (@SMProgressType = 0 OR (Z.SMProgressType = @SMProgressType) OR ( @SMProgressType = 8098001 AND Z.SMProgressType IN (SELECT MinorSeq FROM _TDASMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 1037 AND Serl = 1001 AND ValueText = '1' )) )           
      AND (@SourceNo = '' OR AW.SourceNo LIKE @SourceNo + '%')           -- �߰� 20091202 �ڼҿ�
      AND (@SourceRefNo = '' OR AW.SourceRefNo LIKE @SourceRefNo + '%')  -- �߰� 20091202 �ڼҿ�
      AND (@UMSupplyType = 0  OR M5.UMSupplyType = @UMSupplyType)    
      AND (@TopUnitName  = '' OR M4.ItemName LIKE @TopUnitName + '%')         
      AND (@TopUnitNo    = '' OR M4.ItemNo   LIKE @TopUnitNo + '%') 
 ORDER BY A.BLDate, A.BLNo, B.BLSerl


RETURN
GO


