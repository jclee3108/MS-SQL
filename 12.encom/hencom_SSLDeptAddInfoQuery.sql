IF OBJECT_ID('hencom_SSLDeptAddInfoQuery') IS NOT NULL 
    DROP PROC hencom_SSLDeptAddInfoQuery
GO 

-- v2017.05.22 

/************************************************************
  ��  �� - ������-����Ұ���(�߰�����)_hencom : ��ȸ
  �ۼ��� - 20151020
  �ۼ��� - �ڼ���
        - 2016.03.17  kth ���ο� �������� �߰�
 ************************************************************/
  CREATE PROC hencom_SSLDeptAddInfoQuery
  @xmlDocument    NVARCHAR(MAX) ,            
  @xmlFlags     INT  = 0,            
  @ServiceSeq     INT  = 0,            
  @WorkingTag     NVARCHAR(10)= '',                  
  @CompanySeq     INT  = 1,            
  @LanguageSeq INT  = 1,            
  @UserSeq     INT  = 0,            
  @PgmSeq         INT  = 0         
     
 AS        
  
     SELECT  M.DeptSeq           AS DeptSeq,
             M.DeptName          AS DeptName,
             A.UmAreaLClass      AS UMAreaLClass,
             A.UMTotalDiv        AS UMTotalDiv,
             A.DispSeq           AS DispSeq,
             A.IsLentCarPrice    AS IsLentCarPrice,
             A.MinRotation       AS MinRotation,
             A.Remark            AS Remark,
             A.LastUserSeq       AS LastUserSeq,
             A.LastDateTime      AS LastDateTime,
             A.OracleKey         AS OracleKey,
             -------------------------------
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UmAreaLClass ) AS UMAreaLClassName,
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMTotalDiv )   AS UMTotalDivName,
              ------------------------------- 2016.03.17  kth ���ο� �������� �߰�
             A.ProdDeptSeq       AS ProdDeptSeq,
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.ProdDeptSeq) AS ProdDeptName,
             A.DispQC           AS DispQC,--ǰ����� ȭ�鿡 ��ȸ�Ǵ� �⺻�����
             A.IsUseReport
      FROM _TDADept AS M
     LEFT OUTER JOIN hencom_TDADeptAdd  AS A WITH (NOLOCK) ON A.CompanySeq = @CompanySeq AND A.DeptSeq = M.DeptSeq
     WHERE  M.CompanySeq = @CompanySeq
 --    ORDER BY A.DispSeq
    
  RETURN
