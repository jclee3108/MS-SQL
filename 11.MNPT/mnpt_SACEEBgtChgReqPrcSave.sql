
IF OBJECT_ID('mnpt_SACEEBgtChgReqPrcSave') IS NOT NULL   
    DROP PROC mnpt_SACEEBgtChgReqPrcSave  
GO  
    
-- v2018.02.06
  
-- ���꺯���Է�-���� by ����õ
CREATE PROC mnpt_SACEEBgtChgReqPrcSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #mnpt_TACBgt (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#mnpt_TACBgt'   
    IF @@ERROR <> 0 RETURN    
    
    DECLARE @EnvValue INT 

    SELECT @EnvValue = EnvValue
      FROM _TCOMEnv WITH(NOLOCK)
     WHERE CompanySeq = @CompanySeq
       AND EnvSeq = 4008
    
    UPDATE #mnpt_TACBgt
       SET DeptSeq              = CASE WHEN  @EnvValue = 4013001 THEN DeptCCtrSeq ELSE 0 END,
           CCtrSeq              = CASE WHEN  @EnvValue = 4013002 THEN DeptCCtrSeq ELSE 0 END, 
           SMBgtChangeKind      = CASE WHEN BgtAmt > 0 THEN 4137001 ELSE 4137002 END, 
           SMBgtChangeSource    = 4070003
           
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TACBgt')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TACBgt'    , -- ���̺��        
                  '#mnpt_TACBgt'    , -- �ӽ� ���̺��        
                  'ChgSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TACBgt WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #mnpt_TACBgt AS A   
          JOIN mnpt_TACBgt AS B ON ( B.CompanySeq = @CompanySeq AND A.ChgSeq = B.ChgSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TACBgt WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.BgtYM              = A.BgtYM             ,  
               B.DeptSeq            = A.DeptSeq           ,  
               B.CCtrSeq            = A.CCtrSeq           ,  
               B.AccSeq             = A.AccSeq            ,  
               B.SMBgtChangeKind    = A.SMBgtChangeKind   ,  
               B.BgtSeq             = A.BgtSeq            ,  
               B.UMCostType         = A.UMCostType        ,  
               B.BgtAmt             = ABS(A.BgtAmt)       ,  
               B.ChgBgtDesc         = A.ChgBgtDesc        , 
               B.UMChgType          = A.UMChgType         , 
               B.LastUserSeq        = @UserSeq            ,  
               B.LastDateTime       = GETDATE()           ,  
               B.PgmSeq             = @PgmSeq    
          FROM #mnpt_TACBgt AS A   
          JOIN mnpt_TACBgt AS B ON ( B.CompanySeq = @CompanySeq AND A.ChgSeq = B.ChgSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #mnpt_TACBgt WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO mnpt_TACBgt  
        (   
            CompanySeq, ChgSeq, BgtYM, AccUnit, DeptSeq, 
            CCtrSeq, AccSeq, IniOrAmd, SMBgtChangeKind, SMBgtChangeSource, 
            BgtSeq, UMCostType, BgtAmt, ChgBgtDesc, UMChgType, 
            FirstUserSeq, FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, ChgSeq, BgtYM, AccUnit, DeptSeq, 
               CCtrSeq, AccSeq, IniOrAmd, SMBgtChangeKind, SMBgtChangeSource, 
               BgtSeq, UMCostType, ABS(BgtAmt), ChgBgtDesc, UMChgType, 
               @UserSeq, GETDATE(), @UserSeq, GETDATE(), @PgmSeq
          FROM #mnpt_TACBgt AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    END 
    

    CREATE TABLE #TACBgt
    (
        IDX_NO              INT IDENTITY, 
        Status              INT, 
        WorkingTag          NCHAR(1), 
        AccUnit             INT, 
        BgtSeq              INT, 
        DeptSeq             INT, 
        CCtrSeq             INT, 
        BgtYM               NCHAR(6), 
        UMCostType          INT, 
        IniOrAmd            NCHAR(1), 
        SMBgtChangeSource   INT, 
        SMBgtChangeKind     INT, 
        ChgBgtDesc          NVARCHAR(2000), 
        UMChgType           INT, 
        BgtAmt              DECIMAL(19,5) 
    )
    INSERT INTO #TACBgt 
    ( 
        Status             , WorkingTag         , AccUnit            , BgtSeq             , DeptSeq            , 
        CCtrSeq            , BgtYM              , UMCostType         , IniOrAmd           , SMBgtChangeSource  , 
        SMBgtChangeKind    , ChgBgtDesc         , UMChgType          , BgtAmt             
    )
    SELECT 0 AS Status, 
           CASE WHEN MAX(C.CompanySeq) IS NULL THEN 'A' ELSE 'U' END AS WorkingTag,  
           A.AccUnit,
           A.BgtSeq,    
           A.DeptSeq, 
           A.CCtrSeq, 
           A.BgtYM, 
           A.UMCostType, 
           MAX(A.IniOrAmd) AS IniOrAmd, 
           MAX(A.SMBgtChangeSource) AS SMBgtChangeSource, 
           CASE WHEN SUM(CASE WHEN A.SMBgtChangeKind = 4137002 THEN (-1) * A.BgtAmt ELSE A.BgtAmt END) > 0 THEN 4137001 ELSE 4137002 END AS SMBgtChangeKind, 
           MAX(A.ChgBgtDesc) AS ChgBgtDesc, 
           MAX(A.UMChgType) AS UMChgType, 
           SUM(CASE WHEN A.SMBgtChangeKind = 4137002 THEN (-1) * A.BgtAmt ELSE A.BgtAmt END) AS BgtAmt
      FROM mnpt_TACBgt  AS A 
      JOIN #mnpt_TACBgt AS B ON ( B.AccUnit = A.AccUnit 
                              AND B.BgtSeq = A.BgtSeq 
                              AND B.DeptSeq = A.DeptSeq 
                              AND B.CCtrSeq = A.CCtrSeq 
                              AND B.BgtYM = A.BgtYM
                              AND B.UMCostType = A.UMCostType 
                                ) 
      LEFT OUTER JOIN _TACBgt AS C ON ( C.CompanySeq = @CompanySeq 
                                    AND C.AccUnit = A.AccUnit 
                                    AND C.BgtSeq = A.BgtSeq 
                                    AND C.DeptSeq = A.DeptSeq 
                                    AND C.CCtrSeq = A.CCtrSeq 
                                    AND C.BgtYM = A.BgtYM
                                    AND C.UMCostType = A.UMCostType 
                                    AND C.SMBgtChangeSource = A.SMBgtChangeSource 
                                    AND C.IniOrAmd = A.IniOrAmd
                                 ) 
     WHERE A.CompanySeq = @CompanySeq 
     GROUP BY A.AccUnit,
              A.BgtSeq,    
              A.DeptSeq, 
              A.CCtrSeq, 
              A.BgtYM, 
              A.UMCostType 

    UNION ALL 

    SELECT 0 AS Status, 
           'D' AS WorkingTag,  
           A.AccUnit,
           A.BgtSeq,    
           A.DeptSeq, 
           A.CCtrSeq, 
           A.BgtYM, 
           A.UMCostType, 
           A.IniOrAmd, 
           A.SMBgtChangeSource, 
           NULL, 
           NULL, 
           NULL,
           NULL

      FROM _TACBgt AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.SMBgtChangeSource = 4070003
       AND NOT EXISTS (SELECT 1 
                         FROM mnpt_TACBgt AS Z 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND Z.BgtYM = BgtYM 
                          AND Z.AccUnit = A.AccUnit 
                          AND Z.DeptSeq = A.DeptSeq 
                          AND Z.CCtrSeq = A.CCtrSeq 
                          AND Z.IniOrAmd = A.IniOrAmd
                          AND Z.SMBgtChangeSource = A.SMBgtChangeSource 
                          AND Z.BgtSeq = A.BgtSeq 
                          AND Z.UMCostType = A.UMCostType 
                      )
     GROUP BY A.AccUnit,
           A.BgtSeq,    
           A.DeptSeq, 
           A.CCtrSeq, 
           A.BgtYM, 
           A.UMCostType, 
           A.IniOrAmd, 
           A.SMBgtChangeSource
    
    Update A
       SET SMBgtChangeKind = CASE WHEN BgtAmt > 0 THEN 4137001 ELSE 4137002 END
      FROM #TACBgt AS A 
    
    
    ----------------------------------------------------------------------------------------
    -- ��Ű�� Table�� �ֱ�
    ----------------------------------------------------------------------------------------
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
    EXEC _SCOMLog  @CompanySeq,    
                   @UserSeq,    
                   '_TACBgt',     
                   '#TACBgt',    
                   'BgtYM, AccUnit, DeptSeq, CCtrSeq, IniOrAmd, SMBgtChangeKind, SMBgtChangeSource, BgtSeq, UMCostType',    
                   'CompanySeq,    BgtYM,              AccUnit,            DeptSeq,    CCtrSeq,
                    IniOrAmd,      SMBgtChangeKind,    SMBgtChangeSource,  BgtSeq,     UMCostType,
                    BgtAmt,        LastUserSeq,        LastDateTime, ChgBgtDesc, UMChgType'  
  
    
    -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT    
    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #TACBgt WHERE WorkingTag = 'D')
    BEGIN  
        DELETE _TACBgt
          FROM _TACBgt A JOIN #TACBgt AS B ON (A.BgtYM = B.BgtYM
                                           AND A.AccUnit = B.AccUnit
                                           AND A.DeptSeq = B.DeptSeq
                                           AND A.CCtrSeq = B.CCtrSeq
                                           AND B.IniOrAmd = '1'
                                           AND A.SMBgtChangeSource = B.SMBgtChangeSource
                                           AND A.BgtSeq = B.BgtSeq
                                           AND A.UMCostType = B.UMCostType)  
         WHERE B.WorkingTag = 'D' 
           AND A.CompanySeq  = @CompanySeq
        IF @@ERROR <> 0  RETURN
    END
    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #TACBgt WHERE WorkingTag = 'U')
    BEGIN
        UPDATE _TACBgt
           SET  BgtYM           = B.BgtYM,
                AccUnit         = B.AccUnit,
                DeptSeq         = B.DeptSeq,
                CCtrSeq         = B.CCtrSeq,
                BgtSeq          = B.BgtSeq,
                UMCostType      = B.UMCostType,
                BgtAmt          = B.BgtAmt     ,
                SMBgtChangeKind = B.SMBgtChangeKind, 
                ChgBgtDesc      = B.ChgBgtDesc,  
                UMChgType       = B.UMChgType, 
                LastUserSeq     = @UserSeq     , 
                LastDateTime    = GETDATE()      
                
          FROM _TACBgt AS A JOIN #TACBgt AS B ON (  A.BgtYM = B.BgtYM
                                                AND A.AccUnit = B.AccUnit
                                                AND A.DeptSeq = B.DeptSeq
                                                AND A.CCtrSeq = B.CCtrSeq
                                                AND B.IniOrAmd = '1'
                                                AND A.SMBgtChangeSource = B.SMBgtChangeSource
                                                AND A.BgtSeq = B.BgtSeq
                                                AND A.UMCostType = B.UMCostType)  
         WHERE B.WorkingTag = 'U'
           AND A.CompanySeq  = @CompanySeq  
        IF @@ERROR <> 0  RETURN
    END 
    
    -- INSERT
    IF EXISTS (SELECT 1 FROM #TACBgt WHERE WorkingTag = 'A')
    BEGIN  
        INSERT INTO _TACBgt (CompanySeq,    BgtYM,              AccUnit,            DeptSeq,    CCtrSeq,
                             IniOrAmd,      SMBgtChangeKind,    SMBgtChangeSource,  BgtSeq,     UMCostType,
                             BgtAmt,        LastUserSeq,        LastDateTime,       ChgBgtDesc, UMChgType)
            SELECT @CompanySeq,    BgtYM,              AccUnit,            DeptSeq,    CCtrSeq,
                   IniOrAmd,       SMBgtChangeKind,    SMBgtChangeSource,  BgtSeq,     UMCostType,
                   ABS(BgtAmt),    @UserSeq,           GETDATE(),          ChgBgtDesc, UMChgType
              FROM #TACBgt AS A   
             WHERE A.WorkingTag = 'A'
        IF @@ERROR <> 0 RETURN
    END  
    
    -- ��������������� 
    SELECT A.AccUnit, 
           LEFT(A.AccDate,6) AccYM, 
           A.AccSeq, 
           C.BgtSeq, 
           A.UMCostType, 
           A.BgtDeptSeq AS DeptSeq, 
           A.BgtCCtrSeq AS CCtrSeq, 
           SUM(A.DrAmt + A.CrAmt) AS ResultAmt
      INTO #AccBgtResultAmt 
      FROM _TACSlipRow AS A 
      JOIN (
            SELECT AccSeq, MAX(BgtSeq) AS BgtSeq 
              FROM _TACBgtAcc
             WHERE CompanySeq = @CompanySeq
             GROUP BY AccSeq 
           ) AS C ON ( C.AccSeq = A.AccSeq )  
     WHERE CompanySeq = @CompanySeq 
       AND (A.BgtDeptSeq <> 0 OR A.BgtCCtrSeq <> 0 )
       AND A.IsSet = '1' 
       AND EXISTS (SELECT 1 
                     FROM #mnpt_TACBgt AS Z 
                    WHERE Z.BgtYM = LEFT(A.AccDate,6)
                      AND Z.AccUnit = A.AccUnit 
                      AND Z.DeptSeq = A.BgtDeptSeq 
                      AND Z.CCtrSeq = A.BgtCCtrSeq
                      AND Z.AccSeq = A.AccSeq 
                  )
     GROUP BY A.AccUnit, LEFT(A.AccDate,6), A.AccSeq, C.BgtSeq, A.UMCostType, A.BgtDeptSeq, A.BgtCCtrSeq
    

    -- ó������ݿ�
    UPDATE A
       SET IniBgtAmt = CASE WHEN RIGHT(A.BgtYM,2) = '01' THEN I.Month01 
                            WHEN RIGHT(A.BgtYM,2) = '02' THEN I.Month02 
                            WHEN RIGHT(A.BgtYM,2) = '03' THEN I.Month03 
                            WHEN RIGHT(A.BgtYM,2) = '04' THEN I.Month04 
                            WHEN RIGHT(A.BgtYM,2) = '05' THEN I.Month05 
                            WHEN RIGHT(A.BgtYM,2) = '06' THEN I.Month06 
                            WHEN RIGHT(A.BgtYM,2) = '07' THEN I.Month07 
                            WHEN RIGHT(A.BgtYM,2) = '08' THEN I.Month08 
                            WHEN RIGHT(A.BgtYM,2) = '09' THEN I.Month09 
                            WHEN RIGHT(A.BgtYM,2) = '10' THEN I.Month10 
                            WHEN RIGHT(A.BgtYM,2) = '11' THEN I.Month11 
                            WHEN RIGHT(A.BgtYM,2) = '12' THEN I.Month12
                            ELSE 0 
                            END, 
           BfrBgtAmt = ISNULL(
                                CASE WHEN RIGHT(A.BgtYM,2) = '01' THEN I.Month01 
                                     WHEN RIGHT(A.BgtYM,2) = '02' THEN I.Month02 
                                     WHEN RIGHT(A.BgtYM,2) = '03' THEN I.Month03 
                                     WHEN RIGHT(A.BgtYM,2) = '04' THEN I.Month04 
                                     WHEN RIGHT(A.BgtYM,2) = '05' THEN I.Month05 
                                     WHEN RIGHT(A.BgtYM,2) = '06' THEN I.Month06 
                                     WHEN RIGHT(A.BgtYM,2) = '07' THEN I.Month07 
                                     WHEN RIGHT(A.BgtYM,2) = '08' THEN I.Month08 
                                     WHEN RIGHT(A.BgtYM,2) = '09' THEN I.Month09 
                                     WHEN RIGHT(A.BgtYM,2) = '10' THEN I.Month10 
                                     WHEN RIGHT(A.BgtYM,2) = '11' THEN I.Month11 
                                     WHEN RIGHT(A.BgtYM,2) = '12' THEN I.Month12
                                     ELSE 0 
                                     END,0) - ISNULL(J.ResultAmt,0), 
           ChgBgtAmt = ISNULL( 
                                CASE WHEN RIGHT(A.BgtYM,2) = '01' THEN I.Month01 
                                     WHEN RIGHT(A.BgtYM,2) = '02' THEN I.Month02 
                                     WHEN RIGHT(A.BgtYM,2) = '03' THEN I.Month03 
                                     WHEN RIGHT(A.BgtYM,2) = '04' THEN I.Month04 
                                     WHEN RIGHT(A.BgtYM,2) = '05' THEN I.Month05 
                                     WHEN RIGHT(A.BgtYM,2) = '06' THEN I.Month06 
                                     WHEN RIGHT(A.BgtYM,2) = '07' THEN I.Month07 
                                     WHEN RIGHT(A.BgtYM,2) = '08' THEN I.Month08 
                                     WHEN RIGHT(A.BgtYM,2) = '09' THEN I.Month09 
                                     WHEN RIGHT(A.BgtYM,2) = '10' THEN I.Month10 
                                     WHEN RIGHT(A.BgtYM,2) = '11' THEN I.Month11 
                                     WHEN RIGHT(A.BgtYM,2) = '12' THEN I.Month12
                                     ELSE 0 
                                     END,0) - ISNULL(J.ResultAmt,0) + ISNULL(CASE WHEN B.SMBgtChangeKind = 4137002 THEN (-1) * B.BgtAmt ELSE B.BgtAmt END,0)
      FROM #mnpt_TACBgt AS A 
      LEFT OUTER JOIN mnpt_TACBgt       AS B ON ( B.CompanySeq = @CompanySeq AND B.ChgSeq = A.ChgSeq )
      LEFT OUTER JOIN mnpt_TACEEBgtAdj  AS I ON ( I.CompanySeq = @CompanySeq 
                                              AND I.StdYear = LEFT(B.BgtYM,4) 
                                              AND I.AccUnit = B.AccUnit
                                              AND I.DeptSeq = B.DeptSeq 
                                              AND I.CCtrSeq = B.CCtrSeq 
                                              AND I.AccSeq = B.AccSeq 
                                              AND I.UMCostType = B.UMCostType 
                                                )
      LEFT OUTER JOIN #AccBgtResultAmt  AS J ON ( J.AccYM = B.BgtYM
                                              AND J.AccUnit = B.AccUnit
                                              AND J.DeptSeq = B.DeptSeq 
                                              AND J.CCtrSeq = B.CCtrSeq 
                                              AND J.AccSeq = B.AccSeq 
                                              AND J.UMCostType = B.UMCostType 
                                                )

    SELECT * FROM #mnpt_TACBgt   
      
    RETURN  

