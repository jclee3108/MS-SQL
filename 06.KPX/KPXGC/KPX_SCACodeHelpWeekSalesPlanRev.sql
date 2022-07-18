
IF OBJECT_ID('KPX_SCACodeHelpWeekSalesPlanRev') IS NOT NULL 
    DROP PROC KPX_SCACodeHelpWeekSalesPlanRev
GO 

-- v2014.11.14   
    
-- �ְ��ǸŰ�ȹ-�����ڵ嵵�� by ����õ   
CREATE PROC KPX_SCACodeHelpWeekSalesPlanRev    
    @WorkingTag     NVARCHAR(1),                            
    @LanguageSeq    INT,                            
    @CodeHelpSeq    INT,                            
    @DefQueryOption INT,          
    @CodeHelpType   TINYINT,                            
    @PageCount      INT = 20,                 
    @CompanySeq     INT = 1,                           
    @Keyword        NVARCHAR(200) = '',                            
    @Param1         NVARCHAR(50) = '',      -- ����ι�  
    @Param2         NVARCHAR(50) = '',      -- ��ȹ���  
    @Param3         NVARCHAR(50) = '',                
    @Param4         NVARCHAR(50) = ''   
    
    WITH RECOMPILE          
AS    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED        
      
    SET ROWCOUNT @PageCount          
      
    SELECT PlanRev,   
           CONVERT(INT,PlanRev) AS PlanRevSeq   
      FROM KPX_TSLWeekSalesPlanRev   
     WHERE CompanySeq = @CompanySeq   
       AND BizUnit = CONVERT(INT,@Param1)   
       AND WeekSeq = CONVERT(INT,@Param2) 
       AND PlanRev LIKE @Keyword + '%'    
      
    SET ROWCOUNT 0    
      
    RETURN    