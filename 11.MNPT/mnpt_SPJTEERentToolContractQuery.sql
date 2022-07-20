     
IF OBJECT_ID('mnpt_SPJTEERentToolContractQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTEERentToolContractQuery      
GO      
      
-- v2017.11.21
      
-- �ܺ������������Է�-SS1��ȸ by ����õ
CREATE PROC mnpt_SPJTEERentToolContractQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @FrContractDate NCHAR(8), 
            @ToContractDate NCHAR(8), 
            @BizUnit        INT, 
            @DeptSeq        INT
      
    SELECT @FrContractDate   = ISNULL( FrContractDate, '' ),   
           @ToContractDate   = ISNULL( ToContractDate, '' ), 
           @BizUnit          = ISNULL( BizUnit, 0 ), 
           @DeptSeq          = ISNULL( DeptSeq, 0 ) 
      FROM #BIZ_IN_DataBlock1    
    
    IF @ToContractDate = '' SELECT @ToContractDate = '99991231'
    
    -- SS2 �� ���������� �������
    SELECT A.ContractSeq, D.EquipmentSName AS RentToolName, B.Qty, C.MinorName AS UMRentTypeName, B.TotalAmt, B.Cnt 
      INTO #RentToolInfo
      FROM mnpt_TPJTEERentToolContractItem  AS A 
      JOIN ( 
            SELECT ContractSeq, MIN(ContractSerl) AS ContractSerl , SUM(Qty) AS Qty, SUM(Amt) AS TotalAmt, COUNT(1) AS Cnt 
              FROM mnpt_TPJTEERentToolContractItem 
             WHERE CompanySeq = @CompanySeq 
               AND UMRentKind = 1016351001 
             GROUP BY ContractSeq
           ) AS B ON ( B.ContractSeq = A.ContractSeq AND B.ContractSerl = A.ContractSerl ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMRentType ) 
      LEFT OUTER JOIN mnpt_TPDEquipment AS D ON ( D.CompanySeq = @CompanySeq AND D.EquipmentSeq = A.RentToolSeq ) 
    
    -- SS2 �� ���������� ������������
    SELECT A.ContractSeq, B.Qty, C.MinorName AS UMRentTypeName, B.TotalAmt
      INTO #ManInfo
      FROM mnpt_TPJTEERentToolContractItem  AS A 
      JOIN ( 
            SELECT ContractSeq, MIN(ContractSerl) AS ContractSerl , SUM(Qty) AS Qty, SUM(Amt) AS TotalAmt 
              FROM mnpt_TPJTEERentToolContractItem 
             WHERE CompanySeq = @CompanySeq 
               AND UMRentKind = 1016351002 
             GROUP BY ContractSeq
           ) AS B ON ( B.ContractSeq = A.ContractSeq AND B.ContractSerl = A.ContractSerl ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMRentType ) 
    

    -- ������ȸ
    SELECT A.ContractSeq, -- �����ڵ� 
           A.BizUnit, -- ����ι��ڵ� 
           B.BizUnitName, -- ����ι� 
           A.ContractDate, -- ����� 
           A.ContractNo, -- ����ȣ 
           A.RentCustSeq, -- ������ü�ڵ� 
           C.CustName AS RentCustName, --������ü 
           A.RentSrtDate, -- ���������� 
           A.RentEndDate, -- ���������� 
           
           F.RentToolName + CASE WHEN F.Cnt > 1 THEN ' �� ' + CONVERT(NVARCHAR(10),F.Cnt-1) + '��' ELSE '' END AS ToolName, -- ������� ��� 
           F.Qty AS ToolCnt,  -- ������� ���
           F.UMRentTypeName AS ToolUMToolTypeName, -- ������� ����
           F.TotalAmt AS ToolAmt, -- ������� �����ݾ�
           G.Qty AS ManCnt, -- ���������� �ο� 
           G.UMRentTypeName AS ManUMToolTypeName, -- ���������� ����
           G.TotalAmt AS ManAmt, -- ���������� �����ݾ� 
           ISNULL(F.TotalAmt,0) + ISNULL(G.TotalAmt,0) AS TotalAmt, -- �ѱݾ� 
           A.EmpSeq, -- ������ڵ� 
           D.EmpName, -- ����� 
           A.DeptSeq, -- ���μ��ڵ� 
           E.DeptName, -- ���μ� 
           A.Remark -- ��� 

      FROM mnpt_TPJTEERentToolContract  AS A   
      LEFT OUTER JOIN _TDABizUnit       AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDACust          AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.RentCustSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS D ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept          AS E ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN #RentToolInfo     AS F ON ( F.ContractSeq = A.ContractSeq ) 
      LEFT OUTER JOIN #ManInfo          AS G ON ( G.ContractSeq = A.ContractSeq ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.ContractDate BETWEEN @FrContractDate AND @ToContractDate 
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit) 
       AND (@DeptSEq = 0 OR A.DeptSeq = @DeptSeq)
     ORDER BY BizUnit, ContractDate 
    
    RETURN     
    

    go