go
begin tran 
exec mnpt_SACEEBgtChgReqPrcSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AccUnit>1</AccUnit>
    <DeptCCtrName>����μ�</DeptCCtrName>
    <BgtName>�����Ļ���</BgtName>
    <BgtSeq>1</BgtSeq>
    <DeptCCtrSeq>4</DeptCCtrSeq>
    <UMCostTypeName>����</UMCostTypeName>
    <PgmID>FrmACEEBgtChgReqPrc_mnpt</PgmID>
    <BfrBgtAmt>0.00000</BfrBgtAmt>
    <BgtYM>201802</BgtYM>
    <UMCostType>4001001</UMCostType>
    <ChgBgtAmt>0.00000</ChgBgtAmt>
    <BgtAmt>-5550.00000</BgtAmt>
    <IniOrAmd>1</IniOrAmd>
    <SMBgtChangeSource>4070003</SMBgtChangeSource>
    <ChgBgtDesc />
    <UMChgType>0</UMChgType>
    <AccSeq>233</AccSeq>
    <AccName>�Ҹ�ǰ��</AccName>
    <ChgSeq>13</ChgSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820154,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=167,@PgmSeq=13820134
--select *from mnpt_TACBgt
--select * From _TACBgt where SMBgtChangeSource = 4070003 
rollback 