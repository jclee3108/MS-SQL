  
IF OBJECT_ID('KPX_SQCCycleInspectionQuerySub') IS NOT NULL   
    DROP PROC KPX_SQCCycleInspectionQuerySub  
GO  
    
-- v2014.12.04  
  
-- �����˻��ֱ���-Item��ȸ by ����õ   
CREATE PROC KPX_SQCCycleInspectionQuerySub  
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
            @PlantSeq   INT,  
            @IsUse      NCHAR(1)  
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PlantSeq   = ISNULL( PlantSeq, 0 ),  
           @IsUse  = ISNULL( IsUse, '0' )  
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            PlantSeq    INT,   
            IsUse       NCHAR(1)
           )    
    
    -- ������ȸ   
    SELECT A.PlantSeq, 
           A.CycleSerl, 
           A.CycleTime, 
           A.Remark, 
           A.IsUse
      FROM KPX_TQCPlantCycle AS A 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @PlantSeq = 0 OR A.PlantSeq = @PlantSeq )   
       AND ( @IsUse = '0' OR @IsUse = A.IsUse ) 
    
    RETURN  