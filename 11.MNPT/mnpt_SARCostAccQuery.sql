IF OBJECT_ID('mnpt_SARCostAccQuery') IS NOT NULL 
    DROP PROC mnpt_SARCostAccQuery
GO 

-- v2018.01.08 
/*********************************************************************************************************************      
    ȭ��� : ���ڰ��翬������ȯ�漳�� - ��ȸ  
    SP Name: _SARCostAccQuery      
    �ۼ��� : 2010.04.19 : CREATEd by �۰��          
    ������ : 2010.04.22 : Modify by  �۰��  
                        :: ������, ���� �÷� �߰�  
********************************************************************************************************************/      
CREATE PROCEDURE mnpt_SARCostAccQuery        
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.      
    @WorkingTag     NVARCHAR(10)= '',      
    @CompanySeq     INT = 1,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS             
    DECLARE @docHandle      INT      
          , @SMKindSeq      INT             -- ����  
          , @CostName       NVARCHAR(100)   -- ��뱸�и�  
          , @AccSeq         INT             -- ���������ڵ�  
          , @AccName        NVARCHAR(100)   -- ���������  
          , @RemSeq         INT             -- �����׸��ڵ�  
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument       
      
  
    SELECT @SMKindSeq   = ISNULL(SMKindSeq, 0)  -- ����  
         , @CostName    = ISNULL(CostName,'')   -- ��뱸�и�  
         , @AccSeq      = ISNULL(AccSeq,0)      -- ���������ڵ�  
         , @AccName     = ISNULL(AccName,'')    -- ���������  
         , @RemSeq      = ISNULL(RemSeq,0)      -- �����׸��ڵ�  
             
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)           
    WITH (SMKindSeq     INT  
        , CostName      NVARCHAR(100)  
        , AccSeq        INT  
        , AccName       NVARCHAR(100)  
        , RemSeq        INT  
         )        
      
    SELECT @SMKindSeq   = ISNULL(@SMKindSeq, 0)   
        , @CostName     = ISNULL(@CostName,'')  
        , @AccSeq       = ISNULL(@AccSeq,0)  
        , @AccName      = ISNULL(@AccName,'')  
        , @RemSeq       = ISNULL(@RemSeq,0)  
  


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


/***********************************************************************************************************************************************/      
    SELECT A.SMKindSeq     AS SMKindSeq    --  ����  
        , A.CostSeq         AS CostSeq      -- ��뱸�г����ڵ�  
        , A.CostName        AS CostName     -- ��뱸�и�  
        , A.AccSeq          AS AccSeq       -- ��������  
        , A.RemSeq          AS RemSeq       -- �����׸�  
        , A.RemValSeq       AS RemValSeq    -- Default�����׸�  
        , A.CashDate        AS CashDate     -- �ⳳ�����ϼ�  
        , A.Remark          AS Remark       -- ���  
        , B.AccName         AS AccName      -- ���������  
        , C.RemName         AS RemName      -- �����׸�  
        , D.RemValueName    AS RemValueName -- Default�����׸��  
        , E.MInorName       AS SMKindName   -- ���и�  
        , A.SMKindSeq       AS OldSMKindSeq --  Old����  
  
        , A.OppAccSeq       AS OppAccSeq    -- �������ڵ�  
        , F.AccName         AS OppAccName   -- ������  
        , A.EvidSeq         AS EvidSeq      -- �����ڵ�  
        , G.EvidName        AS EvidName     -- ����  
        , ISNULL(H.MinorName    , '') AS UMCostTypeName -- ��뱸��  
        , ISNULL(A.UMCostType   ,  0) AS UMCostType     -- ��뱸���ڵ�  
/********************************************************************  
    ��ȸ�� �������, ���� ��µǰ� ���� 2011.02.07 - ����  
********************************************************************/  
        , ISNULL(J.BgtName      , '') AS BgtName        -- �������  
        , ISNULL(A.Sort         , 0 ) AS Sort           -- ����   
        , ISNULL(A.IsNotUse        , '') AS IsNotUse    -- ������
        , L.CostSClassSeq
        , L.CostMClassSeq
        , L.CostLClassSeq
        , L.CostSClassName
        , L.CostMClassName
        , L.CostLClassName
      FROM _TARCostAcc AS A WITH(NOLOCK)  
        LEFT OUTER JOIN _TDAAccount AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.AccSeq = B.AccSeq  
        LEFT OUTER JOIN _TDAAccountRem AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.RemSeq = C.RemSeq  
        LEFT OUTER JOIN _TDAAccountRemValue AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.RemSeq = D.RemSeq AND A.RemValSeq = D.RemValueSerl  
        LEFT OUTER JOIN _TDASMinor AS E ON A.CompanySeq = E.CompanySEq AND A.SMKindSeq = E.MinorSeq  
        LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq AND A.OppAccSeq = F.AccSeq  
        LEFT OUTER JOIN _TDAEvid    AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq AND A.EvidSeq = G.EvidSeq  
        LEFT OUTER JOIN _TDAUMinor  AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq AND A.UMCostType = H.MinorSeq AND H.MajorSeq = 4001  
        LEFT OUTER JOIN _TACBgtAcc  AS I ON A.CompanySeq = I.CompanySeq AND A.AccSeq = I.AccSeq AND A.RemSeq = I.RemSeq AND A.RemValSeq = I.RemValSeq  
        LEFT OUTER JOIN _TACBgtItem AS J ON A.CompanySeq = J.CompanySeq AND I.BgtSeq = J.BgtSeq    
        LEFT OUTER JOIN mnpt_TARCostAccSub AS K ON ( K.CompanySeq = @CompanySeq AND K.SMKindSeq = A.SMKindSeq AND K.CostSeq = A.CostSeq ) 
        LEFT OUTER JOIN #CostClass         AS L ON ( L.CostSClassSeq = K.CostSClassSeq ) 
     
     WHERE A.CompanySeq = @CompanySeq  
       AND (@SMKindSeq = 0 OR A.SMKindSeq = @SMKindSeq)  
       AND (@CostName = '' OR A.CostName LIKE @CostName + '%')  
       AND (@AccSeq = 0 OR A.AccSeq = @AccSeq)  
       AND (@AccName = '' OR B.AccName LIKE @AccName + '%')  
       AND (@RemSeq = 0 OR C.RemSeq = @RemSeq)  
    ORDER BY A.Sort
  
    RETURN

    go
    exec mnpt_SARCostAccQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <SMKindSeq />
    <CostName />
    <AccSeq />
    <AccName />
    <RemSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820111,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=167,@PgmSeq=13820107