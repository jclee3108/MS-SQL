
IF OBJECT_ID('DTI_SPUDelvSave') IS NOT NULL 
    DROP PROC DTI_SPUDelvSave
GO 

-- v2013.12.29 

-- ���ų�ǰ�Է�_DIT(����������) by����õ
CREATE PROC DTI_SPUDelvSave       
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT = 0,        
    @ServiceSeq     INT = 0,        
    @WorkingTag     NVARCHAR(10) = '',        
    @CompanySeq     INT = 0,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0        
AS        
        
    -- ���� ����        
    DECLARE  @docHandle     INT,        
             @LotSeq        INT,        
             @count         INT,  
             @QCAutoIn      NCHAR(1)        
    
    -- �ӽ� ���̺� ����        
    CREATE TABLE #TPUDelv (WorkingTag NCHAR(1) NULL)        
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUDelv'        
    --select * from #TPUDelv 
    --return 
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)        
    EXEC _SCOMLog   @CompanySeq       ,        
                    @UserSeq          ,        
                    '_TPUDelv', -- �����̺��        
                    '#TPUDelv'    , -- �������̺��        
                    'DelvSeq'    , -- Ű�� �������� ���� , �� �����Ѵ�.         
                    'CompanySeq,DelvSeq,BizUnit,DelvNo,SMImpType,  
                     DelvDate,DeptSeq,EmpSeq,CustSeq,CurrSeq,  
                     ExRate,SMDelvType,Remark,IsPJT,SMStkType,  
                     IsReturn,LastUserSeq,LastDateTime'      
    
    -- DELETE                                                                                                        
    IF EXISTS (SELECT 1 FROM #TPUDelv WHERE WorkingTag = 'D' AND Status = 0 )          
    BEGIN    
  
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
    EXEC _SCOMDeleteLog  @CompanySeq   ,  
                         @UserSeq      ,  
                       '_TPUDelvItem', -- �����̺��      
                       '#TPUDelv', -- �������̺��      
                       'DelvSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.       
                       'CompanySeq,DelvSeq,DelvSerl,ItemSeq,UnitSeq,      
                        Price,Qty,CurAmt,CurVAT,DomPrice,      
                        DomAmt,DomVAT,IsVAT,StdUnitSeq,StdUnitQty,      
                        SMQcType,QcEmpSeq,QcDate,QcQty,QcCurAmt,      
                        WHSeq,LOTNo,FromSerial,ToSerial,SalesCustSeq,      
                        DelvCustSeq,PJTSeq,WBSSeq,UMDelayType,Remark,      
                        IsReturn,LastUserSeq,LastDateTime,MakerSeq,SourceSeq,SourceSerl'   
                        
      ---- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
      --EXEC _SCOMLog  @CompanySeq   ,  
      --         @UserSeq      ,  
      --         'DTI_TLGLotOrderConnect', -- �����̺��  
      --         '#TPUDelv', -- �������̺��  
      --         'LotNo, ItemSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
      --         'CompanySeq, LotNo, ItemSeq, OrderSeq, OrderSerl, OrderAllocSerl, LotQty, LastUserSeq, LastDateTime'  
    
    --select * from DTI_TLGLotOrderConnectlog 
        DELETE _TPUDelv          
          FROM _TPUDelv       AS A WITH(NOLOCK)        
          JOIN #TPUDelv AS B WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.DelvSeq = B.DelvSeq ) 
         WHERE B.WorkingTag = 'D'         
           AND B.Status = 0          
        
        IF @@ERROR <> 0 RETURN        
        
        -- ���ֿ������� DELETE 
        DELETE DTI_TLGLotOrderConnect 
          FROM #TPUDelv AS A 
          JOIN _TPUDelvItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
          JOIN DTI_TSLContractMngItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ContractSeq = CONVERT(INT,Memo3) AND C.ContractSerl = CONVERT(INT,Memo4) ) 
          JOIN _TSLOrderItem          AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND CONVERT(INT,Dummy6) = C.ContractSeq AND CONVERT(INT,Dummy7) = C.ContractSerl ) 
          JOIN DTI_TLGLotOrderConnect AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq 
                                                         AND E.OrderSeq = D.OrderSeq 
                                                         AND E.OrderSerl = D.OrderSerl 
                                                         AND ISNULL(E.LotNo,'') = ISNULL(B.LotNo,'') 
                                                         AND E.ItemSeq = B.ItemSeq 
                                                           ) 
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0 
        
        -- ���ֿ������� DELETE, END
        
        DELETE _TPUDelvItem          
          FROM _TPUDelvItem   AS A WITH(NOLOCK)        
                JOIN #TPUDelv AS B WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.DelvSeq = B.DelvSeq ) 
         WHERE B.WorkingTag = 'D'         
           AND B.Status = 0          
        
        IF @@ERROR <> 0 RETURN        
        
    END          
    
    -- Update                                                                                                         
    IF EXISTS (SELECT 1 FROM #TPUDelv WHERE WorkingTag = 'U' AND Status = 0 )          
    BEGIN           
    
    
        UPDATE _TPUDelv          
           SET  BizUnit      = B.BizUnit      ,  
                DelvNo       = B.DelvNo       ,  
                SMImpType    = B.SMImpType    ,  
                DelvDate     = B.DelvDate     ,  
                DeptSeq      = B.DeptSeq      ,  
                EmpSeq       = B.EmpSeq       ,  
                CustSeq      = B.CustSeq      ,  
                CurrSeq      = B.CurrSeq      ,  
                ExRate       = B.ExRate       ,  
                SMDelvType   = B.SMDelvType   ,  
                Remark       = B.Remark       ,  
                SMStkType    = B.SMStkType    ,  
                IsReturn     = B.IsReturn     ,  
                LastUserSeq   =  @UserSeq       ,    
                LastDateTime  =  GETDATE()    ,    
                DelvMngNo     = B.DelvMngNo             -- 11.04.25 �輼ȣ �߰�  
         FROM _TPUDelv      AS A WITH(NOLOCK)         
              JOIN #TPUDelv AS B WITH(NOLOCK) ON A.CompanySeq  = @CompanySeq       
                                                AND A.DelvSeq     = B.DelvSeq         
          
         WHERE B.WorkingTag = 'U'         
           AND B.Status = 0        
                 
        IF @@ERROR <> 0 RETURN     
    END           
      
    -- INSERT                               
    IF EXISTS (SELECT 1 FROM #TPUDelv WHERE WorkingTag = 'A' AND Status = 0 )          
    BEGIN          
        INSERT INTO _TPUDelv(CompanySeq    ,DelvSeq       ,BizUnit       ,DelvNo        ,SMImpType     ,  
                             DelvDate      ,DeptSeq       ,EmpSeq        ,CustSeq       ,CurrSeq       ,  
                             ExRate        ,SMDelvType    ,Remark        ,IsPJT         ,SMStkType     ,  
                             IsReturn      ,LastUserSeq   ,LastDateTime  ,DelvMngNo                      -- 11.04.25 �輼ȣ �߰�  
                                )      
        SELECT  @CompanySeq   ,DelvSeq       ,BizUnit       ,DelvNo        ,SMImpType     ,  
                DelvDate      ,DeptSeq       ,EmpSeq        ,CustSeq       ,CurrSeq       ,  
                ExRate        ,SMDelvType    ,Remark        ,IsPJT         ,SMStkType     ,  
                  IsReturn      ,@UserSeq    ,   GETDATE()     ,DelvMngNo                                   -- 11.04.25 �輼ȣ �߰�  
              FROM #TPUDelv          
             WHERE WorkingTag = 'A' AND Status = 0          
                     
        IF @@ERROR <> 0 RETURN        
    END        
              
    SELECT * FROM #TPUDelv        
    
    RETURN 
GO
begin tran 
exec DTI_SPUDelvSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <DelvSeq>1000494</DelvSeq>
    <DelvNo>201312290005</DelvNo>
    <DelvDate>20131229</DelvDate>
    <CustName>���Űŷ�ó_����õ</CustName>
    <CustSeq>42540</CustSeq>
    <DeptName>���������</DeptName>
    <DeptSeq>147</DeptSeq>
    <EmpName>����õ</EmpName>
    <EmpSeq>2028</EmpSeq>
    <Remark />
    <SMImpType>8008001</SMImpType>
    <CurrSeq>1</CurrSeq>
    <CurrName>KRW</CurrName>
    <ExRate>1.00000</ExRate>
    <CustNo>���Űŷ�ó_����õ</CustNo>
    <SMDelvType>6034001</SMDelvType>
    <SMStkType>6033001</SMStkType>
    <InOutType>160</InOutType>
    <BizUnit>1</BizUnit>
    <BizUnitName>�ƻ����</BizUnitName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015948,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001553
select * from DTI_TLGLotOrderConnect where companyseq =1 and orderseq = 1000504
rollback        