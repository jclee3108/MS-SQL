IF OBJECT_ID('KPXCM_SPDSFCWorkReportExcept_POP') IS NOT NULL 
    DROP PROC KPXCM_SPDSFCWorkReportExcept_POP
GO 

-- v2016.11.16

-- �������̽� �Ǵ� â��� ���� ���� 2016.11.15 by����õ 
-- ��ũ���� ���Լ��� ���� 2016.11.15 by����õ 
/************************************************************      
 ��  �� - ����������� ����      
 �ۼ��� - 2014-12-07      
 �ۼ��� - ���游      
************************************************************/      
CREATE PROCEDURE KPXCM_SPDSFCWorkReportExcept_POP
    @CompanySeq  INT = 2             -- ����          
AS        
    DECLARE  @CurrDate              NCHAR(8)            -- ������        
            ,@XmlData               NVARCHAR(MAX)        
            ,@Seq                   INT        
            ,@MaxNo                 NVARCHAR(50)        
            ,@FactUnit              INT        
            ,@Date                  NVARCHAR(8)        
            ,@DataSeq               INT        
            ,@Count                 INT        
            ,@MatItemPoint          INT      
            ,@UserSeq               INT      
           
    SELECT @CurrDate = CONVERT(NCHAR(8), GETDATE(), 112)        
    EXEC dbo._SCOMEnv @CompanySeq,5,1,@@PROCID,@MatItemPoint OUTPUT         
    
    /******************************************************************
    -- ProcYn ���� ǥ�� 
    0 : ��ó�� 
    1 : ����ó�� 
    4 : �������������� ���� 
    5 : ���� ��ó�� (ó�� ����) 
    6 : ���Լ����� 0�� ������ 
    7 : �۾����� ������ 
    8 : ���ʵ����Ͱ� �����ΰ�� (WorkingTag = 'D') 
    ******************************************************************/
    
    -- ���������Ͱ� ���� �ΰ�� ProcYN = 4 �� ���� 
    SELECT A.IFWorkReportSeq, MAX(Seq) AS Seq  
      INTO #MaxSeq 
      FROM KPX_TPDSFCWOrkReport_POP AS A 
      JOIN (
            SELECT DISTINCT IFWorkReportSeq
              FROM KPX_TPDSFCWorkReportExcept_POP 
             WHERE CompanySeq = @CompanySeq  
               AND ProcYn = '5'
           ) AS B ON ( B.IFWorkReportSeq = A.IFWorkReportSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.IsPacking = '0' 
      GROUP BY A.IFWorkReportSeq

    UPDATE A 
       SET ProcYn = '4', 
           ErrorMessage = '������ ���� �Ǿ����ϴ�.' 
      FROM KPX_TPDSFCWorkReportExcept_POP AS A 
      JOIN (
            SELECT Z.WorkingTag, Z.IFWorkReportSeq
              FROM KPX_TPDSFCWOrkReport_POP AS Z 
              JOIN #MaxSeq AS Y ON ( Z.CompanySeq = @CompanySeq AND Y.Seq = Z.Seq ) 
             WHERE Z.WorkingTag = 'D' 
           ) AS B ON ( B.IFWorkReportSeq = A.IFWorkReportSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ProcYn = '5'
    -- ���������Ͱ� ���� �ΰ�� ProcYN = 4 �� ����, END 
       
       
    UPDATE A      
       SET ProcYN = '0'  
      FROM KPX_TPDSFCWorkReportExcept_POP           AS A      
     WHERE A.ProcYN = '5'      
       AND A.CompanySeq = @CompanySeq      
  
    --���� ������ �ݿ��Ѵ�. --�۾����� ���� ��      
    UPDATE A      
       SET ProcYN = '7',      
           ErrorMessage = B.ErrorMessage      
      FROM KPX_TPDSFCworkReportExcept_POP AS A      
           LEFT OUTER JOIN KPX_TPDSFCWorkReport_POP AS B with(Nolock) ON A.CompanySeq = B.CompanySeq And B.IFWorkReportSeq = A.IFWorkReportSeq      
     WHERE A.ProcYN = '0'      
       AND A.CompanySeq = @CompanySeq    
       AND B.ProcYN = '7'      
      
   --UPDATE A      
   --    SET ProcYN = '7',      
   --        ErrorMessage = 'pop���� �ӽ� ���ó��'    
   --   FROM KPX_TPDSFCworkReportExcept_POP AS A      
   --   WHERE A.ProcYN = '0'      
   --    AND A.CompanySeq = @CompanySeq    
   -- and A.RegEmpSeq <> 1064  
  
    --������ ���� ���� ���� �����Ͱ� �����϶��� �ش� �����͸� �����ϵ��� �Ѵ�.      
    UPDATE A       
       SET ProcYN = '8',      
           ErrorMessage = '������ ���� ���� ���� �����Ͱ� �����϶��� �ش� �����͸� �����ϵ��� �Ѵ�.'      
      FROM KPX_TPDSFCWorkReportExcept_POP AS A      
           JOIN (select IFWorkReportSeq, POPKey, MIN(Seq) AS MinSeq      
                   from KPX_TPDSFCWorkReportExcept_POP  AS Z with(Nolock)     
      WHERE Z.CompanySeq = @CompanySeq  
        And WorkingTag = 'D'      
      GROUP BY IFWorkReportSeq, POPKey      
      HAVING  MIN(Seq) < (SELECT MIN(Seq)  
            from KPX_TPDSFCWorkReportExcept_POP  with(Nolock)    
           WHERE CompanySeq = @CompanySeq  
          AND WorkingTag = 'A'   
          AND IFWorkReportSeq = Z.IFWorkReportSeq      
          AND POPKey = Z.POPKey        
           GROUP BY IFWorkReportSeq, POPKey)      
            ) AS B ON B.IFWorkReportSeq = A.IFWorkReportSeq       
                  AND B.POPKey = A.POPKey      
     WHERE A.CompanySeq = @CompanySeq  
       and A.ProcYN = '0'    
         
      
    --���� ������ 0�̸� �����Ѵ�.      
    UPDATE A       
       SET ProcYN = '6',      
           ErrorMessage = '���� ������ 0 �̸� �����Ѵ�.'      
      FROM KPX_TPDSFCWorkReportExcept_POP  AS A with(nolock)      
     WHERE A.CompanySeq = @CompanySeq  
       And ISNULL(A.Qty,0) = 0      
       AND A.ProcYN = '0'      
      
    UPDATE A      
       SET ProcYN = '5',      
           ErrorMessage = 'ó���� ��������� �����ϴ�.'      
      FROM KPX_TPDSFCWorkReportExcept_POP           AS A      
           LEFT OUTER JOIN KPX_TPDSFCWorkReport_POP AS B with(nolock) ON A.CompanySeq = B.CompanySeq And B.Seq = A.ReportSeq      
           LEFT OUTER JOIN _TPDSFCWorkReport        AS C With(Nolock) ON C.CompanySeq = @CompanySeq  AND C.WorkReportSeq = B.WorkReportSeq       
     WHERE A.ProcYN = '0'      
       AND A.CompanySeq = @CompanySeq      
       AND ISNULL(C.CompanySeq, 0) = 0      
      
    SELECT  DISTINCT         
            A.WorkingTag                    AS WorkingTag,              
            IDENTITY(INT,1,1)               AS DataSeq,              
              0                               AS Status,                          0                               AS Selected,            
            'DataBlock2'                    AS TABLE_NAME,              
            A.Qty                           AS Qty,          
            A.Qty                           AS StdUnitQty,          
            CASE WHEN S.IsLotMng = '1' and ISNULL(A.ItemLotNo ,'') = '' THEN I.ItemNo      
                 WHEN S.IsLotMng = '1' and ISNULL(A.ItemLotNo ,'') <> '' THEN ISNULL(A.ItemLotNo,'')      
                 WHEN S.IsLotMng = '0' THEN ''      
                 ELSE '' END                AS RealLotNo,        
            ''                              AS SerialNoFrom,          
            N'�������� ���԰�(���Կ���)'    AS Remark,          
            6042002                         AS InputType,          
            0                               AS IsPaid,          
            0                               AS IsPjt,          
            0                               AS PjtSeq,          
            0                               AS WBSSeq,          
            B.WorkReportSeq                 AS WorkReportSeq,          
            CASE WHEN A.WorkingTag = 'A' THEN 0      
                 WHEN A.WorkingTag in ( 'D','U') THEN      
                        (SELECT TOP 1 ItemSerl      
                           FROM KPX_TPDSFCWorkREportExcept_POP      
                          WHERE CompanySeq = @CompanySeq  
                            And IFWorkReportSeq = A.IFWorkReportSeq      
                            AND POPKey = A.POPKey      
                            AND ProcYN <> '8'      
                            AND Seq < A.Seq      
                            AND ItemSerl > 0 
                          ORDER BY Seq DESC) END                          AS ItemSerl,          
            A.UnitSeq                       AS MatUnitSeq,          
            A.UnitSeq                       AS StdUnitSeq,          
            B.ProcSeq                       AS ProcSeq,          
            '0'                             AS AssyYn,          
            '0'                             AS IsConsign,          
            B.GoodItemSeq                   AS GoodItemSeq,          
            A.WHSeq                         AS WHSeq,          
            0                               AS ProdWRSeq,          
            A.ItemSeq                       AS MatItemSeq,          
            R.WorkDate                      AS InputDate,        
            A.Seq                           AS Seq,      
            A.RegEmpSeq                     AS EmpSeq,      
            A.IFWorkReportSeq, 
            A.Remark AS IsTank
      INTO #TMP_PDSFCMatinput_Xml          
      FROM KPX_TPDSFCWorkReportExcept_POP AS A        
           JOIN KPX_TPDSFCWorkReport_POP AS B ON A.CompanySeq = B.CompanySeq  
                                             And B.IFWorkReportSeq = A.IFWorkReportSeq      
                                             AND B.Seq = A.ReportSeq      
                                             AND B.ProcYN = '1'      
           JOIN (SELECT TOP 1 A.IFWorkReportSeq, A.WorkingTag, B.WorkReportSeq      
                   FROM KPX_TPDSFCWorkReportExcept_POP AS A      
                        JOIN KPX_TPDSFCWorkReport_POP AS B ON A.CompanySeq = B.CompanySeq  
                                                          And B.IFWorkReportSeq = A.IFWorkReportSeq      
                                                          AND B.Seq = A.ReportSeq      
                                                          AND B.ProcYN = '1'      
                        JOIN _TPDSFCWorkReport AS C ON C.CompanySeq = @CompanySeq AND C.WorkReportSeq = B.WorkReportSeq      
                  WHERE A.ProcYN = '0'      
                    AND A.CompanySeq = @CompanySeq      
                    AND ISNULL(A.Qty,0) <> 0      
                    --and a.reportseq = 1000078889 
                  ORDER BY A.Seq) AS X ON X.IFWorkReportSeq = A.IFWorkReportSeq AND X.WorkingTag = A.WorkingTag AND X.WorkReportSeq = B.WorkReportSeq      
           LEFT OUTER JOIN _TPDSFCWorkReport AS R WITH(NOLOCK) ON R.CompanySeq = @CompanySeq      
                                 AND R.WorkReportSeq = B.WorkReportSeq      
           LEFT OUTER JOIN _TPDBaseWorkCenter AS W ON W.CompanySeq = @CompanySeq        
                                                  AND W.WorkCenterSeq = B.WorkCenterSeq      
           LEFT OUTER JOIN _TDAItemStock AS S ON S.CompanySeq = @CompanySeq      
                                             AND S.ItemSeq = A.ItemSeq      
           LEFT OUTER JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq      
                                        AND I.ItemSeq = A.ItemSeq      
                                                               
     WHERE A.CompanySeq = @CompanySeq      
       --and a.reportseq = 1000078889   
       AND A.ProcYN = '0'        
       AND ISNULL(A.Qty,0) <> 0    
     ORDER BY Seq        
      
      
    --���� �����Ϳ� ���� ���ϼ��� ������ ��.      
    --���� IFWorkReportSeq ���� WorkingTag�� ������ �� ���� ������ ���Ĵ� �����Ѵ�.      
    DELETE #TMP_PDSFCMatinput_Xml      
      FROM #TMP_PDSFCMatinput_Xml AS A      
     WHERE Seq > (SELECT MIN(Seq) AS Seq       
                    FROM KPX_TPDSFCWorkReportExcept_POP       
                   WHERE CompanySeq = @CompanySeq And IFWorkReportSeq = A.IFWorkReportSeq AND ProcYN = '0' AND WorkingTag <> A.WorkingTag       
                     AND Seq >= (SELECT MIN(Seq) FROM #TMP_PDSFCMatinput_Xml)      
                 )      
      
     
    SELECT @UserSeq = U.UserSeq      
      FROM #TMP_PDSFCMatinput_Xml AS A      
           LEFT OUTER JOIN _TCAUSer AS U ON U.CompanySeq = @CompanySeq AND U.EmpSeq = A.EmpSeq      
      
      
--select * from #TMP_PDSFCMatinput_Xml-- ���ʽ�����ϰǿ� ����ó�� �ɶ�, �ش� ���ʽ������� ���ڷ� �������� �����ǵ��� ó��  -- 14.02.17 BY �輼ȣ        
    UPDATE #TMP_PDSFCMatinput_Xml        
       SET InputDate = B.WorkDate        
      FROM #TMP_PDSFCMatinput_Xml AS A        
           JOIN _TPDSFCWorkReport  AS B ON B.CompanySeq = @CompanySeq AND A.WorkReportSeq = B.WorkReportSeq        
    
    
    -- ��������� ������ ���� ���̺����� ��� (KPXCM_SPDSFCWorkReportExcept_POP_Main SP ����)
    TRUNCATE TABLE KPXCM_TPDSFCMatInputStockApply 
    INSERT INTO KPXCM_TPDSFCMatInputStockApply ( CompanySeq, InOutYM, LastUserSeq, LastDateTime ) 
    SELECT DISTINCT @CompanySeq, LEFT(A.InputDate,6), 1, GETDATE() 
      FROM #TMP_PDSFCMatinput_Xml AS A 
     WHERE NOT EXISTS (SELECT 1 FROM KPXCM_TPDSFCMatInputStockApply WHERE CompanySeq = @CompanySeq AND InOutYM = LEFT(A.InputDate,6))
    


    -- ���� �� ������ ������ �� ��� �����Ǹ� �ݿ� 2016.10.06 by����õ 
    SELECT * 
      INTO #Main_TMP_PDSFCMatinput_Xml
      FROM #TMP_PDSFCMatinput_Xml

    SELECT WorkingTag, WorkReportSeq, ItemSerl, MAX(Seq) AS MaxSeq 
      INTO #MaxSeq_Sub
      FROM #TMP_PDSFCMatinput_Xml 
     WHERE WorkingTag = 'U' 
     GROUP BY WorkingTag, WorkReportSeq, ItemSerl 
    
    DELETE A 
      FROM #TMP_PDSFCMatinput_Xml AS A 
     WHERE NOT EXISTS (SELECT 1 FROM #MaxSeq_Sub WHERE MaxSeq = A.Seq) 
       AND A.WorkingTag = 'U' 
    -- ���� �� ������ ������ �� ��� �����Ǹ� �ݿ�, END 
    

    -- ��ũ���� ��ǰ,����ǰ ���Լ��� Lot��ü 2016.11.15 by����õ 
    CREATE TABLE #FIFO 
    (
        ItemSeq     INT, 
        LotNo       NVARCHAR(100), 
        WHSeq       INT, 
        Status      INT, 
        Result      NVARCHAR(500)
    )


    DECLARE @MatInPutCnt        INT, 
            @CompanySeqSub      INT, 
            @ItemSeqSub         INT, 
            @LotNoSub           NVARCHAR(100), 
            @WHSeqSub           INT, 
            @QtySub             DECIMAL(19,5), 
            @IsTankSub          NCHAR(1), 
            @InPutDateSub       NCHAR(8), 
            @WorkingTagSub      NCHAR(1), 
            @WorkReportSeqSub   INT, 
            @ItemSerlSub        INT, 
            @SeqSub             INT 
    --select * from #TMP_PDSFCMatinput_Xml
    --return 
    SELECT @MatInPutCnt = 1 

    WHILE ( 1 = 1 ) 
    BEGIN 
        SELECT @ItemSeqSub          = A.MatItemSeq, 
               @LotNoSub            = A.RealLotNo, 
               @WHSeqSub            = A.WHSeq, 
               @QtySub              = A.StdUnitQty, 
               @IsTankSub           = A.IsTank, 
               @InPutDateSub        = A.InPutDate, 
               @WorkingTagSub       = A.WorkingTag, 
               @WorkReportSeqSub    = A.WorkReportSeq, 
               @ItemSerlSub         = A.ItemSerl, 
               @SeqSub              = A.Seq 
          FROM #TMP_PDSFCMatinput_Xml AS A 
         WHERE A.DataSeq = @MatInPutCnt 


        TRUNCATE TABLE #FIFO 
        EXEC KPXCM_SPDSFCWorkReportExcept_POP_FIFO @CompanySeq, 
                                                   @ItemSeqSub, 
                                                   @LotNoSub, 
                                                   @WHSeqSub, 
                                                   @QtySub, 
                                                   @IsTankSub, 
                                                   @InPutDateSub, 
                                                   @WorkingTagSub, 
                                                   @WorkReportSeqSub, 
                                                   @ItemSerlSub, 
                                                   @SeqSub
    
        IF @MatInPutCnt >= ISNULL((SELECT MAX(DataSeq) FROM #TMP_PDSFCMatinput_Xml),0)
        BEGIN
            BREAK 
        END 
        ELSE 
        BEGIN
            SELECT @MatInPutCnt = @MatInPutCnt + 1
        END 
    
    END 
    
    -- ��ũ���� ��ǰ,����ǰ ���Լ��� Lot��ü, END 
    
    
    ------------------------------              
    -- �ҿ����� Check Xml����              
    ------------------------------              
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                SELECT *               
                                                  FROM #TMP_PDSFCMatinput_Xml              
                                                   FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS              
                                            ))              
    IF OBJECT_ID('tempdb..#TPDSFCMatinput') IS NOT NULL          
    BEGIN          
        DROP TABLE #TPDSFCMatinput          
    END          
           
    CREATE TABLE #TPDSFCMatinput (WorkingTag NCHAR(1) NULL)              
    EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2909, 'DataBlock2', '#TPDSFCMatinput'          
        
    ------------------------------              
      -- �ҿ����� Check SP              
    ------------------------------              
    INSERT INTO #TPDSFCMatinput          
    EXEC _SPDSFCWorkReportMatCheck               
         @xmlDocument  = @XmlData,              
         @xmlFlags     = 2,              
         @ServiceSeq   = 2909,              
         @WorkingTag   = '',              
         @CompanySeq   = @CompanySeq,              
         @LanguageSeq  = 1,              
         @UserSeq      = @UserSeq,           
         @PgmSeq       = 1015        
    
    --������ ����ó��        
    UPDATE A        
       SET ProcYN = '2',        
           ErrorMessage = ISNULL(C.Result, ''),        
           ProcDateTime = GETDATE()        
      FROM KPX_TPDSFCWorkReportExcept_POP AS A        
           JOIN #TMP_PDSFCMatinput_Xml AS B ON B.Seq = A.Seq        
           JOIN #TPDSFCMatinput AS C ON C.DataSeq = B.DataSeq        
     WHERE A.CompanySeq = @CompanySeq    
       and C.Status <> 0  
         
      
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                             SELECT *               
                                                 FROM #TPDSFCMatinput               
                                              WHERE Status = 0          
                                                FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS              
                                             ))              
    
    DELETE FROM #TPDSFCMatinput         
     
    ------------------------------              
    -- �ҿ����� SAVE SP              
    ------------------------------              
    INSERT INTO #TPDSFCMatinput              
    EXEC KPXCM_SPDSFCWorkReportMatOutWhSaveIFWh -- 2016.11.15 I/F�Ǵ� â��� ����ó���ϱ� ���� New SP by����õ 
         @xmlDocument  = @XmlData,              
         @xmlFlags     = 2,              
         @ServiceSeq   = 2909,              
         @WorkingTag   = '',              
         @CompanySeq   = @CompanySeq,              
         @LanguageSeq  = 1,              
         @UserSeq      = 1,           
         @PgmSeq       = 1015        
    
    --������ ����ó��        
    UPDATE A        
       SET ProcYN = '2',        
           ErrorMessage = ISNULL(C.Result, ''),        
           ProcDateTime = GETDATE()       
      FROM KPX_TPDSFCWorkReportExcept_POP AS A        
           JOIN #TMP_PDSFCMatinput_Xml AS B ON B.Seq = A.Seq        
           JOIN #TPDSFCMatinput AS C ON C.DataSeq = B.DataSeq      
     WHERE A.CompanySeq = @CompanySeq  
       and C.Status <> 0       
    
    --/*
    ---------------------------------------------------------------------------------------------
    -- �������� 
    ---------------------------------------------------------------------------------------------
    ----------------------------              
    -- ����� SAVE TempData����              
    ------------------------------              
    SELECT 'U' AS WorkingTag,              
           MIN(A.DataSeq) AS IDX_NO, 
           MIN(A.DataSeq) AS DataSeq, 
           MIN(A.Status) AS Status, 
           MIN(A.Selected) AS Selected, 
           'DataBlock1'    AS TABLE_NAME,              
           A.WorkReportSeq AS InOutSeq,              
           130             AS InOutType              
      INTO #TMP_InOutDailyBatchMatInPut_Xml          
      FROM #TMP_PDSFCMatinput_Xml AS A         
     GROUP BY A.WorkReportSeq  
          
    ------------------------------              
    -- ����� SAVE Xml����              
    ------------------------------              
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                SELECT *               
                                                  FROM #TMP_InOutDailyBatchMatInPut_Xml              
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
    ---------------------------------------------------------------------------------------------
    -- ��������, END  
    ---------------------------------------------------------------------------------------------
    --*/
    ------------------------------              
    -- ����� SAVE TempData����              
    ------------------------------              
    IF OBJECT_ID('tempdb..#TMP_InOutDailyBatch_Xml') IS NOT NULL        
    BEGIN        
        DROP TABLE #TMP_InOutDailyBatch_Xml        
    END       
    CREATE TABLE #TMP_InOutDailyBatch_Xml (WorkingTag NCHAR(1), DataSeq INT IDENTITY(1,1), Status INT, Selected INT,        
                                           TABLE_NAME NVARCHAR(100), InOutSeq INT, InOutType INT, Seq INT)        
    INSERT INTO #TMP_InOutDailyBatch_Xml        
    SELECT DISTINCT         
            'A'     AS WorkingTag,           
            --IDENTITY(INT,1,1)   AS DataSeq,              
            0                   AS Status,              
            0                   AS Selected,            
            'DataBlock1'   AS TABLE_NAME,               
            A.WorkReportSeq  AS InOutSeq,              
            180     AS InOutType,        
            MIN(A.DataSeq)  AS Seq        
      FROM #TPDSFCMatinput AS A        
     WHERE EXISTS (SELECT 1 FROM #TPDSFCMatinput WHERE WorkReportSeq = A.WorkReportSeq )--AND Status <> 0)           
       AND A.WorkReportSeq NOT IN (SELECT InOutSeq FROM _TLGInOutDaily WHERE CompanySeq = @CompanySeq AND InOutType = 130)        
       AND A.Status <> 0      
     GROUP BY A.WorkReportSeq        
     UNION         
    SELECT          
            'U'     AS WorkingTag,           
            --IDENTITY(INT,1,1)   AS DataSeq,              
            0                   AS Status,              
            0                   AS Selected,      
            'DataBlock1'   AS TABLE_NAME,              
            A.WorkReportSeq  AS InOutSeq,              
            180     AS InOutType,        
            MIN(A.DataSeq)  AS Seq        
      FROM #TPDSFCMatinput AS A        
     WHERE EXISTS (SELECT 1 FROM #TPDSFCMatinput WHERE WorkReportSeq = A.WorkReportSeq )--AND Status <> 0)           
       AND A.WorkReportSeq IN (SELECT InOutSeq FROM _TLGInOutDaily WHERE CompanySeq = @CompanySeq AND InOutType = 130)       
       AND A.Status <> 0       
     GROUP BY A.WorkReportSeq        
  
    ------------------------------              
    -- ����� SAVE Xml����              
    ------------------------------              
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                SELECT *               
                                                  FROM #TMP_InOutDailyBatch_Xml              
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS              
                                            ))              
    TRUNCATE TABLE #TLGInOutDailyBatch
    --CREATE TABLE #TLGInOutDailyBatch (WorkingTag NCHAR(1) NULL)                
    --EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#TLGInOutDailyBatch'               
--select @XmlData      
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
        
    -----------------------------------------              
    -- �����ɷ��� ���, üũ���� ���           
    -----------------------------------------            
    IF EXISTS (SELECT 1 FROM #TLGInOutDailyBatch WHERE Status <> 0)          
     BEGIN          
        UPDATE KPX_TPDSFCWorkReportExcept_POP          
           SET ProcYN = '2',        
               ErrorMessage = '_SLGInOutDailyBatch ����',        
               ProcDateTime = GETDATE(),        
               WorkReportSeq = B.WorkReportSeq        
          FROM KPX_TPDSFCWorkReportExcept_POP AS A        
               JOIN #TMP_PDSFCMatinput_Xml AS B ON B.Seq = A.Seq        
               JOIN #TLGInOutDailyBatch      AS C ON B.WorkReportSeq = C.InOutSeq          
         WHERE A.CompanySeq = @CompanySeq  
           and C.Status <> 0          
     END          

    -- ���� �� ������ ������ �� ��� �����Ǹ� �ݿ� 2016.10.06 by����õ 
    -- ó�����´� ��� �����ϱ� ���� �۾� 2016.10.19 by����õ 
    SELECT * 
      INTO #Result_Xml
      FROM #TMP_PDSFCMatinput_Xml 
    UNION ALL 
    SELECT A.* 
      FROM #Main_TMP_PDSFCMatinput_Xml AS A 
     WHERE NOT EXISTS (SELECT 1 FROM #TMP_PDSFCMatinput_Xml WHERE DataSeq = A.DataSeq AND WorkingTag = A.WorkingTag) 
    -- ó�����´� ��� �����ϱ� ���� �۾�,END 

  
    UPDATE A        
       SET ProcYN = '1',        
           ErrorMessage = '',        
           ProcDateTime = GETDATE(),        
           WorkReportSeq = B.WorkReportSeq, 
           ItemSerl = ISNULL(C.ItemSerl,B.ItemSerl)
          
      FROM KPX_TPDSFCWorkReportExcept_POP AS A        
           JOIN #Result_Xml AS B ON B.Seq = A.Seq        
           LEFT OUTER JOIN #TPDSFCMatinput AS C ON C.DataSeq = B.DataSeq        
           LEFT OUTER JOIN _TPDSFCMatInput AS S WITH(NOLOCK) ON S.CompanySeq = @CompanySeq      
                                                            AND S.WorkReportSeq = C.WorkReportSeq      
                                                            AND S.ItemSerl = C.ItemSerl      
     WHERE A.CompanySeq = @CompanySeq  
       and B.WorkingTag <> 'D'      
       AND ISNULL(C.Status,0) = 0      
    

    UPDATE A        
       SET ProcYN = '1',        
           ErrorMessage = '',        
           ProcDateTime = GETDATE(),        
           WorkReportSeq = 0,      
           ItemSerl = 0      
           --select * c      
      FROM KPX_TPDSFCWorkReportExcept_POP AS A        
           JOIN #Result_Xml AS B ON B.Seq = A.Seq        
           LEFT OUTER JOIN #TPDSFCMatinput AS C ON C.DataSeq = B.DataSeq        
           LEFT OUTER JOIN _TPDSFCMatInput AS S WITH(NOLOCK) ON S.CompanySeq = @CompanySeq      
                                                            AND S.WorkReportSeq = C.WorkReportSeq      
                                                            AND S.ItemSerl = C.ItemSerl      
     WHERE A.CompanySeq = @CompanySeq  
       and  ISNULL(S.CompanySeq, 0) = 0      
       AND B.WorkingTag = 'D'      
       AND C.Status = 0      
        
    
    UPDATE A 
       SET WorkReportSeq = B.WorkReportSeq, 
           ItemSerl = B.ItemSerl  
      FROM KPXCM_TPDSFCMatInputFIFORelation             AS A 
      LEFT OUTER JOIN KPX_TPDSFCWorkReportExcept_POP    AS B ON ( B.Seq = A.Seq ) 

        
    -- ���������Ͱ� �ű��ΰ�� ProcYN = 5�� ���� 
    SELECT A.IFWorkReportSeq, MAX(Seq) AS Seq  
      INTO #MaxSeqSub
      FROM KPX_TPDSFCWOrkReport_POP AS A 
      JOIN (
            SELECT DISTINCT IFWorkReportSeq
              FROM KPX_TPDSFCWorkReportExcept_POP 
             WHERE CompanySeq = @CompanySeq  
               AND ProcYn = '4'
               AND CONVERT(NCHAR(8),RegDateTime ,112) BETWEEN CONVERT(NCHAR(8), DATEADD(MONTH,-3,GETDATE()),112) AND CONVERT(NCHAR(8),GETDATE(),112) -- 3���� ~ ����
           ) AS B ON ( B.IFWorkReportSeq = A.IFWorkReportSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.IsPacking = '0' 
      GROUP BY A.IFWorkReportSeq

    UPDATE A 
       SET ProcYn = '5', 
           ErrorMessage = '�ű԰��� ���Խ��ϴ�.' 
      FROM KPX_TPDSFCWorkReportExcept_POP AS A 
      JOIN (
            SELECT Z.WorkingTag, Z.IFWorkReportSeq
              FROM KPX_TPDSFCWOrkReport_POP AS Z 
              JOIN #MaxSeqSub AS Y ON ( Z.CompanySeq = @CompanySeq AND Y.Seq = Z.Seq ) 
             WHERE Z.WorkingTag = 'A' 
           ) AS B ON ( B.IFWorkReportSeq = A.IFWorkReportSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ProcYn = '4'
       AND CONVERT(NCHAR(8),RegDateTime ,112) BETWEEN CONVERT(NCHAR(8), DATEADD(MONTH,-3,GETDATE()),112) AND CONVERT(NCHAR(8),GETDATE(),112) -- 3���� ~ ����
    -- ���������Ͱ� �ű��ΰ�� ProcYN = 5 �� ����, END 
        
        
      
RETURN        
       

GO
--begin tran 
--exec KPXCM_SPDSFCWorkReportExcept_POP 2



----select * from KPX_TPDSFCWorkReportExcept_POP as a where companyseq = 2 and IFWorkReportseq = '2016103100118'
----order by seq 
--rollback 

