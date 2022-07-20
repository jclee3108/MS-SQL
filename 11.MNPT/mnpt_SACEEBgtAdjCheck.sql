  
IF OBJECT_ID('mnpt_SACEEBgtAdjCheck') IS NOT NULL   
    DROP PROC mnpt_SACEEBgtAdjCheck  
GO  
    
-- v2017.12.18
  
-- ��񿹻��Է�-üũ by ����õ   
CREATE PROC mnpt_SACEEBgtAdjCheck  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0    
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250), 
            @EnvValue       INT 
    
    UPDATE A
       SET AccUnit = B.AccUnit,
           StdYear = B.StdYear 
      FROM #BIZ_OUT_DataBlock1  AS A 
      JOIN mnpt_TACEEBgtAdj     AS B ON ( B.CompanySeq = @CompanySeq AND B.AdjSeq = A.AdjSeq ) 
     WHERE A.WorkingTag = 'D'   
       AND A.Status = 0   

    
    SELECT @EnvValue = EnvValue
      FROM _TCOMEnv WITH(NOLOCK)
     WHERE CompanySeq = @CompanySeq
       AND EnvSeq = 4008

    UPDATE #BIZ_OUT_DataBlock1
       SET DeptSeq = CASE WHEN  @EnvValue = 4013001 THEN DeptCCtrSeq ELSE 0 END,
           CCtrSeq = CASE WHEN  @EnvValue = 4013002 THEN DeptCCtrSeq ELSE 0 END
     WHERE Status   = 0


	--------------------------------------------------------------------------------------
	-- üũ1, (-)�ݾ� �Է� �Ұ��ϵ��� 
	--------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          1342               ,	-- @1 @2 @3 ��(��) ���� �� �� �����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 AND MessageSeq = 1342)
                          @LanguageSeq       , 
						  31931,	N'-'	 ,	-- SELECT * FROM _TCADictionary WHERE WordSeq = 31931
                          290,		N'�ݾ�'		-- SELECT * FROM _TCADictionary WHERE WordSeq = 290
    UPDATE #BIZ_OUT_DataBlock1
       SET Result        = REPLACE(@Results, '@3', ''),
           MessageType   = @MessageType,
           Status        = @Status
	  FROM #BIZ_OUT_DataBlock1 AS A
	 WHERE A.Status		= 0
	   AND A.WorkingTag IN ('A','U')
	   AND (A.Month01	< 0
	    OR  A.Month02	< 0
		OR	A.Month03	< 0
		OR	A.Month04	< 0
		OR	A.Month05	< 0
		OR	A.Month06	< 0
		OR	A.Month07	< 0
		OR	A.Month08	< 0
		OR  A.Month09	< 0
		OR	A.Month10	< 0
		OR	A.Month11	< 0
		OR	A.Month12	< 0)
	--------------------------------------------------------------------------------------
	-- üũ1, END
	--------------------------------------------------------------------------------------

    --------------------------------------------------------------------------------------
    -- üũ2, �⿹�긶��üũ
    --------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          5                  , -- �̹� @1��(��) �Ϸ�� @2�Դϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 5)  
                          @LanguageSeq       ,   
                          0,'�⿹�긶�� ',   -- SELECT * FROM _TCADictionary WHERE Word like '%����ī���ȣ%'  
                          0,'�ڷ�'  
    UPDATE #BIZ_OUT_DataBlock1  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #BIZ_OUT_DataBlock1 AS A   
                JOIN _TACBgtClosing AS B WITH(NOLOCK) ON A.StdYear = B.BgtYear AND A.AccUnit = B.AccUnit   
      WHERE B.CompanySeq = @CompanySeq   
        AND B.IsCfm = '1'  
        AND Status = 0  
    --------------------------------------------------------------------------------------
    -- üũ2, END
    --------------------------------------------------------------------------------------  
    --------------------------------------------------------------------------------------
    -- üũ3, ���ΰ��� ��꿬���� ������ ���Ϸ��� ������ ��ϵǾ� ���� �ʾ��� �� 
    --------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM _TDAAccFiscal WHERE CompanySeq = @CompanySeq AND FiscalYear IN (SELECT StdYear FROM #BIZ_OUT_DataBlock1))
    BEGIN
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              1170                  , -- @1�� @2��(��) ��ϵǾ� ���� �ʽ��ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%���%')    
                              @LanguageSeq       ,     
                              27121,'���ΰ��� ',   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'    
                              1749,'���꿬��' -- SELECT * FROM _TCADictionary WHERE Word like '%���꿬��%'    
  
        UPDATE #BIZ_OUT_DataBlock1    
           SET Result        = @Results,    
               MessageType   = @MessageType,    
               Status        = @Status  
    END  
    --------------------------------------------------------------------------------------
    -- üũ3, END 
    --------------------------------------------------------------------------------------
    --select 123, *from #BIZ_OUT_DataBlock1 
    --return 
    --------------------------------------------------------------------------------------
    -- üũ4, �ߺ����� üũ 
    --------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          0, ''--,  -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
                          --3543, '��2'  
      
    UPDATE #BIZ_OUT_DataBlock1  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #BIZ_OUT_DataBlock1 AS A   
      JOIN (SELECT S.StdYear, S.AccUnit, S.DeptSeq, S.CCtrSeq, S.AccSeq, S.UMCostType
              FROM (SELECT A1.StdYear, A1.AccUnit, A1.DeptSeq, A1.CCtrSeq, A1.AccSeq, A1.UMCostType
                      FROM #BIZ_OUT_DataBlock1 AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.StdYear, A1.AccUnit, A1.DeptSeq, A1.CCtrSeq, A1.AccSeq, A1.UMCostType
                      FROM mnpt_TACEEBgtAdj AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND AdjSeq = A1.AdjSeq   
                                      )  
                   ) AS S  
             GROUP BY S.StdYear, S.AccUnit, S.DeptSeq, S.CCtrSeq, S.AccSeq, S.UMCostType
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.StdYear = B.StdYear
                   AND A.AccUnit = B.AccUnit
                   AND A.DeptSeq = B.DeptSeq
                   AND A.CCtrSeq = B.CCtrSeq
                   AND A.AccSeq = B.AccSeq
                   AND A.UMCostType = B.UMCostType
                     )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    --------------------------------------------------------------------------------------
    -- üũ4, END 
    --------------------------------------------------------------------------------------

    --------------------------------------------------------------------------------------
    -- üũ5, ����������� ���� �� �� �ֽ��ϴ�.
    --------------------------------------------------------------------------------------
    UPDATE A
       SET Result = '����������� ���� �� �� �ֽ��ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1      AS A 
      LEFT OUTER JOIN _TDAAccount   AS B ON ( B.CompanySeq = @CompanySeq AND B.AccSeq = A.AccSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND B.SMBgtType <> 4005001 
    --------------------------------------------------------------------------------------
    -- üũ5, END 
    --------------------------------------------------------------------------------------    

    
    --return 
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'mnpt_TACEEBgtAdj', 'AdjSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #BIZ_OUT_DataBlock1  
           SET AdjSeq = @Seq + DataSeq   
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #BIZ_OUT_DataBlock1   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #BIZ_OUT_DataBlock1  
     WHERE Status = 0  
       AND ( AdjSeq = 0 OR AdjSeq IS NULL )  
    
    --update #BIZ_OUT_DataBlock1
    --   set status = 1234 
      
    RETURN  

    go
