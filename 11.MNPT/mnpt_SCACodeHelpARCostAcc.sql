IF OBJECT_ID('mnpt_SCACodeHelpARCostAcc') IS NOT NULL 
    DROP PROC mnpt_SCACodeHelpARCostAcc
GO 

-- v2018.01.08 

/*************************************************************************************************                    
ROCEDURE    - _SCACodeHelpARCostAcc                    
DESCRIPTION - ���ڰ��翬����� CodeHelp
��  ��  ��  - 2010�� 04�� 07��                    
��  ��  ��  - �۰�� 
*************************************************************************************************/             
CREATE PROCEDURE mnpt_SCACodeHelpARCostAcc                       
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
    -- ����׸� ���߼� �з� 
    SELECT C.MinorSeq AS CostSClassSeq, C.MinorName AS CostSClassName, -- 'ǰ��Һз�'   
           E.MinorSeq AS CostMClassSeq, E.MinorName AS CostMClassName, -- 'ǰ���ߺз�'   
           G.MinorSeq AS CostLClassSeq, G.MinorName AS CostLClassName  -- 'ǰ���з�'  
      INTO #CostClass
      FROM _TDAUMinor                 AS C WITH(NOLOCK)   
      LEFT OUTER JOIN _TDAUMinorValue AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND C.MinorSeq = D.MinorSeq AND D.Serl = 1000001 ) 
      -- �ߺз�   
      LEFT OUTER JOIN _TDAUMinor  AS E WITH(NOLOCK) ON ( D.ValueSeq = E.MinorSeq AND D.CompanySeq = E.CompanySeq )--AND E.IsUse = '1' )  
      LEFT OUTER JOIN _TDAUMinorValue AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND E.MinorSeq = F.MinorSeq AND F.Serl = 1000001 ) 
      -- ��з�   
      LEFT OUTER JOIN _TDAUMinor  AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND F.ValueSeq = G.MinorSeq ) 
     WHERE C.CompanySeq = @CompanySeq
       AND C.MajorSeq = 1016729
    
    SET ROWCOUNT @PageCount
    
    SELECT A.SMKindSeq	    AS SMKindSeq    --  ����
        , A.CostSeq         AS CostSeq      -- ��뱸�г����ڵ�
        , A.CostName        AS CostName     -- ��뱸�и�
        , A.AccSeq          AS AccSeq       -- ��������
        , A.RemSeq          AS RemSeq       -- �����׸�
        , A.RemValSeq       AS RemValSeq    -- Default�����׸�
        , A.CashDate        AS CashDate     -- �ⳳ�����ϼ�
        , B.AccName         AS AccName      -- ���������
        , C.RemName         AS RemName      -- �����׸�
        , D.RemValueName    AS RemValName   -- Default�����׸��
        , E.MInorName       AS SMKindName   -- ���и�
        , A.OppAccSeq       AS OppAccSeq    -- ������
        , A.EvidSeq         AS EvidSeq      -- ����
        , F.AccName         AS OppAccName   -- ��������
        , G.EvidName        AS EvidName     -- ������
        , I.CostSClassSeq
        , I.CostMClassSeq
        , I.CostLClassSeq
        , I.CostSClassName
        , I.CostMClassName
        , I.CostLClassName
        
      FROM _TARCostAcc                          AS A WITH(NOLOCK)
        LEFT OUTER JOIN _TDAAccount             AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.AccSeq = B.AccSeq
        LEFT OUTER JOIN _TDAAccountRem          AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.RemSeq = C.RemSeq
        LEFT OUTER JOIN _TDAAccountRemValue     AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.RemSeq = D.RemSeq AND A.RemValSeq = D.RemValueSerl
        LEFT OUTER JOIN _TDASMinor              AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySEq AND A.SMKindSeq = E.MinorSeq
        LEFT OUTER JOIN _TDAAccount             AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.OppAccSeq = F.AccSeq
        LEFT OUTER JOIN _TDAEvid                AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq AND A.EvidSeq = G.EvidSeq
        LEFT OUTER JOIN mnpt_TARCostAccSub      AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.CostSeq = A.CostSeq AND H.SMKindSeq = A.SMKindSeq ) 
        LEFT OUTER JOIN #CostClass              AS I              ON ( I.CostSClassSeq = H.CostSClassSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (A.CostName LIKE @Keyword) 
       AND (@Param1 = 0 OR A.SMKindSeq = @Param1)
       AND ISNULL(A.IsNotUse,'') <> '1'
     ORDER BY A.Sort
    SET ROWCOUNT 0
RETURN

go

exec _SCACodeHelpQuery @WorkingTag=N'Q',@CompanySeq=1,@LanguageSeq=1,@CodeHelpSeq=N'13820036',@Keyword=N'%ȸ�ĺ�%',@Param1=N'4503004',@Param2=N'',@Param3=N'',@Param4=N'',@ConditionSeq=N'1',@PageCount=N'1',@PageSize=N'50',@SubConditionSql=N'',@AccUnit=N'1',@BizUnit=1,@FactUnit=1,@DeptSeq=1,@WkDeptSeq=18,@EmpSeq=64,@UserSeq=167