  
IF OBJECT_ID('KPX_SSLMonthSalesPlanSave') IS NOT NULL   
    DROP PROC KPX_SSLMonthSalesPlanSave  
GO  
  
-- v2014.11.14  
  
-- �����ǸŰ�ȹ�Է�-���� by ����õ   
CREATE PROC KPX_SSLMonthSalesPlanSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TSLMonthSalesPlan (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TSLMonthSalesPlan'   
    IF @@ERROR <> 0 RETURN    
    
    --select * From #KPX_TSLMonthSalesPlan 
    
    --return 
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    
    
    IF @WorkingTag = 'Del' 
    BEGIN
    
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLMonthSalesPlanRev')    
        
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TSLMonthSalesPlanRev'    , -- ���̺��        
                      '#KPX_TSLMonthSalesPlan'    , -- �ӽ� ���̺��        
                      'BizUnit,PlanYM,PlanRev'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ�� 
        
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLMonthSalesPlan')    
        
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TSLMonthSalesPlan'    , -- ���̺��        
                      '#KPX_TSLMonthSalesPlan'    , -- �ӽ� ���̺��        
                      'BizUnit,PlanYM,PlanRev'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ�� 
    END 
    ELSE
    BEGIN 
    
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLMonthSalesPlan')    
        
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TSLMonthSalesPlan'    , -- ���̺��        
                      '#KPX_TSLMonthSalesPlan'    , -- �ӽ� ���̺��        
                      'BizUnit,PlanYM,PlanRev,CustSeq,ItemSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , 'BizUnit,PlanYM,PlanRev,CustSeqOld,ItemSeqOld', @PgmSeq  -- ���̺� ��� �ʵ��   
    END 
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TSLMonthSalesPlan WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        IF @WorkingTag = 'Del' 
        BEGIN 
            DELETE B
              FROM #KPX_TSLMonthSalesPlan AS A   
              JOIN KPX_TSLMonthSalesPlan AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.PlanYM = A.PlanYM AND B.PlanRev = A.PlanRev ) 
            
            DELETE B
              FROM #KPX_TSLMonthSalesPlan AS A 
              JOIN KPX_TSLMonthSalesPlanRev AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.PlanYM = A.PlanYM AND B.PlanRev = A.PlanRev ) 
        END 
        ELSE 
        BEGIN 
            DELETE B   
              FROM #KPX_TSLMonthSalesPlan AS A   
              JOIN KPX_TSLMonthSalesPlan AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.PlanYM = A.PlanYM AND B.PlanRev = A.PlanRev AND B.CustSeq = A.CustSeqOld AND B.ItemSeq = A.ItemSeqOld )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0 
            
            IF NOT EXISTS (SELECT 1 FROM #KPX_TSLMonthSalesPlan AS A -- ��Ʈ������ �ش絥���Ͱ� ������ �������̺� �����͵� ����� 
                                    JOIN KPX_TSLMonthSalesPlan AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.PlanYM = A.PlanYM AND B.PlanRev = A.PlanRev ) 
                          ) 
            BEGIN
                SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLMonthSalesPlanRev')    
                
                
                SELECT 1 AS IDX_NO, 
                       1 AS DataSeq, 
                       MAX(A.Status) AS Status, 
                       MAX(A.BizUnit) AS BizUnit, 
                       MAX(A.PlanYM) AS PlanYM, 
                       MAX(A.PlanRev) AS PlanRev, 
                       MAX(A.WorkingTag) AS WorkingTag
                  INTO #RevLog
                  FROM #KPX_TSLMonthSalesPlan AS A 
                
                EXEC _SCOMLog @CompanySeq   ,        
                              @UserSeq      ,        
                              'KPX_TSLMonthSalesPlanRev'    , -- ���̺��        
                              '#RevLog'    , -- �ӽ� ���̺��        
                              'BizUnit,PlanYM,PlanRev'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                               @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ�� 
                DELETE B
                  FROM #KPX_TSLMonthSalesPlan AS A 
                  JOIN KPX_TSLMonthSalesPlanRev AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.PlanYM = A.PlanYM AND B.PlanRev = A.PlanRev ) 
            END 
        END 
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TSLMonthSalesPlan WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.DVPlaceSeq = A.DVPlaceSeq,  
               B.CurrSeq = A.CurrSeq,  
               B.Price = A.Price,  
               B.PlanQty = A.PlanQty,  
               B.PlanCurAmt = A.PlanAmt,  
               B.PlanKorAmt = A.PlanDomAmt,  
               B.Remark = A.Remark,  
               B.EmpSeq = A.EmpSeq,  
               B.CustSeq = A.CustSeq, 
               B.ItemSeq = A.ItemSeq, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE() 
                 
          FROM #KPX_TSLMonthSalesPlan AS A   
          JOIN KPX_TSLMonthSalesPlan AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.PlanYM = A.PlanYM AND B.PlanRev = A.PlanRev AND B.CustSeq = A.CustSeqOld AND B.ItemSeq = A.ItemSeqOld )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TSLMonthSalesPlan WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TSLMonthSalesPlan  
          (    
            CompanySeq,BizUnit,PlanYM,PlanRev,CustSeq,  
            ItemSeq,DVPlaceSeq,CurrSeq,Price,PlanQty,  
            PlanCurAmt,PlanKorAmt,Remark,EmpSeq,LastUserSeq,  
            LastDateTime   
        )   
        SELECT @CompanySeq,A.BizUnit,A.PlanYM,A.PlanRev,A.CustSeq,  
               A.ItemSeq,A.DVPlaceSeq,A.CurrSeq,A.Price,A.PlanQty,  
               A.PlanAmt,A.PlanDomAmt,A.Remark,A.EmpSeq,@UserSeq,  
               GETDATE()   
          FROM #KPX_TSLMonthSalesPlan AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    UPDATE A 
       SET CustSeqOld = A.CustSeq, 
           ItemSeqOld = A.ItemSeq 
      FROM #KPX_TSLMonthSalesPlan AS A 
    
    SELECT * FROM #KPX_TSLMonthSalesPlan   
    
    
    
    RETURN  
