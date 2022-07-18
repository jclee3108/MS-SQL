If Exists (Select 1 From sysobjects where name = 'V_INSA_Dept')   
    Drop View V_INSA_Dept  
GO  
--��å  
CREATE VIEW dbo.V_INSA_Dept  
AS     
      
    -- ������ ��ȸ ����      
    SELECT A.CompanySeq             AS CompanySeq,      --���γ����ڵ�  
           CASE WHEN ISNULL(B.AbrDeptName,'') <> '' THEN B.AbrDeptName ELSE B.DeptName END AS DeptName,        --�μ���    
           ISNULL(A.DeptSeq,  0)    AS DeptSeq,         --�μ�(�ڵ�)        
           ISNULL(A.UppDeptSeq, 0)  AS UppDeptSeq,      --�����μ��ڵ�    
           CASE WHEN ISNULL(C.AbrDeptName,'') <> '' THEN C.AbrDeptName ELSE C.DeptName END  AS UppDeptName      --�����μ���    
           ,CASE WHEN A.LastDateTime >= B.LastDateTime AND A.LastDateTime >= C.LastDateTime THEN A.LastDateTime  
                 WHEN A.LastDateTime >= B.LastDateTime AND A.LastDateTime < C.LastDateTime THEN C.LastDateTime  
                 WHEN A.LastDateTime < B.LastDateTime AND A.LastDateTime >= C.LastDateTime THEN B.LastDateTime  
                 WHEN A.LastDateTime < B.LastDateTime AND A.LastDateTime < C.LastDateTime AND B.LastDateTime >= C.LastDateTime  THEN B.LastDateTime  
                 ELSE C.LastDateTime END AS LastDateTime,  
           A.UMDeptLevel,  
           U.MinorName      AS UMDeptLevelName  
      FROM _THROrgDept AS A   
           LEFT OUTER JOIN _TDADeptHist AS B WITH(NOLOCK) ON A.DeptSeq    = B.DeptSeq      
                                                         AND A.CompanySeq = B.CompanySeq      
                                                         AND (B.BegDate  <= CONVERT(NCHAR(8),GETDATE(),112) AND B.EndDate >= CONVERT(NCHAR(8),GETDATE(),112))      
           LEFT OUTER JOIN _TDAUMinor AS U WITH(NOLOCK) ON U.CompanySeq = A.Companyseq  
                                                       AND U.Minorseq = A.UMDeptLevel  
           LEFT OUTER JOIN _TDADeptHist AS C WITH(NOLOCK) ON A.UppDeptSeq = C.DeptSeq      
                                                         AND A.CompanySeq = C.CompanySeq    
                                                         AND (C.BegDate  <= CONVERT(NCHAR(8),GETDATE(),112) AND C.EndDate >= CONVERT(NCHAR(8),GETDATE(),112))      
  WHERE A.OrgType = CASE WHEN A.CompanySeq = 1 THEN 3 ELSE 1 END 
    AND (A.BegDate <= CONVERT(NCHAR(8),GETDATE(),112) AND A.EndDate >= CONVERT(NCHAR(8),GETDATE(),112))      
  --ORDER BY A.UMDeptLevel  
  