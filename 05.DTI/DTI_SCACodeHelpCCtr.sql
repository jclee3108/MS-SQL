
IF OBJECT_ID('DTI_SCACodeHelpCCtr') IS NOT NULL
    DROP PROC DTI_SCACodeHelpCCtr
    
GO

-- v2013.06.26

-- Ȱ�������ڵ嵵��_DTI by����õ
CREATE PROC DTI_SCACodeHelpCCtr                   
    @WorkingTag     NVARCHAR(1),                      
    @LanguageSeq    INT,                      
    @CodeHelpSeq    INT,                      
    @DefQueryOption INT,    
    @CodeHelpType   TINYINT,                      
    @PageCount      INT = 20,           
    @CompanySeq     INT = 1,                     
    @Keyword        NVARCHAR(200) = '',                      
    @Param1         NVARCHAR(50) = '',      --Ȱ�����ͺз�(�����ڷ� �޴´�.)    
    @Param2         NVARCHAR(50) = '',      --����/�ǰ�/������Ʈ    
    @Param3         NVARCHAR(50) = '',      --��������    
    @Param4         NVARCHAR(50) = '', 
    @pageSize       INT = 50     
AS       
    
    DECLARE @Param5             NVARCHAR(50),  
            @Param6             NVARCHAR(50),  
            @Param7             NCHAR(1),           --�а���ǥ ���� : �а���ǥ���� Ȱ�����͸� ���� ��� SMSourceType�� WorkCenter(5511003)�� ���� �����Ѵ�.  
            @UMSlipCostTypeName NVARCHAR(100),  
            @EnvValue           NCHAR(1)  
  
    SELECT @EnvValue = ISNULL(EnvValue,'0')   
      FROM _TCOMEnv  
     WHERE CompanySeq = @CompanySeq  
       AND EnvSeq = 4716  
  
    -- _/0_/0_/1  
    SELECT @Param5 = Value  
      FROM _FCOMStrSplitOne(@Param4,'_/')  
     WHERE idx = 2                            --�繫ȸ�� AccSeq  
  
    SELECT @Param6 = Value  
      FROM _FCOMStrSplitOne(@Param4,'_/')  
     WHERE idx = 3                            --�繫ȸ�� UMCostType  
  
    SELECT @Param7 = Value  
      FROM _FCOMStrSplitOne(@Param4,'_/')  
     WHERE idx = 4                            --�а���ǥ����  
       
    SELECT @Param4 = Value  
      FROM _FCOMStrSplitOne(@Param4,'_/')  
     WHERE idx = 1                            --����ȸ��  
  
------ �Ľ̼��� �ٲٸ� �ȵ�!!! @Param4 �� �׻� ������!!!  
    SET ROWCOUNT @PageCount    
  
    SELECT @UMSlipCostTypeName = MinorName  
      FROM _TDAUMinor WITH(NOLOCK)  
     WHERE CompanySeq = @CompanySeq  
       AND MinorSeq = @Param6  
  
    SELECT DISTINCT A.CCtrName AS CCtrName, 
             Z.CCtrSeq AS CCtrSeq , 
             B.MinorName AS UMCCtrKindName, 
             A.UMCostType, 
             U.MinorName AS UMCostTypeName,  
           CASE WHEN ISNULL(@EnvValue,'0') <> '1' THEN   
               CASE WHEN ISNULL(@Param6, '0') = '0' THEN A.UMCostType  
               ELSE @Param6 END  
           ELSE A.UMCostType  
           END AS UMSlipCostType,  
           CASE WHEN ISNULL(@EnvValue,'0') <> '1' THEN   
               CASE WHEN ISNULL(@Param6, '0') = '0' THEN U.MinorName  
               ELSE @UMSlipCostTypeName END   
           ELSE U.MinorName  
           END AS UMSlipCostTypeName,  
           A.Remark ,  
           A.SMSourceType,  
           F.MinorName AS SMSourceTypeName,  
           A.IsNotUse,  
           A.IsNotUseDate,  
           A.EmpSeq,  
           A.DeptSeq,  
           G.EmpName,  
           H.DeptName,  
           I.PJTNo AS InfoPJTNo,  
           I.PJTName AS InfoPJTName,  
           I.PJTSeq AS InfoPJTSeq    
      FROM _TDACCtr AS A WITH(NOLOCK) 
      JOIN _THROrgDeptCCtr  AS Z WITH(NOLOCK) ON ( Z.CompanySeq = @CompanySeq AND A.CCtrSeq = Z.CCtrSeq AND Z.DeptSeq = @Param1 ) 
      LEFT OUTER JOIN _TDAUMinor       AS B WITH(NOLOCK) ON ( A.UMCCtrKind = B.MinorSeq AND A.CompanySeq = B.CompanySeq )     
      LEFT OUTER JOIN _TDAUMinorValue  AS M WITH(NOLOCK) ON ( A.CompanySeq = M.CompanySeq AND A.UMCCtrKind = M.MinorSeq AND M.ValueText = '1' )  
      LEFT OUTER JOIN _TDAUMinor       AS U WITH(NOLOCK) ON ( A.UMCostType = U.MinorSeq AND A.CompanySeq = U.CompanySeq )  
      JOIN _TDASMinor   AS F WITH(NOLOCK) ON ( A.CompanySeq = F.CompanySeq AND A.SMSourceType = F.MinorSeq )   
      LEFT OUTER JOIN _TDAEmp       AS G WITH(NOLOCK) ON ( A.EmpSeq = G.EmpSeq AND A.CompanySeq = G.CompanySeq )  
      LEFT OUTER JOIN _TDADept      AS H WITH(NOLOCK) ON ( Z.DeptSeq = H.DeptSeq AND Z.CompanySeq = H.CompanySeq )  
      LEFT OUTER JOIN (SELECT *     
                         FROM _TPJTProject AS A    
                        WHERE A.CCtrSeq NOT IN (SELECT CCtrSeq        
                                                  FROM _TPJTProject    
                                                 WHERE CompanySeq = @CompanySeq    
                                                   AND ISNULL(CCtrSeq, 0) <> 0     
                                                 GROUP BY CCtrSeq    
                                                 HAVING COUNT(*) > 1
                                                )
                      ) AS I ON ( I.CompanySeq = @CompanySeq AND I.CCtrSeq = A.CCtrSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.CCtrName LIKE @Keyword
    
    SET ROWCOUNT 0     
    
    RETURN     
GO
