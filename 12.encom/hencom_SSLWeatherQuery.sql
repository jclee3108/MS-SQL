IF OBJECT_ID('hencom_SSLWeatherQuery') IS NOT NULL 
    DROP PROC hencom_SSLWeatherQuery
GO 

-- v2017.03.23 

/************************************************************
 ��  �� - ������-�������_hencom : ��ȸ
 �ۼ��� - 20151014
 �ۼ��� - ������
************************************************************/
CREATE PROC dbo.hencom_SSLWeatherQuery                
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
	
	DECLARE @docHandle     INT,
		    @WeatherRegSeq INT ,
            @DeptSeq       INT ,
            @BasicYm       NCHAR(6)  
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @WeatherRegSeq = WeatherRegSeq  ,
            @DeptSeq       = DeptSeq        ,
            @BasicYm       = BasicYm        
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (WeatherRegSeq  INT ,
            DeptSeq        INT ,
            BasicYm        NCHAR(6) )
	
	SELECT  A.CompanySeq  ,
	        A.WeatherRegSeq , A.WDate         , A.UMWeather     , A.WeatherStatus      , A.Remark        , 
            A.LastUserSeq   ,
			(SELECT UserName FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = A.LastUserSeq)  AS LastUserName,
			A.LastDateTime  , A.DeptSeq       , B.DeptName, A.Temperature
      FROM  hencom_TSLWeather AS A WITH (NOLOCK)  
	    LEFT OUTER JOIN   _TDADept AS B WITH (NOLOCK)   ON A.CompanySeq  = B.CompanySeq
	                                                   AND A.DeptSeq     = B.DeptSeq
	 WHERE  A.CompanySeq            = @CompanySeq
      ---  AND A.WeatherRegSeq         = @WeatherRegSeq 
        AND A.DeptSeq               = @DeptSeq       
        AND SUBSTRING(A.WDate,1,6)  = @BasicYm       
		
RETURN
