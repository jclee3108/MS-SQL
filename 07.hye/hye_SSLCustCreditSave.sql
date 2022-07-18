   
IF OBJECT_ID('hye_SSLCustCreditSave') IS NOT NULL     
    DROP PROC hye_SSLCustCreditSave    
GO    
    
-- v2016.08.29  
    
-- �ŷ�ó�������ѵ����_hye-���� by ����õ 
CREATE PROC hye_SSLCustCreditSave    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS      
        
    CREATE TABLE #hye_TDACustLimitInfo (WorkingTag NCHAR(1) NULL)      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#hye_TDACustLimitInfo'     
    IF @@ERROR <> 0 RETURN      
        
    -- �α� �����      
    DECLARE @TableColumns NVARCHAR(4000)      
        
    -- Master �α�     
    SELECT @TableColumns = dbo._FGetColumnsForLog('hye_TDACustLimitInfo')      
        
    EXEC _SCOMLog @CompanySeq   ,          
                  @UserSeq      ,          
                  'hye_TDACustLimitInfo'    , -- ���̺��          
                  '#hye_TDACustLimitInfo'    , -- �ӽ� ���̺��          
                  'CustSeq,LimitSerl'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )          
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��     
        
    -- DELETE        
    IF EXISTS ( SELECT TOP 1 1 FROM #hye_TDACustLimitInfo WHERE WorkingTag = 'D' AND Status = 0 )      
    BEGIN      
            
        DELETE B     
          FROM #hye_TDACustLimitInfo AS A     
          JOIN hye_TDACustLimitInfo AS B ON ( B.CompanySeq = @CompanySeq AND A.CustSeq = B.CustSeq AND A.LimitSerl = B.LimitSerl )     
         WHERE A.WorkingTag = 'D'     
           AND A.Status = 0     
            
        IF @@ERROR <> 0  RETURN    
    
    END      
        
    -- UPDATE        
    IF EXISTS ( SELECT TOP 1 1 FROM #hye_TDACustLimitInfo WHERE WorkingTag = 'U' AND Status = 0 )      
    BEGIN    
            
        UPDATE B     
           SET B.UMLimitKind    = A.UMLimitKind,    
               B.LimitAmt       = A.LimitAmt,    
               B.SrtDate        = A.SrtDate,    
               B.EndDate        = A.EndDate,    
               B.Remark         = A.Remark,    
               B.LastUserSeq    = @UserSeq,    
               B.LastDateTime   = GETDATE(),    
               B.PgmSeq         = @PgmSeq      
          FROM #hye_TDACustLimitInfo   AS A     
          JOIN hye_TDACustLimitInfo    AS B ON ( B.CompanySeq = @CompanySeq AND A.CustSeq = B.CustSeq AND A.LimitSerl = B.LimitSerl )     
         WHERE A.WorkingTag = 'U'     
           AND A.Status = 0        
            
        IF @@ERROR <> 0  RETURN    
            
    END 
            
    -- INSERT    
    IF EXISTS ( SELECT TOP 1 1 FROM #hye_TDACustLimitInfo WHERE WorkingTag = 'A' AND Status = 0 )      
    BEGIN      
            
        INSERT INTO hye_TDACustLimitInfo    
        (     
            CompanySeq, CustSeq, LimitSerl, UMLimitKind, LimitAmt, 
            SrtDate, EndDate, Remark, LastUserSeq, LastDateTime, 
            PgmSeq, SumLimitAmt, OkLimitAmt
        )     
        SELECT @CompanySeq, A.CustSeq, A.LimitSerl, A.UMLimitKind, A.LimitAmt, 
               A.SrtDate, A.EndDate, A.Remark, @UserSeq, GETDATE(), 
               @PgmSeq, 0, 0 
          FROM #hye_TDACustLimitInfo AS A     
         WHERE A.WorkingTag = 'A'     
           AND A.Status = 0        
            
        IF @@ERROR <> 0 RETURN    
    
    END       
        
    SELECT * FROM #hye_TDACustLimitInfo     
    
    RETURN   
