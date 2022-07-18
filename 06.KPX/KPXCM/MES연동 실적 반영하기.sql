drop proc test_KPXCM_SPDSFCWorkReport_POP
go 
  
-- v2016.05.02   
  
-- ���� by����õ   
/************************************************************      
 ��  �� - �۾�����������      
 �ۼ��� - 2014-12-07      
 �ۼ��� - ���游      
************************************************************/      
CREATE PROCEDURE [dbo].[test_KPXCM_SPDSFCWorkReport_POP]    
    @CompanySeq  INT = 2             -- ����          
    ,@SeqSub INT 
AS        
    DECLARE  @CurrDATETIME          DATETIME            -- ������        
            ,@XmlData               NVARCHAR(MAX)        
            ,@Seq                   INT        
            ,@MaxNo                 NVARCHAR(50)        
            ,@FactUnit              INT        
            ,@Date                  NVARCHAR(8)        
            ,@DataSeq               INT        
            ,@Count                 INT,      
            @UserSeq                INT      
        
    SELECT @CurrDATETIME    = GETDATE()        
      
      
    ----���� ���� �� �۾����ð� ���� ���� �����Ѵ�.      
    --UPDATE A      
    --   SET ProcYN = '7',      
    --       ErrorMessage = '�۾����� ������ �����ϴ�.'      
    --  FROM KPX_TPDSFCWorkReport_POP AS A      
    --       LEFT OUTER JOIN _TPDSFCWorkOrder AS B ON B.CompanySeq = A.CompanySeq and B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkOrderSerl = A.WorkORderSerl      
    -- WHERE A.ProcYN = '0'      
    --   AND A.IsPacking = '0'      
    --   AND ISNULL(B.CompanySeq, 0) = 0      
    --   AND A.CompanySeq = @CompanySeq      
      
  --UPDATE A      
  --     SET ProcYN = '7',      
  --         ErrorMessage = 'pop���� ���� �ӽ� ���'      
  --    FROM KPX_TPDSFCWorkReport_POP AS A      
  --    WHERE A.ProcYN = '0'      
  --     AND A.IsPacking = '0'      
  --     AND A.CompanySeq = @CompanySeq      
 --   and A.EmpSeq <> 1064  
      
    ----���� ���� �����Ͱ� ������ ������ �����Ѵ�.      
    --UPDATE A       
    --   SET ProcYN = '8',      
    --       ErrorMessage = '���� ���� �����Ͱ� ������ ������ �����Ѵ�.'      
    --  FROM KPX_TPDSFCWorkReport_POP AS A      
    -- WHERE Seq IN (      
    --                SELECT A.Seq      
    --                  FROM KPX_TPDSFCWorkReport_POP AS A      
    --                 WHERE A.CompanySeq = @CompanySeq  
    --                   and IsPacking = '0'      
    --                   AND WorkingTag = 'D'      
    --                   AND IFWorkReportSeq IN (SELECT IFWorkReportSeq      
    --                                             FROM KPX_TPDSFCWorkReport_POP      
    --                                            WHERE CompanySeq = @CompanySeq  
    --                                              and IsPacking = '0'      
    --                                            GROUP BY IFWorkReportSeq      
    --                                            HAVING COUNT(1) = 1)      
    --                UNION ALL      
    --                SELECT A.Seq      
    --                  FROM (SELECT IFWorkReportSeq, MIN(Seq) AS Seq      
    --                          FROM KPX_TPDSFCWorkReport_POP AS A      
    --                         WHERE A.CompanySeq = @CompanySeq  
    --                           And IsPacking = '0'      
    --                           AND WorkingTag = 'D'      
    --                         GROUP BY IFWorkReportSeq) AS A      
    --                        LEFT OUTER JOIN (SELECT IFWorkReportSeq, MIN(Seq) AS Seq      
    --                                           FROM KPX_TPDSFCWorkReport_POP AS A      
    --                                          WHERE A.CompanySeq = @CompanySeq  
    --                                            And IsPacking = '0'      
    --                                            AND WorkingTag = 'A'      
    --                                          GROUP BY IFWorkReportSeq) AS B ON B.IFWorkReportSeq = A.IFWorkReportSeq      
    --                 WHERE A.Seq < B.Seq      
    --                )      
    --    and A.CompanySeq = @CompanySeq  
          
    update a
       set ProcYn = '0', ErrorMessage = '' 
      from KPX_TPDSFCWorkReport_POP as a 
     where a.CompanySeq = 2 and a.Seq = @SeqSub 
     
     
    -- I/F ��� ������ ��� (KPX_TPDSFCWorkReport_POP)        
    SELECT TOP 1       
            ROW_NUMBER() OVER(ORDER BY A.Seq) AS RowCnt      
            ,A.CompanySeq          
            ,A.Seq          
            ,A.IFWorkReportSeq          
              ,0      AS WorkReportSeq                    ,ISNULL(A.WorkOrderSeq, 0)      AS WorkOrderSeq          
            ,ISNULL(A.WorkOrderSerl, 0)     AS WorkOrderSerl      
            ,IsPacking      
            ,A.WorkTimeGroup        
            ,A.WorkStartDate      
            ,A.WorkEndDate      
            ,A.WorkCenterSeq        
            ,A.GoodItemSeq        
            ,A.ProcSeq        
            ,A.AssyItemSeq        
            ,A.ProdUnitSeq        
            ,A.ProdQty        
            ,A.OkQty        
            ,A.BadQty        
            ,A.WorkStartTime        
            ,A.WorkEndTime        
            ,A.WorkMin                     -- ����ð�(��)      
            ,ISNULL(A.RealLotNo,'')   AS RealLotNo        
            ,A.WorkType        
            ,ISNULL(A.OutKind,0)   AS OutKind        
            ,CASE WHEN ISNULL(A.RegEmpSeq, 0) = 0 THEN 1 ELSE A.RegEmpSeq END                 AS EmpSeq        
            ,A.Remark        
            ,A.ProcDateTime        
            ,A.ProcYn        
            ,A.ErrorMessage                ,(CASE WHEN ISNULL(A.FactUnit, 0) = 0 THEN B.FactUnit ELSE A.FactUnit END)  AS FactUnit        
            ,(CASE WHEN ISNULL(A.DeptSeq, 0) = 0 THEN B.DeptSeq ELSE A.DeptSeq END)     AS DeptSeq        
            ,0                                                                          AS BizUnit        
            ,0                                                                          AS Status        
            ,CONVERT(NVARCHAR(100), '')                                                 AS Result        
            ,CONVERT(DECIMAL(19,5), 0)                                                  AS StdUnitProdQty        
            ,CONVERT(DECIMAL(19,5), 0)                                                  AS StdUnitBadQty        
            ,A.WorkingTag      
            --,A.HambaQty      
            --,ISNULL(A.RealWorkHour, 0)             AS WorkCond4  -- �ǰ����ð�(= �����ð� - �񰡵��ð�)        
      INTO #Temp_Source          
      FROM KPX_TPDSFCWorkReport_POP     AS A          
           JOIN _TPDBaseWorkCenter      AS B ON A.CompanySeq = B.CompanySeq          
                                            AND A.WorkCenterSeq = B.WorkCenterSeq          
           LEFT OUTER JOIN _fnadmEmpOrd(@CompanySeq, '') AS E ON E.EmpSeq = A.RegEmpSeq      
           LEFT OUTER JOIN _TDAItemUnit AS U ON A.CompanySeq = U.CompanySeq  
                                            And A.GoodItemSeq = U.ItemSeq          
                                            AND A.ProdUnitSeq = U.UnitSeq           
           --JOIN _TPDSFCWorkOrder AS W ON W.CompanySeq = @CompanySeq AND W.WorkOrderSeq = A.WorkOrderSeq AND W.WorkOrderSerl = A.WorkOrderSerl      
    WHERE A.CompanySeq = @CompanySeq 
      and A.Seq = @SeqSub 
      --AND ISNULL(A.ProcYn, '0') = '0'        
      --AND IsPacking ='0'     
    ORDER BY A.Seq      
    
    --select *from #Temp_Source 
    --return 
      
    UPDATE A      
       SET ProcYN = '5' --ó������      
      FROM KPX_TPDSFCWorkReport_POP AS A      
     WHERE A.CompanySeq = @CompanySeq  
       And ISNULL(A.ProcYN ,'0') = '0'      
       AND Seq IN (SELECT Seq FROM #Temp_Source)      
         
    IF NOT EXISTS (SELECT 1 FROM #Temp_Source)      
    BEGIN      
        RETURN      
    END      
      
      
    SELECT @UserSeq = U.UserSeq      
      FROM #Temp_Source AS A      
           LEFT OUTER JOIN _TCAUSer AS U ON U.CompanySeq = @CompanySeq AND U.EmpSeq = A.EmpSeq      
      
    UPDATE A         
       SET DeptSeq = (SELECT DeptSeq FROM _FnadmEmpOrd(@CompanySeq, '') WHERE EmpSeq = A.EmpSeq)        
      FROM #Temp_Source AS A        
     WHERE ISNULL(DeptSeq, 0) = 0        
        
    -- ����ι� UPDATE �� ���ش��� ȯ�� (����/��ǰ/�ҷ� ������ ����Save SP ������ ȯ����������, ������ ����/�ҷ� ���ش��������� ���Ǿ ȯ�� �̸�����)          
    UPDATE A          
       SET BizUnit = B.BizUnit          
            ,StdUnitProdQty = (CASE WHEN ISNULL(U.ConvDen, 0) = 0 THEN A.ProdQty           
                               ELSE A.ProdQty * (CONVERT(DECIMAL(19, 10), U.ConvNum / U.ConvDen)) END)           
              ,StdUnitBadQty =  (CASE WHEN ISNULL(U.ConvDen, 0) = 0 THEN A.BadQty           
                               ELSE A.BadQty * (CONVERT(DECIMAL(19, 10), U.ConvNum / U.ConvDen)) END)                 
      FROM #Temp_Source    AS A          
           JOIN _TDAFactUnit        AS B ON A.CompanySeq = B.CompanySeq          
                           AND A.FactUnit = B.FactUnit          
           LEFT OUTER JOIN _TDAItemUnit     AS U ON A.CompanySeq = U.CompanySeq    
                                                AnD A.GoodItemSeq = U.ItemSeq          
                                                AND A.ProdUnitSeq = U.UnitSeq              
                                                  
    ALTER TABLE #Temp_Source ADD WorkDate NCHAR(8)      
          
      
    --=================================================================================          
    -- Ʈ������ ���� �κ�          
    --=================================================================================          
    --SET LOCK_TIMEOUT -1          
    --BEGIN TRANSACTION          
    --BEGIN TRY         
              
    --WHILE (1=1)      
    --BEGIN      
    --    IF ISNULL(@MaxCnt,0) < @Cnt      
    --        BREAK      
      
      
      
    --Row�� ó���� ���� ������(#Temp_Source)���� ���� ������ �ϳ��� #TMP_TPDSFCWorkReport�� �����Ѵ�.      
    IF OBJECT_ID('tempdb..#TMP_TPDSFCWorkReport') IS NOT NULL        
    BEGIN        
       DROP TABLE #TMP_TPDSFCWorkReport        
    END       
      
    SELECT *       
      INTO #TMP_TPDSFCWorkReport      
      FROM #Temp_Source      
    
    
    UPDATE A      
       SET WorkReportSeq = ISNULL((SELECT MAX(P.WorkReportSeq)       
                                     FROM KPX_TPDSFCWorkReport_POP AS P      
                                          JOIN _TPDSFCWorkReport AS R ON R.CompanySeq = P.CompanySeq       
                                                                     AND R.WorkOrderSeq = P.WorkOrderSeq      
                                                                     AND R.WorkOrderSerl = P.WorkOrderSerl      
                                                                     AND R.WorkReportSeq = P.WorkReportSeq      
                                    WHERE P.CompanySeq = A.CompanySeq       
                                      AND P.WorkOrderseq = A.WorkOrderSeq       
                                      AND P.WorkOrderSerl = A.WorkOrderSerl       
                                      AND P.IFWorkReportSeq = A.IFWorkReportSeq),0)      
      FROM #TMP_TPDSFCWorkReport AS A      
     WHERE A.WorkingTag in ( 'D','U')  
    
    --select * from #TMP_TPDSFCWorkReport 
    --return 
  
 /*------------------------------------------------------------------------------------------------------------------------------          
  ���� ���� üũ           
   ------------------------------------------------------------------------------------------------------------------------------*/          
    UPDATE A      
       SET WorkDate = WorkEndDate      
      FROM #TMP_TPDSFCWorkReport AS A      
    IF OBJECT_ID('tempdb..#TMP_CloseItemCheck') IS NOT NULL        
    BEGIN        
       DROP TABLE #TMP_CloseItemCheck        
    END       
    SELECT  DISTINCT            
            A.WorkingTag        AS WorkingTag,              
            IDENTITY(INT,1,1)   AS DataSeq,              
            0                   AS Status,              
            0                   AS Selected,              
           'DataBlock2'         AS TABLE_NAME,           
            A.GoodItemSeq       AS ItemSeq,          
            A.BizUnit           AS BizUnit,          
            A.BizUnit           AS BizUnitOld,             
            2894                AS ServiceSeq,          
            2                   AS MethodSeq,          
            A.DeptSeq           AS DeptSeq,            
            A.WorkDate          AS Date,          
            A.WorkDate          AS DateOld,          
            A.Seq               AS Seq          
      INTO #TMP_CloseItemCheck          
      FROM #TMP_TPDSFCWorkReport    AS A          
       --WHERE A.RowCnt = @Cnt      
    
    
    ------------------------------              
    -- Temp���̺� ������ XMl�� ����              
    ------------------------------              
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(SELECT  DataSeq  AS IDX_NO, *               
                                                  FROM #TMP_CloseItemCheck              
   FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS))             
          
          
 IF OBJECT_ID('tempdb..#TCOMCloseItemCheck') IS NOT NULL        
 BEGIN        
  DROP TABLE #TCOMCloseItemCheck        
 END       
    CREATE TABLE #TCOMCloseItemCheck (WorkingTag NCHAR(1) NULL)                  
    EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2639, 'DataBlock2', '#TCOMCloseItemCheck'           
          
    INSERT INTO #TCOMCloseItemCheck          
    EXEC _SCOMCloseItemCheck              
         @xmlDocument  = @XmlData,              
         @xmlFlags     = 2,              
         @ServiceSeq   = 2639,              
         @WorkingTag   = '',              
         @CompanySeq   = @CompanySeq,              
         @LanguageSeq  = 1,              
         @UserSeq      = @UserSeq,      
         @PgmSeq       = 1015           
          
      
    IF @@ERROR <> 0               
    BEGIN          
        RAISERROR('Error during ''EXEC _SCOMCloseItemCheck''', 15, 1)          
    END          
          
    -----------------------------------------              
    -- �����ɷ��� ���, üũ���� ���           
    -----------------------------------------            
      IF EXISTS (SELECT 1 FROM  #TCOMCloseItemCheck WHERE Status <> 0)          
     BEGIN          
        UPDATE #TMP_TPDSFCWorkReport          
          SET Status = C.Status          
             ,Result = C.Result          
         FROM #TMP_TPDSFCWorkReport  AS A          
         JOIN #TMP_CloseItemCheck    AS B ON A.Seq = B.Seq          
         JOIN #TCOMCloseItemCheck    AS C ON B.DataSeq = C.DataSeq          
        WHERE A.Status = 0          
          AND C.Status <> 0          
          --AND A.RowCnt = @Cnt       
           
     END           
          
      
      
/*------------------------------------------------------------------------------------------------------------------------------          
    ������� üũ           
------------------------------------------------------------------------------------------------------------------------------*/          
 IF OBJECT_ID('tempdb..#TMP_TPDSFCWorkReport_Xml') IS NOT NULL        
 BEGIN        
  DROP TABLE #TMP_TPDSFCWorkReport_Xml        
 END       
    SELECT  A.WorkingTag                AS WorkingTag        
            ,IDENTITY(INT, 1, 1)        AS DataSeq        
            ,0                          AS Status        
            ,0                          AS Selected        
            ,'DataBlock1'               AS TABLE_NAME        
            ,'00'                       AS ItemBomRevName        
            ,A.ProdQty        
            ,A.OKQty        
            ,A.BadQty        
            ,A.BadQty                   AS ReOrderQty        
            ,0                          AS LossCostQty        
            ,0                          AS DisuseQty        
            ,A.WorkStartTime        
            ,A.WorkEndTime        
            ,(A.WorkMin/60.0)           AS WorkHour       
            ,0                          AS WorkerQty        
            ,0                          AS ProcHour      
            ,A.RealLotNo        
            ,''                         AS SerialNoFrom        
            ,''                         AS SerialNoTo        
            ,A.WorkstartDate            AS WorkCondition1        
            ,A.WorkEndDate              AS WorkCondition2        
            ,''                         AS WorkCondition3        
            ,A.WorkMin                  AS WorkCondition4        
            ,0                          AS WorkCondition5        
            ,0                          AS WorkCondition6        
              ,A.StdUnitBadQty             AS StdUnitReOrderQty        
            ,0                          AS StdUnitLossCostQty        
            ,0                          AS StdUnitDisuseQty        
            ,N'�������� ������'         AS Remark        
            ,'00'                       AS ProcRev        
            ,A.WorkReportSeq            AS WorkReportSeq        
            ,A.WorkOrderSeq        
            ,A.WorkCenterSeq        
            ,A.AssyItemSeq        
            ,A.ProcSeq        
            ,A.ProdUnitSeq        
        ,0                          AS ChainGoodsSeq        
            ,EmpSeq                     AS EmpSeq        
            ,A.WorkOrderSerl        
            ,'0'                        AS IsProcQC        
            ,C.IsLastProc                        AS IsLastProc        
            ,'0'                        AS IsPjt        
            ,0                          AS PJTSeq        
            ,0                          AS WBSSeq        
            ,0                          AS SubEtcInSeq        
            ,A.WorkTimeGroup        
            ,0                          AS QCSeq        
            ,''                         AS QCNo        
            ,0                          AS PreProdWRSeq        
            ,0                          AS PreAssySeq        
            ,0                          AS PreAssyQty        
            ,''                         AS PreLotNo        
            ,0                          AS PreUnitSeq        
            ,0                          AS CustSeq        
            ,ISNULL(A.WorkType, 6041001) AS WorkType        
            ,A.GoodItemSeq        
            ,A.WorkDate             AS WorkDate        
            ,ISNULL(A.DeptSeq  ,8)      AS DeptSeq      
            ,A.FactUnit        
            ,A.Seq        
        INTO #TMP_TPDSFCWorkReport_Xml        
        FROM #TMP_TPDSFCWorkReport   AS A        
             LEFT OUTER JOIN _TPDROUItemProcWC  AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq         
                                                          AND A.GoodItemSeq = B.ItemSeq         
                                                          AND A.WorkCenterSeq = B.WorkCenterSeq      
                                                          AND A.ProcSeq = B.ProcSeq      
             LEFT OUTER JOIN _TPDROUItemProc AS C with(Nolock) ON C.CompanySeq = @CompanySeq  
                                                              And C.ProcSeq = A.ProcSeq       
                                                              AND C.ItemSeq = A.GoodItemSeq      
                       
    WHERE A.Status = 0        
  
    ------------------------------              
    -- Temp���̺� ������ XMl�� ����              
    ------------------------------              
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                SELECT DataSeq AS IDX_NO, *               
                                                  FROM #TMP_TPDSFCWorkReport_Xml              
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS              
                                            ))              
    
    

    
 IF OBJECT_ID('tempdb..#TPDSFCWorkReport') IS NOT NULL        
 BEGIN        
  DROP TABLE #TPDSFCWorkReport        
 END       
    CREATE TABLE #TPDSFCWorkReport (WorkingTag NCHAR(1) NULL)                  
    EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2909, 'DataBlock1', '#TPDSFCWorkReport'                  
              
      
    INSERT INTO #TPDSFCWorkReport              
    EXEC KPXCM_SPDSFCWorkReportCheckPOP      
         @xmlDocument  = @XmlData,              
         @xmlFlags     = 2,              
         @ServiceSeq   = 2909,              
         @WorkingTag   = '',              
         @CompanySeq   = @CompanySeq,              
         @LanguageSeq  = 1,              
         @UserSeq      = @UserSeq,      
         @PgmSeq       = 1015              
    
    --select * from #TPDSFCWorkReport 
    --return 
    IF @@ERROR <> 0               
      BEGIN                  RAISERROR('Error during ''EXEC _SPDSFCWorkReportCheck''', 15, 1)          
            
    END          
  --������ ����ó��          
  UPDATE A        
  SET ProcYN = '2',        
   ErrorMessage = '''EXEC _SPDSFCWorkReportCheck Error'''        
    FROM KPX_TPDSFCWorkReport_POP AS A        
   JOIN #TMP_TPDSFCWorkReport AS B ON B.Seq = A.Seq        
   JOIN #TMP_TPDSFCWorkReport_Xml AS C ON C.Seq = B.Seq        
   JOIN #TPDSFCWorkReport AS D ON D.DataSeq = C.DataSeq        
   WHERE D.Status <> 0    
     and A.CompanySeq = @CompanySeq       
    -----------------------------------------              
    -- �����ɷ��� ���, üũ���� ���           
    -----------------------------------------            
          
    UPDATE A      
      SET Status        = CASE WHEN C.Status <> 0 THEN C.Status ELSE 0 END          
         ,Result        = CASE WHEN C.Status <> 0 THEN C.Result ELSE '' END          
         ,WorkReportSeq = CASE WHEN C.Status <> 0 THEN 0 ELSE C.WorkReportSeq END          
     FROM #TMP_TPDSFCWorkReport         AS A          
     JOIN #TMP_TPDSFCWorkReport_Xml     AS B ON A.Seq = B.Seq          
     JOIN #TPDSFCWorkReport             AS C ON B.DataSeq = C.DataSeq          
    --WHERE A.RowCnt = @Cnt      
          
   UPDATE C      
      SET Status        = CASE WHEN C.Status <> 0 THEN C.Status ELSE 0 END          
         ,Result        = CASE WHEN C.Status <> 0 THEN C.Result ELSE '' END          
         ,WorkReportSeq = CASE WHEN C.Status <> 0 THEN 0 ELSE C.WorkReportSeq END          
     FROM #TMP_TPDSFCWorkReport         AS A          
     JOIN #TMP_TPDSFCWorkReport_Xml     AS B ON A.Seq = B.Seq          
     JOIN #TPDSFCWorkReport             AS C ON B.DataSeq = C.DataSeq          
    --WHERE A.RowCnt = @Cnt      
      
/*------------------------------------------------------------------------------------------------------------------------------          
    LotMaster üũ           
----------------------------------------------------------------------------------------------------------------------------*/          
 IF OBJECT_ID('tempdb..#TMP_TLGLotMaster_Xml') IS NOT NULL        
 BEGIN        
  DROP TABLE #TMP_TLGLotMaster_Xml        
 END       
    SELECT A.WorkingTag,        
           A.IDX_NO,        
           A.DataSeq,        
           A.Status,        
           A.Selected,        
           'DataBlock1'                 AS TABLE_NAME,        
           ISNULL(B.WorkOrderNo, '')    AS InNo,        
           ''                           AS LotNoOld,        
           0                            AS ItemSeqOld,        
           A.WorkDate                   AS RegDate,         --�԰���      
           A.WorkDate                   AS CreateDate2,     --��������      
           DATEADD(DAY, CASE WHEN I.SMLimitTermKind = 8004001 THEN I.LimitTerm*30      
                             ELSE I.LimitTerm END, A.WorkDate) AS Validate,        --��ȿ����      
           A.GoodItemSeq                AS ItemSeq,        
           A.ProdUnitSeq                AS UnitSeq,        
           A.OKQty                      AS Qty,        
           B.WorkCond3                  AS LotNo,        
           N'������� ����'             AS Remark,        
           '0'                          AS IsDelete,        
           '1'                          AS IsProductItem,        
           ''                           AS IsExceptEmptyLotNo        
      INTO #TMP_TLGLotMaster_Xml        
      FROM #TPDSFCWorkReport       AS A        
           LEFT OUTER JOIN _TPDSFCWorkOrder AS B ON B.COmpanySeq = @CompanySeq        
                                                AND A.WorkOrderSeq = B.WorkOrderSeq        
                                                AND A.WorkOrderSerl = B.WorkOrderSerl        
           LEFT OUTER JOIN _TDAItemStock AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq      
                                                          AND I.ItemSeq = A.GoodItemSeq      
     WHERE A.Status = 0           
                     
      ------------------------------              
    -- Temp���̺� ������ XMl�� ����              
    ------------------------------              
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                SELECT *           
                                                  FROM #TMP_TLGLotMaster_Xml              
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS              
                                            ))            
 IF OBJECT_ID('tempdb..#TLGLotMaster') IS NOT NULL        
 BEGIN        
  DROP TABLE #TLGLotMaster        
 END       
    CREATE TABLE #TLGLotMaster (WorkingTag NVARCHAR(4) NULL)                
      EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 4422, 'DataBlock1', '#TLGLotMaster'              
      
    ------------------------------              
    -- Lot������ Check SP              
    ------------------------------              
    INSERT INTO #TLGLotMaster              
    EXEC _SLGLotNoMasterCheck               
         @xmlDocument  = @XmlData,              
         @xmlFlags     = 2,              
         @ServiceSeq   = 4422,              
         @WorkingTag   = '',              
         @CompanySeq   = @CompanySeq,              
         @LanguageSeq  = 1,              
         @UserSeq      = @UserSeq,      
         @PgmSeq       = 1015            
