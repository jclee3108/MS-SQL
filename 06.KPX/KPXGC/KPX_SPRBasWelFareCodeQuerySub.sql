  
IF OBJECT_ID('KPX_SPRBasWelFareCodeQuerySub') IS NOT NULL   
    DROP PROC KPX_SPRBasWelFareCodeQuerySub  
GO  
  
-- v2014.12.01  
  
-- �����Ļ��ڵ���-Item��ȸ by ����õ   
CREATE PROC KPX_SPRBasWelFareCodeQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- ��ȸ����   
            @WelCodeSeq INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @WelCodeSeq   = ISNULL( WelCodeSeq, 0 )
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (WelCodeSeq   INT)    
    
    -- ������ȸ   
    SELECT A.WelCodeSeq, 
           A.WelCodeSerl, 
           A.YY, 
           A.RegName, 
           A.DateFr, 
           A.DateTo, 
           A.EmpAmt
      FROM KPX_THRWelCodeYearItem AS A  
     WHERE A.CompanySeq = @CompanySeq  
       AND A.WelCodeSeq = @WelCodeSeq 
      ORDER BY A.WelCodeSerl  
    
    RETURN  