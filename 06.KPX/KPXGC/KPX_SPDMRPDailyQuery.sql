  
IF OBJECT_ID('KPX_SPDMRPDailyQuery') IS NOT NULL   
    DROP PROC KPX_SPDMRPDailyQuery  
GO  
  
-- v2014.12.15  
  
-- �Ϻ�����ҿ���-��ȸ by ����õ   
CREATE PROC KPX_SPDMRPDailyQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle      INT,  
            -- ��ȸ����   
            @MRPDailySeq    INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @MRPDailySeq = ISNULL( MRPDailySeq, 0 )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (MRPDailySeq   INT)    
      
    -- ������ȸ   
    SELECT A.MRPDailySeq, 
           A.DateFr, 
           A.DateTo, 
           A.MRPNo, 
           STUFF(STUFF(A.PlanDate, 5,0,'-'),8,0,'-') + ' ' + STUFF(A.PlanTime,3,0,':') AS PlanDateTime, 
           A.SMInOutTypePur, 
           B.MinorName AS SMInOutTypePurName 
           
      FROM KPX_TPDMRPDaily AS A 
      LEFT OUTER JOIN _TDASMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMInOutTypePur ) 
    
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.MRPDailySeq = @MRPDailySeq )   

      
    RETURN  
GO 
exec KPX_SPDMRPDailyQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <MRPDailySeq>1</MRPDailySeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026771,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021414