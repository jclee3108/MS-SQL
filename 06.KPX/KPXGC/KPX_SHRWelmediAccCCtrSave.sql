
IF OBJECT_ID('KPX_SHRWelmediAccCCtrSave') IS NOT NULL 
    DROP PROC KPX_SHRWelmediAccCCtrSave
GO 

-- v2014.12.08 

-- �Ƿ��������(Ȱ������)-���� by����õ
 CREATE PROCEDURE KPX_SHRWelmediAccCCtrSave
     @xmlDocument NVARCHAR(MAX)   ,    -- ȭ���� ������ XML�� ����  
     @xmlFlags    INT = 0         ,    -- �ش� XML�� TYPE  
     @ServiceSeq  INT = 0         ,    -- ���� ��ȣ  
     @WorkingTag  NVARCHAR(10)= '',    -- ��ŷ �±�  
     @CompanySeq  INT = 1         ,    -- ȸ�� ��ȣ  
     @LanguageSeq INT = 1         ,    -- ��� ��ȣ  
     @UserSeq     INT = 0         ,    -- ����� ��ȣ  
     @PgmSeq      INT = 0              -- ���α׷� ��ȣ  
   
 AS  
   
     -- XML�����͸� ���� �ӽ����̺� ����  
     CREATE TABLE #KPX_THRWelmediAccCCtr (WorkingTag NCHAR(1) NULL)  
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelmediAccCCtr'  
     IF @@ERROR <> 0 RETURN    -- ������ �߻��ϸ� ����   
    
    UPDATE A
       SET WorkingTag = 'A' 
      FROM #KPX_THRWelmediAccCCtr AS A 
     WHERE NOT EXISTS (SELECT 1 FROM KPX_THRWelmediAccCCtr WHERE CompanySeq = @CompanySeq AND YM = A.YM AND GroupSeq = A.GroupSeq AND WelCodeSeq = A.WelCodeSeq AND EnvValue = A.EnvValue)
       AND A.WorkingTag IN ( 'A','U' ) 
    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THRWelmediAccCCtr')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_THRWelmediAccCCtr'    , -- ���̺��        
                  '#KPX_THRWelmediAccCCtr'    , -- �ӽ� ���̺��        
                  'EnvValue,YM,GroupSeq,WelCodeSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
   
   
    -- DELETE  
    IF EXISTS (SELECT 1 FROM #KPX_THRWelmediAccCCtr WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
    
        DELETE B 
          FROM #KPX_THRWelmediAccCCtr AS A 
          JOIN KPX_THRWelmediAccCCtr AS B ON ( B.CompanySeq = @CompanySeq 
                                           AND A.EnvValue   = B.EnvValue  
                                           AND A.YM         = B.YM
                                           AND A.GroupSeq   = B.GroupSeq
                                           AND A.WelCodeSeq     = B.WelCodeSeq
                                             )
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0  
        
        IF @@ERROR <> 0 RETURN  
        
    END  
    
    -- UPDATE 
    IF EXISTS (SELECT 1 FROM #KPX_THRWelmediAccCCtr WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN  
    
        UPDATE B  
           SET AccSeq        = A.AccSeq,
               UMCostType    = A.UMCostType,
               OppAccSeq     = A.OppAccSeq,
               VatAccSeq     = A.VatAccSeq, 
               LastUserSeq   = @UserSeq,
               LastDateTime  = GETDATE() 
          FROM #KPX_THRWelmediAccCCtr AS A 
          JOIN KPX_THRWelmediAccCCtr  AS B ON ( B.CompanySeq    = @CompanySeq 
                                            AND A.EnvValue      = B.EnvValue  
                                            AND A.YM            = B.YM
                                            AND A.GroupSeq      = B.GroupSeq
                                            AND A.WelCodeSeq    = B.WelCodeSeq
                                              )
         WHERE A.WorkingTag = 'U'
           AND A.Status = 0  
        
        IF @@ERROR <> 0 RETURN    
    END 
    
    -- INSERT 
    IF EXISTS (SELECT 1 FROM #KPX_THRWelmediAccCCtr WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN 
        
        INSERT INTO KPX_THRWelmediAccCCtr
        (      
            CompanySeq, EnvValue, YM, GroupSeq, WelCodeSeq, 
            AccSeq, UMCostType, OppAccSeq, VatAccSeq, LastUserSeq, 
            LastDateTime
        )  
        SELECT @CompanySeq, A.EnvValue, A.YM, A.GroupSeq, A.WelCodeSeq, 
               A.AccSeq, A.UMCostType, A.OppAccSeq, A.VatAccSeq, @UserSeq, 
               GETDATE()
          FROM #KPX_THRWelmediAccCCtr AS A  
         WHERE A.WorkingTag = 'A'
           AND A.Status = 0
        
        IF @@ERROR <> 0 RETURN   
    
    END  
    
    SELECT * FROM #KPX_THRWelmediAccCCtr 
    
    RETURN