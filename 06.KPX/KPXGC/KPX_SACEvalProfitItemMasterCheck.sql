  
IF OBJECT_ID('KPX_SACEvalProfitItemMasterCheck') IS NOT NULL   
    DROP PROC KPX_SACEvalProfitItemMasterCheck  
GO  
  
-- v2014.12.20  
  
-- �򰡼��ͻ�ǰ������-üũ by ����õ   
CREATE PROC KPX_SACEvalProfitItemMasterCheck  
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
            @Results        NVARCHAR(250), 
            @MaxNo          NVARCHAR(10) 
    
    CREATE TABLE #KPX_TACEvalProfitItemMaster( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACEvalProfitItemMaster'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT @MaxNo = CONVERT(INT,MAX(RIGHT(FundNo,4))) FROM KPX_TACEvalProfitItemMaster WHERE CompanySeq = @CompanySeq AND StdDate = (SELECT TOP 1 StdDate FROM #KPX_TACEvalProfitItemMaster) 
    
    
    UPDATE A 
       SET FundNo = CASE WHEN @CompanySeq = 1 THEN 'A'
                         WHEN @CompanySeq = 2 THEN 'B'
                         WHEN @CompanySeq = 3 THEN 'C'
                         WHEN @CompanySeq = 4 THEN 'D'
                         ELSE 'E'
                    END  + '-' + A.StdDate + '-' + RIGHT('000' + CONVERT(NVARCHAR(10),ISNULL(@MaxNo,0) + DataSeq),4)
                    
                         
      FROM #KPX_TACEvalProfitItemMaster AS A 
    
    /*
    -- �ߺ����� üũ :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          3542, '��1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%��%'  
                          --3543, '��2'  
      
    UPDATE #TSample  
       SET Result       = REPLACE( @Results, '@2', B.SampleName ), -- Ȥ�� @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #TSample AS A   
      JOIN (SELECT S.SampleName  
              FROM (SELECT A1.SampleName  
                      FROM #TSample AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.SampleName  
                      FROM _TSample AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #TSample   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND SampleSeq = A1.SampleSeq  
                                      )  
                   ) AS S  
             GROUP BY S.SampleName  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.SampleName = B.SampleName )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    */
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TACEvalProfitItemMaster WHERE WorkingTag = 'A' AND Status = 0  
    
    IF @Count > 0  
    BEGIN 
          
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TACEvalProfitItemMaster', 'EvalProfitSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPX_TACEvalProfitItemMaster  
           SET EvalProfitSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE A   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TACEvalProfitItemMaster AS A  
     WHERE Status = 0  
       AND ( EvalProfitSeq = 0 OR EvalProfitSeq IS NULL )  
    
    SELECT * FROM #KPX_TACEvalProfitItemMaster   
    
    RETURN  
GO 
begin tran 
exec KPX_SACEvalProfitItemMasterCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMHelpComName>����ȸ��1</UMHelpComName>
    <UMHelpCom>1010494001</UMHelpCom>
    <FundCode>101042800210104290020005</FundCode>
    <FundName>1233545asdf435345aa</FundName>
    <FundSeq>6</FundSeq>
    <FundNo />
    <FundKindName>��ǰ��з�2</FundKindName>
    <FundKindLName>��ǰ����2</FundKindLName>
    <FundKindMName>��ǰ�ߺз�2</FundKindMName>
    <FundKindSName>��ǰ�Һз�1</FundKindSName>
    <TitileName />
    <SrtDate />
    <DurDate />
    <ActAmt>0</ActAmt>
    <PrevAmt>0</PrevAmt>
    <InvestAmt>0</InvestAmt>
    <TestAmt>0</TestAmt>
    <AddAmt>0</AddAmt>
    <DiffActDate>0</DiffActDate>
    <TagetAdd>0</TagetAdd>
    <StdAdd>0</StdAdd>
    <Risk />
    <TrustLevel />
    <Remark1 />
    <Remark2 />
    <Remark3 />
    <EvalProfitSeq>0</EvalProfitSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <StdDate>20141222</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMHelpComName>����ȸ��2</UMHelpComName>
    <UMHelpCom>1010494002</UMHelpCom>
    <FundCode>101042800210104290020006</FundCode>
    <FundName>teset</FundName>
    <FundSeq>8</FundSeq>
    <FundNo />
    <FundKindName>��ǰ��з�2</FundKindName>
    <FundKindLName>��ǰ����2</FundKindLName>
    <FundKindMName>��ǰ�ߺз�2</FundKindMName>
    <FundKindSName>��ǰ�Һз�1</FundKindSName>
    <TitileName>123</TitileName>
    <SrtDate />
    <DurDate />
    <ActAmt>0</ActAmt>
    <PrevAmt>0</PrevAmt>
    <InvestAmt>0</InvestAmt>
    <TestAmt>0</TestAmt>
    <AddAmt>0</AddAmt>
    <DiffActDate>0</DiffActDate>
    <TagetAdd>0</TagetAdd>
    <StdAdd>0</StdAdd>
    <Risk />
    <TrustLevel />
    <Remark1 />
    <Remark2 />
    <Remark3 />
    <EvalProfitSeq>0</EvalProfitSeq>
    <StdDate>20141222</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMHelpComName>����ȸ��3</UMHelpComName>
    <UMHelpCom>1010494003</UMHelpCom>
    <FundCode>101042800210104290020007</FundCode>
    <FundName>teset11</FundName>
    <FundSeq>9</FundSeq>
    <FundNo />
    <FundKindName>��ǰ��з�2</FundKindName>
    <FundKindLName>��ǰ����2</FundKindLName>
    <FundKindMName>��ǰ�ߺз�2</FundKindMName>
    <FundKindSName>��ǰ�Һз�1</FundKindSName>
    <TitileName>123</TitileName>
    <SrtDate />
    <DurDate />
    <ActAmt>0</ActAmt>
    <PrevAmt>0</PrevAmt>
    <InvestAmt>0</InvestAmt>
    <TestAmt>0</TestAmt>
    <AddAmt>0</AddAmt>
    <DiffActDate>0</DiffActDate>
    <TagetAdd>0</TagetAdd>
    <StdAdd>0</StdAdd>
    <Risk />
    <TrustLevel />
    <Remark1 />
    <Remark2 />
    <Remark3 />
    <EvalProfitSeq>0</EvalProfitSeq>
    <StdDate>20141222</StdDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026966,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020380

rollback 