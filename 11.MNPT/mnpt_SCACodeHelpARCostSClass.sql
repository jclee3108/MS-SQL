IF OBJECT_ID('mnpt_SCACodeHelpARCostSClass') IS NOT NULL 
    DROP PROC mnpt_SCACodeHelpARCostSClass
GO 
-- v2018.01.08 

-- ���Һз� by����õ           
CREATE PROCEDURE mnpt_SCACodeHelpARCostSClass                       
    @WorkingTag     NVARCHAR(1),                  
    @LanguageSeq    INT,                  
    @CodeHelpSeq    INT,                  
    @DefQueryOption INT, -- 2: direct search                  
    @CodeHelpType   TINYINT,                  
    @PageCount      INT = 20,       
    @CompanySeq     INT = 1,                 
    @Keyword        NVARCHAR(200) = '',    -- �������   -- �Էµ� Ű���带 ���������� �������� ���� Ǯ�������� ��ȸ �� ��ȸ���� �ʾ� ������. (���񽺿�û��ȣ : 201605300174) 2016.05.31 by sryoun          
    @Param1         NVARCHAR(50) = '',    -- ����ڵ�
    @Param2         NVARCHAR(50) = '',    -- 
    @Param3         NVARCHAR(50) = '',      
    @Param4         NVARCHAR(50) = ''      
AS  
    SET ROWCOUNT @PageCount
    
    -- ����׸� ���߼� �з� 
    SELECT C.MinorSeq AS CostSClassSeq, C.MinorName AS CostSClassName, -- 'ǰ��Һз�'   
           E.MinorSeq AS CostMClassSeq, E.MinorName AS CostMClassName, -- 'ǰ���ߺз�'   
           G.MinorSeq AS CostLClassSeq, G.MinorName AS CostLClassName  -- 'ǰ���з�'  
      FROM _TDAUMinor                 AS C WITH(NOLOCK)   
      LEFT OUTER JOIN _TDAUMinorValue AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND C.MinorSeq = D.MinorSeq AND D.Serl = 1000001 ) 
      -- �ߺз�   
      LEFT OUTER JOIN _TDAUMinor  AS E WITH(NOLOCK) ON ( D.ValueSeq = E.MinorSeq AND D.CompanySeq = E.CompanySeq )--AND E.IsUse = '1' )  
      LEFT OUTER JOIN _TDAUMinorValue AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND E.MinorSeq = F.MinorSeq AND F.Serl = 1000001 ) 
      -- ��з�   
      LEFT OUTER JOIN _TDAUMinor  AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND F.ValueSeq = G.MinorSeq ) 
     WHERE C.CompanySeq = @CompanySeq
       AND C.MajorSeq = 1016729 
       AND (@Keyword = '' OR C.MinorName LIKE @Keyword + '%') 
     ORDER BY C.MinorSort
    
    SET ROWCOUNT 0
RETURN
go
--exec _SCACodeHelpQuery @WorkingTag=N'Q',@CompanySeq=1,@LanguageSeq=1,@CodeHelpSeq=N'13820039',@Keyword=N'%%',@Param1=N'',@Param2=N'',@Param3=N'',@Param4=N'',@ConditionSeq=N'1',@PageCount=N'1',@PageSize=N'50',@SubConditionSql=N'',@AccUnit=N'1',@BizUnit=1,@FactUnit=1,@DeptSeq=1,@WkDeptSeq=18,@EmpSeq=64,@UserSeq=167