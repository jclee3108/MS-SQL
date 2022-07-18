
IF OBJECT_ID('KPX_SPRWkempVacAppGWQuery') IS NOT NULL 
    DROP PROC KPX_SPRWkempVacAppGWQuery 
GO 

-- v2014.12.10 

-- �ް���û ���ڰ���SP by����õ 
CREATE PROC KPX_SPRWkempVacAppGWQuery                  
    @xmlDocument    NVARCHAR(MAX) ,              
    @xmlFlags       INT = 0,              
    @ServiceSeq     INT = 0,              
    @WorkingTag     NVARCHAR(10)= '',                    
    @CompanySeq     INT = 1,              
    @LanguageSeq    INT = 1,              
    @UserSeq        INT = 0,              
    @PgmSeq         INT = 0         
AS          
    
    DECLARE @docHandle  INT,  
            @EmpSeq     INT, 
            @VacSeq     INT
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
    
    SELECT @EmpSeq = EmpSeq, 
           @VacSeq = VacSeq    
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (
            EmpSeq     INT,
            VacSeq     INT
           )     
    
    SELECT A.EmpSeq, 
           C.EmpName, 
           A.WkItemSeq                           , --�����׸��ڵ�
           ISNULL(D.WkItemName, '') AS WkItemName, --�����׸�
           A.VacSeq                              , --�Ϸù�ȣ
           A.WkFrDate                            , --�ް���������
           A.WkToDate                            , --�ް���������
           A.PrevUseDays                         , --�ް��ϼ�
           A.AppDate                             , --��û����
           A.VacReason                           , --�ް�����
           A.CrisisTel                           , --��޿���ó
           A.TelNo                               , --��ȭ��ȣ
           A.AccptEmpSeq                         , --�μ���
           A.CCSeq                               , --������
           A.IsHalf                              , --��������
           A.IsEnd                               , --Ȯ������
           A.IsReturn                            , --�ݼۿ���
           A.ReturnReason                        , --�ݼۻ���
           A.TimeTerm AS TimeTerm,
           ISNULL(A.CCSeq,0) AS CCSeq,
           ISNULL((SELECT ConName FROM _THRWelCon WHERE CompanySeq = @CompanySeq AND ConSeq = A.CCSeq),'') AS CCName,
           CASE WHEN EXISTS(SELECT * FROM _TPRWkAppItem WHERE CompanySeq = @CompanySeq AND SMWkAppSeq = 3122003 AND WkItemSeq = A.WkItemSeq ) THEN '1' ELSE '0' END AS IsCC, 
           
           E.DeptSeq, 
           E.DeptName, 
           E.PosName, -- PosName 
           E.UMJpName, -- ����

           F.ItemName + ' * ' + CONVERT(NVARCHAR(10),CONVERT(INT,B.Numerator)) + '/' + CONVERT(NVARCHAR(10),CONVERT(INT,B.Denominator)) AS StdCon, -- ����   
           0 AS ConAmt  -- ������   
      FROM _TPRWkEmpVacApp              AS A 
      LEFT OUTER JOIN KPX_THRWelConAmt  AS B ON ( B.CompanySeq = @CompanySeq AND B.WkItemSeq = A.WKItemSEq AND B.ConSeq = A.CCSeq )
      LEFT OUTER JOIN _TDAEmp           AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TPRWkItem        AS D ON ( D.CompanySeq = @CompanySeq AND D.WkItemSeq = A.WkItemSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS E ON ( E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TPRBasPayItem    AS F ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = B.WkItemSeq )   
     WHERE A.CompanySeq = @CompanySeq 
       AND A.EmpSeq = @EmpSeq 
       AND A.VacSeq = @VacSeq 
    
    RETURN 
    