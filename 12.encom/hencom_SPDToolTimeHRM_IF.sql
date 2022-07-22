IF OBJECT_ID('hencom_SPDToolTimeHRM_IF') IS NOT NULL 
    DROP PROC hencom_SPDToolTimeHRM_IF
GO 

-- v2017.06.16

-- ���񰡵��ð� - HRM�� �ݿ� by����õ 
CREATE PROC hencom_SPDToolTimeHRM_IF
    @CompanySeq INT, 
    @DateFr     NCHAR(8), 
    @DateTo     NCHAR(8), 
    @DeptSeq    INT 
AS 
    
    -- HRM ������ڵ� ��� 
    DECLARE @HRMDept    NVARCHAR(20), 
            @Result     NVARCHAR(4000)

    SELECT @HRMDept = B.ValueText 
      FROM _TDAUMinorValue              AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAUMinorValue   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1014724
       AND A.Serl = 1000005 
       AND A.ValueSeq = @DeptSeq 
    
    -- ���񰡵� ���۽ð� 
    SELECT A.b_date AS StdDate, A.DeptSeq, MIN(REPLACE(LEFT(A.b_time,5),':','')) AS TooTime 
      INTO #StartTime
      FROM hencom_TIFBCPProdClose AS A 
     WHERE A.CompanySeq = @CompanySeq
       AND A.b_date BETWEEN @DateFr AND @DateTo
       AND A.DeptSeq = @DeptSeq 
     GROUP BY A.b_date, A.DeptSeq 
    
    -- ���񰡵� ����ð� 
    SELECT A.b_date AS StdDate, A.DeptSeq, MAX(REPLACE(LEFT(A.b_time,5),':','')) AS TooTime
      INTO #EndTime
      FROM hencom_TIFBCPProdClose AS A 
     WHERE A.CompanySeq = @CompanySeq
       AND A.b_date BETWEEN @DateFr AND @DateTo
       AND A.DeptSeq = @DeptSeq 
     GROUP BY A.b_date, A.DeptSeq 
    
    -- �߰� �ӽ����̺�
    SELECT A.StdDate, A.DeptSeq, @HRMDept AS HRMDept, A.TooTime AS StartTime, B.TooTime AS EndTime
      INTO #THR_ODM_DAILY_WORK_INF
      FROM #StartTime               AS A 
      LEFT OUTER JOIN #EndTime      AS B ON ( B.StdDate = A.StdDate AND B.DeptSeq = A.DeptSeq ) 
    
    IF EXISTS (SELECT 1 FROM #THR_ODM_DAILY_WORK_INF WHERE ISNULL(HRMDept,'') = '' OR ISNULL(HRMDept,'') = '0')
    BEGIN 
        
        SELECT @Result = 'ERP�� HRM(�λ�)�� ����� ������ ���� �ʾҽ��ϴ�.'
        
    END 
    ELSE 
    BEGIN

        DELETE A
          FROM [GHRM]..[HGHR].[THR_ODM_DAILY_WORK_INF] AS A 
         WHERE A.ENT_CD  = @HRMDept 
           AND A.APPLY_YMD BETWEEN @DateFr AND @DateTo
        
        INSERT INTO [GHRM]..[HGHR].[THR_ODM_DAILY_WORK_INF] 
        (
            COM_CD, ENT_CD, APPLY_YMD, STA_HHMM, END_HHMM, 
            DEL_YN
        )
        SELECT '00003', A.HRMDept, StdDate, StartTime, EndTime, 
               'N'
          FROM #THR_ODM_DAILY_WORK_INF AS A 
        
        SELECT @Result = '�����Ͱ� ���������� ������ �Ǿ����ϴ�.'

    END 

    -- ���
    SELECT (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = @DeptSeq) AS '�����', 
           STUFF(STUFF(@DateFr,5,0,'-'),8,0,'-') AS '��������From',
           STUFF(STUFF(@DateTo,5,0,'-'),8,0,'-') AS '��������To',
           @Result AS '���'
    
    RETURN 
GO

exec hencom_SPDToolTimeHRM_IF @CompanySeq = 1, 
                              @DateFr = '20151203',
                              @DateTo = '20151203', 
                              @DeptSeq = 37



