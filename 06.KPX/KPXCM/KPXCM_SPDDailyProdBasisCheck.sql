  
IF OBJECT_ID('KPXCM_SPDDailyProdBasisCheck') IS NOT NULL   
    DROP PROC KPXCM_SPDDailyProdBasisCheck  
GO  
  
-- v2016.05.10  
  
-- ���ϻ��귮�������������Է�(�������)-üũ by ����õ   
CREATE PROC KPXCM_SPDDailyProdBasisCheck  
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
      
    CREATE TABLE #KPXCM_TPDDailyProdBasis( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDDailyProdBasis'   
    IF @@ERROR <> 0 RETURN     
    
    CREATE TABLE #KPXCM_TPDDailyProdBasisItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TPDDailyProdBasisItem'   
    IF @@ERROR <> 0 RETURN     
    
    -- üũ1, ������������ �ߺ����� �ԷµǾ����ϴ�.
    UPDATE #KPXCM_TPDDailyProdBasis  
       SET Result       = '������������ �ߺ����� �ԷµǾ����ϴ�.',  
           MessageType  = 1234,  
           Status       = 1234  
      FROM #KPXCM_TPDDailyProdBasis AS A   
      JOIN (SELECT S.UnitProcName, S.UMItemKind
              FROM (SELECT A1.UnitProcName, A1.UMItemKind
                      FROM #KPXCM_TPDDailyProdBasis AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.UnitProcName, A1.UMItemKind
                      FROM KPXCM_TPDDailyProdBasis AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPXCM_TPDDailyProdBasis   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND UnitProcSeq = A1.UnitProcSeq  
                                                 AND UMItemKind = A1.UMItemKind 
                                      )  
                   ) AS S  
             GROUP BY S.UnitProcName, S.UMItemKind
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.UnitProcName = B.UnitProcName AND A.UMItemKind = B.UMItemKind )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    -- üũ1, END 
    
    -- üũ2, ��ȸ������ �ߺ����� �ԷµǾ����ϴ�.
    UPDATE #KPXCM_TPDDailyProdBasis  
       SET Result       = '��ȸ������ �ߺ����� �ԷµǾ����ϴ�.',  
           MessageType  = 1234,  
           Status       = 1234  
      FROM #KPXCM_TPDDailyProdBasis AS A   
      JOIN (SELECT S.Sort, S.UMItemKind
              FROM (SELECT A1.Sort, A1.UMItemKind
                      FROM #KPXCM_TPDDailyProdBasis AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.Sort, A1.UMItemKind
                      FROM KPXCM_TPDDailyProdBasis AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPXCM_TPDDailyProdBasis   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND UnitProcSeq = A1.UnitProcSeq  
                                                 AND UMItemKind = A1.UMItemKind 
                                      )  
                   ) AS S  
             GROUP BY S.Sort, S.UMItemKind
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.Sort = B.Sort AND A.UMItemKind = B.UMItemKind )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    -- üũ2, END 
    
    -- üũ3, ǰ���� �ߺ����� �ԷµǾ����ϴ�.
    UPDATE #KPXCM_TPDDailyProdBasisItem  
       SET Result       = 'ǰ���� �ߺ����� �ԷµǾ����ϴ�.',  
           MessageType  = 1234,  
           Status       = 1234  
      FROM #KPXCM_TPDDailyProdBasisItem AS A   
      JOIN (SELECT S.UnitProcSeq, S.ItemSeq
              FROM (SELECT A1.UnitProcSeq, A1.ItemSeq
                      FROM #KPXCM_TPDDailyProdBasisItem AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.UnitProcSeq, A1.ItemSeq
                      FROM KPXCM_TPDDailyProdBasisItem AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPXCM_TPDDailyProdBasisItem  
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND UnitProcSeq = A1.UnitProcSeq  
                                                 AND ItemSeqOld = A1.ItemSeq 
                                      )  
                   ) AS S  
             GROUP BY S.UnitProcSeq, S.ItemSeq
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.UnitProcSeq = B.UnitProcSeq AND A.ItemSeq = B.ItemSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    -- üũ3, END 
    /*
    -- üũ4, ��ȸ������ �ߺ����� �ԷµǾ����ϴ�.
    UPDATE #KPXCM_TPDDailyProdBasisItem  
       SET Result       = '��ȸ������ �ߺ����� �ԷµǾ����ϴ�.',  
           MessageType  = 1234,  
           Status       = 1234  
      FROM #KPXCM_TPDDailyProdBasisItem AS A   
      JOIN (SELECT S.UnitProcSeq, S.Sort
              FROM (SELECT A1.UnitProcSeq, A1.Sort
                      FROM #KPXCM_TPDDailyProdBasisItem AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.UnitProcSeq, A1.Sort
                      FROM KPXCM_TPDDailyProdBasisItem AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPXCM_TPDDailyProdBasisItem  
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND UnitProcSeq = A1.UnitProcSeq  
                                                 AND ItemSeqOld = A1.ItemSeq 
                                      )  
                   ) AS S  
             GROUP BY S.UnitProcSeq, S.Sort
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.UnitProcSeq = B.UnitProcSeq AND A.Sort = B.Sort )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    -- üũ4, END 
    */
    -- üũ5, ��ǰ, ����ǰ, ���ǰ�� �Է� �� �� �ֽ��ϴ�. 
    UPDATE A
       SET Result = '��ǰ, ����ǰ, ���ǰ�� �Է� �� �� �ֽ��ϴ�.', 
           MessageType = 1234, 
           Status = 1234 
      FROM #KPXCM_TPDDailyProdBasisItem AS A 
      JOIN _TDAItem                     AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      JOIN _TDAItemAsset                AS C ON ( C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND C.SMAssetGrp NOT IN ( 6008004, 6008005 ) 
    -- üũ5, END 
    
    -- ��ȣ+�ڵ� ���� :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TPDDailyProdBasis WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- Ű�������ڵ�κ� ����  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TPDDailyProdBasis', 'UnitProcSeq', @Count  
          
        -- Temp Talbe �� ������ Ű�� UPDATE  
        UPDATE #KPXCM_TPDDailyProdBasis  
           SET UnitProcSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- �����ڵ� 0�� �� �� ����ó��   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- ó���۾��߿������߻��߽��ϴ�. �ٽ�ó���Ͻʽÿ�!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXCM_TPDDailyProdBasis   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXCM_TPDDailyProdBasis  
     WHERE Status = 0  
       AND ( UnitProcSeq = 0 OR UnitProcSeq IS NULL )  
      
    SELECT * FROM #KPXCM_TPDDailyProdBasis
    SELECT * FROM #KPXCM_TPDDailyProdBasisItem 
      
    RETURN  
    go
    begin tran 
exec KPXCM_SPDDailyProdBasisCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Sort>1</Sort>
    <UnitProcSeq>1</UnitProcSeq>
    <ItemName>KE-810</ItemName>
    <ItemNo>41290021</ItemNo>
    <ItemSeq>147</ItemSeq>
    <ItemSeqOld>81898</ItemSeqOld>
    <ItemPrtName>��ǰ</ItemPrtName>
    <ConvDen>0</ConvDen>
    <Remark />
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1036949,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1030269
rollback 