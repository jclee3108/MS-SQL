  
IF OBJECT_ID('KPX_SSLDelvItemPriceCurrQuery') IS NOT NULL   
    DROP PROC KPX_SSLDelvItemPriceCurrQuery  
GO  
  
-- v2014.11.12  
  
-- �ŷ�ó����ǰó�ܰ����-�ڱ���ȭ��ȸ by ����õ   
CREATE PROC KPX_SSLDelvItemPriceCurrQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    SELECT EnvValue AS CurrSeq         
      FROM _TCOMEnv AS A WITH (NOLOCK) 
     WHERE A.CompanySeq = @CompanySeq
       AND EnvSeq = 13
    
    RETURN