GO 
begin tran 
EXEC KPX_SSLMonthSalesPlanSave @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BizUnit>2</BizUnit>
    <CurrName>KRW</CurrName>
    <CurrSeq>1</CurrSeq>
    <CustName>(��)����ǵ��ö�������</CustName>
    <CustNo>TEST101</CustNo>
    <CustSeq>37535</CustSeq>
    <CustSeqOld>37535</CustSeqOld>
    <UMCustClass>8004041</UMCustClass>
    <UMCustClassName>�������뱸��</UMCustClassName>
    <DVPlaceName />
    <DVPlaceSeq>0</DVPlaceSeq>
    <EmpName />
    <EmpSeq>0</EmpSeq>
    <EmpSeqOld>0</EmpSeqOld>
    <ItemClassLSeq>2003001</ItemClassLSeq>
    <ItemClassLName>�ﵿ��з�</ItemClassLName>
    <ItemClassMSeq>2002013</ItemClassMSeq>
    <ItemClassMName>���̽�ǰ</ItemClassMName>
    <ItemName>@��������������</ItemName>
    <ItemNo>@��������������</ItemNo>
    <ItemClassSeq>2001008</ItemClassSeq>
    <ItemClassName>���-������</ItemClassName>
    <ItemSeq>14532</ItemSeq>
    <ItemSeqOld>14532</ItemSeqOld>
    <PlanAmt>0.00000</PlanAmt>
    <PlanDomAmt>0.00000</PlanDomAmt>
    <PlanQty>0.00000</PlanQty>
    <PlanRev>03</PlanRev>
    <PlanYM>201411</PlanYM>
    <Price>0.00000</Price>
    <Remark />
    <Spec />
    <STDUnitName>EA</STDUnitName>
    <STDUnitSeq>2</STDUnitSeq>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1025841, @WorkingTag = N'SSDel', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 50322, @PgmSeq = 1021320



rollback 