IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id('mnpt_SCACodeHelpPJTTypeClassMQuery'))
DROP PROCEDURE dbo.mnpt_SCACodeHelpPJTTypeClassMQuery
GO  
  /************************************************************
 ��  ��		- �����ȸȭ���� ȭ�� �ߺз� �ڵ嵵�� 
 �ۼ���		- 2017�� 9�� 12��  
 �ۼ���		- ����
 ��������		- 
 ************************************************************/
CREATE PROCEDURE mnpt_SCACodeHelpPJTTypeClassMQuery
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

	SELECT DISTINCT 
           A.ItemClassLName		AS PJTTypeClassLName,	--ȭ�´�з�
		   A.ItemClassMName		AS PJTTypeClassMName,	--ȭ���ߺз�
		   A.ItemClassLSeq		AS PJTTypeClassLSeq,	--ȭ�´�з��ڵ�
		   A.ItemClassMSeq		AS PJTTypeClassMSeq		--ȭ���ߺз��ڵ�
	  FROM _VDAItemClass AS A 
	 WHERE A.CompanySeq	= @CompanySeq
	   AND (@Keyword	= '' OR A.ItemClassMName LIKE @Keyword)
       AND A.ItemClassLSeq = @PJTTypeClassLSeq 
	   AND EXISTS (
					SELECT 1
					  FROM _TPJTType
					 WHERE CompanySeq	= @CompanySeq
					   AND ItemClassSeq	= A.ItemClassSSeq
				)
     ORDER BY A.ItemClassLName, A.ItemClassMName 