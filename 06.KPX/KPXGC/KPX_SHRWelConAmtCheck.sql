  
IF OBJECT_ID('KPX_SHRWelConAmtCheck') IS NOT NULL   
    DROP PROC KPX_SHRWelConAmtCheck  
GO  
  
-- v2014.11.27  
  
-- ���������ޱ��ص��-üũ by ����õ   
CREATE PROC KPX_SHRWelConAmtCheck  
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
    
    CREATE TABLE #KPX_THRWelConAmt( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelConAmt'   
    IF @@ERROR <> 0 RETURN     
    
    -- �ߺ����� üũ :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%�ߺ�%')  
                          @LanguageSeq       ,  
                          0

    UPDATE #KPX_THRWelConAmt  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_THRWelConAmt AS A   
      JOIN (SELECT S.SMConMutual, S.ConSeq, S.WkItemSeq  
              FROM (SELECT A1.SMConMutual, A1.ConSeq, A1.WkItemSeq    
                      FROM #KPX_THRWelConAmt AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.SMConMutual, A1.ConSeq, A1.WkItemSeq   
                      FROM KPX_THRWelConAmt AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_THRWelConAmt   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND SMConMutual = A1.SMConMutual   
                                                 AND ConSeq = A1.ConSeq 
                                                 AND WkItemSeqOld = A1.WkItemSeq 
                                      )  
                   ) AS S  
             GROUP BY S.SMConMutual, S.ConSeq, S.WkItemSeq  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.SMConMutual = B.SMConMutual AND A.ConSeq = B.ConSeq AND A.WkItemSeq = B.WkItemSeq)  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    SELECT * FROM #KPX_THRWelConAmt   
    
    RETURN  
    
    
