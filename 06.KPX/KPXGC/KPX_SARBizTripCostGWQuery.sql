
IF OBJECT_ID('KPX_SARBizTripCostGWQuery') IS NOT NULL 
    DROP PROC KPX_SARBizTripCostGWQuery
GO 

-- v2015.01.08 

-- ����� ����ǰ�Ǽ� GW��ȸ by����õ 
 CREATE PROC KPX_SARBizTripCostGWQuery           
     @xmlDocument    NVARCHAR(MAX) ,                                
     @xmlFlags       INT = 0,                                
     @ServiceSeq     INT = 0,                                
     @WorkingTag     NVARCHAR(10)= '',                                      
     @CompanySeq     INT = 1,                                
     @LanguageSeq    INT = 1,                                
     @UserSeq        INT = 0,                                
     @PgmSeq         INT = 0                                   
    
 AS 
    
    -- ���� ����              
    DECLARE @docHandle      INT,                      
             @SlipMstSeq     INT,              
             @SlipSeq        INT,              
             @AccUnit        INT,              
             @SlipUnit       INT,              
             @AccDate        NCHAR(8),              
             @SlipNo         NCHAR(4),            
             @RemTotalCount  INT,            
             @index          INT,            
             @Word           NVARCHAR(200),      
             @Mask           NVARCHAR(50),      
             @EnvValue       NVARCHAR(20),      
             @CurrDate       NCHAR(8),      
             @KORDecimal     INT,      
             @FORDecimal     INT,      
             @ExraDecimal    INT,      
             @SumDrAmt       DECIMAL(19,5),      
             @SumCrAmt       DECIMAL(19,5),      
             @MaxIDX         INT,  
             @DrSumFirstFage   DECIMAL(19, 5),   
             @CrSumFirstFage   DECIMAL(19, 5),  
             @IsOnlyOnPage     NCHAR(1),  
             @Cnt            INT,  
             @IniCnt         INT,  
             @MaxCnt         INT,  
             @SubCnt         INT,  
             @SubMaxCnt      INT,  
             @DataBlock2     NVARCHAR(Max),  
             @XmlData        NVARCHAR(MAX),  
             @NativeCurr     INT,  
             @PersonId       NVARCHAR(20),  
             @IsNotGW        NCHAR(1),  
             @Env4058  NCHAR(1),   -- ��ǥ��½�, ������ �հ�ǥ�ÿ���  
             @Env4040        NCHAR(1),    --�ⳳ�ܾױ���  
             @BizTripSeq    INT 
               
     -- xml�غ�              
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument              
     CREATE TABLE #Temp (Cnt         INT IDENTITY(0,1),  
                         SlipMstSeq  INT,  
                         DataBlock2  NVARCHAR(MAX)          )  
     -- ��¹����� �ݺ��ο� ����� �������� XML���������� ��� �� �ӽ����̺��� �����Ѵ�.    
     CREATE TABLE #Temp_DetailRepeat (   SubCnt          INT IDENTITY(0,1),  
                                         SlipMstSeq      INT,  
                                         DataBlock2      NVARCHAR(MAX)  )  
    
       
     SELECT @SlipMstSeq      = ISNULL(SlipMstSeq, 0),              
            @SlipSeq         = ISNULL(SlipSeq, 0),              
            @AccUnit         = AccUnit,              
            @SlipUnit        = SlipUnit,              
            @AccDate         = AccDate,              
            @SlipNo          = LTRIM(RTRIM(SlipNo)),  
            @IsNotGW         = ISNULL(IsNotGW,''), 
            @BizTripSeq     = ISNULL(BizTripSeq,0)          
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)              
       WITH (SlipMstSeq      INT,              
             SlipSeq         INT,              
             AccUnit         INT,              
             SlipUnit        INT,              
             AccDate         NCHAR(8),              
             SlipNo          NVARCHAR(4),  
             IsNotGW         NCHAR(1), 
             BizTripSeq      INT ) 
    
    INSERT INTO #Temp (SlipMstSeq)  
     SELECT ISNULL(SlipMstSeq, 0) AS SlipMstSeq  
       FROM KPX_TARBizTripCost AS A     
      WHERE A.BizTripSeq = @BizTripSeq 
    
    
    -- ����ڹ�ȣ Mask Format      
    SELECT @Mask  = ISNULL(EnvValue, '') FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 17      
    IF @@ROWCOUNT = 0 SELECT @Mask = ''          
    
    SET @SlipNo = RIGHT('000' + LTRIM(RTRIM(@SlipNo)), 4)              
    SELECT @NativeCurr  = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 13 -- �ڱ���ȭ  
    SELECT @KORDecimal  = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 15   -- ��ȭ�Ҽ����ڸ���          
    SELECT @FORDecimal  = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 14   -- ��ȭ�Ҽ����ڸ���      
    SELECT @ExraDecimal = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 11   -- ȯ���Ҽ����ڸ���       
    SELECT @Env4058     = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 4058 -- ��ǥ��½� �հ�ǥ�ÿ���  
    
    IF @KORDecimal = 0 SELECT @KORDecimal = -1      
    IF @FORDecimal = 0 SELECT @FORDecimal = -1      
    IF @ExraDecimal = 0 SELECT @ExraDecimal = -1      
    --================================================================================================================================                   
    -- ȯ�漳��(�ⳳ�Է�(�ܾױ���))������ ���� �ⳳ������ ����� ���� �ӽ����̺� ���� (2012.02.01 mypark)       
    --================================================================================================================================         
    CREATE TABLE #tempCash    
    (    
          CompanySeq      INT,     
          SlipSeq         INT,     
          Amt             DECIMAL(19,5),    
          ForAmt          DECIMAL(19,5),     
          CashDate        NCHAR(8),    
          Serl            INT,  
          SMInOrOut       INT,  
          SMCashMethod    INT  
     
    )    
    CREATE TABLE #tempCashOff    
    (    
          CompanySeq      INT,     
          SlipSeq         INT,     
          OffSlipSeq      INT,    
          Serl            INT,    
     
    )                
      --�ⳳ���� �����͸� ��� ���� ���� �ʵ��� SlipSeq�� �޾Ƴ��´�.  
     CREATE TABLE #CashSlipSeq  
     (     
         SlipSeq     INT  
      )  
        
      INSERT INTO #CashSlipSeq (SlipSeq)  
      SELECT SlipSeq FROM _TACSlipRow WHERE CompanySeq = @CompanySeq AND SlipMstSeq IN (SELECT SlipMstSeq FROM #Temp )  
                
     SELECT @Env4040 = ''  
     SELECT @Env4040 = EnvValue FROM _TCOMEnv where CompanySeq = @CompanySeq AND EnvSeq = 4040  
     
      IF @Env4040 <> '1'  
      BEGIN  --�ⳳ(����)  
          INSERT INTO #tempCash (CompanySeq, SlipSeq,Amt, ForAmt, CashDate, Serl, SMInOrOut, SMCashMethod)    
              SELECT A.CompanySeq, A.SlipSeq, A.Amt, A.ForAmt, A.CashDate, A.Serl, B.SMInOrOut, A.SMCashMethod   
                FROM _TAPCashOn AS A JOIN (SELECT CompanySeq, SlipSeq, MIN(Serl) AS Serl  
                                             FROM _TAPCashOn   
                                            WHERE CompanySeq = @CompanySeq  
                                              AND SlipSeq IN (SELECT SlipSeq FROM #CashSlipSeq)  
                                            GROUP BY CompanySeq, SlipSeq) AS A2  
                                       ON A.CompanySeq   = A2.CompanySeq  
                                      AND A.SlipSeq      = A2.SlipSeq  
                                      AND A.Serl         = A2.Serl  
                                     LEFT OUTER JOIN _TAPCash AS B WITH(NOLOCK)  
                                         ON A.CompanySeq = B.CompanySeq   
                                        AND A.SlipSeq    = B.SlipSeq   
               WHERE A.CompanySeq = @CompanySeq  
                 AND A.SlipSeq    IN (SELECT SlipSeq FROM #CashSlipSeq)  
           INSERT INTO #tempCashOff (CompanySeq, SlipSeq, OffSlipSeq, Serl)    
              SELECT CompanySeq, SlipSeq, OffSlipSeq, Serl    
                FROM _TAPCashOff    
               WHERE CompanySeq  = @CompanySeq   
       END     
      ELSE    
      BEGIN  --�ⳳ(�ܾױ���)  
          INSERT INTO #tempCash (CompanySeq, SlipSeq, Amt, ForAmt, CashDate, Serl, SMInOrOut, SMCashMethod)    
    SELECT CompanySeq, SlipSeq, OnAmt, OnForAmt, CashDate, 1, SMInOrOut, SMCashMethod  
                FROM _TACCashOn   
               WHERE CompanySeq = @CompanySeq    
                 AND SlipSeq IN (SELECT SlipSeq FROM #CashSlipSeq)  
                   
          INSERT INTO #tempCashOff (CompanySeq, SlipSeq, OffSlipSeq, Serl)    
              SELECT CompanySeq, OnSlipSeq, SlipSeq,  1    
                FROM _TACCashOff   
               WHERE CompanySeq = @CompanySeq   
      END    
        
     --================================================================================================================================                  
     -- ȯ�漳��(�ⳳ�Է�(�ܾױ���))������ ���� �ⳳ������ ����� ���� �ӽ����̺� ���� ��     
     --================================================================================================================================              
        
     SELECT             
            A.CompanySeq,              
            A.SlipMstSeq,        -- ��ǥ�������ڵ�              
            A.AccUnit,           -- ȸ�����              
            A.SlipUnit,          -- ��ǥ��������              
            A.AccDate,           -- ȸ����              
            A.SlipNo,            -- ��ǥ�Ϸù�ȣ              
            A.SlipKind,          -- ��ǥ����         
            B.SlipKindName,             
            A.RegEmpSeq,         -- ��ǥ��              
            A.RegDeptSeq,        -- ��ǥ�μ�              
            A.Remark,            -- ���              
            A.SMCurrStatus,      -- ��������              
            A.AptDate,           -- ������              
            A.AptEmpSeq,         -- ������              
            A.AptDeptSeq,        -- �����μ�              
            A.AptRemark,         -- �������              
            A.SMCheckStatus,     -- ��������              
            A.CheckOrigin,       -- ��õ��ȣ              
            A.IsSet,             -- ���ο���        
            A.SetSlipNo,         -- �����Ϸù�ȣ              
            A.SetEmpSeq,         -- ������              
            A.SetDeptSeq,        -- ���κμ�              
            A.SlipMstID,         -- ��ǥ��ǥ��ȣ              
            CASE              
 --                WHEN A.IsSet = '1' THEN              
 --                   RIGHT('0' + CAST(A.AccUnit AS VARCHAR), 2) + '-' +             
 --                        A.AccDate + '-' + A.SetSlipNo              
 --                ELSE ''          
                 WHEN A.IsSet = '1' THEN  
                    ISNULL(A.SetSlipID, '')  
                 ELSE ''            
            END AS SlipAppNo, -- ��ǥ��ȣ              
            A.RegAccDate,     -- ��ǥ��ȣ  
            A.RegDateTime,     -- ��ǥ�������  
            CONVERT(NCHAR(8), A.RegDateTime, 112) AS RTRegAccDate,  
            CASE WHEN ISNULL(D.IsSet, '') <> '1' THEN '' ELSE CONVERT(NVARCHAR(100),D.ApprovalDateTime, 121) END AS ApprovalDateTime,--���� �����Ͻ�  
            CASE WHEN ISNULL(D.IsSet, '') <> '1' THEN '' ELSE CONVERT(NCHAR(8), D.ApprovalDateTime, 112) END AS RTSetAccDate,  
            U.Remark AS UMSlipKindGroupName  
       INTO #tmp              
       FROM _TACSlip AS A WITH (NOLOCK)      
                 INNER JOIN #Temp        AS C ON A.SlipMstSeq = C.SlipMstSeq     
            LEFT OUTER JOIN _TACSlipKind AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.SlipKind = B.SlipKind       
            LEFT OUTER JOIN _TDAUMinor AS U WITH(NOLOCK) ON U.CompanySeq = B.CompanySeq AND U.MinorSeq = B.UMSlipKindGroup  
            LEFT OUTER JOIN _TACSlipSetData AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq   
                                                             AND A.SlipMstSeq = D.SlipMstSeq   
                                                             AND D.Serl      = (SELECT MAX(Serl) AS Serl   
                                                                                 FROM _TACSlipSetData  
                                                                                WHERE CompanySeq = A.CompanySeq  
        AND SlipMstSeq = A.SlipMstSeq  
                                                                                )  
              
 --           LEFT OUTER JOIN _TACSlipSetNo AS K WITH(NOLOCK) ON A.CompanySeq = K.CompanySeq AND A.SlipMstSeq = K.SlipMstSeq           
      WHERE A.CompanySeq = @CompanySeq              
 --       AND (    (@SlipMstSeq <> 0 AND A.SlipMstSeq = @SlipMstSeq)              
 --                OR              
 --                (@SlipMstSeq = 0 AND @SlipMstSeq = 0 AND (              
 --                                    (A.AccUnit    = @AccUnit)              
 --                                     AND (A.SlipUnit   = @SlipUnit)              
 --                                    AND (A.AccDate   = @AccDate)              
 --                                    AND (A.SlipNo    = @SlipNo)              
 --                                    )              
 --                )              
 --                OR              
 --                (@SlipMstSeq = 0 AND EXISTS (SELECT * FROM _TACSlipRow WHERE CompanySeq = A.CompanySeq AND SlipSeq = @SlipSeq AND SlipMstSeq = A.SlipMstSeq)              
 --                )              
 --           )              
    
        
      SELECT A.SlipMstSeq,        -- ��ǥ�������ڵ�              
            A.AccUnit,           -- ȸ�����              
            A.SlipUnit,          -- ��ǥ��������              
            A.AccDate,           -- ȸ����              
            A.SlipNo,            -- ��ǥ�Ϸù�ȣ              
            A.SlipKind,          -- ��ǥ����           
            A.SlipKindName,          -- ��ǥ����           
            A.RegEmpSeq,         -- ��ǥ��              
            A.RegDeptSeq,        -- ��ǥ�μ�              
            A.Remark,            -- ���              
            A.SMCurrStatus,      -- ��������              
            A.AptDate,           -- ������              
            A.AptEmpSeq,         -- ������              
            A.AptDeptSeq,        -- �����μ�              
            A.AptRemark,         -- �������              
            A.SMCheckStatus,     -- ��������              
            A.CheckOrigin, -- ��õ��ȣ              
            A.IsSet,             -- ���ο���              
            A.SetSlipNo,         -- �����Ϸù�ȣ              
            A.SetEmpSeq,         -- ������              
            A.SetDeptSeq,        -- ���κμ�              
            C.EmpName    AS RegEmpName,      -- ��ǥ��              
            F.DeptName   AS RegDeptName,     -- ��ǥ�μ�              
            D.EmpName    AS AptEmpName,      -- ������              
            G.DeptName   AS AptDeptName,     -- �����μ�              
            E.EmpName    AS SetEmpName,      -- ������              
            H.DeptName   AS SetDeptName,     -- ���κμ�              
            I.SlipUnitName,                  -- ��ǥ��������              
            -- 01-01-20080716-0001              
            A.SlipMstID,         -- ��ǥ��ǥ��ȣ              
            A.SlipAppNo,               -- ��ǥ��ȣ              
            ISNULL(B.DrAmt, CAST(0 AS DECIMAL(19,5)) ) AS MstDrAmt,         -- �����ݾ�              
            ISNULL(B.CrAmt, CAST(0 AS DECIMAL(19,5)) ) AS MstCrAmt,         -- �뺯�ݾ�              
            ISNULL(B.DrForAmt, CAST(0 AS DECIMAL(19,5)) ) AS MstDrForAmt,   -- ��ȭ�����ݾ�              
            ISNULL(B.CrForAmt, CAST(0 AS DECIMAL(19,5)) ) AS MstCrForAmt,   -- ��ȭ�뺯�ݾ�              
            ISNULL(B.DrAmt, CAST(0 AS DECIMAL(19,5)) ) - ISNULL(B.CrAmt, CAST(0 AS DECIMAL(19,5)) ) AS MstBalanceAmt,           -- ��������              
            ISNULL(B.DrForAmt, CAST(0 AS DECIMAL(19,5)) ) - ISNULL(B.CrForAmt, CAST(0 AS DECIMAL(19,5)) ) AS MstForBalanceAmt,   -- ��ȭ��������              
            A.RegAccDate,    --��ǥ��ȣ  
            A.RegDateTime,    -- ��ǥ�������  
            A.RTRegAccDate,  
            A.ApprovalDateTime,  
            A.RTSetAccDate,  
            A.UMSlipKindGroupName  
       INTO #Result_tmp            
       FROM #tmp AS A              
            LEFT JOIN (SELECT R.SlipMstSeq,              
         SUM(R.DrAmt)       AS DrAmt,              
                              SUM(R.CrAmt)       AS CrAmt,              
                              SUM(R.DrForAmt)    AS DrForAmt,              
                              SUM(R.CrForAmt)    AS CrForAmt              
      FROM _TACSlipRow AS R WITH (NOLOCK)              
                        WHERE R.CompanySeq = @CompanySeq              
                          AND EXISTS (SELECT * FROM #tmp WHERE SlipMstSeq = R.SlipMstSeq)              
                        GROUP BY SlipMstSeq              
                      ) AS B              
                   ON B.SlipMstSeq   = A.SlipMstSeq              
            LEFT JOIN _TDAEmp AS C WITH (NOLOCK)   -- ��ǥ��              
                   ON C.CompanySeq   = A.CompanySeq               
                  AND C.EmpSeq       = A.RegEmpSeq              
            LEFT JOIN _TDAEmp AS D WITH (NOLOCK)   -- ������              
                   ON D.CompanySeq   = A.CompanySeq              
                  AND D.EmpSeq       = A.AptEmpSeq              
            LEFT JOIN _TDAEmp AS E WITH (NOLOCK)   -- ������              
                   ON E.CompanySeq   = A.CompanySeq              
                  AND E.EmpSeq       = A.SetEmpSeq              
            LEFT JOIN _TDADept AS F WITH (NOLOCK)  -- ��ǥ�μ�              
                   ON F.CompanySeq   = A.CompanySeq              
                  AND F.DeptSeq      = A.RegDeptSeq              
            LEFT JOIN _TDADept AS G WITH (NOLOCK)  -- �����μ�              
                   ON G.CompanySeq   = A.CompanySeq              
                  AND G.DeptSeq      = A.AptDeptSeq              
            LEFT JOIN _TDADept AS H WITH (NOLOCK)  -- ���κμ�              
                   ON H.CompanySeq   = A.CompanySeq              
                  AND H.DeptSeq      = A.SetDeptSeq              
            LEFT JOIN _TACSlipUnit AS I WITH (NOLOCK)  -- ��ǥ��������              
                   ON I.CompanySeq   = A.CompanySeq              
                  AND I.SlipUnit     = A.SlipUnit              
             
     --================================================================================================================================                
     -- �÷� ���� ����              
     --================================================================================================================================                
     CREATE TABLE #TempTitle           
     (              
         ColIDX          INT IDENTITY(0, 1),              
         Title           NVARCHAR(100),              
         TitleSeq        INT,              
         SubColIDX       INT,              
         columnName      NVARCHAR(100)              
     )              
               
     EXEC dbo._SCOMEnv @CompanySeq, 4001, @UserSeq, @@PROCID, @RemTotalCount OUTPUT              
     SET @index = 0              
               
     EXEC @Word = _FCOMGetWord @LanguageSeq, 291, '�����׸�'              
               
     WHILE @index < @RemTotalCount              
     BEGIN              
         INSERT INTO #TempTitle (Title, TitleSeq)              
         SELECT @Word + CAST(@index + 1 AS VARCHAR),              
                @index + 1              
               
         SELECT @index = @index + 1              
     END              
               
               
     --================================================================================================================================                
     -- ���� �÷� ���� ����              
     --================================================================================================================================                
     CREATE TABLE #TempSubTitle              
     (              
         SubColIDX       INT IDENTITY(0, 1),              
         columnName      NVARCHAR(100)              
     )              
               
     INSERT INTO #TempSubTitle (columnName)              
         SELECT 'RemSeq'              
       INSERT INTO #TempSubTitle (columnName)              
         SELECT 'RemName'              
     INSERT INTO #TempSubTitle (columnName)              
         SELECT 'RemValSeq'              
     INSERT INTO #TempSubTitle (columnName)              
         SELECT 'RemValue'              
     INSERT INTO #TempSubTitle (columnName)              
         SELECT 'IsDrEss'              
     INSERT INTO #TempSubTitle (columnName)              
         SELECT 'IsCrEss'              
     INSERT INTO #TempSubTitle (columnName)              
         SELECT 'Sort'       
     INSERT INTO #TempSubTitle (columnName)              
         SELECT 'CellType'              
     INSERT INTO #TempSubTitle (columnName)              
         SELECT 'CodeHelpSeq'              
     INSERT INTO #TempSubTitle (columnName)              
         SELECT 'CodeHelpParams'              
               
               
               
 --     SELECT A.Title,              
 --            A.TitleSeq,              
 --            B.SubColIDX,              
 --            B.columnName              
 --       FROM #TempTitle AS A              
 --            CROSS JOIN #TempSubTitle AS B              
 --      ORDER BY A.ColIDX, B.SubColIDX              
               
               
     -- �ʱ�ȭ�� ��ﶧ�� �ٸ� ������ �ʿ�����Ƿ� ���� ���� 2009.01.12 by ȫ��ȭ              
     --IF ISNULL(@SlipMstSeq,0) = 0 AND ISNULL(@SlipSeq,0) = 0               
     --BEGIN     
            
     --    SELECT 0 AS RowNum FROM _TDAAccUnit WHERE 1 = 0              
     --    SELECT 0 AS RowIDX FROM _TDAAccUnit WHERE 1 = 0       
           
     --    IF ISNULL(@IsNotGW,'') = '1' OR NOT EXISTS(SELECT 1 FROM #Temp) -- ��ǥ������� ȭ�鿡�� ���þ��� ������� ��, ��� ���̺�� �ٸ��ٴ� ������ ���� �߰�  
     --    BEGIN  
     --     -- ��ǥ ��½� ������ �հ�ǥ�� ����   
     --     SELECT '' AS AccNo FROM _TDAAccUnit WHERE 1 = 0       
     --    END  
                  
     --    RETURN              
     --END              
     --ELSE              
     --BEGIN              
         --================================================================================================================================              
         -- �����÷��� ��ȸ              
         --================================================================================================================================              
         SELECT --IDENTITY(INT, 0, 1)  AS RowIDX,   
       0 AS RowIDX,    -- ������¶����� ������ǥ�� ���ü� �־ �Ʒ��� ��ȣ�� ������Ʈ�Ѵ�.    
       0 AS MaxIDX,             -- ������¶����� ������ǥ�� ���ü� �־ �Ʒ��� ��ȣ�� ������Ʈ�Ѵ�.    
                A.SlipSeq,               -- ��ǥ�ڵ�              
                A.SlipMstSeq,            -- ��ǥ�������ڵ�              
                A.SlipID,                -- ��ǥ��ǥ��ȣ              
                A.AccUnit,               -- ȸ�����              
                A.SlipUnit,              -- ��ǥ��������              
                A.AccDate,               -- ȸ����              
                A.SlipNo,                -- ��ǥ�Ϸù�ȣ              
                A.RowNo,                 -- ���ȣ              
                A.RowSlipUnit,           -- �ະ��ǥ��������              
                A.AccSeq,                -- �����ڵ�              
                A.UMCostType,            -- ��뱸��              
                A.SMDrOrCr,              -- ���뱸��              
                A.DrAmt,                 -- �����ݾ�              
                A.CrAmt,                 -- �뺯�ݾ�              
                CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN 0 ELSE A.DrForAmt END AS DrForAmt,              -- ��ȭ�����ݾ�              
                CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN 0 ELSE A.CrForAmt END AS CrForAmt,              -- ��ȭ�뺯�ݾ�              
                CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN 0 ELSE A.CurrSeq END AS CurrSeq,               -- ��ȭ�ڵ�              
                A.ExRate,                -- ȯ��              
                A.DivExRate,             -- ������ ȯ��              
                A.EvidSeq,               -- �����ڵ�              
                  0 AS TaxKindSeq,             -- ���������ڵ�              
                CAST(0 AS DECIMAL(19,5))  AS NDVATAmt,              -- �Ұ�������              
                A.CashItemSeq,           -- �����帧ǥ�����ڵ�              
                A.SMCostItemKind,        -- �����׸�����              
                A.CostItemSeq,           -- �����׸�              
                REPLACE(REPLACE(A.Summary,'<','��'),'>','��') AS Summary,           -- ����              
                A.BgtDeptSeq,            -- ����μ�              
                A.BgtCCtrSeq,            -- ����Ȱ������              
                A.BgtSeq,                -- ��������ڵ�              
                A.IsSet,                 -- ���ο���              
                B.AccName,               -- ��������              
                B.AccNo,                 -- ������ȣ              
                CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN '' ELSE ISNULL(C.CurrName, '') END      AS CurrName,            -- ��ȭ�ڵ�    
                CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN '' ELSE ISNULL(C.CurrUnit, '') END      AS CurrUnit,            -- ��ȭǥ�ô���  
       ISNULL(E.EvidName, '')       AS EvidName,            -- �����ڵ�              
     --           ISNULL(T.TaxKindName, '')    AS TaxKindName,         -- ���������ڵ�              
                ''    AS TaxKindName,         -- ���������ڵ�              
                ISNULL(CAI.CashItemName, '') AS CashItemName,        -- �����帧ǥ�����ڵ�              
                CostKind.MinorName           AS SMCostItemKindName,  -- �����׸�����              
                '' AS CostItemName,          -- �����׸�              
                ISNULL(D.DeptName, '')       AS BgtDeptName,         -- ����μ�              
                ISNULL(CC.CCtrName, '')      AS BgtCCtrName,         -- ����Ȱ������              
                ISNULL(BG.BgtName, '')       AS BgtName,             -- ��������ڵ�              
                CA.SMInOrOut,              
                CASE ISNULL(CA.SlipSeq, 0)              
                     WHEN 0 THEN '0'              
                     ELSE '1'              
                END AS IsCash,           -- �ⳳó������              
                CAO.CashDate,            -- �ⳳ������              
                CAO.SMCashMethod,        -- �ⳳ���              
                CashOff.Serl                 AS CashOffSerl,         -- �ⳳ�������� ����              
                SlipOff.OnSlipSeq            AS OnSlipSeq,              
                SlipOnRow.SlipID             AS OnSlipID,              
                B.SMDrOrCr                   AS SMAccDrOrCr,              
                B.IsAnti,              
                B.IsSlip,              
                B.IsLevel2,              
                B.IsZeroAllow,              
                B.IsEssForAmt,              
                B.SMIsEssEvid,              
                B.IsEssCost,              
                B.IsCostTrn,              
                B.SMIsUseRNP,              
                B.SMRNPMethod,              
                B.SMBgtType,              
                B.IsCash                     AS IsCashAcc,              
                B.SMCashItemKind,              
                B.IsFundSet,              
                B.IsAutoExec,              
                B.SMAccType,              
                B.SMAccKind,              
                B.OffRemSeq,              
                B.BgtRemSeq,              
                B.RemSeq1,              
                B.RemSeq2,              
                ISNULL((SELECT COUNT(*) FROM _TDAAccountCostType WHERE CompanySeq = A.CompanySeq AND AccSeq = A.AccSeq), 0)  AS CostTypeCount,              
                A.CoCustSeq                  AS CoCustSeq,    --����ȸ���ڵ�              
                CoCust.CustName              AS CoCustName,    --����ȸ��              
                Cao.SMCashMethodName  ,   
                CAST(0 AS DECIMAL(19,5)) AS SumDrAmt,    
                CAST(0 AS DECIMAL(19,5)) AS SumCrAmt,    
                  CAST(0 AS DECIMAL(19,5)) AS DrSumFirstFage, -- �ϴ�0 �ٷξƷ���update�Ѵ�.    
                CAST(0 AS DECIMAL(19,5)) AS CrSumFirstFage, -- �ϴ�0 �ٷξƷ���update�Ѵ�.    
       '' AS IsOnlyOnPage, -- �ϴ� '' �ٷ� �Ʒ��� update�Ѵ�.  
                CASE WHEN Rem.RemSeq = 1017 THEN Rem.RemValSeq ELSE 0 END AS CustSeq, -- �ŷ�ó�ڵ�  , �ⳳ������ �ŷ�ó�� ������ �ŷ�ó ������ �ޱ� ���� �߰���.  
                CASE WHEN B.SMAccType = 4002012 AND SlipOff.OnSlipSeq <> 0 THEN  
                     ISNULL(SUnit.AccUnitName , '') ELSE '' END AS S_AccUnitName, -- �����������̸鼭 ������ǥ(������ǥ�� �ִ� ���)���, �����׸��� ȸ������� �����ֵ��� ����  
                CAST ('' AS NVARCHAR(200)) AS TopUserName,  
                CASE WHEN CA.SlipSeq <> 0 AND ISNULL(ERem.RemSeq, 0) > 0 THEN ERem.RemValSeq ELSE 0 END AS EmpSeq -- ����ڵ�, �ⳳ������ ����� �ִ� ����� ó���� ����  
           INTO #TempFixedCol              
           FROM _TACSlipRow AS A WITH (NOLOCK)              
                LEFT JOIN _TDAAccount AS B WITH (NOLOCK)              
                   ON B.CompanySeq   = A.CompanySeq              
                      AND B.AccSeq       = A.AccSeq              
                LEFT JOIN _TDACurr AS C WITH (NOLOCK)              
                       ON C.CompanySeq   = A.CompanySeq              
                      AND C.CurrSeq      = A.CurrSeq              
                LEFT JOIN _TDAEvid AS E WITH (NOLOCK)              
                       ON E.CompanySeq   = A.CompanySeq              
                      AND E.EvidSeq      = A.EvidSeq              
     --           LEFT JOIN _TDATaxKind AS T WITH (NOLOCK)              
     --                  ON T.CompanySeq   = A.CompanySeq              
     --                 AND T.TaxKindSeq   = A.TaxKindSeq              
                LEFT JOIN _TACDCashItem AS CAI WITH (NOLOCK)              
                       ON CAI.CompanySeq  = A.CompanySeq              
                      AND CAI.CashItemSeq = A.CashItemSeq              
                LEFT JOIN _TACBgtItem AS BG WITH (NOLOCK)              
                       ON BG.CompanySeq  = A.CompanySeq              
                      AND BG.BgtSeq      = A.BgtSeq              
                LEFT JOIN _TDADept AS D WITH (NOLOCK)              
                       ON D.CompanySeq   = A.CompanySeq              
                      AND D.DeptSeq      = A.BgtDeptSeq              
                LEFT JOIN _TDACCtr AS CC WITH (NOLOCK)              
                       ON CC.CompanySeq  = A.CompanySeq              
                      AND CC.CCtrSeq     = A.BgtCCtrSeq              
                LEFT JOIN #tempCash AS CA WITH (NOLOCK)              
                       ON CA.CompanySeq  = A.CompanySeq              
                      AND CA.SlipSeq     = A.SlipSeq               
                LEFT JOIN _TACSlipRem AS ERem WITH (NOLOCK)              
                       ON ERem.CompanySeq  = A.CompanySeq              
                      AND ERem.SlipSeq     = A.SlipSeq  
                      AND ERem.RemSeq      = 1002  
                LEFT JOIN _TDASMinor AS CostKind WITH (NOLOCK)              
                       ON CostKind.CompanySeq    = A.CompanySeq              
                      AND CostKind.MinorSeq      = A.SMCostItemKind              
                      AND CostKind.MajorSeq      = 5508 -- �����׸� ����              
                LEFT JOIN (  
                         SELECT A.SlipSeq, A.CashDate, A.SMCashMethod, SM1.MinorName AS SMCashMethodName      
                           FROM #tempCash AS A JOIN (  
                                                     SELECT CAO.SlipSeq, MIN(CAO.Serl) AS Serl   
                                                       FROM #tempCash AS CAO WITH (NOLOCK)          
                                                           INNER JOIN _TACSlipRow AS ROW WITH (NOLOCK)          
                                                                   ON ROW.CompanySeq = CAO.CompanySeq          
                                                                  AND ROW.SlipSeq    = CAO.SlipSeq          
                                --AND ((@SlipSeq = 0 AND @SlipMstSeq <> 0) OR ROW.SlipSeq = @SlipSeq)          
                                                                 --AND ((@SlipMstSeq = 0 AND @SlipSeq <> 0) OR ROW.SlipMstSeq = @SlipMstSeq)          
                                                                   AND (ROW.SlipMstSeq IN (SELECT SlipMstSeq FROM #Temp) )          
                                                      WHERE CAO.CompanySeq = @CompanySeq   
                                                      GROUP BY CAO.SlipSeq) AS B ON A.SlipSeq = B.SlipSeq AND A.Serl = B.Serl  
                                               LEFT JOIN _TDAUMinor AS SM1        
                     ON A.CompanySeq      = SM1.CompanySeq      
                                                     AND A.SMCashMethod    = SM1.MinorSeq      
                                                     AND SM1.MajorSeq        = 4008   
                           WHERE A.CompanySeq = @CompanySeq             
                          ) AS CAO ON CAO.SlipSeq = A.SlipSeq              
                LEFT JOIN _TACSlipOff AS SlipOff WITH (NOLOCK)              
                       ON SlipOff.CompanySeq = A.CompanySeq              
                      AND SlipOff.SlipSeq    = A.SlipSeq              
            LEFT JOIN #tempCashOff AS CashOff WITH (NOLOCK)              
                       ON CashOff.CompanySeq = A.CompanySeq              
                      AND CashOff.OffSlipSeq = A.SlipSeq              
                LEFT JOIN _TACSlipRow AS SlipOnRow WITH (NOLOCK)              
                       ON SlipOnRow.CompanySeq   = SlipOff.CompanySeq              
                      AND SlipOnRow.SlipSeq      = SlipOff.OnSlipSeq              
                LEFT JOIN _TDACust AS CoCust WITH (NOLOCK)       -- ����ȸ��              
                       ON CoCust.CompanySeq   = A.CompanySeq              
                      AND CoCust.CustSeq      = A.CoCustSeq  
 --               LEFT OUTER JOIN _TACSlipRem AS UnitRem  
 --                      ON A.CompanySeq       = UnitRem.CompanySeq  
 --                     AND A.SlipSeq          = UnitRem.SlipSeq  
 --                     AND UnitRem.RemSeq     = 1031 -- ȸ�����  
                LEFT OUTER JOIN _TDAAccUnit AS SUnit  
                       ON A.CompanySeq       = SUnit.CompanySeq  
                      AND SlipOnRow.AccUnit  = SUnit.AccUnit  
                --LEFT OUTER JOIN _TCOMGroupWare AS GW ON A.CompanySeq = GW.CompanySeq AND GW.WorkKind = 'Slip' AND A.SlipMstSeq = GW.TblKey  
                LEFT OUTER JOIN _TACSlipRem AS Rem WITH(NOLOCK)   
                       ON A.CompanySeq       = Rem.CompanySeq   
                      AND CA.SlipSeq         = Rem.SlipSeq  
                      AND Rem.RemSeq         = 1017          --�ŷ�ó  
          WHERE A.CompanySeq     = @CompanySeq     
            AND A.SlipMstSeq     IN (SELECT SlipMstSeq FROM #Temp)           
 --           AND ((@SlipSeq       = 0 AND @SlipMstSeq <> 0) OR A.SlipSeq = @SlipSeq)              
 --           AND ((@SlipMstSeq    = 0 AND @SlipSeq    <> 0) OR A.SlipMstSeq = @SlipMstSeq)              
          ORDER BY A.RowNo              
      --JOIN ���� �ʰ� ���� update�ϴ°��� �ӵ��鿡�� �ξ� ����  
     UPDATE A  
        SET A.TopUserName = B.TopUserName  
       FROM #TempFixedCol AS A JOIN _TCOMGroupWare AS B ON B.CompanySeq = @CompanySeq  
                                                       AND B.WorkKind    = 'Slip'  
                                                       AND A.SlipMstSeq = B.TblKey  
    
        
     -- �Ǻ����� �����̳�, �ⳳ���� �� [������ǥ]�� ��쿡��, CustSeq, EmpSeq�� ���� �־�,  
     -- �ŷ�ó ���Ұ��³�, ��� �ְ��������� ��¹��� ������ �� �ֵ��� ������.  
     UPDATE A  
        SET CustSeq  = ISNULL(C.RemValSeq, 0)  
       FROM #TempFixedCol AS A JOIN _TACSlipRow AS B  
                                 ON B.CompanySeq = @CompanySeq  
                                AND A.OnSlipSeq  = B.SlipSeq  
                               JOIN _TACSlipRem AS C  
                                   ON C.CompanySeq = @CompanySeq  
                                AND A.OnSlipSeq  = C.SlipSeq  
                                AND C.RemSeq     = 1017 ------ �ŷ�ó �����׸�  
      WHERE A.CustSeq    = 0  
        AND ISNULL(A.OnSlipSeq, 0) <> 0  
    
     UPDATE A  
        SET EmpSeq = ISNULL(C.RemValSeq, 0)  
       FROM #TempFixedCol AS A JOIN _TACSlipRow AS B  
                                 ON B.CompanySeq = @CompanySeq  
                                AND A.OnSlipSeq  = B.SlipSeq  
                               JOIN _TACSlipRem AS C  
                                 ON C.CompanySeq = @CompanySeq  
                                AND A.OnSlipSeq  = C.SlipSeq  
                                AND C.RemSeq     = 1002 ------ ��� �����׸�  
      WHERE A.CustSeq    = 0  
        AND ISNULL(A.OnSlipSeq, 0) <> 0  
        
      --================================================================================================================================              
     -- �����׸���ȸ        
     --================================================================================================================================            
      CREATE TABLE #tmp_SlipCostItemName  
     (ID_Count       INT IDENTITY(1,1),  
      SMCostItemKind INT, --�����׸񱸺�  
      CostItemSeq    INT, --�����׸��ڵ�  
      CostItemName   NVARCHAR(400), --�����׸�  
      SlipSeq        INT  
     )  
    
     INSERT INTO #tmp_SlipCostItemName(SMCostItemKind, CostItemSeq, SlipSeq)  
     SELECT SMCostItemKind, CostItemSeq, SlipSeq FROM #TempFixedCol WHERE SMCostItemKind > 0   
     EXEC _SESMBGetCostIemNameData @CompanySeq, @LanguageSeq,149, '#tmp_SlipCostItemName','CostItemName'  
     --================================================================================================================================              
     -- �����׸���ȸ��      
     --================================================================================================================================           
                 
         SELECT A.SlipSeq,              
                A.CostDeptSeq,              
                A.CostCCtrSeq,              
                CASE              
                     WHEN X.Cnt > 1 THEN D.DeptName + '��' + CAST(X.Cnt AS NVARCHAR)              
                     ELSE D.DeptName              
                END          AS CostDeptName,              
                C.CCtrName   AS CostCCtrName,              
                X.Cnt        AS SlipCostCnt              
           INTO #tmp2              
           FROM _TACSlipCost AS A              
                INNER JOIN (              
                             SELECT A.SlipSeq, MIN(A.Serl) AS Serl, COUNT(*) AS Cnt              
                               FROM _TACSlipCost AS A              
                              WHERE A.CompanySeq = @CompanySeq              
                                AND EXISTS (SELECT * FROM #TempFixedCol WHERE SlipSeq = A.SlipSeq)              
                              GROUP BY A.SlipSeq              
                           ) AS X              
                        ON X.SlipSeq = A.SlipSeq                            AND X.Serl = A.Serl              
                LEFT JOIN _TDACCtr AS C WITH(NOLOCK)              
                       ON C.CompanySeq   = A.CompanySeq              
                      AND C.CCtrSeq      = A.CostCCtrSeq              
                LEFT JOIN _TDADept AS D WITH(NOLOCK)              
                       ON D.CompanySeq   = A.CompanySeq              
                      AND D.DeptSeq      = A.CostDeptSeq              
          WHERE A.CompanySeq = @CompanySeq              
                   
                   
    
             
         --================================================================================================================================                
         -- �����÷��� ��ȸ(�����׸�)              
           --================================================================================================================================              
         -- �ڵ������� ��Ī�� �������� ���� �ӽ����̺� ����              
         CREATE TABLE #tmp_SlipRemValue              
         (              
             SlipSeq         INT,              
             RemSeq          INT,              
             --RemName         NVARCHAR(100),              
             Seq             INT,              
             RemValText      NVARCHAR(100),              
             CellType        NVARCHAR(50),              
             IsDrEss         NCHAR(1),              
             IsCrEss         NCHAR(1),              
             Sort            INT,  
             CustNo          NVARCHAR(200) --�ŷ�ó��ȣ            
         )              
                   
         -- �ӽ����̺� ��Ī�� �������� ���� Ű���� �־��ְ�              
         INSERT INTO #tmp_SlipRemValue        
             SELECT A.SlipSeq,              
                    B.RemSeq,              
                    --D.RemName,              
                    B.RemValSeq,              
                    B.RemValText,              
                    CASE D.SMInputType              
                         WHEN 4016001 THEN 'enText'              
                         WHEN 4016002 THEN 'enCodeHelp'              
                         WHEN 4016003 THEN 'enFloat'              
                         WHEN 4016004 THEN 'enFloat'              
                         WHEN 4016005 THEN 'enDate'              
                         WHEN 4016006 THEN 'enText'              
                         WHEN 4016007 THEN 'enFloat'              
 ELSE 'enText'              
                    END AS CellType,       -- �Է�����              
                    C.IsDrEss,              
                    C.IsCrEss,              
                    C.Sort,   
                    ''              
               FROM #TempFixedCol AS A              
                    INNER JOIN _TACSlipRem AS B WITH (NOLOCK)              
                            ON B.CompanySeq  = @CompanySeq              
                           AND B.SlipSeq     = A.SlipSeq              
                    INNER JOIN _TDAAccountSub AS C WITH (NOLOCK)              
                            ON C.CompanySeq  = B.CompanySeq              
                           AND C.AccSeq      = A.AccSeq              
                           AND C.RemSeq      = B.RemSeq   
 --                          AND C.IsRpt       = '1'     -- ��¿� üũ�Ȱ͸�         
                    INNER JOIN _TDAAccountRem AS D WITH (NOLOCK)              
                            ON D.CompanySeq  = B.CompanySeq              
                           AND D.RemSeq      = B.RemSeq              
                                 
         -- ��Ī�� �����´�.              
         -- ���� �Ŀ��� ValueName �÷��� �ڵ������Ǿ� ����.              
       
         EXEC _SUTACGetSlipRemData @CompanySeq, @LanguageSeq, '#tmp_SlipRemValue'     
    
     -- ��¥������ �����׸� - ���̱�  
     --UPDATE #tmp_SlipRemValue  
     --   SET RemValue = CASE WHEN LEN(RTRIM(LTRIM(RemValue))) = 8 THEN   
     --                            LEFT(RemValue, 4) + '-' + SUBSTRING(RemValue, 5,2) + '-' + RIGHT(RemValue, 2)  
     --                       WHEN LEN(RTRIM(LTRIM(RemValue))) = 6 THEN   
     --                            LEFT(RemValue, 4) + '-' + RIGHT(RemValue, 2)  
     --                       ELSE RemValue END  
     -- WHERE CellType = 'enDate'  
    
     UPDATE #tmp_SlipRemValue  
        SET RemValue = LEFT(RemValue, 8) + '-' + RIGHT(RemValue, 8)  
      WHERE RemSeq = 3013    
        AND LEN(RemValue) = 16    
      -- �ΰ��������� "���ް���" �ݾ� ","���̴� FUNCTION��� (_fnCOMCurrency)  
     -- ���������׸���(�ý���) ȭ�鿡�� ���ڷ� ��ϵ� �����׸񿡵� "," ���̴� FUNCTION ��� (3120:�ΰ���(����ī��), 3108:�Ұ�����, 3125:����(����ī��))  
     UPDATE #tmp_SlipRemValue  
        SET RemValue     = dbo._fnCOMCurrency(RemValText,@KORDecimal)  
      WHERE RemSeq IN (3009, 3120, 3108, 3125) -- ���ް���, �ΰ���(����ī��), �Ұ�����, ����(����ī��)  
      -- ����ڹ�ȣ ���� ȯ�漳������ ��������  
    SELECT @EnvValue = EnvValue       
      FROM _TCOMEnv WITH(NOLOCK)      
       WHERE CompanySeq = @CompanySeq      
       AND EnvSeq = 17      
     IF @@ROWCOUNT = 0 OR ISNULL(@EnvValue, '') = ''  
     SELECT @EnvValue = ''  
    
     -- �ֹε�Ϲ�ȣ ���� ȯ�漳������ ��������  
    SELECT @PersonId = EnvValue       
      FROM _TCOMEnv WITH(NOLOCK)      
     WHERE CompanySeq = @CompanySeq      
       AND EnvSeq = 16  
     IF @@ROWCOUNT = 0 OR ISNULL(@PersonId, '') = ''  
     SELECT @PersonId = ''  
    
    
 --    UPDATE #tmp_SlipRemValue      
 --       SET RemRefValue = REPLACE(RemRefValue, '-', '')      
 --      FROM #tmp_SlipRemValue AS A      
 --                    JOIN _TCACodeHelpData AS B ON A.CodeHelpSeq = B.CodeHelpSeq      
 --     WHERE B.CompanySeq = 0      
 --       AND B.RefColumnName IN ('BizNo', 'TaxNo')      
 --  
 --    UPDATE #tmp_SlipRemValue      
 --       SET RemRefValue = LEFT(RemRefValue, 3) + '-' + SUBSTRING(RemRefValue, 4, 2) + '-' + SUBSTRING(RemRefValue, 6, 5)      
 --      FROM #tmp_SlipRemValue AS A      
 --                JOIN _TCACodeHelpData AS B ON A.CodeHelpSeq = B.CodeHelpSeq      
 --     WHERE B.CompanySeq = 0      
 --       AND B.RefColumnName IN ('BizNo', 'TaxNo')      
 --       AND ISNULL(A.RemRefValue, '') <> ''      
        
     UPDATE A  
        SET A.CustNo = ISNULL(RTRIM(LTRIM(C.CustNo)),'')  
       FROM #tmp_SlipRemValue AS A JOIN _TACSlipRow AS B ON B.CompanySeq = @CompanySeq  
                                                        AND A.SlipSeq    = B.SlipSeq  
                                   LEFT OUTER JOIN _TDACust   AS C ON C.CompanySeq    = @CompanySeq  
                                                                  AND C.CustSeq       = A.Seq                                                                  
      WHERE A.RemSeq = 1017      
     --�ƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢ�  
     --------------------------------------------------------------------------------------------------------------------------------------------  
     -- #tmp_SlipRemValue �� RemValue �� �����׸� ����ڹ�ȣ (1013), �ŷ�ó(1017) �� ��쿣 �̷¿� ���� ��Ī�� �����ü� �ֵ��� �Ѵ�. ����  
     --------------------------------------------------------------------------------------------------------------------------------------------  
     --�ƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢ�  
      IF EXISTS ( SELECT 1 FROM #tmp_SlipRemValue WHERE RemSeq   = 1013)  
     BEGIN   
         UPDATE A  
            SET A.RemValue       = CASE WHEN ISNULL(C.TaxNoAlias,'') = '' THEN A.RemValue ELSE C.TaxNoAlias END,  
                A.RemRefValue    = CASE WHEN ISNULL(C.TaxNo,'') = '' THEN A.RemRefValue ELSE C.TaxNo END  
           FROM #tmp_SlipRemValue AS A JOIN _TACSlipRow AS B ON B.CompanySeq = @CompanySeq  
                                                            AND A.SlipSeq    = B.SlipSeq  
                                       LEFT OUTER JOIN _TDATaxUnitHist   AS C ON C.CompanySeq    = @CompanySeq  
                                                                             AND C.TaxUnit       = A.Seq  
                                                                             AND B.AccDate       BETWEEN C.FrDate AND C.ToDate         
          WHERE A.RemSeq = 1013  
     END  
      
     IF EXISTS ( SELECT 1 FROM #tmp_SlipRemValue WHERE RemSeq   = 1017)  
     BEGIN  
         UPDATE A  
            SET A.RemValue   = CASE WHEN ISNULL(C.FullName,'') = '' THEN A.RemValue ELSE C.FullName END,  
                A.RemRefValue    = CASE WHEN ISNULL(C.BizNo,'') = '' THEN A.RemRefValue ELSE C.BizNo END  
           FROM #tmp_SlipRemValue AS A JOIN _TACSlipRow AS B ON B.CompanySeq = @CompanySeq  
                                                            AND A.SlipSeq    = B.SlipSeq  
                                       LEFT OUTER JOIN _TDACustTaxHist   AS C ON C.CompanySeq    = @CompanySeq  
                                                                             AND C.CustSeq       = A.Seq  
                                                                               AND B.AccDate       BETWEEN ISNULL(C.FrDate,'') AND ISNULL(C.ToDate,'29991231')                                                                    
          WHERE A.RemSeq = 1017      
     END   
       
     -- ����ڹ�ȣ�� '-' �ֱ�  
     UPDATE #tmp_SlipRemValue      
        SET RemRefValue = dbo._FCOMMaskConv(@EnvValue,RemRefValue)  
       FROM #tmp_SlipRemValue AS A      
                 JOIN _TCACodeHelpData AS B ON A.CodeHelpSeq = B.CodeHelpSeq      
      WHERE B.CompanySeq = 0      
        AND B.RefColumnName IN ('BizNo', 'TaxNo')      
        AND ISNULL(A.RemRefValue, '') <> ''      
      -- ȯ�漳���� '��ǥ ��½� ���ΰŷ�ó�� �ֹε�Ϲ�ȣ �����'�� üũ �Ǿ� �ִ� ��쿡�� �ֹι�ȣ ��������.    
     IF EXISTS (select * From _TCOMEnv where CompanySeq = @CompanySeq AND EnvSeq = 4705 AND EnvValue = '1')    
     BEGIN    
         -- ����ڹ�ȣ�� ���ٸ� �ֹι�ȣ ��������    
         IF EXISTS (SELECT RemRefValue FROM #tmp_SlipRemValue WHERE RemSeq = 1017 AND RemRefValue = '')         
   BEGIN    
     UPDATE #tmp_SlipRemValue    
                SET RemRefValue = dbo._FCOMMASKConv(@PersonId, dbo._FCOMDecrypt(B.PersonId, '_TDACust', 'PersonId', @CompanySeq))    
               FROM #tmp_SlipRemValue AS A JOIN _TDACust AS B ON A.Seq = B.CustSeq    
              WHERE B.CompanySeq = @CompanySeq    
                AND A.RemSeq = 1017      -- �ŷ�ó  
       AND A.RemRefValue = '' -- ����ڹ�ȣ�� �������� �ʴ� ��  
          END    
     END    
    
            
     --�ƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢ�  
     --------------------------------------------------------------------------------------------------------------------------------------------  
     -- #tmp_SlipRemValue �� RemValue �� �����׸� ����ڹ�ȣ (1013), �ŷ�ó(1017) �� ��쿣 �̷¿� ���� ��Ī�� �����ü� �ֵ��� �Ѵ�. ��  
     --------------------------------------------------------------------------------------------------------------------------------------------  
     --�ƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢƢ�     
    
       
      SELECT @CurrDate = CONVERT(NCHAR(8), GETDATE(), 112)    
      -- ������ ���� ���� ó�� ����  
      SELECT @MaxCnt      = COUNT(*) FROM #Temp  
     SELECT @Cnt         = 0  
      WHILE (@Cnt < @MaxCnt)            
     BEGIN  
    SELECT @SlipMstSeq = SlipMstSeq FROM #Temp WHERE Cnt = @Cnt  
     UPDATE A  
       SET A.RowIDX = B.RowIDX  
        FROM #TempFixedCol AS A JOIN (SELECT ROW_NUMBER() OVER(ORDER BY RowIDX)-1 AS RowIDX, SlipMstSeq, SlipSeq  
             FROM  #TempFixedCol  
            WHERE SlipMstSeq = @SlipMstSeq) AS B ON A.SlipMstSeq = B.SlipMstSeq  
                     AND A.SlipSeq  = B.SlipSeq  
     
        
    UPDATE A  
          SET A.SumDrAmt = B.SumDrAmt,  
        A.SumCrAmt = B.SumCrAmt,  
        A.MaxIDX   = B.MaxIDX  
         FROM #TempFixedCol AS A JOIN (SELECT SUM(DrAmt) AS SumDrAmt,   
                SUM(CrAMt) AS SumCrAmt,   
                MAX(RowIDX) AS MaxIDX,  
                SlipMstSeq  
                 FROM #TempFixedCol  
                WHERE SlipMstSeq = @SlipMstSeq  
                GROUP BY SlipMstSeq) AS B ON A.SlipMstSeq = B.SlipMstSeq  
    
    UPDATE A  
          SET A.DrSumFirstFage = B.DrSumFirstFage,  
        A.CrSumFirstFage = B.CrSumFirstFage  
         FROM #TempFixedCol AS A JOIN (SELECT SUM(DrAmt) AS DrSumFirstFage,   
                SUM(CrAMt) AS CrSumFirstFage,  
                SlipMstSeq  
                 FROM  #TempFixedCol  
                WHERE SlipMstSeq = @SlipMstSeq  
                AND CONVERT(INT, RIGHT(RTRIM(RowNo), 2)) < 10  
                GROUP BY SlipMstSeq) AS B ON A.SlipMstSeq = B.SlipMstSeq  
        
    UPDATE A  
          SET A.IsOnlyOnPage = CASE WHEN B.TotCnt < 10 THEN '1' ELSE '0' END  
         FROM #TempFixedCol AS A JOIN (SELECT COUNT(*) AS TotCnt,  
                 SlipMstSeq  
                 FROM  #TempFixedCol  
                WHERE SlipMstSeq = @SlipMstSeq  
                GROUP BY SlipMstSeq  
                ) AS B ON A.SlipMstSeq = B.SlipMstSeq       
       
    SELECT @Cnt = @Cnt + 1  
     END   
      -- ������ ���� ���� ó�� ��  
          SELECT A.MaxIDX,      
                  A.RowIDX,      
                LEFT(RIGHT(MstSlip.AccDate, 4),2) +'/'+ RIGHT(RIGHT(MstSlip.AccDate, 4),2) AS AccDate,   
                MstSlip.AccDate  AS OrgAccDate,       
                @CurrDate AS CurrDate,      
 --                   MstSlip.*,    
                ISNULL(MstSlip.RegDeptName,'') AS RegDeptName,      
                ISNULL(MstSlip.RegEmpName,'') AS RegEmpName,            
                ISNULL(MstSlip.SetSlipNo,'') AS SetSlipNo,         
                A.SlipMstSeq,  
                ISNULL(MstSlip.SlipKind, 0) AS SlipKind,      
                ISNULL(MstSlip.SlipKindName, '') AS SlipKindName,      
                ISNULL(MstSlip.RegEmpSeq,0) AS RegEmpSeq,      
                ISNULL(MstSlip.RegDeptSeq,0) AS RegDeptSeq,      
 --               MstSlip.Remark,      
                ISNULL(REPLACE(REPLACE(MstSlip.Remark,'<','��'),'>','��'),'') AS Remark,           -- ����              
                ISNULL(MstSlip.SMCurrStatus,0) AS SMCurrStatus,      
       ISNULL(MstSlip.AptDate,'')   AS AptDate,      
                ISNULL(MstSlip.AptEmpSeq,0) AS AptEmpSeq,      
                ISNULL(MstSlip.AptDeptSeq,0) AS AptDeptSeq,      
                ISNULL(MstSlip.AptRemark,'') AS AptRemark,      
                ISNULL(MstSlip.SMCheckStatus,0) AS SMCheckStatus,      
                ISNULL(MstSlip.CheckOrigin,'') AS CheckOrigin,    
                ISNULL(MstSlip.SetEmpSeq,0)  AS SetEmpSeq,     
                ISNULL(MstSlip.SetDeptSeq,0) AS SetDeptSeq,      
                ISNULL(MstSlip.SlipUnitName,'') AS SlipUnitName,    
                ISNULL(MstSlip.SlipAppNo,'') AS SlipAppNo,  
                ISNULL(MstSlip.SlipMstID,'') AS SlipMstID,  
                CASE WHEN MstSlip.IsSet = '1' THEN MstSlip.AccDate ELSE '' END  AS AccDateFull,    -- ������  
                A.RowIDX + 1 AS RowNum,              
                A.SlipSeq,               -- ��ǥ�ڵ�              
 --                A.SlipMstSeq,            -- ��ǥ�������ڵ�              
                A.SlipID,                -- ��ǥ��ǥ��ȣ              
                A.AccUnit,               -- ȸ�����           
                ISNULL(Acc.AccUnitName,'') AS AccUnitName,           
                A.SlipUnit,              -- ��ǥ��������              
                A.SlipNo,                -- ��ǥ�Ϸù�ȣ              
                A.RowNo,                 -- ���ȣ              
                A.RowSlipUnit,           -- �ະ��ǥ��������              
                A.AccSeq,                -- �����ڵ�              
                A.UMCostType,            -- ��뱸��              
                A.SMDrOrCr,              -- ���뱸��              
                A.DrAmt,                 -- �����ݾ�              
                A.CrAmt,                 -- �뺯�ݾ�              
                A.DrForAmt,              -- ��ȭ�����ݾ�              
                A.CrForAmt,           -- ��ȭ�뺯�ݾ�              
                A.CurrSeq,               -- ��ȭ�ڵ�              
                A.ExRate,    -- ȯ��              
                A.DivExRate,             -- ������ ȯ��              
                A.EvidSeq,               -- �����ڵ�              
                A.TaxKindSeq,            -- ���������ڵ�              
                A.NDVATAmt,              -- �Ұ�������              
                A.CashItemSeq,           -- �����帧ǥ�����ڵ�              
                ISNULL(L.SMCostItemKind,0) AS SMCostItemKind,        -- �����׸�����              
                ISNULL(L.CostItemSeq,0) AS CostItemSeq,           -- �����׸�              
                A.Summary,               -- ����              
                ISNULL(A.BgtDeptSeq,0) AS BgtDeptSeq,            -- ����μ�              
                ISNULL(A.BgtCCtrSeq,0) AS BgtCCtrSeq,            -- ����Ȱ������              
                ISNULL(A.BgtSeq,0) AS BgtSeq,                -- ��������ڵ�              
                ISNULL(A.IsSet,'') AS IsSet,                 -- ���ο���              
                ISNULL(A.AccName,'') AS AccName,        -- ��������              
                  ISNULL(A.AccNo, '') AS AccNo,                 -- ������ȣ               
                ISNULL(A.CurrName,'') AS CurrName,              -- ��ȭ�ڵ�       
                ISNULL(A.CurrUnit,'') AS CurrUnit,              -- ��ȭǥ�ô���           
                ISNULL(A.EvidName, '') AS EvidName,              -- �����ڵ�              
                ISNULL(A.TaxKindName,'') AS TaxKindName,           -- ���������ڵ�              
                ISNULL(A.CashItemName,'') AS CashItemName,         -- �����帧ǥ�����ڵ�              
                ISNULL(A.SMCostItemKindName,'') AS SMCostItemKindName,    -- �����׸�����              
                ISNULL(L.CostItemName, '') AS CostItemName,          -- �����׸�              
                A.BgtDeptName,   -- ����μ�              
                A.BgtCCtrName,  -- ����Ȱ������              
                A.BgtName,               -- ��������ڵ�              
                ISNULL(A.SMInOrOut,0) AS SMInOrOut,              
                ISNULL(A.IsCash,'') AS IsCash,           -- �ⳳó������              
                ISNULL(A.CashDate,'') AS CashDate,            -- �ⳳ������              
                ISNULL(A.SMCashMethod,0) AS SMCashMethod,        -- �ⳳ���              
                ISNULL(A.CashOffSerl,0) AS CashOffSerl,              
                ISNULL(A.OnSlipSeq,0) AS OnSlipSeq,              
                ISNULL(A.OnSlipID,'') AS OnSlipID,              
                A.SMAccDrOrCr,              
                A.IsAnti,              
                A.IsSlip,              
                A.IsLevel2,              
                A.IsZeroAllow,              
                A.IsEssForAmt,              
                A.SMIsEssEvid,              
                A.IsEssCost,              
                A.IsCostTrn,              
                A.SMIsUseRNP,              
                A.SMRNPMethod,              
                A.SMBgtType,              
                A.IsCashAcc,              
                A.SMCashItemKind,              
                A.IsFundSet,              
                A.IsAutoExec,              
                A.SMAccType,              
                A.SMAccKind,              
                A.OffRemSeq,              
                A.BgtRemSeq,              
                A.RemSeq1,              
                A.RemSeq2,              
                A.CostTypeCount,              
                ISNULL(X.LinkedKeyXMLData,'') AS LinkedKeyXMLData,              
                ISNULL(C.MinorName,'')  AS UMCostTypeName,              
                (              
                    SELECT *              
                     FROM _TACSlipCost              
                     WHERE CompanySeq    = @CompanySeq               
                       AND SlipSeq       = A.SlipSeq           
                       FOR XML AUTO, ELEMENTS              
                ) AS SlipCostXmlData,              
                ISNULL(B.CostDeptName,'') AS CostDeptName,  
                ISNULL(REPLACE(REPLACE(B.CostCCtrName,'<','��'),'>','��'),'') AS CostCCtrName,  
                B.CostDeptSeq,              
                B.CostCCtrSeq,              
                B.SlipCostCnt,              
                A.CoCustSeq,              
                ISNULL(A.CoCustName,'') AS CoCustName,  
                G.RemValue,  
                -- �ŷ�ó �����׸��� ��� (����ڹ�ȣ)�� ��µ� �� �ֵ���..      
                ISNULL(CASE WHEN D.RemSeq IN (1017, 1013) THEN RTRIM(D.RemValue) + (CASE WHEN ISNULL(D.RemRefValue, '') = '' THEN ''       
                                                                         ELSE ' (' + RTRIM(D.RemRefValue) + ')' END)       
                     ELSE ISNULL(D.RemValue,'') END,'') AS RemValue1,          
                ISNULL(CASE WHEN E.RemSeq IN (1017, 1013) THEN RTRIM(E.RemValue) + (CASE WHEN ISNULL(E.RemRefValue, '') = '' THEN ''       
                                                                         ELSE ' (' + RTRIM(E.RemRefValue) + ')' END)           
                     ELSE ISNULL(E.RemValue,'') END,'') AS RemValue2,          
                  ISNULL(CASE WHEN F.RemSeq IN (1017, 1013) THEN RTRIM(F.RemValue) + (CASE WHEN ISNULL(F.RemRefValue, '') = '' THEN ''       
                                                                         ELSE ' (' + RTRIM(F.RemRefValue) + ')' END)       
                     ELSE ISNULL(F.RemValue,'') END,'') AS RemValue3,          
                ISNULL(CASE WHEN G.RemSeq IN (1017, 1013) THEN RTRIM(G.RemValue) + (CASE WHEN ISNULL(G.RemRefValue, '') = '' THEN ''       
                                                                         ELSE ' (' + RTRIM(G.RemRefValue) + ')' END)       
                     ELSE ISNULL(G.RemValue,'') END,'') AS RemValue4,       
                ISNULL(CASE WHEN H.RemSeq IN (1017, 1013) THEN RTRIM(H.RemValue) + (CASE WHEN ISNULL(H.RemRefValue, '') = '' THEN ''       
                                                                         ELSE ' (' + RTRIM(H.RemRefValue) + ')' END)       
                     ELSE ISNULL(H.RemValue,'') END,'') AS RemValue5,      
                ISNULL(CASE WHEN I.RemSeq IN (1017, 1013) THEN RTRIM(I.RemValue) + (CASE WHEN ISNULL(I.RemRefValue, '') = '' THEN ''       
                                                                         ELSE ' (' + RTRIM(I.RemRefValue) + ')' END)       
                     ELSE ISNULL(I.RemValue,'') END,'') AS RemValue6,      
                ISNULL(CASE WHEN J.RemSeq IN (1017, 1013) THEN RTRIM(J.RemValue) + (CASE WHEN ISNULL(J.RemRefValue, '') = '' THEN ''       
                                                                         ELSE ' (' + RTRIM(J.RemRefValue) + ')' END)      
                     ELSE ISNULL(J.RemValue,'') END,'') AS RemValue7,      
                ISNULL(CASE WHEN K.RemSeq IN (1017, 1013) THEN RTRIM(K.RemValue) + (CASE WHEN ISNULL(K.RemRefValue, '') = '' THEN ''       
                                                                         ELSE ' (' + RTRIM(K.RemRefValue) + ')' END)      
                     ELSE ISNULL(K.RemValue,'') END,'') AS RemValue8,    
                 ISNULL(D.RemName,'') AS RemName1,    
                 ISNULL(E.RemName,'') AS RemName2,  
                 ISNULL(F.RemName,'') AS RemName3,  
                 ISNULL(G.RemName,'') AS RemName4,  
                 ISNULL(H.RemName,'') AS  RemName5,  
                 ISNULL(I.RemName,'') AS RemName6,  
                 ISNULL(J.RemName,'') AS RemName7,  
                 ISNULL(K.RemName,'') AS RemName8,  
             CASE WHEN ISNULL(Bank.BankAccNo,'') = ''   
                     THEN (ISNULL(C3.PayBankName, '') + ' ' + CASE WHEN ISNULL(EmpBank.AccNo, '') = '' THEN '' ELSE '(' + RTRIM(EmpBank.AccNo) + ')' END) -- _THRBasBank  
                  ELSE  
                     ISNULL(C2.MinorName,'') + CASE WHEN ISNULL(Bank.BankAccNo,'') = '' THEN '' ELSE '('+RTRIM(Bank.BankAccNo)+')' END  
             END AS CustInfo,                    
 --                   '�ⳳ�ŷ�ó����' AS CustInfo,    
 --                ISNULL(C2.MinorName,'') + CASE WHEN ISNULL(Bank.BankAccNo,'') = '' THEN '' ELSE '('+Bank.BankAccNo+')' END AS CustInfo,     
             ISNULL(A.SMCashMethodName,'') AS SMCashMethodName ,      
             A.SumDrAmt,      
             A.SUMCrAmt  ,  
             A.SlipNo AS SlipNoOne,  
             CASE WHEN CONVERT(INT, RIGHT(RTRIM(A.RowNo), 2)) < 10 THEN '1'   
             ELSE '0' END IsFirstPage,  
             --@DrSumFirstFage AS DrSumFirstFage,  
             --@CrSumFirstFage AS CrSumFirstFage,  
             --@IsOnlyOnPage   AS IsOnlyOnPage,  
    A.DrSumFirstFage,  
    A.CrSumFirstFage,  
    A.IsOnlyOnPage,  
             MstSlip.RTRegAccDate  AS RegDateTime, -- ��ǥ �ۼ���  
             MstSlip.RegAccDate                         AS RegDate    , -- ��ǥ��      
             A.S_AccUnitName                            AS S_AccUnitName, -- ������ ������ǥ�� ��� �߻���ǥ�� ȸ�������  
             ISNULL(cctr.Remark, '')                                AS CCtrRemark,  
    ISNULL(A.TopUserName,'') AS TopUserName,  
               CASE WHEN ISNULL(C.MinorName, '') <> '' THEN A.AccName + '(' + RTRIM(ISNULL(C.MinorName, '')) + ')'  
                  ELSE A.AccName  
             END AS AccName2,  
             ISNULL(MstSlip.SetEmpName,'') AS SetEmpName,  
             CASE WHEN ISNULL(Bank.BankAccNo,'') = ''   
                     THEN (ISNULL(C4.PayBankName, '') + ' ' + CASE WHEN ISNULL(EmpBankFBS.AccNo, '') = '' THEN '' ELSE '(' + RTRIM(EmpBankFBS.AccNo) + ')' END) -- _THRBasBank  
                  ELSE  
                     ISNULL(C2.MinorName,'') + CASE WHEN ISNULL(Bank.BankAccNo,'') = '' THEN '' ELSE '('+RTRIM(Bank.BankAccNo)+')' END  
             END AS CustInfoFBS,  
             MstSlip.RegDateTime  AS FullRegDateTime,    --��ǥ�ۼ��Ͻú���  
             MstSlip.ApprovalDateTime AS ApprovalDateTime,   --���������Ͻú���  
             MstSlip.RTSetAccDate     AS RTSetAccDate,       --8�ڸ��� ������������              
             CASE WHEN D.RemSeq = 1017 THEN D.CustNo  
                  WHEN E.RemSeq = 1017 THEN E.CustNo  
                  WHEN F.RemSeq = 1017 THEN F.CustNo  
                  WHEN G.RemSeq = 1017 THEN G.CustNo  
                  WHEN H.RemSeq = 1017 THEN H.CustNo  
                  WHEN I.RemSeq = 1017 THEN I.CustNo  
 WHEN J.RemSeq = 1017 THEN J.CustNo  
                  WHEN K.RemSeq = 1017 THEN K.CustNo END AS CustNo,      
             CASE WHEN D.RemSeq = 1013 THEN D.RemValue  
                  WHEN E.RemSeq = 1013 THEN E.RemValue  
                  WHEN F.RemSeq = 1013 THEN F.RemValue  
                  WHEN G.RemSeq = 1013 THEN G.RemValue  
                  WHEN H.RemSeq = 1013 THEN H.RemValue  
                  WHEN I.RemSeq = 1013 THEN I.RemValue  
                  WHEN J.RemSeq = 1013 THEN J.RemValue  
                  WHEN K.RemSeq = 1013 THEN K.RemValue END AS TaxNoAlias -- ����ڹ�ȣ��         
                , MstSlip.UMSlipKindGroupName, 
                ZZZ.SMTripKind, 
                YYY.MinorName AS SMTripKindName, 
                ZZZ.TripFrDate, 
                ZZZ.TripToDate,
                ZZZ.TermNight, 
                ZZZ.TermDay, 
                ZZZ.TripPlace, 
                ZZZ.Purpose, 
                ZZZ.EmpSeq, 
                CONVERT(INT,ZZZ.TransCost) AS TransCost, 
                CONVERT(INT,ZZZ.DailyCost) AS DailyCost, 
                CONVERT(INT,ZZZ.LodgeCost) AS LodgeCost, 
                CONVERT(INT,ZZZ.EctCost) AS EctCost, 
                QQQ.EmpName, 
                QQQ.UMJPName, 
                QQQ.DeptName, 
                CONVERT(INT,ISNULL(ZZZ.TransCost,0) + ISNULL(ZZZ.DailyCost,0) + ISNULL(ZZZ.LodgeCost,0) + ISNULL(ZZZ.EctCost,0)) AS SumCost
                
           INTO #Temp_Detail   
           FROM #TempFixedCol AS A              
                LEFT JOIN #tmp2 AS B              
                       ON B.SlipSeq      = A.SlipSeq              
                LEFT JOIN _TACSlipLinkedData AS X WITH (NOLOCK)              
                       ON X.CompanySeq   = @CompanySeq              
                      AND X.SlipSeq      = A.SlipSeq              
                LEFT JOIN _TDAUMinor AS C WITH(NOLOCK)              
                       ON C.CompanySeq   = @CompanySeq              
                      AND C.MinorSeq     = A.UMCostType                    
                LEFT OUTER JOIN #Result_tmp AS MstSlip ON A.SlipMstSeq = MstSlip.SlipMstSeq            
                LEFT OUTER JOIN #tmp_SlipRemValue AS D ON A.SlipSeq = D.SlipSeq AND D.Sort = 1          
                LEFT OUTER JOIN #tmp_SlipRemValue AS E ON A.SlipSeq = E.SlipSeq AND E.Sort = 2          
                LEFT OUTER JOIN #tmp_SlipRemValue AS F ON A.SlipSeq = F.SlipSeq AND F.Sort = 3          
                LEFT OUTER JOIN #tmp_SlipRemValue AS G ON A.SlipSeq = G.SlipSeq AND G.Sort = 4          
                LEFT OUTER JOIN #tmp_SlipRemValue AS H ON A.SlipSeq = H.SlipSeq AND H.Sort = 5          
                LEFT OUTER JOIN #tmp_SlipRemValue AS I ON A.SlipSeq = I.SlipSeq AND I.Sort = 6          
                LEFT OUTER JOIN #tmp_SlipRemValue AS J ON A.SlipSeq = J.SlipSeq AND J.Sort = 7          
                LEFT OUTER JOIN #tmp_SlipRemValue AS K ON A.SlipSeq = K.SlipSeq AND K.Sort = 8          
                LEFT OUTER JOIN _TDAAccUnit AS Acc WITH (NOLOCK) ON A.AccUnit = Acc.AccUnit AND Acc.CompanySeq = @CompanySeq    
                LEFT OUTER JOIN _TDACustBankAcc AS bank WITH(NOLOCK) ON A.CustSeq    = bank.CustSeq AND bank.CompanySeq  = @CompanySeq  
                                                                    AND bank.IsDefault = '1'   
                                                                    AND bank.CustSeq   <> 0  
                LEFT OUTER JOIN _THRBasEmpAccNo AS EmpBank WITH(NOLOCK) ON EmpBank.CompanySeq = @CompanySeq  
                                                                         AND EmpBank.UMAccNoType = 3098001 -- �ְ��¸�..  
                                                                       AND A.EmpSeq            = EmpBank.EmpSeq  
                LEFT OUTER JOIN _TCOMEnvAccFBS AS AccFBS WITH(NOLOCK) ON AccFBS.CompanySeq = @CompanySeq AND AccFBS.AccSeq = A.AccSeq   
                LEFT OUTER JOIN _THRBasEmpAccNo AS EmpBankFBS WITH(NOLOCK) ON EmpBankFBS.CompanySeq = @CompanySeq   
                                                           AND EmpBankFBS.UMAccNoType = AccFBS.SMBankAccClass  
                                                           AND A.EmpSeq  = EmpBankFBS.EmpSeq   
 --select UMAccNoType From _THRBasEmpAccNo   
 --select SMBankAccClass from _TCOMEnvAccFBS  
                 LEFT OUTER JOIN _TDAUMinor AS C2 WITH(NOLOCK) ON bank.CompanySeq = C2.CompanySeq AND bank.UMBankHQ = C2.MinorSeq      
                LEFT OUTER JOIN _THRBasBank AS C3 WITH(NOLOCK) ON C3.CompanySeq = @CompanySeq AND EmpBank.PayBankSeq = C3.PayBankSeq     
                LEFT OUTER JOIN #tmp_SlipCostItemName AS L ON A.SlipSeq = L.SlipSeq   
                LEFT OUTER JOIN _TDACCtr AS cctr ON cctr.CompanySeq = @CompanySeq AND A.BgtCCtrSeq = cctr.CCtrSeq  
 --select * from _TCOMEnvAccFBS  
 --SMBankAccClass  
                LEFT OUTER JOIN _THRBasBank AS C4 WITH(NOLOCK) ON C4.CompanySeq = @CompanySeq AND EmpBankFBS.PayBankSeq = C4.PayBankSeq  
                LEFT OUTER JOIN KPX_TARBizTripCost AS ZZZ WITH(NOLOCK) ON ( ZZZ.BizTripSeq = @BizTripSeq )
                LEFT OUTER JOIN _TDASMinor         AS YYY WITH(NOLOCK) ON ( YYY.CompanySeq = @CompanySeq AND YYY.MinorSeq = ZZZ.SMTripKind ) 
                LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS QQQ ON ( QQQ.EmpSeq = ZZZ.EmpSeq ) 
    
          ORDER BY A.RowIDX     
    
    --select * From #Temp_Detail 
    --return 
    
     -- #TempItemAmtRepeat�� #TempItemAmt�� ��Ƶ� �ݺ��� ��� �����Ϳ� XML���������� �־��ش�.      
     INSERT INTO #Temp_DetailRepeat(SlipMstSeq, DataBlock2)      
     SELECT  SlipMstSeq,  
       '<MaxIDX>' + ISNULL(CONVERT(NVARCHAR(20),MaxIDX),'') + '</MaxIDX>' +  
             '<RowIDX>' + ISNULL(CONVERT(NVARCHAR(20),RowIDX),'') + '</RowIDX>' +  
             '<AccDate>' + ISNULL(AccDate,'') + '</AccDate>' +      
             '<OrgAccDate>' + ISNULL(OrgAccDate,'') + '</OrgAccDate>' +   
             '<CurrDate>' + ISNULL(CurrDate,'') + '</CurrDate>' +      
             '<AccDatefull>' + ISNULL(AccDatefull,'') + '</AccDatefull>' +   
             '<RegDeptName>' + ISNULL(RegDeptName,'') + '</RegDeptName>' +       
             '<RegEmpName>' + ISNULL(RegEmpName,'') + '</RegEmpName>' +             
             '<SetSlipNo>' + ISNULL(SetSlipNo,'') + '</SetSlipNo>' +       
             '<SlipKindName>' + ISNULL(SlipKindName,'') + '</SlipKindName>' +     
             '<SlipKind>' + ISNULL(CONVERT(NVARCHAR(20),SlipKind),'') + '</SlipKind>' +     
             '<Remark>' + ISNULL(Remark,'') + '</Remark>' +           
             '<AptDate>' + ISNULL(AptDate,'') + '</AptDate>' +          
             '<AptRemark>' + ISNULL(AptRemark,'') + '</AptRemark>' +          
             '<IsSet>' + ISNULL(IsSet,'') + '</IsSet>' +        
             '<SetEmpName>' + ISNULL(SetEmpName,'') + '</SetEmpName>' +        
             '<SlipUnitName>' + ISNULL(SlipUnitName,'') + '</SlipUnitName>' +    
             '<SlipMstID>' + ISNULL(SlipMstID,'') + '</SlipMstID>' +    
             '<SlipAppNo>' + ISNULL(SlipAppNo,'') + '</SlipAppNo>' +               
             '<RowNum>' + ISNULL(CONVERT(NVARCHAR(20),RowNum),'') + '</RowNum>' +                     
             '<SlipID>' + ISNULL(SlipID,'') + '</SlipID>' +                      
             '<AccUnitName>' + ISNULL(AccUnitName,'') + '</AccUnitName>' +                           
             '<SlipNo>' + ISNULL(SlipNo,'') + '</SlipNo>' +                       
             '<RowNo>' + ISNULL(RowNo,'') + '</RowNo>' +                             
             '<DrAmt>' + ISNULL(CONVERT(NVARCHAR(20),DrAmt),'') + '</DrAmt>' +                    
             '<CrAmt>' + ISNULL(CONVERT(NVARCHAR(20),CrAmt),'') + '</CrAmt>' +                    
             '<DrForAmt>' + ISNULL(CONVERT(NVARCHAR(20),DrForAmt),'') + '</DrForAmt>' +                     
             '<CrForAmt>' + ISNULL(CONVERT(NVARCHAR(20),CrForAmt),'') + '</CrForAmt>' +   
             '<ExRate>' + ISNULL(CONVERT(NVARCHAR(20), dbo._fnCOMCurrency(ExRate,@Exradecimal)),'') + '</ExRate>' +                 
               '<DivExRate>' + ISNULL(CONVERT(NVARCHAR(20),DivExRate),'') + '</DivExRate>' +     
             '<NDVATAmt>' + ISNULL(CONVERT(NVARCHAR(20),NDVATAmt),'') + '</NDVATAmt>' +                 
             '<Summary>' + ISNULL(Summary,'') + '</Summary>' +                
             '<AccName>' + ISNULL(AccName,'') + '</AccName>' +                  
             '<AccNo>' + ISNULL(AccNo,'') + '</AccNo>' +                    
             '<CurrName>' + ISNULL(CurrName,'') + '</CurrName>' +                 
             '<CurrUnit>' + ISNULL(CurrUnit,'') + '</CurrUnit>' +  
             '<EvidName>' + ISNULL(EvidName,'') + '</EvidName>' +                 
             '<TaxKindName>' + ISNULL(TaxKindName,'') + '</TaxKindName>' +                  
             '<CashItemName>' + ISNULL(CashItemName,'') + '</CashItemName>' +                   
             '<SMCostItemKindName>' + ISNULL(SMCostItemKindName,'') + '</SMCostItemKindName>' +           
             '<CostItemName>' + ISNULL(CostItemName,'') + '</CostItemName>' +             
             '<BgtDeptName>' + ISNULL(BgtDeptName,'') + '</BgtDeptName>' +      
             '<BgtCCtrName>' + ISNULL(BgtCCtrName,'') + '</BgtCCtrName>' +     
             '<BgtName>' + ISNULL(BgtName,'') + '</BgtName>' +                    
   '<IsCash>' + ISNULL(IsCash,'') + '</IsCash>' +              
             '<CashDate>' + ISNULL(CashDate,'') + '</CashDate>' +          
             '<OnSlipID>' + ISNULL(OnSlipID,'') + '</OnSlipID>' +                       
             '<IsAnti>' + ISNULL(IsAnti,'') + '</IsAnti>' +             
             '<IsSlip>' + ISNULL(IsSlip,'') + '</IsSlip>' +             
             '<IsLevel2>' + ISNULL(IsLevel2,'') + '</IsLevel2>' +             
             '<IsZeroAllow>' + ISNULL(IsZeroAllow,'') + '</IsZeroAllow>' +             
             '<IsEssForAmt>' + ISNULL(IsEssForAmt,'') + '</IsEssForAmt>' +               
             '<IsEssCost>' + ISNULL(IsEssCost,'') + '</IsEssCost>' +             
             '<IsCostTrn>' + ISNULL(IsCostTrn,'') + '</IsCostTrn>' +                     
             '<IsCashAcc>' + ISNULL(IsCashAcc,'') + '</IsCashAcc>' +                      
             '<IsFundSet>' + ISNULL(IsFundSet,'') + '</IsFundSet>' +             
             '<IsAutoExec>' + ISNULL(IsAutoExec,'') + '</IsAutoExec>' +                    
             --'<LinkedKeyXMLData>' + ISNULL(LinkedKeyXMLData,'') + '</LinkedKeyXMLData>' +             
             '<UMCostTypeName>' + ISNULL(UMCostTypeName,'') + '</UMCostTypeName>' +             
             --'<SlipCostXmlData>' + ISNULL(SlipCostXmlData,'') + '</SlipCostXmlData>' +             
             '<CostDeptName>' + REPLACE(REPLACE(ISNULL(CostDeptName,''),'<','��'),'>','��') + '</CostDeptName>' +             
             '<CostCCtrName>' + REPLACE(REPLACE(ISNULL(CostCCtrName,''),'<','��'),'>','��') + '</CostCCtrName>' +    
             '<CoCustName>' + ISNULL(CoCustName,'') + '</CoCustName>' +           
             '<RemValue1>' + REPLACE(REPLACE(ISNULL(RemValue1,''),'<','��'),'>','��')  + '</RemValue1>' +         
             '<RemValue2>' + REPLACE(REPLACE(ISNULL(RemValue2,''),'<','��'),'>','��')  + '</RemValue2>' +         
             '<RemValue3>' + REPLACE(REPLACE(ISNULL(RemValue3,''),'<','��'),'>','��')  + '</RemValue3>' +         
             '<RemValue4>' + REPLACE(REPLACE(ISNULL(RemValue4,''),'<','��'),'>','��')  + '</RemValue4>' +         
             '<RemValue5>' + REPLACE(REPLACE(ISNULL(RemValue5,''),'<','��'),'>','��')  + '</RemValue5>' +         
             '<RemValue6>' + REPLACE(REPLACE(ISNULL(RemValue6,''),'<','��'),'>','��')  + '</RemValue6>' +         
             '<RemValue7>' + REPLACE(REPLACE(ISNULL(RemValue7,''),'<','��'),'>','��')  + '</RemValue7>' +         
             '<RemValue8>' + REPLACE(REPLACE(ISNULL(RemValue8,''),'<','��'),'>','��')  + '</RemValue8>' +      
             '<RemName1>' + ISNULL(RemName1,'') + '</RemName1>' +         
             '<RemName2>' + ISNULL(RemName2,'') + '</RemName2>' +         
               '<RemName3>' + ISNULL(RemName3,'') + '</RemName3>' +         
             '<RemName4>' + ISNULL(RemName4,'') + '</RemName4>' +         
             '<RemName5>' + ISNULL(RemName5,'') + '</RemName5>' +         
             '<RemName6>' + ISNULL(RemName6,'') + '</RemName6>' +         
             '<RemName7>' + ISNULL(RemName7,'') + '</RemName7>' +         
             '<RemName8>' + ISNULL(RemName8,'') + '</RemName8>' +      
             '<SMCashMethodName>' + ISNULL(SMCashMethodName,'') + '</SMCashMethodName>' +      
             '<SumDrAmt>' + ISNULL(CONVERT(NVARCHAR(20),SumDrAmt),'') + '</SumDrAmt>' +      
             '<SUMCrAmt>' + ISNULL(CONVERT(NVARCHAR(20),SUMCrAmt),'') + '</SUMCrAmt>' +      
             '<SlipNoOne>' + ISNULL(SlipNoOne,'') + '</SlipNoOne>' +      
             '<IsFirstPage>' + ISNULL(IsFirstPage,'') + '</IsFirstPage>' +     
             '<DrSumFirstFage>' + ISNULL(CONVERT(NVARCHAR(20),DrSumFirstFage),'') + '</DrSumFirstFage>' +     
             '<CrSumFirstFage>' + ISNULL(CONVERT(NVARCHAR(20),CrSumFirstFage),'') + '</CrSumFirstFage>' +     
             '<IsOnlyOnPage>' + ISNULL(IsOnlyOnPage,'') + '</IsOnlyOnPage>' +     
             '<RegDateTime>' + ISNULL(RegDateTime,'') + '</RegDateTime>' +     
             '<RegDate>' + ISNULL(RegDate,'') + '</RegDate>' +     
          '<CustInfo>' + ISNULL(CustInfo,'') + '</CustInfo>' +  
             '<S_AccUnitName>' + ISNULL(S_AccUnitName, '') + '</S_AccUnitName>'  +  
             '<CCtrRemark>' + ISNULL(CCtrRemark, '') + '</CCtrRemark>' +    
             '<TopUserName>' + ISNULL(TopUserName, '') + '</TopUserName>' +  
             '<AccName2>' + ISNULL(AccName2, '') + '</AccName2>' +  
             '<CustInfoFBS>' + ISNULL(CustInfoFBS,'') + '</CustInfoFBS>' +  
             '<FullRegDateTime>' + ISNULL(CONVERT(NVARCHAR(100),FullRegDateTime),'') + '</FullRegDateTime>' +                
             '<ApprovalDateTime>' + ISNULL(CONVERT(NVARCHAR(100),ApprovalDateTime),'') + '</ApprovalDateTime>' +    
             '<RTSetAccDate>' + ISNULL(RTSetAccDate,'') + '</RTSetAccDate>' +   
             '<CustNo>' + ISNULL(CONVERT(NVARCHAR(200),CustNo),'') + '</CustNo>' +   
       '<TaxNoAlias>' + ISNULL(CONVERT(NVARCHAR(200),TaxNoAlias),'') + '</TaxNoAlias>' +  
       '<FullRegDate>' + CONVERT(NCHAR(8), ISNULL(FullRegDateTime, ''), 112) + '</FullRegDate> '               
             AS DataBlock2  
            FROM #Temp_Detail      
           ORDER BY SlipMstSeq, RowNo       
    
    
      SELECT @MaxCnt      = COUNT(*) FROM #Temp  
     SELECT @Cnt         = 0  
      WHILE (@Cnt < @MaxCnt)            
     BEGIN  
         SELECT @SlipMstSeq   = SlipMstSeq   FROM #Temp WHERE Cnt    = @Cnt  
          SELECT @SubCnt      = MIN(SubCnt) FROM #Temp_DetailRepeat WHERE SlipMstSeq = @SlipMstSeq  
         SELECT @IniCnt      = MIN(SubCnt) FROM #Temp_DetailRepeat WHERE SlipMstSeq = @SlipMstSeq  
         SELECT @SubMaxCnt   = MAX(SubCnt) FROM #Temp_DetailRepeat WHERE SlipMstSeq = @SlipMstSeq  
          SELECT @XmlData = ''         
          IF @WorkingTag <> 'S' ------------ �׷���� SP(_SCOMGroupWarePrint)���� ȣ���ϴ� ��� XML �����Ͱ� �ǹ� ���� Pass�� (�ڹ��� 430�� ��ǥ Select�� 12�� �ҿ�)  
         WHILE (@SubCnt  <= @SubMaxCnt)  
         BEGIN  
             SELECT @DataBlock2 = DataBlock2 FROM #Temp_DetailRepeat WHERE SubCnt  = @SubCnt AND SlipMstSeq = @SlipMstSeq  
            
             IF (@IniCnt = @SubCnt)   
             BEGIN  
                 SELECT @XmlData     = @XmlData + @DataBlock2  
             END  
             ELSE  
             BEGIN  
                 SELECT @XmlData     = @XmlData + + '</DataBlock2><DataBlock2>' + @DataBlock2  
             END  
              SELECT @SubCnt   = @SubCnt + 1  
         END  
          UPDATE #Temp  
            SET DataBlock2 = @XmlData  
          WHERE SlipMstSeq = @SlipMstSeq  
           
           
          SELECT @Cnt  = @Cnt + 1  
     END  
      SELECT SlipMstSeq, DataBlock2 FROM #Temp     
--select * from #Temp_Detail  
       -- ��ǥ�����Ͽ� �׷����� ȭ���� ����ٶ� ����ϱ� ���� ���������� ��ȯ ���� �����͵� SELECT �Ѵ�.  
     SELECT * ,  
            CASE WHEN RemName6 = '���ڼ��ݰ�꼭 ���ι�ȣ' THEN '1'  
                 WHEN RemName4 = 'ī����ι�ȣ' THEN '2'  
            ELSE '0' END AS TaxType,  
            CASE WHEN RemName6 = '���ڼ��ݰ�꼭 ���ι�ȣ' THEN RemValue6  
                 WHEN RemName4 = 'ī����ι�ȣ' THEN RemValue4  
            ELSE '0' END AS TaxNO,  
            CASE WHEN RemName6 = '���ڼ��ݰ�꼭 ���ι�ȣ' THEN   
                        N'<a href="#" style="cursor: pointer;" onclick="KpxViewTax('''+ '1' +''','''+ ''+CONVERT(NVARCHAR(100),RemValue6)+'' +''','''+ ''+CONVERT(NVARCHAR(100),@CompanySeq)+'' +''');">��������</a>'  
                 WHEN RemName4 = 'ī����ι�ȣ' THEN   
                        N'<a href="#" style="cursor: pointer;" onclick="KpxViewCard('''+ '2' +''','''+ ''+CONVERT(NVARCHAR(100),RemValue4)+'' +''','''+ ''+CONVERT(NVARCHAR(100),@CompanySeq)+'' +''');">��������</a>'  
                 ELSE '' END AS Link  
  
       FROM #Temp_Detail 
      ORDER BY RowNo  
    
    
    
      
    IF ISNULL(@IsNotGW,'') = '1'  
     BEGIN  
      -- ��ǥ ��½� ������ �հ�ǥ�� ����   
      SELECT AccNo, AccName,     
          SUM(DrAmt)       AS SumDrAmt,     
          SUM(CrAmt)       AS SumCrAmt,     
          SUM(DrForAmt)    AS SumDrForAmt,     
          SUM(CrForAmt)    AS SumCrForAmt    
        FROM #Temp_Detail     
       GROUP BY AccNo, AccName    
       ORDER BY AccNo  
     END  
    
    
    --=========================================================================================================================  
    -- ���ȸ�� ����  
    --=========================================================================================================================  
    IF EXISTS (SELECT 1 FROM #Temp)  
    BEGIN  
        SELECT @Cnt = 0  
        SELECT @MaxCnt = MAX(Cnt) FROM #Temp  
        WHILE @Cnt <= @MaxCnt  
        BEGIN  
            SELECT @SlipMstSeq = SlipMstSeq FROM #Temp WHERE Cnt = @Cnt  
             UPDATE _TACSlipPrintCount  
               SET PrintCnt = PrintCnt + 1  
             WHERE CompanySeq   = @CompanySeq  
               AND SlipMstSeq   = @SlipMstSeq  
            IF @@ROWCOUNT = 0  
            BEGIN  
                INSERT INTO _TACSlipPrintCount (CompanySeq, SlipMstSeq, PrintCnt, LastUserSeq, LastDateTime)  
                SELECT @CompanySeq, @SlipMstSeq, 1, @UserSeq, GETDATE()  
            END  
            SELECT @Cnt = @Cnt + 1  
        END  
    END  
    --END              
    
    
    --> ���� �㶧 �����ȹ�� �ٽ� ��� �� ���� ���� SUB SP�� �и���. ---> ����� ������ ��ǥ�� �ٽ� �����ؾ� �� ����              
    
    RETURN   
GO 
exec KPX_SARBizTripCostGWQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BizTripSeq>1</BizTripSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027319,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=857
