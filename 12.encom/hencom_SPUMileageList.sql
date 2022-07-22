IF OBJECT_ID('hencom_SPUMileageList') IS NOT NULL 
    DROP PROC hencom_SPUMileageList
GO 

-- v2017.02.21 

-- Total�� �߰� 
/************************************************************    
 ��  �� - ������Ȳ��ȸ_hencom    
 �ۼ��� - 2015.12.16    
 �ۼ��� - kth    
 ������ -by�ڼ���2016.05.30 ������� ����.  
************************************************************/    
CREATE PROCEDURE [dbo].[hencom_SPUMileageList]    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
    
AS           
    
    DECLARE @docHandle      INT    
            ,@WorkDateFr    NCHAR(8)    
            ,@WorkDateTo    NCHAR(8)    
            ,@DeptSeq       INT     
            ,@UMCarClass    INT    
            ,@SubContrCarSeq    INT    
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
    
    SELECT   @WorkDateFr          =   ISNULL(WorkDateFr,''   )    
            ,@WorkDateTo          =   ISNULL(WorkDateTo,''   )    
            ,@DeptSeq             =   ISNULL(DeptSeq     ,0)     
            ,@UMCarClass          =   ISNULL(UMCarClass     ,0)     
            ,@SubContrCarSeq      =   ISNULL(SubContrCarSeq     ,0)     
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
      WITH  (WorkDateFr     NCHAR(8)    
            ,WorkDateTo     NCHAR(8)    
            ,DeptSeq        INT    
            ,UMCarClass     INT    
            ,SubContrCarSeq INT)    
    
-- �����  �������� ������ȣ ȸ���� ����Ÿ�(km) ���Ÿ�(km)  ������(��) �������(��/km) ����(��/km) ����(��/km)       
    
    SELECT   A.DeptSeq     
            ,B.DeptName    
            ,A.UMCarClass    
            ,D.MinorName AS UMCarClassName    
            ,A.SubContrCarSeq    
            ,C.CarNo AS CarNo    
--            ,MAX(C.StdMileage) AS StdMileage      -- �������    
            ,MAX(SM.StdMileage) AS StdMileage      -- �������  ����2016.05.31by�ڼ���
            ,MAX(E.OutQty) AS OutQty                        -- ������    
            ,SUM(A.Rotation) AS Rotation                    -- ȸ����    
            ,SUM(A.RealDistance) AS RealDistance            -- ����Ÿ�    
            ,(SUM(A.RealDistance) / 2) AS OneWayDistance    -- ���Ÿ�    
                       
        
      INTO #TPUSubContrCalc    
      FROM hencom_TPUSubContrCalc AS A WITH (NOLOCK)     
      LEFT OUTER JOIN _TDADept AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq     
                                                AND B.DeptSeq = A.DeptSeq    
      LEFT OUTER JOIN _TDAUMinor AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq     
                                                  AND D.MinorSeq = A.UMCarClass    
      left outer join  hencom_VPUContrCarInfo as c on c.CompanySeq = a.CompanySeq    
                                                  and c.SubContrCarSeq = a.SubContrCarSeq    
                                   and a.workdate between c.StartDate and c.EndDate    
    
      LEFT OUTER JOIN (SELECT CompanySeq, DeptSeq, SubContrCarSeq, SUM(OutQty) AS OutQty     
                         FROM hencom_TPUFuelOut     
                        WHERE OutDate BETWEEN @WorkDateFr AND @WorkDateTo    
                        GROUP BY CompanySeq, DeptSeq, SubContrCarSeq) AS E ON E.CompanySeq = A.CompanySeq    
                                                                          AND E.DeptSeq = A.DeptSeq     
                                                                          AND E.SubContrCarSeq = A.SubContrCarSeq    
        LEFT OUTER JOIN hencom_VPUMileageCarClass AS SM WITH(NOLOCK) ON SM.CompanySeq = @CompanySeq   
                                                                    AND SM.DeptSeq = A.DeptSeq   
                                                                    AND SM.UMCarClass = A.UMCarClass   
                                                                    AND A.WorkDate BETWEEN SM.StartDate AND SM.EndDate  
     WHERE A.CompanySeq   = @CompanySeq    
       AND (A.WorkDate BETWEEN @WorkDateFr AND @WorkDateTo)    
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)     
       AND (@UMCarClass = 0 OR A.UMCarClass = @UMCarClass)     
       AND (@SubContrCarSeq = 0 OR A.SubContrCarSeq = @SubContrCarSeq)     
         
     GROUP BY A.DeptSeq, B.DeptName, A.UMCarClass, D.MinorName, A.SubContrCarSeq, C.CarNo     
    
    

    -- �հ�
    SELECT 0 AS DeptSeq    
          ,'TOTAL' AS DeptName    
          ,0 AS UMCarClass    
          ,'' AS UMCarClassName    
          ,0 AS SubContrCarSeq    
          ,'' AS CarNo    
          ,SUM(StdMileage) AS StdMileage
          ,SUM(Rotation) AS Rotation
          ,SUM(RealDistance) AS RealDistance
          ,SUM(OneWayDistance) AS OneWayDistance
          ,SUM(OutQty) AS OutQty
          ,CASE WHEN SUM(ISNULL(RealDistance,0)) = 0 THEN 0    
                ELSE SUM(ISNULL(OutQty,0)) / SUM(ISNULL(RealDistance,0)) END AS ResultMileage      -- ����(��/km)
          ,CASE WHEN SUM(ISNULL(RealDistance,0)) = 0 THEN 0 - SUM(ISNULL(StdMileage,0))    
                ELSE (SUM(ISNULL(OutQty,0)) / SUM(ISNULL(RealDistance,0))) - SUM(ISNULL(StdMileage,0)) END AS ChangeMileage       -- ����(��/km)     
          ,1 AS Sort
      FROM #TPUSubContrCalc
    
    UNION ALL 
    -- Result 
    SELECT  DeptSeq    
           ,DeptName    
           ,UMCarClass    
           ,UMCarClassName    
           ,SubContrCarSeq    
           ,CarNo    
           ,StdMileage    
           ,Rotation    
           ,RealDistance    
           ,OneWayDistance    
           ,OutQty    
           ,CASE WHEN ISNULL(RealDistance,0) = 0 THEN 0    
                 ELSE ISNULL(OutQty,0) / ISNULL(RealDistance,0) END AS ResultMileage      -- ����(��/km)
           ,CASE WHEN ISNULL(RealDistance,0) = 0 THEN 0 - ISNULL(StdMileage,0)    
                 ELSE (ISNULL(OutQty,0) / ISNULL(RealDistance,0)) - ISNULL(StdMileage,0) END AS ChangeMileage       -- ����(��/km)     
           ,2 AS Sort
      FROM #TPUSubContrCalc AS A    
     ORDER BY Sort
    


RETURN      
/***************************************************************************************************************/    
    
go
begin tran 
exec hencom_SPUMileageList @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <WorkDateFr>20150101</WorkDateFr>
    <DeptSeq>41</DeptSeq>
    <SubContrCarSeq />
    <WorkDateTo>20170221</WorkDateTo>
    <UMCarClass />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033845,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028023
rollback 