print 408      
          
    IF @@ERROR <> 0               
    BEGIN          
        RAISERROR('Error during ''EXEC _SLGLotNoMasterCheck''', 15, 1)          
    END          
          
          
    -----------------------------------------              
    -- �����ɷ��� ���, üũ���� ���           
    -----------------------------------------            
    IF EXISTS (SELECT 1 FROM #TLGLotMaster WHERE Status <> 0)          
     BEGIN          
        UPDATE #TMP_TPDSFCWorkReport          
          SET Status = C.Status          
             ,Result = C.Result          
         FROM #TMP_TPDSFCWorkReport         AS A          
         JOIN #TLGLotMaster                 AS C ON A.GoodItemSeq = C.ItemSeq          
                                                AND A.RealLotNo = C.LotNo          
        WHERE A.Status = 0          
          AND C.Status <> 0         
          --AND A.RowCnt = @Cnt       
           
     END           
          
          
          
/*------------------------------------------------------------------------------------------------------------------------------          
    LotMaster ����           
------------------------------------------------------------------------------------------------------------------------------*/          
        
    ------------------------------              
    -- Lot������ Check SP XML ����              
    ------------------------------              
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                SELECT *               
                                                  FROM #TLGLotMaster             
                                                 WHERE Status = 0           
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS              
                                            ))              
    DELETE FROM #TLGLotMaster              
          
    ------------------------------              
    -- Lot������ SAVE SP              
    ------------------------------              
    INSERT INTO #TLGLotMaster              
    EXEC _SLGLotNoMasterSave               
         @xmlDocument  = @XmlData,              
         @xmlFlags     = 2,              
         @ServiceSeq   = 4422,              
         @WorkingTag   = '',              
         @CompanySeq   = @CompanySeq,              
         @LanguageSeq  = 1,              
         @UserSeq      = @UserSeq,      
         @PgmSeq       = 1015             
          
          
    IF @@ERROR <> 0               
    BEGIN          
          RAISERROR('Error during ''EXEC _SLGLotNoMasterSave''', 15, 1)          
    END          
          
