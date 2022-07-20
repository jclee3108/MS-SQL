  
IF OBJECT_ID('mnpt_SACEEBgtChgReqPrcCheck') IS NOT NULL   
    DROP PROC mnpt_SACEEBgtChgReqPrcCheck  
GO  
    
-- v2018.02.06
  
-- ���꺯���Է�-üũ by ����õ
CREATE PROC mnpt_SACEEBgtChgReqPrcCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #mnpt_TACBgt( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#mnpt_TACBgt'   
    IF @@ERROR <> 0 RETURN     
    

    DECLARE @EnvValue INT 

    SELECT @EnvValue = EnvValue
      FROM _TCOMEnv WITH(NOLOCK)
     WHERE CompanySeq = @CompanySeq
       AND EnvSeq = 4008
    
    UPDATE #mnpt_TACBgt
       SET DeptSeq = CASE WHEN  @EnvValue = 4013001 THEN DeptCCtrSeq ELSE 0 END,
           CCtrSeq = CASE WHEN  @EnvValue = 4013002 THEN DeptCCtrSeq ELSE 0 END

    -- �ߺ����� üũ :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          0, ''--,  -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
                          --3543, '��2'  
      
    UPDATE #mnpt_TACBgt  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #mnpt_TACBgt AS A   
      JOIN (SELECT S.BgtYM, S.AccUnit, S.DeptSeq, S.CCtrSeq, S.AccSeq, S.IniOrAmd, S.BgtSeq, S.UMCostType
              FROM (SELECT A1.BgtYM, A1.AccUnit, A1.DeptSeq, A1.CCtrSeq, A1.AccSeq, A1.IniOrAmd, A1.BgtSeq, A1.UMCostType
                      FROM #mnpt_TACBgt AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.BgtYM, A1.AccUnit, A1.DeptSeq, A1.CCtrSeq, A1.AccSeq, A1.IniOrAmd, A1.BgtSeq, A1.UMCostType 
                      FROM mnpt_TACBgt AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #mnpt_TACBgt   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND ChgSeq = A1.ChgSeq 
                                      )  
                   ) AS S  
             GROUP BY S.BgtYM, S.AccUnit, S.DeptSeq, S.CCtrSeq, S.AccSeq, S.IniOrAmd, S.BgtSeq, S.UMCostType
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.BgtYM = B.BgtYM 
                   AND A.AccUnit = B.AccUnit 
                   AND A.DeptSeq = B.DeptSeq 
                   AND A.CCtrSeq = B.CCtrSeq 
                   AND A.AccSeq = B.AccSeq 
                   AND A.IniOrAmd = B.IniOrAmd 
                   AND A.BgtSeq = B.BgtSeq 
                   AND A.UMCostType = B.UMCostType 
                     )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  

    --------------------------------------------------------------------------------------------------------------------------------------------------
    -- ��� ���� üũ
    --------------------------------------------------------------------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT   ,  
                          @Status      OUTPUT   ,  
                          @Results     OUTPUT   ,  
                          2195                  , -- SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 2195 -- @1 ��(��) �����ϴ� @2 �Դϴ�. @1 ��(��) @3 �ϼ���.
                          @LanguageSeq          ,   
                          652, '��뱸��',
                          1737, '��������',
                          307, '�Է�'
                          
    UPDATE #mnpt_TACBgt  
       SET Result        = @Results,        -- ��뱸�� ��(��) �����ϴ� ������� �Դϴ�. ��뱸�� ��(��) �Է� �ϼ���.
           MessageType   = @MessageType,  
           Status        = @Status
     FROM #mnpt_TACBgt AS A 
     LEFT OUTER JOIN _TDAAccountCostType  AS C WITH(NOLOCK) ON ( C.CompanySeq  = @CompanySeq AND C.AccSeq = A.AccSeq ) 
    WHERE A.Status      = 0
      AND A.WorkingTag  IN ('A', 'U')
      AND ISNULL(A.UMCostType, 0)  = 0     -- �ش� �������� ����� ���������� ��뱸���� �ִµ�, ������� ���� ��뱸���� �������� �Ѿ���� üũ
      AND C.CompanySeq  IS NOT NULL 

    --------------------------------------------------------------------------------------------------------------------------------------------------
    -- ��� ���� üũ ( ��뱸���� �ִµ� �߸� �Ѿ���ų� ��뱸���� ���µ� ���� �Ѿ���� ��� )
    --------------------------------------------------------------------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT   ,  
                          @Status      OUTPUT   ,  
                          @Results     OUTPUT   ,  
                          2062                  , -- @1���� ���� @2(@3)�� �ԷµǾ����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 2062)
                          @LanguageSeq          ,   
                          24260, '����',
                          652, '��뱸��',
                          0, ''
                          
    UPDATE #mnpt_TACBgt  
       SET Result        = REPLACE(@Results, '@3', UM.MinorName),        -- �������� ���� ��뱸��( )�� �ԷµǾ����ϴ�.
           MessageType   = @MessageType,  
           Status        = @Status
      FROM #mnpt_TACBgt AS A JOIN _TDAAccountCostType AS D WITH(NOLOCK)
                               ON D.CompanySeq     = @CompanySeq
                              AND D.AccSeq         = A.AccSeq   -- �������� ������ ��뱸���� ������ ��
                             LEFT OUTER JOIN _TDAUMinor AS UM WITH(NOLOCK)
                               ON UM.CompanySeq    = @CompanySeq
                              AND UM.MajorSeq      = 4001      -- ��뱸��
                              AND UM.MinorSeq      = A.UMCostType
     WHERE A.Status = 0
       AND A.WorkingTag IN ('A', 'U')
       AND ISNULL(A.UMCostType, 0) <> 0
       AND (A.UMCostType NOT IN ( SELECT DISTINCT D.UMCostType
                                            FROM #mnpt_TACBgt AS A JOIN _TDAAccountCostType AS D WITH(NOLOCK)
                                                                   ON D.CompanySeq    = @CompanySeq
                                                                  AND D.AccSeq        = A.AccSeq
                                )
            OR D.CompanySeq IS NULL
           )

    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #mnpt_TACBgt WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
      
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TACBgt', 'ChgSeq', @Count  
        
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #mnpt_TACBgt  
           SET ChgSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
      
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #mnpt_TACBgt   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #mnpt_TACBgt  
     WHERE Status = 0  
       AND ( ChgSeq = 0 OR ChgSeq IS NULL )  
      
    SELECT * FROM #mnpt_TACBgt   
    
    RETURN  
go
begin tran 
exec mnpt_SACEEBgtChgReqPrcCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <DeptCCtrName>�����μ�(����)</DeptCCtrName>
    <AccName>��ǰ</AccName>
    <BgtName>����_test</BgtName>
    <UMCostTypeName>����</UMCostTypeName>
    <BgtYM>201801</BgtYM>
    <BfrBgtAmt>0</BfrBgtAmt>
    <BgtAmt>22</BgtAmt>
    <ChgBgtAmt>0</ChgBgtAmt>
    <UMChgType />
    <ChgBgtDesc />
    <AccSeq>36</AccSeq>
    <BgtSeq>11</BgtSeq>
    <DeptCCtrSeq>18</DeptCCtrSeq>
    <UMCostType>4001001</UMCostType>
    <ChgSeq>0</ChgSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <PgmID>FrmACEEBgtChgReqPrc_mnpt</PgmID>
    <AccUnit>1</AccUnit>
    <IniOrAmd>1</IniOrAmd>
    <SMBgtChangeSource>4070003</SMBgtChangeSource>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820154,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=167,@PgmSeq=13820134
rollback 