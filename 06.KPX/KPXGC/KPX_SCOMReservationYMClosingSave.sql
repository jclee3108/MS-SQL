  
IF OBJECT_ID('KPX_SCOMReservationYMClosingSave') IS NOT NULL   
    DROP PROC KPX_SCOMReservationYMClosingSave  
GO  
  
-- v2015.07.28  
  
-- ���ึ������-���� by ����õ   
CREATE PROC KPX_SCOMReservationYMClosingSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TCOMReservationYMClosing (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TCOMReservationYMClosing'   
    IF @@ERROR <> 0 RETURN    
      
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TCOMReservationYMClosing')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TCOMReservationYMClosing'    , -- ���̺��        
                  '#KPX_TCOMReservationYMClosing'    , -- �ӽ� ���̺��        
                  'ClosingSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TCOMReservationYMClosing WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.ReservationDate = A.ReservationDate,  
               B.ReservationTime = A.ReservationTime, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
          FROM #KPX_TCOMReservationYMClosing AS A   
          JOIN KPX_TCOMReservationYMClosing AS B ON ( B.CompanySeq = @CompanySeq AND B.ClosingSeq = A.ClosingSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TCOMReservationYMClosing WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TCOMReservationYMClosing  
        (   
            CompanySeq,ClosingSeq,ClosingYM,AccUnit,IsCancel,  
            ReservationDate,ReservationTime,ProcDate,ProcResult,LastUserSeq,  
            LastDateTime,PgmSeq   
        )   
          SELECT @CompanySeq,A.ClosingSeq,A.ClosingYM,A.AccUnit,A.IsCancel,  
               A.ReservationDate,A.ReservationTime,NULL,NULL,@UserSeq,  
               GETDATE(),@PgmSeq   
          FROM #KPX_TCOMReservationYMClosing AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #KPX_TCOMReservationYMClosing   
      
    RETURN  