/*------------------------------------------------------------------------------------------------------------------------------          
    ������� ����           
------------------------------------------------------------------------------------------------------------------------------*/          
          
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                SELECT *               
                                                  FROM #TPDSFCWorkReport              
                                                 WHERE Status = 0          
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS              
                                            ))              
  
    DELETE FROM #TPDSFCWorkReport               
    ------------------------------              
    -- ��������Է� SAVE SP              
    ------------------------------              
    INSERT INTO #TPDSFCWorkReport              
    EXEC _SPDSFCWorkReportSave               
         @xmlDocument  = @XmlData,              
         @xmlFlags     = 2,              
         @ServiceSeq   = 2909,              
         @WorkingTag   = '',              
         @CompanySeq   = @CompanySeq,              
         @LanguageSeq  = 1,              
         @UserSeq = @UserSeq,      
         @PgmSeq       = 1015            
    
    

    IF @@ERROR <> 0               
    BEGIN          
        RAISERROR('Error during ''EXEC _SPDSFCWorkReportSave''', 15, 1)          
                
                
    END          
          

          
    -----------------------------------------              
    -- �����ɷ��� ���, üũ���� ���           
    -----------------------------------------            
    IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport WHERE Status <> 0)          
     BEGIN         
    --select 471       
     UPDATE #TMP_TPDSFCWorkReport          
        SET Status = C.Status          
             ,Result = C.Result          
             ,WorkReportSeq = 0           
         FROM #TMP_TPDSFCWorkReport         AS A        
         JOIN #TPDSFCWorkReport             AS C ON A.WorkReportSeq = C.WorkReportSeq        
        WHERE A.Status = 0        
          AND C.Status <> 0           
          --AND A.RowCnt = @Cnt      
     END           
          
  /*------------------------------------------------------------------------------------------------------------------------------          
    ���� Save          
   ------------------------------------------------------------------------------------------------------------------------------*/          
 IF OBJECT_ID('tempdb..#TMP_SourceDaily_Xml') IS NOT NULL        
 BEGIN        
  DROP TABLE #TMP_SourceDaily_Xml        
 END       
    SELECT A.WorkingTag,              
           A.IDX_NO,              
           A.DataSeq,              
           A.Status,              
           A.Selected,              
           'DataBlock1'    AS TABLE_NAME,              
           5               AS FromTableSeq,              
           A.WorkOrderSeq  AS FromSeq,              
           A.WorkOrderSerl AS FromSerl,              
           0               AS FromSubSerl,              
           6               AS ToTableSeq,              
           B.OrderQty      AS FromQty,              
           B.StdUnitQty    AS FromSTDQty,              
           0               AS FromAmt,              
           0               AS FromVAT,              
           0               AS PrevFromTableSeq,              
           A.WorkReportSeq AS ToSeq,            
           A.StdUnitOKQty  AS ToSTDQty,            
           A.ProdQty       AS ToQty              
      INTO #TMP_SourceDaily_Xml              
      FROM #TPDSFCWorkReport            AS A              
          JOIN _TPDSFCWorkOrder             AS B ON B.CompanySeq = @CompanySeq  
                                                  And A.WorkOrderSeq  = B.WorkOrderSeq              
                                                AND A.WorkOrderSerl = B.WorkOrderSerl              
     WHERE B.CompanySeq = @CompanySeq              
       AND NOT EXISTS (SELECT 1 FROM #TMP_TPDSFCWorkReport WHERE WorkReportSeq = A.WorkReportSeq AND Status <> 0)           
        
    ------------------------------              
    -- ���� SAVE Xml����              
      ------------------------------               
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                SELECT *               
                                                  FROM #TMP_SourceDaily_Xml              
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS              
                                            ))              
 IF OBJECT_ID('tempdb..#TCOMSourceDaily') IS NOT NULL        
 BEGIN        
  DROP TABLE #TCOMSourceDaily        
 END       
     CREATE TABLE #TCOMSourceDaily  (WorkingTag NCHAR(1) NULL)                        
     ExEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 3181, 'DataBlock1', '#TCOMSourceDaily'            
          
     Alter Table #TCOMSourceDaily Add OldToQty DECIMAL(19, 5)                     
     Alter Table #TCOMSourceDaily Add OldToSTDQty DECIMAL(19, 5)                     
     Alter Table #TCOMSourceDaily Add OldToAmt DECIMAL(19, 5)                     
     Alter Table #TCOMSourceDaily Add OldToVAT DECIMAL(19, 5)            
          
    ------------------------------              
    -- ���� SAVE SP              
    ------------------------------              
    INSERT INTO #TCOMSourceDaily          
    EXEC _SCOMSourceDailySave               
         @xmlDocument  = @XmlData,              
         @xmlFlags     = 2,              
         @ServiceSeq   = 3181,                     @WorkingTag   = '',              
         @CompanySeq   = @CompanySeq,              
         @LanguageSeq  = 1,              
         @UserSeq      = @UserSeq,      
         @PgmSeq       = 1015              
          
          
    IF @@ERROR <> 0               
    BEGIN          
        RAISERROR('Error during ''EXEC _SCOMSourceDailySave''', 15, 1)          
    END          
          
          
    -----------------------------------------              
    -- �����ɷ��� ���, üũ���� ���           
    -----------------------------------------            
    IF EXISTS (SELECT 1 FROM #TCOMSourceDaily WHERE Status <> 0)          
     BEGIN          
          
        UPDATE #TMP_TPDSFCWorkReport          
           SET   Status = B.Status          
                ,Result = B.Result          
          FROM #TMP_TPDSFCWorkReport    AS A          
          JOIN #TCOMSourceDaily         AS B ON A.WorkReportSeq = B.ToSeq          
        WHERE A.Status = 0          
          AND B.Status <> 0           
          --AND A.RowCnt = @Cnt      
           
     END           
          
          
/*------------------------------------------------------------------------------------------------------------------------------          
    ���� Batch Save          
------------------------------------------------------------------------------------------------------------------------------*/            
 IF OBJECT_ID('tempdb..#TMP_InOutDailyBatch_Xml') IS NOT NULL        
 BEGIN        
  DROP TABLE #TMP_InOutDailyBatch_Xml        
 END       
    ------------------------------              
    -- ����� SAVE TempData����              
    ------------------------------              
    SELECT A.WorkingTag,              
           A.IDX_NO,              
           A.DataSeq,              
           A.Status,              
           A.Selected,              
           'DataBlock1'    AS TABLE_NAME,              
           A.WorkReportSeq AS InOutSeq,              
   130             AS InOutType              
      INTO #TMP_InOutDailyBatch_Xml          
      FROM #TPDSFCWorkReport AS A              
      WHERE  NOT EXISTS (SELECT 1 FROM #TMP_TPDSFCWorkReport WHERE WorkReportSeq = A.WorkReportSeq AND Status <> 0)           
          
    ------------------------------              
    -- ����� SAVE Xml����              
    ------------------------------              
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                SELECT *               
                                                  FROM #TMP_InOutDailyBatch_Xml              
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS              
                                            ))              
 IF OBJECT_ID('tempdb..#TLGInOutDailyBatch') IS NOT NULL        
 BEGIN        
  DROP TABLE #TLGInOutDailyBatch        
 END      
     CREATE TABLE #TLGInOutDailyBatch (WorkingTag NCHAR(1) NULL)                
     EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#TLGInOutDailyBatch'         
  
    ------------------------------              
    -- ����� SAVE SP              
    ------------------------------              
    INSERT INTO #TLGInOutDailyBatch          
    EXEC _SLGInOutDailyBatch               
         @xmlDocument  = @XmlData,              
         @xmlFlags     = 2,              
         @ServiceSeq   = 2619,              
         @WorkingTag   = '',              
         @CompanySeq   = @CompanySeq,               
         @LanguageSeq  = 1,              
         @UserSeq      = @UserSeq,      
         @PgmSeq       = 1015              
    
    IF @@ERROR <> 0               
    BEGIN          
        RAISERROR('Error during ''EXEC _SLGInOutDailyBatch''', 15, 1)          
    END          
      
    -----------------------------------------              
    -- �����ɷ��� ���, üũ���� ���           
    -----------------------------------------            
    IF EXISTS (SELECT 1 FROM #TLGInOutDailyBatch WHERE Status <> 0)          
     BEGIN          
        UPDATE #TMP_TPDSFCWorkReport          
           SET   Status = B.Status          
                ,Result = B.Result          
          FROM #TMP_TPDSFCWorkReport    AS A          
          JOIN #TLGInOutDailyBatch      AS B ON A.WorkReportSeq = B.InOutSeq          
        WHERE A.Status = 0          
          AND B.Status <> 0         
          --AND A.RowCnt = @Cnt       
                  
     END          
        
--------------------------------------------------------------------------------------------------------------------------------------------------           
    -- ���� �ݿ�����  UPDATE          
--------------------------------------------------------------------------------------------------------------------------------------------------           
    UPDATE A          
       SET   ProcYn = CASE WHEN B.Status = 0 THEN '1' ELSE '2' END          
            ,ProcDateTime = @CurrDATETIME          
            ,ErrorMessage = B.Result          
            ,WorkReportSeq    = CASE WHEN B.Status = 0 THEN B.WorkReportSeq ELSE 0 END        
      FROM KPX_TPDSFCWorkReport_POP        AS A          
      JOIN #TMP_TPDSFCWorkReport          AS B ON A.Seq = B.Seq         
                                              AND A.WorkOrderSeq = B.WorkOrderSeq      
                                              AND A.WorkOrderSerl = B.WorkOrderSerl       
    where A.CompanySeq = @CompanySeq   
           
  
      
    --END TRY         
          
           
    --BEGIN CATCH          
    --select 1      
        SELECT ERROR_NUMBER()    AS ErrorNumber,          
               ERROR_SEVERITY()  AS ErrorSeverity,          
               ERROR_STATE()     AS ErrorState,          
               ERROR_PROCEDURE() AS ErrorProcedure,          
               ERROR_LINE()      AS ErrorLine,          
               ERROR_MESSAGE()   AS ErrorMessage;          
          
        --IF @@TRANCOUNT > 0          
        --    ROLLBACK TRANSACTION;          
          
    --END CATCH          
          
    --IF @@TRANCOUNT > 0          
    --    COMMIT TRANSACTION;          
                  
          
          
      
  RETURN         
  
  go 
begin tran 

exec test_KPXCM_SPDSFCWorkReport_POP 2, 1000043336
rollback 