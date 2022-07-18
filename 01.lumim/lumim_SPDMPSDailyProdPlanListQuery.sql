  
IF OBJECT_ID('lumim_SPDMPSDailyProdPlanListQuery') IS NOT NULL 
    DROP PROC lumim_SPDMPSDailyProdPlanListQuery 
GO 
    
-- v2013.08.13 
    
-- �����ȹ��ȸ_lumim(��ȸ) by����õ 
CREATE PROC lumim_SPDMPSDailyProdPlanListQuery 
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @docHandle      INT, 
            @ItemName       NVARCHAR(200), 
            @ItemNo         NVARCHAR(100), 
            @ProdPlanNo     NVARCHAR(100), 
            @DelvDateTo     NVARCHAR(8), 
            @CustSeq        INT, 
            @ProdPlanDateFr NVARCHAR(8), 
            @ProdPlanDateTo NVARCHAR(8), 
            @DelvDateFr     NVARCHAR(8)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @ItemName        = ItemName, 
           @ItemNo          = ItemNo, 
           @ProdPlanNo      = ProdPlanNo, 
           @DelvDateTo      = DelvDateTo, 
           @CustSeq         = CustSeq, 
           @ProdPlanDateFr  = ProdPlanDateFr, 
           @ProdPlanDateTo  = ProdPlanDateTo, 
           @DelvDateFr      = DelvDateFr 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      
	  WITH (
            ItemName        NVARCHAR(200), 
            ItemNo          NVARCHAR(100), 
            ProdPlanNo      NVARCHAR(100), 
            DelvDateTo      NVARCHAR(8), 
            CustSeq         INT, 
            ProdPlanDateFr  NVARCHAR(8), 
            ProdPlanDateTo  NVARCHAR(8), 
            DelvDateFr      NVARCHAR(8)
           )
    
    IF @DelvDateTo = '' SELECT @DelvDateTo = '99991231' 
    
    -- �����Ƿ� ��õã��, BEGIN
    
    CREATE TABLE #Temp (IDX_NO INT IDENTITY, ProdPlanSeq INT) 
            
    INSERT INTO #Temp(ProdPlanSeq) 
         SELECT ProdPlanSeq
           FROM _TPDMPSDailyProdPlan
          WHERE CompanySeq = @CompanySeq
            AND EndDate BETWEEN @ProdPlanDateFr AND @ProdPlanDateTo 
            AND (@ProdPlanNo = '' OR ProdPlanNo LIKE @ProdPlanNo + '%')
    
    CREATE TABLE #TMP_SourceTable 
            (IDOrder   INT, 
             TableName NVARCHAR(100))  
    
    INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
         SELECT 1, '_TPDMPSProdReqItem' 
    
    CREATE TABLE #TCOMSourceTracking 
            (IDX_NO  INT, 
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)) 
    
    EXEC _SCOMSourceTracking 
             @CompanySeq = @CompanySeq, 
             @TableName = '_TPDMPSDailyProdPlan', 
             @TempTableName = '#Temp', 
             @TempSeqColumnName = 'ProdPlanSeq', 
             @TempSerlColumnName = '', 
             @TempSubSerlColumnName = '' 
    
    -- �����Ƿ� ��õã��, END
    
    -- ������ȸ   
    SELECT ISNULL(K.CfmCode, 0) AS IsConfirm, -- Ȯ������
           A.ProdPlanSeq, -- �����ȹ�ڵ�
           A.ProdPlanNo, -- �����ȹ��ȣ
           B.FactUnitName, -- ��������
           A.FactUnit, -- ���������ڵ�
           A.EndDate AS ProdPlanEndDate, -- �����ȹ�� 
           C.ItemNo, -- ǰ��
           C.Itemname, -- ǰ��
           C.Spec, -- �԰�
           A.ProdQty AS Qty, -- ����
           O.CustName, -- �ŷ�ó
           N.CustSeq, -- �ŷ�ó�ڵ�
           Q.MinorName AS ProgramName, -- ���α׷�
           P.UMItemClass AS ProgramSeq, -- ���α׷��ڵ�
           A.WorkCond1, -- �ֵ�
           A.WorkCond2, -- ��ǥ
           A.WorkCond3, -- VF
           D.MinorName AS WorkCond4, -- D/B Paste 
           A.WorkCond4 AS WorkCond3Seq, -- D/B Paste�ڵ� 
           N.DelvDate, -- ������
           E.MinorName AS WorkCond5, -- Resin
           A.WorkCond5 AS WorkCond5Seq, -- Resin�ڵ�
           A.Remark, -- ���
           F.MinorName AS WorkCond6, -- ChipMaker
           A.WorkCond6 AS WorkCond6Seq, -- ChopMaker�ڵ� 
           CASE WHEN ISNULL(H.ItemBOMRevRemark,'') = '' THEN A.BOMRev ELSE H.ItemBOMRevRemark END AS BOMRevName, -- BOM����
           A.BOMRev, 
           A.ProcRev, -- �����帧���� 
           I.ProcRevName, -- �����帧������
           G.AssetName, -- ǰ���ڻ�з�
           A.DeptSeq AS ProdDeptSeq, -- ��������μ��ڵ�
           J.DeptName AS ProdDeptName, -- ��������μ�
           CASE WHEN ISNULL(R.ValueSeq,0) = 0 THEN ''     
                ELSE ( SELECT ISNULL(MinorName,'')       
                         FROM _TDAUMinor WITH(NOLOCK)       
                        WHERE CompanySeq = @CompanySeq AND MinorSeq = R.ValueSeq ) END AS PKGName,  -- ǰ���ߺз� 
           STUFF(STUFF(C.ItemNo,1,18,''),2,10,'') + 'C' AS Chip, -- Chip
           STUFF(STUFF(STUFF(C.ItemNo,1,5,''),3,20,''),2,0,'.') + 'T' AS LF -- L_F
           
      FROM _TPDMPSDailyProdPlan           AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAFactUnit        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit ) 
      JOIN _TDAItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq 
                                       AND C.AssetSeq = (
                                                         SELECT EnvValue 
                                                           FROM lumim_TCOMEnv 
                                                          WHERE CompanySeq = @CompanySeq AND EnvSeq = 3 AND EnvSerl = 1
                                                        ) 
                                         )               
      LEFT OUTER JOIN _TDAUMinor          AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.WorkCond4 ) 
      LEFT OUTER JOIN _TDAUMinor          AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.WorkCond5 ) 
      LEFT OUTER JOIN _TDAUMinor          AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.WorkCond6 ) 
      LEFT OUTER JOIN _TDAItemAsset       AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.AssetSeq = C.AssetSeq ) 
      LEFT OUTER JOIN _TPDBOMManagement   AS H WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND A.ItemSeq = H.ItemSeq AND A.BOMRev = H.ItemBomRev ) 
      LEFT OUTER JOIN _TPDROUItemProcRev  AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND A.ItemSeq = I.ItemSeq AND A.ProcRev = I.ProcRev ) 
      LEFT OUTER JOIN _TDADept            AS J WITH(NOLOCK) ON ( J.CompanySeq = @COmpanySeq AND J.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TPDMPSDailyProdPlan_Confirm AS K WITH(NOLOCK) ON ( A.CompanySeq = K.CompanySeq AND A.ProdPlanSeq = K.CfmSeq ) 
      LEFT OUTER JOIN #TEMP               AS L WITH(NOLOCK) ON ( L.ProdPlanSeq = A.ProdPlanSeq ) 
      LEFT OUTER JOIN #TCOMSourceTracking AS M WITH(NOLOCK) ON ( M.IDX_NO = L.IDX_NO ) 
      LEFT OUTER JOIN _TPDMPSProdReqItem  AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND N.ProdReqSeq = M.Seq ) 
      LEFT OUTER JOIN _TDACust            AS O WITH(NOLOCK) ON ( O.CompanySeq = @CompanySeq AND O.CustSeq = N.CustSeq ) 
      LEFT OUTER JOIN _TDAItemClass       AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.ItemSeq = C.ItemSeq AND P.UMajorItemClass = 2001 ) 
      LEFT OUTER JOIN _TDAUMinor          AS Q WITH(NOLOCK) ON ( Q.CompanySeq = @CompanySeq AND Q.MajorSeq = LEFT( P.UMItemClass, 4 ) AND P.UMItemClass = Q.MinorSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue     AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND R.MajorSeq = 2001 AND R.MinorSeq = Q.MinorSeq AND R.Serl = 1001 ) 
      
     WHERE A.CompanySeq = @CompanySeq  
       AND A.EndDate BETWEEN @ProdPlanDateFr AND @ProdPlanDateTo 
       AND N.DelvDate BETWEEN @DelvDateFr AND @DelvDateTo
       AND (@CustSeq = 0 OR N.CustSeq = @CustSeq)
       AND (@ItemNo = '' OR C.ItemNo LIKE @ItemNo + '%') 
       AND (@ItemName = '' OR C.ItemName LIKE @ItemName + '%')
       AND (@ProdPlanNo = '' OR A.ProdPlanNo LIKE @ProdPlanNo + '%')
    
    RETURN 
    
GO
exec lumim_SPDMPSDailyProdPlanListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ProdPlanDateFr>20130801</ProdPlanDateFr>
    <ProdPlanDateTo>20130830</ProdPlanDateTo>
    <DelvDateFr />
    <DelvDateTo />
    <CustSeq />
    <ItemNo />
    <ItemName />
    <ProdPlanNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017126,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014663