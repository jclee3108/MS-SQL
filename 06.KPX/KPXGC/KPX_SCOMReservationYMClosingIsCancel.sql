  
IF OBJECT_ID('KPX_SCOMReservationYMClosingIsCancel') IS NOT NULL   
    DROP PROC KPX_SCOMReservationYMClosingIsCancel  
GO  
  
-- v2015.07.28  

-- ���ึ������-������� by ����õ   
CREATE PROC KPX_SCOMReservationYMClosingIsCancel  
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
    
    UPDATE A 
       SET WorkingTag = 'U'
      FROM #KPX_TCOMReservationYMClosing AS A 
    
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
           SET B.IsCancel = A.IsCancel, 
               B.ReservationDate = CASE WHEN A.IsCancel = '1' THEN '' ELSE B.ReservationDate END, 
               B.ReservationTime = CASE WHEN A.IsCancel = '1' THEN '' ELSE B.ReservationTime END 
          FROM #KPX_TCOMReservationYMClosing AS A   
          JOIN KPX_TCOMReservationYMClosing AS B ON ( B.CompanySeq = @CompanySeq AND B.ClosingSeq = A.ClosingSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
        
    END    
    
    SELECT * FROM #KPX_TCOMReservationYMClosing 
    
    RETURN  
GO 
begin tran 
exec KPX_SCOMReservationYMClosingIsCancel @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsCancel>1</IsCancel>
    <ReservationDate>20150812</ReservationDate>
    <ReservationTime>04</ReservationTime>
    <ClosingSeq>8</ClosingSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031128,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025935
select * from KPX_TCOMReservationYMClosing 

rollback 