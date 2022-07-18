  
IF OBJECT_ID('KPX_SPRPayEstGrpRateQuery') IS NOT NULL   
    DROP PROC KPX_SPRPayEstGrpRateQuery  
GO  
  
-- v2014.12.15  
  
-- �޿����� ���޺��λ���-��ȸ by ����õ   
CREATE PROC KPX_SPRPayEstGrpRateQuery  
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
            @YY         NCHAR(4), 
            @UMPayType  INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @YY   = ISNULL( YY, 0 ), 
           @UMPayType = ISNULL( UMPayType, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (    
            YY          NCHAR(4), 
            UMPayType   INT 
           )    
    
    -- ������ȸ   
    SELECT A.YY, 
           A.UMPayType, 
           B.MinorName AS UMPayTypeName, -- �޿�����
           A.UMPgSeq, 
           C.MinorName AS UMPgName, -- ���� 
           A.UMPgSeq AS UMPgSeqOld, 
           A.EstRate, 
           A.AddRate, 
           A.Remark 
      FROM KPX_TPRPayEstGrpRate     AS A  
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMPayType ) 
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMPgSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.YY = @YY )   
       AND ( @UMPayType = A.UMPayType ) 
      
    RETURN  