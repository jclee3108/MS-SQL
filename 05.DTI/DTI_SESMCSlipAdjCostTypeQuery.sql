
IF OBJECT_ID('DTI_SESMCSlipAdjCostTypeQuery') IS NOT NULL 
    DROP PROC DTI_SESMCSlipAdjCostTypeQuery
GO

-- v2013.12.21 

-- ������-����ȸ����ǥ�ۼ�_DTI(�������� ���� ��뱸�� ��������)_DTI by����õ
CREATE PROC DTI_SESMCSlipAdjCostTypeQuery                 
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS          
    
    DECLARE @docHandle      INT, 
            @AccSeq         INT, 
            @SMCostKind     INT, 
            @EmpSeq         INT, 
            @DeptSeq        INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
    
    SELECT @AccSeq = ISNULL(AccSeq, 0) 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (AccSeq INT) 
    
    --IF 1 = (SELECT COUNT(*) FROM _TDAAccountCostType WHERE CompanySeq = @CompanySeq AND AccSeq = @AccSeq)  
    --BEGIN  
    SELECT TOP 1 A.UMCostType, B.MInorName AS UMCostTypeName
      FROM _TDAAccountCostType  AS A 
      JOIN _TDAUMinor           AS B ON ( B.CompanySeq = @CompanySeq AND A.UMCostType = B.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.AccSeq     = @AccSeq  
    
    UNION ALL 
    
    SELECT 0 AS UMCostType, ''AS UMCostTypeName
     WHERE NOT EXISTS ( SELECT 1
                          FROM _TDAAccountCostType  AS A 
                         WHERE A.CompanySeq = @CompanySeq  
                           AND A.AccSeq     = @AccSeq  
                      )
        
           /*
    END  
    ELSE  
    BEGIN  
        -- ���������� (ȯ�漳��)  
        SELECT @SMCostKind = CONVERT(INT, ISNULL(EnvValue, '0')) FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 5531  
        IF @@ROWCOUNT = 0 OR ISNULL(@SMCostKind, 0) = 0 SELECT @SMCostKind = 0  
        -- ����ڵ�  
        SELECT @EmpSeq = EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq  
        IF @@ROWCOUNT = 0 OR ISNULL(@EmpSeq, 0) = 0 SELECT @EmpSeq = 0  
            -- �μ��ڵ�  
        SELECT @DeptSeq = DeptSeq FROM dbo._fnAdmEmpCCtr(@CompanySeq, '') WHERE EmpSeq = @EmpSeq  
        IF @@ROWCOUNT = 0 OR ISNULL(@DeptSeq, 0) = 0 SELECT @DeptSeq = 0  

        --==================================================================================================================================  
        -- 1. �������� "�⺻����"�̰ų� �������� �ʰ�, �μ� �� ����ڵ尡 �ִ� �����, �ͼӺμ��� �ش�Ǵ� ��뱸���� ���� �����Ų��.  
        --==================================================================================================================================  
        IF @EmpSeq <> 0 AND @DeptSeq <> 0 AND (@SMCostKind = 5518001 OR @SMCostKind = 0)  
        BEGIN  
            SELECT A.UMCostType AS UMCostType, 
                   ISNULL(B.MinorName, '') AS UMCostTypeName  
              FROM _TDADept AS A  
              LEFT OUTER JOIN _TDAAccountCostType AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq 
                                                                     AND C.AccSeq = @AccSeq  
                                                                     AND A.UMCostType = C.UMCostType 
                                                                       )
              LEFT OUTER JOIN _TDAUMinor AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq  
                                                            AND A.UMCostType = B.MinorSeq  
                                                            AND B.MajorSeq = 4001 
                                                              )
             WHERE A.CompanySeq = @CompanySeq  
               AND A.DeptSeq = @DeptSeq  
        END  
        --==================================================================================================================================  
        -- 2. �׷��� ���� ���� ������ ���������� Ȱ�������� ��뱸������ ���õǵ��� �Ѵ�.  
        --==================================================================================================================================  
        ELSE  
        BEGIN  
            SELECT A.UMCostType AS UMCostType, 
                   ISNULL(B.MInorName,'') AS UMCostTypeName 
              FROM _TDACCtr AS A  
              LEFT OUTER JOIN _TDAAccountCostType AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq  
                                                                     AND C.AccSeq = @AccSeq  
                                                                     AND A.UMCostType = C.UMCostType 
                                                                       )
              LEFT OUTER JOIN _TDAUMinor AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND C.UMCostType = B.MinorSeq ) 
             WHERE A.CompanySeq = @CompanySeq  
               AND A.CCtrSeq = @CCtrSeq    
        END  
    END           
    */
    RETURN  
GO
exec DTI_SESMCSlipAdjCostTypeQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <AccSeq>762</AccSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019994,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016860