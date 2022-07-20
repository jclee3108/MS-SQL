IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id('mnpt_SCACodeHelpPJTTypeClassLQuery'))
DROP PROCEDURE dbo.mnpt_SCACodeHelpPJTTypeClassLQuery
GO  
  /************************************************************
 ��  ��		- �����ȸȭ���� ȭ�� ��з� �ڵ嵵�� 
 �ۼ���		- 2017�� 9�� 12��  
 �ۼ���		- ����
 ��������		- 
 ************************************************************/
CREATE PROCEDURE mnpt_SCACodeHelpPJTTypeClassLQuery
	@WorkingTag     NVARCHAR(1),                    
    @LanguageSeq    INT,                    
    @CodeHelpSeq    INT,                    
    @DefQueryOption INT, -- 2: direct search                    
    @CodeHelpType   TINYINT,                    
    @PageCount      INT = 20,         
    @CompanySeq     INT = 1,                   
    @Keyword        NVARCHAR(50) = '',                    
    @Param1         NVARCHAR(50) = '',        
    @Param2         NVARCHAR(50) = '',        
    @Param3         NVARCHAR(50) = '',        
    @Param4         NVARCHAR(50) = ''        
AS     

    DECLARE @PJTTypeClassLSeq INT 
    SELECT @PJTTypeClassLSeq = EnvValue 
      FROM mnpt_TCOMEnv 
     WHERE CompanySeq = @CompanySeq 
       AND EnvSeq = 18 

	SELECT A.ItemClassLName		AS PJTTypeClassLName,	--ȭ�´�з�
		   A.ItemClassLSeq		AS PJTTypeClassLSeq  	--ȭ�´�з��ڵ�
	  FROM _VDAItemClass AS A 
	 WHERE A.CompanySeq	= @CompanySeq
	   AND (@Keyword	= '' OR A.ItemClassLName LIKE @Keyword)
       AND A.ItemClassLSeq = @PJTTypeClassLSeq 
	   AND EXISTS (
					SELECT 1
					  FROM _TPJTType
					 WHERE CompanySeq	= @CompanySeq
					   AND ItemClassSeq	= A.ItemClassSSeq
				)
     ORDER BY A.ItemClassLName