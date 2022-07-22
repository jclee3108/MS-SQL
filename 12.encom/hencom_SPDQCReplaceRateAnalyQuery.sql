IF OBJECT_ID('hencom_SPDQCReplaceRateAnalyQuery') IS NOT NULL 
    DROP PROC hencom_SPDQCReplaceRateAnalyQuery
GO 

-- v2017.04.17 

/************************************************************                
 ��  �� - ġȯ���м���ȸ_hencom                
 �ۼ��� - 2016.01.19                
 �ۼ��� - kth                
 ����: by�ڼ��� 2016.05.11              
************************************************************/                 
CREATE PROCEDURE hencom_SPDQCReplaceRateAnalyQuery                 
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
            ,@DateFr        NCHAR(8)                  
            ,@DateTo        NCHAR(8)                  
            ,@DeptSeq       INT                   
            ,@SMQryUnitSeq  INT
            ,@IsType        NCHAR(1)
                  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                  
                  
    SELECT   @DateFr            =   ISNULL(DateFr,''   )                  
            ,@DateTo            =   ISNULL(DateTo,''   )                  
            ,@DeptSeq           =   ISNULL(DeptSeq     ,0)                   
            ,@SMQryUnitSeq      =   ISNULL(SMQryUnitSeq,0) 
            ,@IsType            =   ISNULL(IsType, '0')                 
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)                  
      WITH  (DateFr        NCHAR(8)                  
            ,DateTo        NCHAR(8)                  
            ,DeptSeq       INT                   
            ,SMQryUnitSeq  INT
            ,IsType        NCHAR(1))                  
                        
                                          
    DECLARE @TotOutQty DECIMAL(19,5),       -- ���Ͻ��� �Ѽ���                  
            @TotOKQty  DECIMAL(19,5),       -- ������� �Ѽ���                  
            @AmtUnit   INT                  -- �ݾ״��� ����                  
                                              
                                              
    IF ISNULL(@SMQryUnitSeq, 0) = 0                   
       SELECT @AmtUnit = 1                       
                  
    ELSE                      
                  
        SELECT @AmtUnit = MinorValue                    
          FROM _TDASMInor WITH(NOLOCK)                       
         WHERE CompanySeq = @CompanySeq                    
           AND MinorSeq   = @SMQryUnitSeq                    
                   
-- ��õȭ��(���Ͻ�����������, �����������, ���ų�ǰ, ���԰����, ���������ߵ��)         
                   
  /*0������ ���� ��� ó��*/                              
     SET ANSI_WARNINGS OFF                              
     SET ARITHIGNORE ON                              
     SET ARITHABORT OFF                  
      
    -- �������翩��
    SELECT A.MinorSeq AS ItemClassSSeq
      INTO #IsType
      FROM _TDAUMinorValue AS A 
     WHERE A.CompanySeq = @CompanySeq
       AND A.Majorseq = 2004 
       AND A.Serl = 2002 
       AND A.ValueText = '1' 
    
    --select * from #IsType 
    --return 

    --���ܵǴ� �����
    CREATE TABLE #TMP_ExceptMat (MatItemSeq INT)

    INSERT #TMP_ExceptMat(MatItemSeq)
    VALUES (21715) --�ٶ�_�۾�
    INSERT #TMP_ExceptMat(MatItemSeq)
    VALUES (61040) --ŻȲ����

--select * from #TMP_ExceptMat return
    --����Һ� ���ܰ��� ���Ѵ�.        
    --ǰ���� ȭ���� �μ��� ����      
        DECLARE @AvgPrice   DECIMAL(19,5)         

    SELECT        
        N.DeptSeq ,              
        SUM(CASE WHEN S1.ItemClassSSeq = 2004027 THEN ISNULL(A.Amt,0) ELSE 0 END ) AS OPCMAmt ,                
        SUM(CASE WHEN S1.ItemClassSSeq = 2004034 THEN ISNULL(A.Amt,0) ELSE 0 END )AS SCMAmt    ,                 
        SUM(CASE WHEN S1.ItemClassSSeq = 2004035 THEN ISNULL(A.Amt,0) ELSE 0 END )AS SPMAmt    ,                
        SUM(CASE WHEN S1.ItemClassSSeq = 2004048 THEN ISNULL(A.Amt,0) ELSE 0 END )AS FAMAmt     ,         
        SUM(CASE WHEN S1.ItemClassSSeq = 2004027 THEN ISNULL(A.Qty,0) ELSE 0 END )AS OPCMQty ,                
        SUM(CASE WHEN S1.ItemClassSSeq = 2004034 THEN ISNULL(A.Qty,0) ELSE 0 END )AS SCMQty    ,                 
        SUM(CASE WHEN S1.ItemClassSSeq = 2004035 THEN ISNULL(A.Qty,0) ELSE 0 END )AS SPMQty    ,                
        SUM(CASE WHEN S1.ItemClassSSeq = 2004048 THEN ISNULL(A.Qty,0) ELSE 0 END )AS FAMQty     ,            
        SUM(ISNULL(A.Qty,0)) AS Qty,                
        SUM(ISNULL(A.Amt,0)) AS Amt                
      INTO #TMPOutPrice                
    FROM _TESMGInOutStock AS A WITH(NOLOCK)             
        LEFT OUTER JOIN _VDAGetItemClass AS S1 WITH(NOLOCK) ON A.CompanySeq = S1.CompanySeq                   
                                                 AND A.ItemSeq = S1.ItemSeq           
      LEFT OUTER JOIN _TDAItem AS N WITH(NOLOCK) ON N.CompanySeq = A.CompanySeq AND N.ItemSeq = A.ItemSeq               
    WHERE A.inoutdate BETWEEN @DateFr AND @DateTo                
    AND A.InOut = -1                
    AND ISNULL(A.itemseq,0) <> 0                
    AND S1.ItemClassSSeq IN (2004027, 2004034, 2004035, 2004048)         
    AND ISNULL(N.DeptSeq,0) <> 0         --�԰ݿ� ������ִ� �͸� ����� �ȴ�.    
    AND A.ItemSeq NOT IN (SELECT MatItemSeq FROM #TMP_ExceptMat)   
    AND ( @IsType = '0' OR ( @IsType = '1' AND NOT EXISTS (SELECT 1 FROM #IsType WHERE ItemClassSSeq = S1.ItemClassSSeq) ) )
    GROUP BY N.DeptSeq              
      
    SELECT DeptSeq ,      
            ISNULL(OPCMAmt / OPCMQty,0) AS OPCMAvg , --������� OPC���ܰ�      
            ISNULL(SCMAmt / SCMQty,0) AS SCMAvg, --SC      
            ISNULL(SPMAmt / SPMQty,0) AS SPMAvg , --SP      
            ISNULL(FAMAmt / FAMQty,0) AS FAMAvg, --FA      
            ISNULL(Amt / Qty,0) AS DeptAvg --����� ��ü��ü�� ������ܰ�      
    INTO #TMPDeptPrice      
    FROM #TMPOutPrice       
          
      
    SELECT @AvgPrice = SUM(ISNULL(Amt,0)) / SUM(ISNULL(Qty,0))      
    FROM #TMPOutPrice AS A      
    WHERE (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq )      
    AND EXISTS (SELECT 1 FROM hencom_TDADeptAdd WITH(NOLOCK)       
                            WHERE CompanySeq  = @CompanySeq       
                            AND DeptSeq = A.DeptSeq       
                            AND DispQC = '1')       
      
--    select @AvgPrice return      
--    select * from #TMPDeptPrice      
--    return                
--select @OPCMAvg,@SCMAvg,@SPMAvg,@FAMAvg                
                
    -- 1�� ��õ���̺�                  
    CREATE TABLE #TPDQCReplace                  
    (                     
        DeptSeq         INT,                -- ������ڵ�                  
        DeptName     NVARCHAR(200),      -- �����                  
        OutQty         DECIMAL(19,5),      -- ���Ͻ���(��)-(���Ͻ�����������)                  
        OKQty         DECIMAL(19,5),      -- �������(��)-(���Ͻ�����������)                  
        PlanOPC      DECIMAL(19,5),      -- ��ȹOPC                  
        PlanSC         DECIMAL(19,5),      -- ��ȹSC                  
        PlanSP         DECIMAL(19,5),      -- ��ȹSP                  
        PlanFA         DECIMAL(19,5),      -- ��ȹFA                  
        ResOPC          DECIMAL(19,5),      -- ����OPC-(�����������)                  
        ResSC         DECIMAL(19,5),      -- ����SC-(�����������)                  
        ResSP         DECIMAL(19,5),      -- ����SP-(�����������)                  
        ResFA         DECIMAL(19,5),      -- ����FA-(�����������)                  
        CementPlan      DECIMAL(19,5),      -- ��ü����ȹ                  
        CementRes     DECIMAL(19,5),      -- ��ü������-(�����������)                  
        InQty         DECIMAL(19,5),      -- ���԰�-(���԰����)                  
        InAmt         DECIMAL(19,5),      -- ���԰��-(���԰����)                  
        -------------------------------------------------------------- ������� �÷�                  
        OPCInQty     DECIMAL(19,5),      -- OPC���԰�-(���԰����)                  
        SCInQty         DECIMAL(19,5),      -- SC���԰�-(���԰����)      
        SPInQty         DECIMAL(19,5),      -- SP���԰�-(���԰����)                  
        FAInQty         DECIMAL(19,5),      -- FA���԰�-(���԰����)                 
        OPCDelvQty     DECIMAL(19,5),      -- OPC���ų�ǰ����-(���ų�ǰ)                  
        SCDelvQty     DECIMAL(19,5),      -- SC���ų�ǰ����-(���ų�ǰ)                  
        SPDelvQty     DECIMAL(19,5),      -- SP���ų�ǰ����-(���ų�ǰ)                  
        FADelvQty     DECIMAL(19,5),      -- FA���ų�ǰ����-(���ų�ǰ)                  
        CementDelvQty DECIMAL(19,5),      -- ��ü���ų�ǰ����-(���ų�ǰ)      
        OPCDelvAmt     DECIMAL(19,5),      -- OPC���ų�ǰ���ް�-(���ų�ǰ)                  
        SCDelvAmt     DECIMAL(19,5),      -- SC���ų�ǰ���ް�-(���ų�ǰ)                  
          SPDelvAmt     DECIMAL(19,5),      --  SP���ų�ǰ���ް�-(���ų�ǰ)                  
        FADelvAmt     DECIMAL(19,5),      -- FA���ų�ǰ���ް�-(���ų�ǰ)                  
        CementDelvAmt DECIMAL(19,5),      -- ��ü���ų�ǰ���ް�-(���ų�ǰ)                  
    )                  
      ------------------------------------ ����Ұ���(�߰�����) ���� ����Ҹ� ����                   
    SELECT  A.DeptSeq                  
           ,A.DeptName                  
      INTO #TPDQCReplaceDept                  
        FROM _TDADept AS A WITH (NOLOCK)                   
        LEFT OUTER JOIN hencom_TDADeptAdd AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.DeptSeq = B.DeptSeq                   
     WHERE  A.CompanySeq = @CompanySeq                  
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)                             
        AND B.DispQC = '1'         
              
    ------------------------------------ ��ȹ (���Ͻ������������� ��������� ������)       2016.03.30                  
    SELECT A.DeptSeq, A.GoodItemSeq, LEFT(A.WorkDate, 6) AS WorkDate, SUM(A.ProdQty) AS ProdQty                   
      INTO #TPDQPlan                  
        FROM hencom_TIFProdWorkReportCloseSum AS A WITH(NOLOCK)                    
      JOIN #TPDQCReplaceDept AS B WITH (NOLOCK) ON A.CompanySeq = @CompanySeq AND A.DeptSeq = B.DeptSeq                  
     WHERE A.CompanySeq = @CompanySeq                  
       AND A.WorkDate BETWEEN @DateFr AND @DateTo                             
     GROUP BY A.DeptSeq, A.GoodItemSeq, LEFT(A.WorkDate, 6)                  
                  
    --##################################################################################### ��õ������ ��������                  
    INSERT  #TPDQCReplace(DeptSeq, DeptName, OutQty, OKQty, PlanOPC, PlanSC, PlanSP, PlanFA,                  
                          ResOPC, ResSC, ResSP, ResFA, CementPlan, CementRes, InQty, InAmt,                  
                            OPCInQty, SCInQty, SPInQty, FAInQty,                   
                          OPCDelvQty, SCDelvQty, SPDelvQty, FADelvQty, CementDelvQty,                   
                          OPCDelvAmt, SCDelvAmt, SPDelvAmt, FADelvAmt, CementDelvAmt)                  
                  
                  
    --##################### ���Ͻ�����������(���Ͻ���, �������) #####################                  
    SELECT A.DeptSeq                  
           ,A.DeptName                  
           ,SUM(C.OutQty) AS OutQty     -- ���ϼ���                  
           ,SUM(C.ProdQty) AS OKQty     -- �������                  
           ,0 AS PlanOPC                  
           ,0 AS PlanSC                  
           ,0 AS PlanSP                  
           ,0 AS PlanFA                  
           ,0 AS ResOPC                  
           ,0 AS ResSC                  
           ,0 AS ResSP                  
           ,0 AS ResFA                  
           ,0 AS CementPlan                  
           ,0 AS CementRes                  
           ,0 AS InQty                  
           ,0 AS InAmt                  
           ,0 AS OPCInQty                  
           ,0 AS SCInQty                  
           ,0 AS SPInQty                  
           ,0 AS FAInQty                  
           ,0 AS OPCDelvQty                  
           ,0 AS SCDelvQty                  
           ,0 AS SPDelvQty                  
           ,0 AS FADelvQty                  
           ,0 AS CementDelvQty                  
           ,0 AS OPCDelvAmt                  
           ,0 AS SCDelvAmt                  
           ,0 AS SPDelvAmt                  
           ,0 AS FADelvAmt                  
           ,0 AS CementDelvAmt                  
      FROM #TPDQCReplaceDept AS A                  
        JOIN hencom_TIFProdWorkReportCloseSum AS C  WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND A.DeptSeq = C.DeptSeq                  
     WHERE C.CompanySeq = @CompanySeq                  
       AND C.WorkDate BETWEEN @DateFr AND @DateTo                  
     GROUP BY A.DeptSeq, A.DeptName                  
                  
    UNION ALL                   
                  
      --##################### ġȯ�� ��ȹ(����Һз� OPC, SC, SP, FA) 2016.03.30 #####################                  
    SELECT A.DeptSeq                  
           ,A.DeptName                  
           ,0 AS OutQty     -- ���ϼ���                  
           ,0 AS OKQty      -- �������                  
           ,CASE WHEN C.ItemClassSSeq = 2004027 THEN C.ItemQty * D.ProdQty END AS PlanOPC                  
               ,CASE WHEN C.ItemClassSSeq = 2004034 THEN C.ItemQty * D.ProdQty END AS PlanSC                  
           ,CASE WHEN C.ItemClassSSeq = 2004035 THEN C.ItemQty * D.ProdQty END AS PlanSP                  
           ,CASE WHEN C.ItemClassSSeq = 2004048 THEN C.ItemQty * D.ProdQty END AS PlanFA                  
           ,0 AS ResOPC                  
           ,0 AS ResSC                  
           ,0 AS ResSP                  
           ,0 AS ResFA                  
             ,0 AS CementPlan                   
           ,0 AS CementRes                  
           ,0 AS InQty                  
           ,0 AS InAmt                  
           ,0 AS OPCInQty                  
           ,0 AS SCInQty                  
           ,0 AS SPInQty                  
           ,0 AS FAInQty                  
           ,0 AS OPCDelvQty                  
             ,0 AS SCDelvQty                  
           ,0 AS SPDelvQty              
           ,0 AS FADelvQty                  
           ,0 AS CementDelvQty                  
           ,0 AS OPCDelvAmt                  
           ,0 AS SCDelvAmt                  
           ,0 AS SPDelvAmt                  
           ,0 AS FADelvAmt                  
           ,0 AS CementDelvAmt                  
      FROM #TPDQCReplaceDept AS A                  
      JOIN hencom_VPDQCStMixMat AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND A.DeptSeq = C.DeptSeq                  
      JOIN #TPDQPlan AS D WITH (NOLOCK) ON D.DeptSeq = C.DeptSeq AND D.GoodItemSeq = C.ItemSeq AND D.WorkDate = C.StYM                  
     WHERE C.CompanySeq = @CompanySeq                  
       AND C.StYM BETWEEN LEFT(@DateFr, 6) AND LEFT(@DateTo, 6)                  
         AND C.ItemClassSSeq IN (2004027, 2004034, 2004035, 2004048)        -- ����Һз� OPC, SC, SP, FA�ΰ͸� 
         AND C.MatItemSeq NOT IN (SELECT MatItemSeq FROM #TMP_ExceptMat)                 
                         
    UNION ALL                   
                  
    --##################### ġȯ�� ��ȹ(�����з� ��ü) 2016.03.30 #####################                  
    SELECT A.DeptSeq                  
           ,A.DeptName                  
           ,0 AS OutQty     -- ���ϼ���                  
           ,0 AS OKQty      -- �������                  
           ,0 AS PlanOPC                  
           ,0 AS PlanSC                  
           ,0 AS PlanSP                  
           ,0 AS PlanFA                  
           ,0 AS ResOPC                  
           ,0 AS ResSC                  
           ,0 AS ResSP                  
           ,0 AS ResFA                  
           ,CASE WHEN C.ItemClassLSeq = 2006003 THEN C.ItemQty * D.ProdQty END AS CementPlan                  
           ,0 AS CementRes                  
           ,0 AS InQty                  
           ,0 AS InAmt                  
           ,0 AS OPCInQty                  
           ,0 AS SCInQty                  
           ,0 AS SPInQty                  
           ,0 AS FAInQty                  
           ,0 AS OPCDelvQty              
           ,0 AS SCDelvQty                  
           ,0 AS SPDelvQty                  
           ,0 AS FADelvQty                  
           ,0 AS CementDelvQty                  
           ,0 AS OPCDelvAmt                  
           ,0 AS SCDelvAmt                  
           ,0 AS SPDelvAmt                  
           ,0 AS FADelvAmt                  
           ,0 AS CementDelvAmt                  
      FROM #TPDQCReplaceDept AS A                  
      JOIN hencom_VPDQCStMixMat AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND A.DeptSeq = C.DeptSeq                  
        JOIN #TPDQPlan AS D WITH (NOLOCK) ON D.DeptSeq = C.DeptSeq AND D.GoodItemSeq = C.ItemSeq AND D.WorkDate = C.StYM                  
     WHERE C.CompanySeq = @CompanySeq                  
         AND C.StYM BETWEEN LEFT(@DateFr, 6) AND LEFT(@DateTo, 6)                  
       AND C.ItemClassLSeq IN (2006003)        -- �����з� ��ü�ΰ͸�  
       AND C.MatItemSeq NOT IN (SELECT MatItemSeq FROM #TMP_ExceptMat)                
                         
    UNION ALL                   
                  
    --##################### �����������(����Һз� OPC, SC, SP, FA ȯ�����Լ���) #####################                  
    /*SELECT A.DeptSeq                  
           ,A.DeptName                  
             ,0 AS OutQty     -- ���ϼ���                   
           ,0 AS OKQty      -- �������                  
           ,0 AS PlanOPC                  
           ,0 AS PlanSC                  
           ,0 AS PlanSP                  
           ,0 AS PlanFA                
           ,CASE WHEN S1.ItemClassSSeq = 2004027 THEN D.Qty END AS ResOPC                  
           ,CASE WHEN S1.ItemClassSSeq = 2004034 THEN D.Qty END AS ResSC                  
           ,CASE WHEN S1.ItemClassSSeq = 2004035 THEN D.Qty END AS ResSP                  
           ,CASE WHEN S1.ItemClassSSeq = 2004048 THEN D.Qty END AS ResFA                  
           ,0 AS CementPlan                  
             ,0 AS CementRes                  
           ,0 AS InQty                  
           ,0 AS InAmt                  
           ,0 AS OPCInQty                  
           ,0 AS SCInQty                  
           ,0 AS SPInQty                  
           ,0 AS FAInQty                  
           ,0 AS OPCDelvQty                  
           ,0 AS SCDelvQty                  
           ,0 AS SPDelvQty                  
           ,0 AS FADelvQty                  
           ,0 AS CementDelvQty                  
             ,0 AS OPCDelvAmt                  
           ,0 AS SCDelvAmt                  
           ,0 AS SPDelvAmt                  
           ,0 AS FADelvAmt                  
           ,0 AS CementDelvAmt                  
      FROM #TPDQCReplaceDept AS A                  
      JOIN hencom_TIFProdWorkReportCloseSum AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND A.DeptSeq = C.DeptSeq                  
      JOIN hencom_TIFProdMatInputCloseSum AS D WITH (NOLOCK) ON D.CompanySeq = C.CompanySeq AND D.SumMesKey = C.SumMesKey                  
                  
      -- ����з� ��                  
      LEFT OUTER JOIN _VDAGetItemClass AS S1 WITH(NOLOCK) ON D.CompanySeq = S1.CompanySeq                   
                                                         AND D.MatItemSeq = S1.ItemSeq                      
     WHERE C.CompanySeq = @CompanySeq                  
       AND C.WorkDate BETWEEN @DateFr AND @DateTo                  
       AND S1.ItemClassSSeq IN (2004027, 2004034, 2004035, 2004048)        -- ����Һз� OPC, SC, SP, FA�ΰ͸�                  
    */  
SELECT A.DeptSeq                  
           ,A.DeptName                  
             ,0 AS OutQty     -- ���ϼ���                   
           ,0 AS OKQty      -- �������                  
           ,0 AS PlanOPC                  
           ,0 AS PlanSC                  
           ,0 AS PlanSP                  
           ,0 AS PlanFA                
           ,CASE WHEN S1.ItemClassSSeq = 2004027 THEN SB.Qty*H.ConvFactor END AS ResOPC                  
           ,CASE WHEN S1.ItemClassSSeq = 2004034 THEN SB.Qty*H.ConvFactor END AS ResSC                  
           ,CASE WHEN S1.ItemClassSSeq = 2004035 THEN SB.Qty*H.ConvFactor END AS ResSP                  
           ,CASE WHEN S1.ItemClassSSeq = 2004048 THEN SB.Qty*H.ConvFactor END AS ResFA                  
           ,0 AS CementPlan                  
             ,0 AS CementRes                  
           ,0 AS InQty                  
           ,0 AS InAmt                  
           ,0 AS OPCInQty                  
           ,0 AS SCInQty                  
           ,0 AS SPInQty                  
           ,0 AS FAInQty                  
           ,0 AS OPCDelvQty                  
             ,0 AS SCDelvQty                   
           ,0 AS SPDelvQty                  
           ,0 AS FADelvQty                  
           ,0 AS CementDelvQty                  
             ,0 AS OPCDelvAmt                  
           ,0 AS SCDelvAmt                  
           ,0 AS SPDelvAmt                  
           ,0 AS FADelvAmt                  
           ,0 AS CementDelvAmt                  
      FROM #TPDQCReplaceDept AS A    
    JOIN (SELECT   
                (SELECT MAX(DeptSeq) FROM hencom_TDADeptAdd WHERE ProdDeptSeq = R.DeptSeq ) AS DeptSeq,  
            M.MatItemSeq ,  
            R.WorkDate ,  
            SUM(ISNULL(M.Qty,0)) AS Qty  
        FROM _TPDSFCMatinput AS M WITH(NOLOCK) 
        JOIN _TPDSFCWorkReport AS R WITH(NOLOCK) ON R.CompanySeq = M.CompanySeq AND R.WorkReportSeq = M.WorkReportSeq     
  
        WHERE M.CompanySeq = @CompanySeq   
        AND R.WorkDate BETWEEN @DateFr AND @DateTo  
        GROUP BY R.DeptSeq,M.MatItemSeq ,R.WorkDate  
    ) AS SB ON SB.DeptSeq = A.DeptSeq  
     LEFT OUTER JOIN _VDAGetItemClass AS S1 WITH(NOLOCK) ON @CompanySeq = S1.CompanySeq                   
                                                            AND SB.MatItemSeq = S1.ItemSeq   
     LEFT OUTER JOIN hencom_VPDConvFactorDate AS H (NOLOCK) ON H.CompanySeq = @CompanySeq   
                                                        AND H.DeptSeq = SB.DeptSeq   
                                                        AND H.ItemSeq = SB.MatItemSeq    
                                                        AND SB.WorkDate BETWEEN H.StartDate AND H.EndDate   
    WHERE  S1.ItemClassSSeq IN (2004027, 2004034, 2004035, 2004048)        -- ����Һз� OPC, SC, SP, FA�ΰ͸�  
    AND SB.MatItemSeq NOT IN (SELECT MatItemSeq FROM #TMP_ExceptMat)
  
 /*  
      UNION ALL                   
              
      --##################### �����������(�����з� ��ü ȯ�����Լ���) #####################                  
    SELECT A.DeptSeq                  
           ,A.DeptName                  
           ,0 AS OutQty     -- ���ϼ���                  
           ,0 AS OKQty      -- �������                  
           ,0 AS PlanOPC                  
           ,0 AS PlanSC                  
           ,0 AS PlanSP                  
           ,0 AS PlanFA                  
           ,0 AS ResOPC                  
           ,0 AS ResSC                  
           ,0 AS ResSP                  
           ,0 AS ResFA                  
           ,0 AS CementPlan                  
           ,CASE WHEN S1.ItemClassLSeq = 2006003 THEN D.Qty END AS CementRes --�����߷� ȯ��Ǳ� ���� ����. ����2016.05.10 by�ڼ���                 
           ,0 AS InQty                  
           ,0 AS InAmt                  
           ,0 AS OPCInQty                  
           ,0 AS SCInQty                  
           ,0 AS SPInQty                  
           ,0 AS FAInQty                  
           ,0 AS OPCDelvQty                  
           ,0 AS SCDelvQty                  
           ,0 AS SPDelvQty                  
           ,0 AS FADelvQty                  
           ,0 AS CementDelvQty      
           ,0 AS OPCDelvAmt              
           ,0 AS SCDelvAmt                  
           ,0 AS SPDelvAmt                  
           ,0 AS FADelvAmt                  
           ,0 AS CementDelvAmt                  
      FROM #TPDQCReplaceDept AS A                  
      JOIN hencom_TIFProdWorkReportCloseSum AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND A.DeptSeq = C.DeptSeq                  
      JOIN hencom_TIFProdMatInputCloseSum AS D WITH (NOLOCK) ON D.CompanySeq = C.CompanySeq AND D.SumMesKey = C.SumMesKey                  
                  
      -- ����з� ��                  
        LEFT OUTER JOIN _VDAGetItemClass AS S1 WITH(NOLOCK) ON D.CompanySeq = S1.CompanySeq                   
                                                         AND D.MatItemSeq = S1.ItemSeq                      
     WHERE C.CompanySeq = @CompanySeq                  
       AND C.WorkDate BETWEEN @DateFr AND @DateTo                  
       AND S1.ItemClassLSeq IN (2006003)        -- �����з� ��ü�ΰ͸�                  
*/  
UNION ALL      
   SELECT A.DeptSeq                   
           ,A.DeptName                  
           ,0 AS OutQty     -- ���ϼ���                  
           ,0 AS OKQty      -- �������                  
           ,0 AS PlanOPC                  
           ,0 AS PlanSC                  
           ,0 AS PlanSP                  
           ,0 AS PlanFA                  
           ,0 AS ResOPC                  
           ,0 AS ResSC                  
           ,0 AS ResSP                  
           ,0 AS ResFA                  
           ,0 AS CementPlan                  
           ,CASE WHEN S1.ItemClassLSeq = 2006003 THEN SB.Qty*H.ConvFactor END AS CementRes --�����߷� ȯ��Ǳ� ���� ����. ����2016.05.10 by�ڼ���                 
           ,0 AS InQty                  
           ,0 AS InAmt                  
           ,0 AS OPCInQty                  
           ,0 AS SCInQty                  
           ,0 AS SPInQty                  
           ,0 AS FAInQty                  
           ,0 AS OPCDelvQty                  
           ,0 AS SCDelvQty                  
           ,0 AS SPDelvQty                  
           ,0 AS FADelvQty                  
           ,0 AS CementDelvQty      
           ,0 AS OPCDelvAmt              
           ,0 AS SCDelvAmt                  
           ,0 AS SPDelvAmt                  
           ,0 AS FADelvAmt                  
           ,0 AS CementDelvAmt                  
      FROM #TPDQCReplaceDept AS A    
  JOIN (SELECT   
                (SELECT MAX(DeptSeq) FROM hencom_TDADeptAdd WHERE ProdDeptSeq = R.DeptSeq ) AS DeptSeq,  
            M.MatItemSeq ,  
            R.WorkDate ,  
            SUM(ISNULL(M.Qty,0)) AS Qty  
        FROM _TPDSFCMatinput AS M WITH(NOLOCK)      
        JOIN _TPDSFCWorkReport AS R WITH(NOLOCK) ON R.CompanySeq = M.CompanySeq AND R.WorkReportSeq = M.WorkReportSeq     
  
        WHERE M.CompanySeq = @CompanySeq   
        AND R.WorkDate BETWEEN @DateFr AND @DateTo  
        GROUP BY R.DeptSeq,M.MatItemSeq ,R.WorkDate  
    ) AS SB ON SB.DeptSeq = A.DeptSeq  
     LEFT OUTER JOIN _VDAGetItemClass AS S1 WITH(NOLOCK) ON @CompanySeq = S1.CompanySeq                   
                                                            AND SB.MatItemSeq = S1.ItemSeq   
     LEFT OUTER JOIN hencom_VPDConvFactorDate AS H (NOLOCK) ON H.CompanySeq = @CompanySeq   
                                                        AND H.DeptSeq = SB.DeptSeq   
                                                        AND H.ItemSeq = SB.MatItemSeq    
                                                        AND SB.WorkDate BETWEEN H.StartDate AND H.EndDate   
    WHERE S1.ItemClassLSeq IN (2006003)        -- �����з� ��ü�ΰ͸�   
    AND SB.MatItemSeq NOT IN (SELECT MatItemSeq FROM #TMP_ExceptMat) 
                                                          
    UNION ALL                   
              
    --##################### ���԰�(����Һз� OPC, SC, SP, FA ���԰����)                  
    SELECT A.DeptSeq                  
           ,A.DeptName                  
           ,0 AS OutQty     -- ���ϼ���                  
           ,0 AS OKQty      -- �������                  
           ,0 AS PlanOPC                  
           ,0 AS PlanSC  
           ,0 AS PlanSP                  
           ,0 AS PlanFA                  
           ,0 AS ResOPC                  
           ,0 AS ResSC                  
           ,0 AS ResSP                  
           ,0 AS ResFA                  
           ,0 AS CementPlan                  
           ,0 AS CementRes                  
           ,0 AS InQty                  
           ,0 AS InAmt              
           ,CASE WHEN S1.ItemClassSSeq = 2004027                   
                 THEN (CASE WHEN ISNULL(H.ConvFactor, 0) = 0 THEN 0                  
                            ELSE F.Qty / H.ConvFactor END) END AS OPCInQty    -- OPC���԰�-(���԰����)              
           ,CASE WHEN S1.ItemClassSSeq = 2004034                   
                 THEN (CASE WHEN ISNULL(H.ConvFactor, 0) = 0 THEN 0                  
                            ELSE F.Qty / H.ConvFactor END) END AS SCInQty     -- SC���԰�-(���԰����)              
               ,CASE WHEN S1.ItemClassSSeq = 2004035                    
                 THEN (CASE WHEN ISNULL(H.ConvFactor, 0) = 0 THEN 0                  
                            ELSE F.Qty / H.ConvFactor END) END AS SPInQty     -- SP���԰�-(���԰����)              
           ,CASE WHEN S1.ItemClassSSeq = 2004048                   
                 THEN (CASE WHEN ISNULL(H.ConvFactor, 0) = 0 THEN 0                  
                            ELSE F.Qty / H.ConvFactor END) END AS FAInQty     -- FA���԰�-(���԰����)              
           ,0 AS OPCDelvQty                  
           ,0 AS SCDelvQty                  
           ,0 AS SPDelvQty                  
           ,0 AS FADelvQty                  
           ,0 AS CementDelvQty                  
           ,0 AS OPCDelvAmt                  
           ,0 AS SCDelvAmt                  
           ,0 AS SPDelvAmt                  
           ,0 AS FADelvAmt                  
           ,0 AS CementDelvAmt                  
      FROM #TPDQCReplaceDept AS A                  
      JOIN _TDAWH AS E WITH (NOLOCK) ON E.CompanySeq = @CompanySeq AND E.MngDeptSeq = A.DeptSeq                  
      JOIN _TLGInOutDaily AS G WITH (NOLOCK) ON E.CompanySeq = G.CompanySeq AND E.WHSeq = G.InWHSeq AND G.InOutType = 40                  
        JOIN _TLGInOutDailyItem AS F WITH (NOLOCK) ON F.CompanySeq = G.CompanySeq AND F.InOutSeq = G.InOutSeq AND F.InOutType = G.InOutType                  
--      LEFT OUTER JOIN hencom_TPDConvFactor AS H (NOLOCK) ON H.CompanySeq = F.CompanySeq AND H.DeptSeq = A.DeptSeq AND H.ItemSeq = F.ItemSeq    
        LEFT OUTER JOIN hencom_VPDConvFactorDate AS H (NOLOCK) ON H.CompanySeq = F.CompanySeq   
                                                                AND H.DeptSeq = A.DeptSeq   
                                                                AND H.ItemSeq = F.ItemSeq    
                                                                AND G.InOutDate BETWEEN H.StartDate AND H.EndDate                  
  
      -- ����з� ��                  
      LEFT OUTER JOIN _VDAGetItemClass AS S1 WITH(NOLOCK) ON F.CompanySeq = S1.CompanySeq                   
                                                         AND F.ItemSeq = S1.ItemSeq                      
     WHERE E.CompanySeq = @CompanySeq                  
         AND G.InOutDate BETWEEN @DateFr AND @DateTo                  
         AND S1.ItemClassSSeq IN (2004027, 2004034, 2004035, 2004048)         -- ����Һз� OPC, SC, SP, FA�ΰ͸�                  
         AND F.ItemSeq NOT IN (SELECT MatItemSeq FROM #TMP_ExceptMat)         
    UNION ALL                   
              
    --##################### ���԰�(�����з� ��ü ���԰����, �ݾ�)                  
    SELECT A.DeptSeq                  
           ,A.DeptName                  
           ,0 AS OutQty     -- ���ϼ���  
           ,0 AS OKQty      -- �������                  
           ,0 AS PlanOPC                  
           ,0 AS PlanSC                  
           ,0 AS PlanSP                  
           ,0 AS PlanFA                  
           ,0 AS ResOPC                  
           ,0 AS ResSC                  
           ,0 AS ResSP                  
           ,0 AS ResFA                  
           ,0 AS CementPlan              
           ,0 AS CementRes                      
           ,CASE WHEN S1.ItemClassLSeq = 2006003                   
                 THEN (CASE WHEN ISNULL(H.ConvFactor, 0) = 0 THEN 0                  
                            ELSE F.Qty * H.ConvFactor END) END AS InQty    -- ��ü���԰����-(���԰����)                  
           ,CASE WHEN S1.ItemClassLSeq = 2006003 THEN F.Amt END AS InAmt     -- ��ü���԰�ݾ�-(���԰����)              
           ,0 AS OPCInQty                  
           ,0 AS SCInQty                  
           ,0 AS SPInQty  
           ,0 AS FAInQty  
           ,0 AS OPCDelvQty                   
           ,0 AS SCDelvQty                  
           ,0 AS SPDelvQty                  
           ,0 AS FADelvQty                  
           ,0 AS CementDelvQty            
              ,CASE WHEN S1.ItemClassSSeq = 2004027 THEN F.Qty * H.ConvFactor * DPC.OPCMAvg END AS OPCDelvAmt                   
            ,CASE WHEN S1.ItemClassSSeq = 2004034 THEN F.Qty * H.ConvFactor * DPC.SCMAvg END AS SCDelvAmt                  
            ,CASE WHEN S1.ItemClassSSeq = 2004035 THEN F.Qty * H.ConvFactor * DPC.SPMAvg END AS SPDelvAmt                  
            ,CASE WHEN S1.ItemClassSSeq = 2004048 THEN F.Qty * H.ConvFactor * DPC.FAMAvg END AS FADelvAmt                       
           ,0 AS CementDelvAmt                  
      FROM #TPDQCReplaceDept AS A                  
      JOIN _TDAWH AS E WITH (NOLOCK) ON E.CompanySeq = @CompanySeq AND E.MngDeptSeq = A.DeptSeq                  
      JOIN _TLGInOutDaily AS G WITH (NOLOCK) ON E.CompanySeq = G.CompanySeq AND E.WHSeq = G.InWHSeq AND G.InOutType = 40                  
        JOIN _TLGInOutDailyItem AS F WITH (NOLOCK) ON F.CompanySeq = G.CompanySeq AND F.InOutSeq = G.InOutSeq AND F.InOutType = G.InOutType                  
--      LEFT OUTER JOIN hencom_TPDConvFactor AS H (NOLOCK) ON H.CompanySeq = F.CompanySeq AND H.DeptSeq = A.DeptSeq AND H.ItemSeq = F.ItemSeq     
      LEFT OUTER JOIN hencom_VPDConvFactorDate AS H (NOLOCK) ON H.CompanySeq = F.CompanySeq   
                                                            AND H.DeptSeq = A.DeptSeq   
                                                            AND H.ItemSeq = F.ItemSeq    
                                                            AND G.InOutDate BETWEEN H.StartDate AND H.EndDate           
      -- ����з� ��                  
      LEFT OUTER JOIN _VDAGetItemClass AS S1 WITH(NOLOCK) ON F.CompanySeq = S1.CompanySeq                   
                                                         AND F.ItemSeq = S1.ItemSeq         
    LEFT OUTER JOIN #TMPDeptPrice AS DPC ON DPC.DeptSeq = A.DeptSeq                   
     WHERE E.CompanySeq = @CompanySeq                  
       AND G.InOutDate BETWEEN @DateFr AND @DateTo                  
       AND S1.ItemClassLSeq IN (2006003)        -- �����з� ��ü�ΰ͸�    
       AND F.ItemSeq NOT IN (SELECT MatItemSeq FROM #TMP_ExceptMat)                  
                  
    SELECT  DeptSeq                  
           ,DeptName                  
           ,SUM(OutQty) AS OutQty                       
           ,SUM(OKQty) AS OKQty                       
           ,SUM(PlanOPC) AS PlanOPC                  
             ,SUM(PlanSC) AS PlanSC                   
           ,SUM(PlanSP) AS PlanSP                  
           ,SUM(PlanFA) AS PlanFA                  
           ,SUM(ResOPC) AS ResOPC                  
           ,SUM(ResSC) AS ResSC                  
           ,SUM(ResSP) AS ResSP                  
           ,SUM(ResFA) AS ResFA                  
           ,SUM(CementPlan) AS CementPlan                  
           ,SUM(CementRes) AS CementRes
           ,SUM(InQty) AS InQty                  
           ,SUM(InAmt) AS InAmt                  
           ,SUM(OPCInQty) AS OPCInQty                  
           ,SUM(SCInQty) AS SCInQty                  
           ,SUM(SPInQty) AS SPInQty                  
           ,SUM(FAInQty) AS FAInQty                  
           ,SUM(OPCDelvQty) AS OPCDelvQty                  
           ,SUM(SCDelvQty) AS SCDelvQty                  
           ,SUM(SPDelvQty) AS SPDelvQty                  
             ,SUM(FADelvQty) AS FADelvQty                   
           ,SUM(CementDelvQty) AS CementDelvQty                  
           ,SUM(OPCDelvAmt) AS OPCDelvAmt                  
           ,SUM(SCDelvAmt) AS SCDelvAmt                  
           ,SUM(SPDelvAmt) AS SPDelvAmt                  
           ,SUM(FADelvAmt) AS FADelvAmt                  
           ,SUM(CementDelvAmt) AS CementDelvAmt                  
      INTO #TPDQCReplaceSUM                  
      FROM #TPDQCReplace  AS A              
      WHERE EXISTS (SELECT 1 FROM hencom_TDADeptAdd WITH(NOLOCK)           
                    WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq AND DispQC = '1')              
     GROUP BY DeptSeq, DeptName                  
                  
        --##################################################################################### ��õ������ ������                  
                  
    --##################################################################################### ��굥���� ��������                           
    SELECT  M.DeptSeq                  
           ,M.DeptName
           ,M.OutQty                       
           ,OKQty                      
           ,PlanOPC                  
           ,CASE WHEN ISNULL(CementPlan,0) = 0 THEN 0                   
                 ELSE ISNULL(PlanSC,0) / ISNULL(CementPlan,0) END AS PlanSC        -- ��ȹSC                  
           ,CASE WHEN ISNULL(CementPlan,0) = 0 THEN 0                   
                 ELSE ISNULL(PlanSP,0) / ISNULL(CementPlan,0) END AS PlanSP        -- ��ȹSP              
           ,CASE WHEN ISNULL(CementPlan,0) = 0  THEN 0                   
                 ELSE ISNULL(PlanFA,0) / ISNULL(CementPlan,0) END AS PlanFA        -- ��ȹFA                  
           ,ResOPC                     
           ,CASE WHEN  ISNULL(CementRes,0) = 0 THEN 0                   
                 ELSE ISNULL(ResSC,0) / ISNULL(CementRes,0) END AS ResSC        -- ����SC                  
           ,CASE WHEN ISNULL(CementRes,0) = 0 THEN 0                   
                 ELSE ISNULL(ResSP,0) / ISNULL(CementRes,0) END AS ResSP        -- ����SP                  
           ,CASE WHEN ISNULL(CementRes,0) = 0 THEN 0                   
                 ELSE ISNULL(ResFA,0) / ISNULL(CementRes,0) END AS ResFA        -- ����FA                  
           ,CASE WHEN ISNULL(OKQty,0) = 0 THEN 0                   
                   ELSE ISNULL(CementPlan,0)  / ISNULL(OKQty,0) END AS CementPlan    -- ��ü����ȹ                  
           ,CASE WHEN ISNULL(OKQty,0) = 0 THEN 0                   
                 ELSE ISNULL(CementRes,0) / ISNULL(OKQty,0) END AS CementRes    -- ��ü������                  
           ,CASE WHEN ISNULL(OKQty,0) = 0 THEN 0                   
                 ELSE ISNULL(InQty,0) / ISNULL(OKQty,0) END AS InQty    -- ���԰���� (���԰� ��ü �ѷ� / �������)                        
            ,(ISNULL(OPCDelvAmt,0) + ISNULL(SCDelvAmt,0) + ISNULL(SPDelvAmt,0) + ISNULL(FADelvAmt,0))/1000 / ISNULL(OKQty,0) AS InAmt    -- ���԰�ݾ� : ������ ������ Ton�ε� �����߷� �����ص� KG �̶� �ٽ� 1000�� ����.             
--,@OPCMAvg AS OPCMAvg    -- OPC������ܰ�                
--,@SCMAvg AS SCMAvg    -- SC������ܰ�                  
--,@SPMAvg AS SPMAvg    -- SP������ܰ�                  
--,@FAMAvg AS FAMAvg    -- FA������ܰ�           
            ,ISNULL(D.OPCMAvg,0) AS OPCMAvg    -- OPC������ܰ�                
            ,ISNULL(D.SCMAvg,0) AS SCMAvg    -- SC������ܰ�                  
            ,ISNULL(D.SPMAvg,0) AS SPMAvg    -- SP������ܰ�                  
            ,ISNULL(D.FAMAvg,0) AS FAMAvg    -- FA������ܰ�                         
--           ,CASE WHEN ISNULL(CementDelvAmt,0) = 0 THEN 0                   
--                 ELSE (ISNULL(CementDelvQty,0) + ISNULL(InQty,0)) / ISNULL(CementDelvAmt,0) END AS CementMAvg    -- ��ü�̵���� (���� �и� ��� ������ ���� ���̴�)                  
      INTO #TPDQCReplaceA                  
      FROM #TPDQCReplaceSUM   AS M      
      LEFT OUTER JOIN  #TMPDeptPrice AS D ON D.DeptSeq = M.DeptSeq      
                     
                  
    SELECT  DeptSeq                  
           ,DeptName                  
           ,OutQty                       
           ,OKQty                    
          ,1 - PlanSC - PlanSP - PlanFA AS PlanOPC                  
           ,PlanSC                  
           ,PlanSP                  
           ,PlanFA                  
           ,Round((PlanSC/4.25 + PlanSP/2 + PlanFA) * 100, 1) AS PlanScore                  
             -- (������ * OPC�� �̵���մܰ�) - {(OPC�� * OPC�� �̵���մܰ�) + (SC�� * SC�� �̵���մܰ�) + (SP�� * SP�� �̵���մܰ�) + (FA�� * FA�� �̵���մܰ�)} * ������                  
           ,((CementRes * OPCMAvg) - (((1 - PlanSC - PlanSP - PlanFA) * OPCMAvg) + (PlanSC * SCMAvg) + (PlanSP * SPMAvg) + (PlanFA * FAMAvg)) * CementRes) /1000 AS PlanSaveAmt              
             ,1 - ResSC - ResSP - ResFA AS ResOPC      -- 1-SC-SP-FA = ResOPC                  
           ,ResSC        -- ����SC                  
           ,ResSP        -- ����SP                  
           ,ResFA        -- ����FA                  
           ,Round((ResSC/4.25 + ResSP/2 + ResFA) * 100, 1) AS ResScore  -- (SC/4.25 + SP/2 + FA) * 100 [�Ҽ��� 1�ڸ� / �ݿø�]              
           -- (������ * OPC�� �̵���մܰ�) - {(OPC�� * OPC�� �̵���մܰ�) + (SC�� * SC�� �̵���մܰ�) + (SP�� * SP�� �̵���մܰ�) + (FA�� * FA�� �̵���մܰ�)} * ������                  
             ,((CementRes * OPCMAvg) - (((1 - ResSC - ResSP - ResFA) * OPCMAvg) + (ResSC * SCMAvg) + (ResSP * SPMAvg) + (ResFA * FAMAvg)) * CementRes) /1000 AS ResSaveAmt                      
           ,CementPlan                  
           ,CementRes                 
           ,ISNULL(CementPlan,0) - ISNULL(CementRes,0)   AS CementPlanPre -- ��ȹ - ���� --����2016.05.10 by�ڼ���                
           ,InQty                    
           ,InAmt    -- ���԰�ݾ�                       
      INTO #TPDQCReplaceB                  
      FROM #TPDQCReplaceA                 
            
--      select * from #TPDQCReplaceA return       
                  
    SELECT @TotOutQty = SUM(OutQty) FROM #TPDQCReplaceB      -- ���Ͻ��� �Ѽ���                  
      SELECT @TotOKQty  = SUM(OKQty) FROM #TPDQCReplaceB        -- ������� �Ѽ���                  
                  
--              select @AvgPrice    
    --##################### ������ȸ                  
    /*    
    �ش� ȭ�鿡�� ��ȸ�Ǵ� ������� �����������м�,�Ѱ��м� ��� �״�� ���ǹǷ�     
    �ʵ� ���� ���� �� �ʵ��߰��� ��� ���õ� ȭ�鵵 Ȯ���ؾ���.      
    */          
    SELECT  0 AS Gubun                 
           ,0 as DispSeq              
           ,0 AS DeptSeq                  
           ,'[TOTAL]' AS DeptName                  
           ,@TotOutQty AS OutQty                       
           ,@TotOKQty AS OKQty                       
           ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                 ELSE (SUM(PlanOPC * OKQty) / ISNULL(@TotOKQty,0)) * 100 END AS PlanOPC                      
           ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                 ELSE (SUM(PlanSC * OKQty) / ISNULL(@TotOKQty,0)) * 100 END AS PlanSC                                                  
           ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                 ELSE (SUM(PlanSP * OKQty) / ISNULL(@TotOKQty,0)) * 100 END AS PlanSP                      
           ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                 ELSE (SUM(PlanFA * OKQty) / ISNULL(@TotOKQty,0)) * 100 END AS PlanFA                      
           ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                   ELSE (SUM(PlanScore * OKQty) / ISNULL(@TotOKQty,0)) END AS PlanScore                      
           ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                 ELSE (SUM(PlanSaveAmt * OKQty) / ISNULL(@TotOKQty,0)) END AS PlanSaveAmt                     
           ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                 ELSE (SUM(ResOPC * OKQty) / ISNULL(@TotOKQty,0)) * 100 END AS ResOPC                     
           ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                 ELSE (SUM(ResSC * OKQty) / ISNULL(@TotOKQty,0)) * 100 END AS ResSC                     
             ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                 ELSE (SUM(ResSP * OKQty) / ISNULL(@TotOKQty,0)) * 100 END AS ResSP                   
             ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                 ELSE (SUM(ResFA * OKQty) / ISNULL(@TotOKQty,0)) * 100 END AS ResFA                   
           ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                 ELSE (SUM(ResScore * OKQty) / ISNULL(@TotOKQty,0)) END AS ResScore                   
           ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                 ELSE (SUM(ResSaveAmt * OKQty) / ISNULL(@TotOKQty,0)) END AS ResSaveAmt                   
             ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                    
                 ELSE (SUM(CementPlan * OKQty) / ISNULL(@TotOKQty,0))  END AS CementPlan               
           ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                 ELSE (SUM(CementRes * OKQty) / ISNULL(@TotOKQty,0))  END AS CementRes                     
           ,(SUM(CementPlan * OKQty) / ISNULL(@TotOKQty,0)) - (SUM(CementRes * OKQty) / ISNULL(@TotOKQty,0)) AS CementPlanPre --��ȹ���               
--           ,SUM(ISNULL(CementPlanPre,0)) * @AvgPrice /1000   AS SaveAmt --��ü�������ݾ� = ��ȹ��� * ������ܰ�(��ü��ü)       
           ,((SUM(CementPlan * OKQty) / ISNULL(@TotOKQty,0)) - (SUM(CementRes * OKQty) / ISNULL(@TotOKQty,0))) * @AvgPrice /1000   AS SaveAmt --��ü�������ݾ� = ��ȹ��� * ������ܰ�(��ü��ü)                 
           ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                 ELSE (SUM(InQty * OKQty) / ISNULL(@TotOKQty,0)) END AS InQty                   
           ,CASE WHEN ISNULL(@TotOKQty,0) = 0 THEN 0                   
                   ELSE (SUM(InAmt * OKQty) / ISNULL(@TotOKQty,0))  END AS InAmt                          
            ,(SUM(ResSaveAmt * OKQty) - SUM(PlanSaveAmt * OKQty)) / ISNULL(@TotOKQty,0) AS SaveRepRate -- ġȯ�� = ġȯ��_����_�����ݾ�   - ġȯ��_��ȹ_�����ݾ�                         
           ,SUM((ISNULL(CementPlanPre,0) * ISNULL(@AvgPrice,0) /1000  + ISNULL(InAmt,0)) *  OKQty ) / ISNULL(@TotOKQty,0)  AS SaveCement    --�����ݾ�_��ȹ���_��ü���� = ��ü�������ݾ� + ���԰��                        
            ,((SUM(ResSaveAmt * OKQty) - SUM(PlanSaveAmt * OKQty)) / ISNULL(@TotOKQty,0) + (SUM((ISNULL(CementPlanPre,0) * ISNULL(@AvgPrice,0) /1000  + ISNULL(InAmt,0)) *  OKQty ) / ISNULL(@TotOKQty,0))) * SUM(OKQty) / ISNULL(@TotOKQty,0) AS SaveTot               
      INTO #TMPResult              
      FROM hencom_TDADeptAdd AS B  WITH(NOLOCK)               
      LEFT OUTER JOIN #TPDQCReplaceB AS A ON A.DeptSeq = B.DeptSeq              
      WHERE B.CompanySeq = @CompanySeq               
      AND B.DispQC = '1'              
      AND (@DeptSeq = 0 OR B.DeptSeq = @DeptSeq)               
              
    UNION ALL                  
                  
    SELECT  1 AS Gubun                 
           ,B.DispSeq              
           ,B.DeptSeq                  
           ,D.DeptName                  
           ,OutQty                  
           ,OKQty                  
           ,PlanOPC * 100                  
           ,PlanSC * 100                  
           ,PlanSP * 100                  
           ,PlanFA * 100                  
           ,PlanScore                   
           ,PlanSaveAmt   --ġȯ��_��ȹ_�����ݾ�                
           ,ResOPC * 100                  
           ,ResSC * 100                  
           ,ResSP * 100                  
           ,ResFA * 100                  
           ,ResScore                   
           ,ResSaveAmt  --ġȯ��_����_�����ݾ�                      
           ,CementPlan  --��ü��_��뷮_��ȹ ���� 2016.05.10 by�ڼ���                         
           ,CementRes --��ü��_��뷮_���� ���� 2016.05.10 by�ڼ���                            
           ,CementPlanPre --��ü��_��뷮_��ȹ��� ���� 2016.05.10 by�ڼ���       
           ,CementPlanPre * DPC.DeptAvg /1000 AS SaveAmt --��ü�������ݾ� = ��ȹ��� * ������ܰ�(��ü��ü)            
           ,InQty                   
           ,InAmt                  
           ,ISNULL(ResSaveAmt,0) - ISNULL(PlanSaveAmt,0)         AS SaveRepRate   -- ġȯ�� = ġȯ��_����_�����ݾ�  - ġȯ��_��ȹ_�����ݾ�               
           ,ISNULL(CementPlanPre,0) * ISNULL(DPC.DeptAvg,0) /1000  + ISNULL(InAmt,0)  AS SaveCement    --�����ݾ�_��ȹ���_��ü���� = ��ü�������ݾ� + ���԰��               
           ,ISNULL(ResSaveAmt,0) - ISNULL(PlanSaveAmt,0) + (ISNULL(CementPlanPre,0) * ISNULL(DPC.DeptAvg,0) /1000 + ISNULL(InAmt,0)) AS SaveTot    --�հ� = ġȯ�� + ��ü����           
      FROM hencom_TDADeptAdd  AS B WITH(NOLOCK)               
      LEFT OUTER JOIN #TPDQCReplaceB AS A ON A.DeptSeq = B.DeptSeq              
      LEFT OUTER JOIN _TDADept AS D ON D.CompanySeq = @CompanySeq AND D.DeptSeq = B.DeptSeq       
        LEFT OUTER JOIN #TMPDeptPrice AS DPC ON DPC.DeptSeq = B.DeptSeq             
      WHERE B.CompanySeq = @CompanySeq               
      AND B.DispQC = '1'              
      AND (@DeptSeq = 0 OR B.DeptSeq = @DeptSeq)               
              
    SELECT *               
    FROM #TMPResult              
    ORDER BY Gubun,DispSeq              
                      
RETURN                    
/***************************************************************************************************************/    
go
begin tran 
exec hencom_SPDQCReplaceRateAnalyQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <SMQryUnitSeq>1060001</SMQryUnitSeq>
    <DateFr>20151201</DateFr>
    <DateTo>20151231</DateTo>
    <DeptSeq>0</DeptSeq>
    <IsType>0</IsType>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034422,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028499
rollback 