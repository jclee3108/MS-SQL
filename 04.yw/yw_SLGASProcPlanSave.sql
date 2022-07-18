
IF OBJECT_ID('yw_SLGASProcPlanSave') IS NOT NULL
    DROP PROC yw_SLGASProcPlanSave
GO

-- v2013.07.17

-- ASó�����_YW(����) by����õ
CREATE PROC yw_SLGASProcPlanSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS   
    	
    CREATE TABLE #YW_TLGASProcPlan (WorkingTag NCHAR(1) NULL) 
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TLGASProcPlan' 
    IF @@ERROR <> 0 RETURN 
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('YW_TLGASProcPlan')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'YW_TLGASProcPlan'    , -- ���̺��        
                  '#YW_TLGASProcPlan'    , -- �ӽ� ���̺��        
                  'ASRegSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   	    
    
    UPDATE #YW_TLGASProcPlan
       SET WorkingTag = 'U'
      FROM #YW_TLGASProcPlan AS A
     WHERE ASRegSeq IN (SELECT ASRegSeq FROM YW_TLGASProcPlan WHERE CompanySeq = 1)
       AND WorkingTag = 'U'
       
    UPDATE #YW_TLGASProcPlan
       SET WorkingTag = 'A'
      FROM #YW_TLGASProcPlan AS A
     WHERE ASRegSeq NOT IN (SELECT ASRegSeq FROM YW_TLGASProcPlan WHERE CompanySeq = 1)
       AND WorkingTag = 'U'
    
    

    -- �۾����� : DELETE -> UPDATE -> INSERT 

	-- DELETE    
	IF EXISTS (SELECT TOP 1 1 FROM #YW_TLGASProcPlan WHERE WorkingTag = 'D' AND Status = 0)  
	BEGIN  
        DELETE B
          FROM #YW_TLGASProcPlan A 
          JOIN YW_TLGASProcPlan B ON ( B.CompanySeq = @CompanySeq AND A.ASRegSeq = B.ASRegSeq ) 
                 
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0  
          
        IF @@ERROR <> 0  RETURN
    
	END  


	-- UPDATE    
	IF EXISTS (SELECT 1 FROM #YW_TLGASProcPlan WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE B
           SET UMLastDecision   = A.UMLastDecision, 
               UMLotMagnitude   = A.UMLotMagnitude, 
               UMBadMagnitude   = A.UMBadMagnitude, 
               UMMkind          = A.UMMkind, 
               UMMtype          = A.UMMtype, 
               UMIsEnd          = A.UMIsEnd, 
               UMProbleSubItem  = A.UMProbleSubItem, 
               UMProbleSemiItem = A.UMProbleSemiItem,	
               UMBadType        = A.UMBadType,
               UMBadLKind       = A.UMBadLKind,
               UMBadMKind       = A.UMBadMKind,
               UMResponsType    = A.UMResponsType, 
               ResponsProc      = A.ResponsProc, 
               ResponsDept      = A.ResponsDept, 
               ProcDept         = A.ProcDept, 
               ProbleCause      = A.ProbleCause, 
               ImsiProc         = A.ImsiProc, 
               ImsiEmp          = A.ImsiEmp, 
               ImsiDate         = A.ImsiDate, 	
               RootProc         = A.RootProc, 	
               RootEmp          = A.RootEmp, 
               RootDate         = A.RootDate, 	
               EndDate          = A.EndDate, 
               LastUserSeq      = @UserSeq, 
               LastDateTime     = GetDate() 
        
          FROM #YW_TLGASProcPlan AS A 
          JOIN YW_TLGASProcPlan AS B ON ( B.CompanySeq = @CompanySeq AND A.ASRegSeq = B.ASRegSeq ) 
         
         WHERE A.WorkingTag = 'U' 
           AND A.Status = 0    

        IF @@ERROR <> 0  RETURN
    END  
    
    -- INSERT
    IF EXISTS (SELECT 1 FROM #YW_TLGASProcPlan WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO YW_TLGASProcPlan 
        (
         CompanySeq  , ASRegSeq   , UMLastDecision   , UMLotMagnitude  , UMBadMagnitude   ,									
         UMMkind     , UMMtype    , UMIsEnd          , UMProbleSubItem , UMProbleSemiItem , 
         UMBadType   , UMBadLKind , UMBadMKind       , UMResponsType   , ResponsProc      ,
         ResponsDept , ProcDept   , ProbleCause      , ImsiProc        , ImsiEmp          ,
         ImsiDate    , RootProc   , RootEmp,RootDate , EndDate         , LastUserSeq      , LastDateTime
        ) 
        SELECT @CompanySeq , ASRegSeq   , UMLastDecision   , UMLotMagnitude  , UMBadMagnitude   ,									
               UMMkind     , UMMtype    , UMIsEnd          , UMProbleSubItem , UMProbleSemiItem , 
               UMBadType   , UMBadLKind , UMBadMKind       , UMResponsType   , ResponsProc      ,
               ResponsDept , ProcDept   , ProbleCause      , ImsiProc        , ImsiEmp          ,
               ImsiDate    , RootProc   , RootEmp,RootDate , EndDate         , @UserSeq         , GetDate() 
    
          FROM #YW_TLGASProcPlan AS A   
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0    
    
        IF @@ERROR <> 0 RETURN
    
    END   
    
    SELECT * FROM #YW_TLGASProcPlan 
    
    RETURN    

GO
begin tran
exec yw_SLGASProcPlanSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ASRegSeq>48</ASRegSeq>
    <ASRegDate>20130717</ASRegDate>
    <ASRegNo>AS-201307-0022</ASRegNo>
    <ASState>ff</ASState>
    <BadRate>1.00000</BadRate>
    <Confirm>0</Confirm>
    <CustEmpName>����õ</CustEmpName>
    <CustItemName>11</CustItemName>
    <CustName>(��)���Ѱ����򰡹���</CustName>
    <CustRemark>fffffff</CustRemark>
    <CustSeq>37606</CustSeq>
    <EndDate>20130712</EndDate>
    <ImsiDate>23</ImsiDate>
    <ImsiEmp>251</ImsiEmp>
    <ImsiEmpName>anh</ImsiEmpName>
    <ImsiProc>31</ImsiProc>
    <IsStop>1</IsStop>
    <ItemName>12345678901234567890123456789012345678901</ItemName>
    <ItemNo>12345612</ItemNo>
    <ItemSeq>24789</ItemSeq>
    <OrderItemNo>130700039</OrderItemNo>
    <OutDate xml:space="preserve">        </OutDate>
    <ProbleCause>2</ProbleCause>
    <ProcDept>1512</ProcDept>
    <ProcDeptName>3</ProcDeptName>
    <ResponsDept>131</ResponsDept>
    <ResponsProc>12</ResponsProc>
    <RootDate>123412</RootDate>
    <RootEmp>251</RootEmp>
    <RootEmpName>anh</RootEmpName>
    <RootProc>12</RootProc>
    <Sel>0</Sel>
    <SMLocalType>8918001</SMLocalType>
    <SMLocalTypeName>����</SMLocalTypeName>
    <TargetQty>5.00000</TargetQty>
    <UMASMClass>10011001</UMASMClass>
    <UMASMClassName>TestM</UMASMClassName>
    <UMBadLKind>1008287002</UMBadLKind>
    <UMBadLKindName>�ҷ�������2</UMBadLKindName>
    <UMBadMagnitude>1008280001</UMBadMagnitude>
    <UMBadMagnitudeName>�����ɰ���1</UMBadMagnitudeName>
    <UMBadMKind>1008288002</UMBadMKind>
    <UMBadMKindName>�ҷ�������2</UMBadMKindName>
    <UMBadType>1008286002</UMBadType>
    <UMBadTypeName>�ҷ�����2</UMBadTypeName>
    <UMFindKind>1008276001</UMFindKind>
    <UMFindKindName>�԰�˻�</UMFindKindName>
    <UMIsEnd>1008283001</UMIsEnd>
    <UMIsEndName>���Ῡ��1</UMIsEndName>
    <UMLastDecision>1008278001</UMLastDecision>
    <UMLastDecisionName>�����Ǵ�1</UMLastDecisionName>
    <UMLotMagnitude>1008279001</UMLotMagnitude>
    <UMLotMagnitudeName>Lot�ɰ���1</UMLotMagnitudeName>
    <UMMkind>1008281001</UMMkind>
    <UMMkindName>4m�з�1</UMMkindName>
    <UMMtype>1008282001</UMMtype>
    <UMMtypeName>4m����1</UMMtypeName>
    <UMProbleSemiItem>1008285002</UMProbleSemiItem>
    <UMProbleSemiItemName>������ǰ2</UMProbleSemiItemName>
    <UMProbleSubItem>1008284002</UMProbleSubItem>
    <UMProbleSubItemName>��������ǰ2</UMProbleSubItemName>
    <UMResponsType>1008289001</UMResponsType>
    <UMResponsTypeName>��å����1</UMResponsTypeName>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ASRegSeq>49</ASRegSeq>
    <ASRegDate>20130717</ASRegDate>
    <ASRegNo>AS-201307-0023</ASRegNo>
    <ASState>����������������</ASState>
    <BadRate>123.00000</BadRate>
    <Confirm>1</Confirm>
    <CustEmpName>����õ</CustEmpName>
    <CustItemName />
    <CustName>(��)�������ӽ���</CustName>
    <CustRemark>��������</CustRemark>
    <CustSeq>42125</CustSeq>
    <EndDate>20130712</EndDate>
    <ImsiDate>23</ImsiDate>
    <ImsiEmp>251</ImsiEmp>
    <ImsiEmpName>anh</ImsiEmpName>
    <ImsiProc>31</ImsiProc>
    <IsStop>0</IsStop>
    <ItemName>��ǳ��_����</ItemName>
    <ItemNo>��ǳ��_����</ItemNo>
    <ItemSeq>24762</ItemSeq>
    <OrderItemNo>20120210</OrderItemNo>
    <OutDate>20130712</OutDate>
    <ProbleCause>2</ProbleCause>
    <ProcDept>1512</ProcDept>
    <ProcDeptName>3</ProcDeptName>
    <ResponsDept>131</ResponsDept>
    <ResponsProc>12</ResponsProc>
    <RootDate>12</RootDate>
    <RootEmp>251</RootEmp>
    <RootEmpName>anh</RootEmpName>
    <RootProc>12</RootProc>
    <Sel>0</Sel>
    <SMLocalType>8918001</SMLocalType>
    <SMLocalTypeName>����</SMLocalTypeName>
    <TargetQty>23.00000</TargetQty>
    <UMASMClass>10011001</UMASMClass>
    <UMASMClassName>TestM</UMASMClassName>
    <UMBadLKind>1008287002</UMBadLKind>
    <UMBadLKindName>�ҷ�������2</UMBadLKindName>
    <UMBadMagnitude>1008280001</UMBadMagnitude>
    <UMBadMagnitudeName>�����ɰ���1</UMBadMagnitudeName>
    <UMBadMKind>1008288002</UMBadMKind>
    <UMBadMKindName>�ҷ�������2</UMBadMKindName>
    <UMBadType>1008286002</UMBadType>
    <UMBadTypeName>�ҷ�����2</UMBadTypeName>
    <UMFindKind>1008276001</UMFindKind>
    <UMFindKindName>�԰�˻�</UMFindKindName>
    <UMIsEnd>1008283001</UMIsEnd>
    <UMIsEndName>���Ῡ��1</UMIsEndName>
    <UMLastDecision>1008278001</UMLastDecision>
    <UMLastDecisionName>�����Ǵ�1</UMLastDecisionName>
    <UMLotMagnitude>1008279001</UMLotMagnitude>
    <UMLotMagnitudeName>Lot�ɰ���1</UMLotMagnitudeName>
    <UMMkind>1008281001</UMMkind>
    <UMMkindName>4m�з�1</UMMkindName>
    <UMMtype>1008282001</UMMtype>
    <UMMtypeName>4m����1</UMMtypeName>
    <UMProbleSemiItem>1008285002</UMProbleSemiItem>
    <UMProbleSemiItemName>������ǰ2</UMProbleSemiItemName>
    <UMProbleSubItem>1008284002</UMProbleSubItem>
    <UMProbleSubItemName>��������ǰ2</UMProbleSubItemName>
    <UMResponsType>1008289001</UMResponsType>
    <UMResponsTypeName>��å����1</UMResponsTypeName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016629,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014197
rollback