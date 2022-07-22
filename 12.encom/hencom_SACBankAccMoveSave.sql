  
IF OBJECT_ID('hencom_SACBankAccMoveSave') IS NOT NULL   
    DROP PROC hencom_SACBankAccMoveSave  
GO  
  
-- v2017.05.15
  
-- ���°��̵��Է�-���� by ����õ
CREATE PROC hencom_SACBankAccMoveSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_TACBankAccMove (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACBankAccMove'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TACBankAccMove')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'hencom_TACBankAccMove'    , -- ���̺��        
                  '#hencom_TACBankAccMove'    , -- �ӽ� ���̺��        
                  'MoveSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACBankAccMove WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #hencom_TACBankAccMove   AS A   
          JOIN hencom_TACBankAccMove    AS B ON ( B.CompanySeq = @CompanySeq AND A.MoveSeq = B.MoveSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACBankAccMove WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.StdDate        = A.StdDate       ,  
               B.OutBankAccSeq  = A.OutBankAccSeq ,  
               B.OutAmt         = A.OutAmt        ,  
               B.InBankAccSeq   = A.InBankAccSeq  ,  
               B.InAmt          = A.InAmt         ,  
               B.AddAmt         = A.AddAmt        ,  
               B.DrAccSeq       = A.DrAccSeq      ,  
               B.CrAccSeq       = A.CrAccSeq      ,  
               B.AddAccSeq      = A.AddAccSeq     ,  
               B.Remark         = A.Remark        ,
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
          FROM #hencom_TACBankAccMove   AS A   
          JOIN hencom_TACBankAccMove    AS B ON ( B.CompanySeq = @CompanySeq AND A.MoveSeq = B.MoveSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TACBankAccMove WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO hencom_TACBankAccMove  
        (   
            CompanySeq, MoveSeq, StdDate, OutBankAccSeq, OutAmt, 
            InBankAccSeq, InAmt, AddAmt, DrAccSeq, CrAccSeq, 
            AddAccSeq, Remark, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, A.MoveSeq, A.StdDate, A.OutBankAccSeq, A.OutAmt, 
               A.InBankAccSeq, A.InAmt, A.AddAmt, A.DrAccSeq, A.CrAccSeq, 
               A.AddAccSeq, A.Remark, @UserSeq, GETDATE(), @PgmSeq 
          FROM #hencom_TACBankAccMove AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #hencom_TACBankAccMove   
    
    RETURN  
GO
begin tran 
exec hencom_SACBankAccMoveSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <StdDate>20170501</StdDate>
    <OutBankAccName>����2</OutBankAccName>
    <OutAmt>200000.00000</OutAmt>
    <InBankAccName>�׽�Ʈ����</InBankAccName>
    <InAmt>90000.00000</InAmt>
    <AddAmt>110000.00000</AddAmt>
    <OutBankAccNo>140-008-670759</OutBankAccNo>
    <OutBankName>��������</OutBankName>
    <InBankAccNo>123123123</InBankAccNo>
    <InBankName>�׽�Ʈ�����������</InBankName>
    <DrAccName>������</DrAccName>
    <CrAccName>�������_��Ÿȸ����</CrAccName>
    <AddAccName>�ŵ����ɱ����ڻ�_�������ä������</AddAccName>
    <MoveSeq>8</MoveSeq>
    <DrAccSeq>7</DrAccSeq>
    <CrAccSeq>401</CrAccSeq>
    <AddAccSeq>412</AddAccSeq>
    <OutBankAccSeq>5</OutBankAccSeq>
    <InBankAccSeq>1</InBankAccSeq>
    <Remark>2</Remark>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512197,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033591
rollback 