IF OBJECT_ID('hencom_SSLWeatherSave') IS NOT NULL 
    DROP PROC hencom_SSLWeatherSave
GO 

-- v2017.03.23 

/************************************************************
 ��  �� - ������-�������_hencom : ����
 �ۼ��� - 20151013
 �ۼ��� - ������
************************************************************/
CREATE PROC dbo.hencom_SSLWeatherSave
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0  
AS   
	
	CREATE TABLE #hencom_TSLWeather (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TSLWeather'     
	IF @@ERROR <> 0 RETURN  
	    
	-- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
	EXEC _SCOMLog  @CompanySeq   ,
   				   @UserSeq      ,
   				   'hencom_TSLWeather', -- �����̺��
   				   '#hencom_TSLWeather', -- �������̺��
   				   'WeatherRegSeq  ' , -- Ű�� �������� ���� , �� �����Ѵ�. 
   				   'CompanySeq,  WeatherRegSeq  ,  WDate          ,UMWeather      ,WeatherStatus         ,Remark         ,LastUserSeq    ,LastDateTime   ,DeptSeq, Temperature '

	-- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
	-- DELETE    
	IF EXISTS (SELECT TOP 1 1 FROM #hencom_TSLWeather WHERE WorkingTag = 'D' AND Status = 0)  
	BEGIN  
			DELETE hencom_TSLWeather
			  FROM #hencom_TSLWeather A 
				   JOIN hencom_TSLWeather B ON ( A.WeatherRegSeq  = B.WeatherRegSeq ) 
                         
			 WHERE B.CompanySeq  = @CompanySeq
			   AND A.WorkingTag = 'D' 
			   AND A.Status = 0    
			 IF @@ERROR <> 0  RETURN
	END  

	-- UPDATE    
	IF EXISTS (SELECT 1 FROM #hencom_TSLWeather WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
			UPDATE hencom_TSLWeather
			   SET WDate          = A.WDate          ,
                   UMWeather      = A.UMWeather      ,
                   WeatherStatus  = A.WeatherStatus  ,
                   Remark         = A.Remark         ,
                   LastUserSeq    = @UserSeq         ,
                   LastDateTime   = GETDATE()        ,
                   DeptSeq        = A.DeptSeq        , 
                   Temperature    = A.Temperature
			  FROM #hencom_TSLWeather AS A 
			       JOIN hencom_TSLWeather AS B ON ( A.WeatherRegSeq  = B.WeatherRegSeq ) 
                         
			 WHERE B.CompanySeq = @CompanySeq
			   AND A.WorkingTag = 'U' 
			   AND A.Status = 0    
			   
			IF @@ERROR <> 0  RETURN
	END  
	-- INSERT
	IF EXISTS (SELECT 1 FROM #hencom_TSLWeather WHERE WorkingTag = 'A' AND Status = 0)  
	BEGIN  
			INSERT INTO hencom_TSLWeather ( CompanySeq , WeatherRegSeq  ,WDate          ,UMWeather      ,WeatherStatus         ,Remark         ,
                         LastUserSeq    ,LastDateTime   ,DeptSeq, Temperature        ) 
			SELECT @CompanySeq,  WeatherRegSeq  ,WDate          ,UMWeather      ,WeatherStatus         ,Remark         ,
                  @UserSeq      ,GETDATE()      ,DeptSeq        ,Temperature
			  FROM #hencom_TSLWeather AS A   
			 WHERE A.WorkingTag = 'A' 
			   AND A.Status = 0    
			IF @@ERROR <> 0 RETURN
	END   

	SELECT * FROM #hencom_TSLWeather 
RETURN
