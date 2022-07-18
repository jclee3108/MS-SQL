IF OBJECT_ID('KPXCM_SSLImportOrderDelete') IS NOT NULL 
    DROP PROC KPXCM_SSLImportOrderDelete
GO 

-- v2015.09.24 

-- MES���� �ǽð��ϱ� ���� ����Ʈ�� by����õ 
/*********************************************************************************************************************        
  
    Ver. 121004  
  
    ȭ��� : ����ORDER_����        
    SP Name: _SSLImportOrderDelete        
    �ۼ��� : 2009.06 : CREATEd by ���ظ�            
    ������ :         
********************************************************************************************************************/        
CREATE PROCEDURE KPXCM_SSLImportOrderDelete    
    @xmlDocument    NVARCHAR(MAX),          
    @xmlFlags       INT = 0,          
    @ServiceSeq     INT = 0,          
    @WorkingTag     NVARCHAR(10)= '',          
    @CompanySeq     INT = 1,          
    @LanguageSeq    INT = 1,          
    @UserSeq        INT = 0,          
    @PgmSeq         INT = 0          
AS               
    DECLARE @docHandle  INT        
        
        
    -- ���� ����Ÿ ��� ����          
    CREATE TABLE #TPUORDPO (WorkingTag NCHAR(1) NULL)          
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUORDPO'          
    IF @@ERROR <> 0 RETURN        
    
  
  
    --     �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)        
    EXEC _SCOMLog  @CompanySeq   ,        
                   @UserSeq      ,        
                   '_TPUORDPO', -- �����̺��        
                   '#TPUORDPO', -- �������̺��        
                   'POSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.         
                   'CompanySeq,POSeq,PONo,SMImpType,PODate,DeptSeq,EmpSeq,CustSeq,CurrSeq,ExRate,Payment,Remark,IsCustAccept,POAmd,IsDirectDelv,UnitAssySeq,    
                    IsConfirm,ConfirmDate,ConfirmEmpSeq,B2BTranCnt,IsPJT,POMngNo,SMProgStatus,ERP,LastUserSeq,LastDateTime'         
        
    
    EXEC _SCOMDeleteLog  @CompanySeq   ,        
                         @UserSeq      ,        
                         '_TPUORDPOItem', -- �����̺��        
                         '#TPUORDPO', -- �������̺��        
                         'POSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.         
                         'CompanySeq,POSeq,POSerl,ItemSeq,UnitSeq,Qty,Price,CurAmt,MakerSeq,DelvDate,DomAmt,Remark1,Remark2,SMPriceType,SMPayType,POAmd,WhSeq,DelvTime,    
                          POReqSeq,POReqSerl,StdUnitSeq,StdUnitQty,SourceType,SourceSeq,SourceSerl,UnitAssySeq,IsConfirm,ConfirmDate,ConfirmEmpSeq,ChgDelvDate,PJTSeq,    
                          WBSSeq,CurVAT,DomPrice,DomVAT,IsVAT,LastUserSeq,LastDateTime'        
  
    EXEC _SCOMDeleteLog  @CompanySeq   ,        
                         @UserSeq      ,        
                         '_TSLImpOrder', -- �����̺��        
                         '#TPUORDPO', -- �������̺��        
                         'POSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.         
                         'CompanySeq,POSeq,BizUnit,POAmd,PORefNo,BKCustSeq,UMPriceTerms,UMPayment1,UMPayment2,Payment3,UMShipVia,Packing,LoadingPort,ETD,DischargingPort,ETA,Destination,CountryOfOrigin,Validity,Remark,LastUserSeq,LastDateTime,Memo,IsPJT,FundAccSeq,PrePaymentDate,PaymentBankSeq,PaymentAmt,FileSeq'  
    
    
    -- I/F Table �ݿ� 
    DECLARE @POSeq      INT, 
            @BizUnit    INT  
    
    SELECT @POSeq = (SELECT MAX(POSeq) FROM #TPUORDPO) 
    
    
    SELECT @BizUnit = (SELECT TOP 1 BizUnit
                         FROM (SELECT BizUnit
                                 FROM _TSLImpOrder 
                                WHERE CompanySeq = @CompanySeq 
                                  AND POSeq = @POSeq
                               
                               UNION 
                               
                               SELECT BizUnit 
                                 FROM _TSLImpOrderLog 
                                WHERE CompanySeq = @CompanySeq 
                                  AND POSeq = @POSeq 
                              ) AS A
                      )

    IF @BizUnit = 26 AND (SELECT MAX(WorkingTag) FROM #TPUORDPO) = 'D' 
    BEGIN 
        
        SELECT @CompanySeq AS CompanySeq, 
               @BizUnit AS BizUnit, 
               A.POSeq, 
               A.POSerl, 
               B.PONo,
               B.PODate, 
               C.CustName, 
               D.ItemNo, 
               D.Spec, 
               E.UnitName, 
               ISNULL(CONVERT(FLOAT,G.MngValText ),0) AS LotUnitQty, 
               CONVERT(INT,A.StdUnitQty) AS LotQty, 
               Z.WorkingTag, 
               '0'               AS ProcYn,
               'N'               AS ConfirmFlag,   
               GetDate()         AS CreateTime,  
               ''                AS UpdateTime, 
               ''                AS ConfirmTime,
               ''                AS ErrorMessage,
               CASE WHEN B.SmImpType = 8008001   THEN '0' ELSE '1' END AS ImpType 
          INTO #IF_PUDelv_MES     
          FROM #TPUORDPO AS Z 
          LEFT OUTER JOIN _TPUORDPO         AS B WITH(NOLOCK) ON ( B.POSeq = Z.POSeq ) 
          LEFT OUTER JOIN _TPUORDPOItem     AS A WITH(NOLOCK) ON ( A.POSeq = Z.POSeq ) 
          LEFT OUTER JOIN _TDACust          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = B.CustSeq ) 
          LEFT OUTER JOIN _TDAItem          AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN _TDAUnit          AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.UnitSeq = D.UnitSeq ) 
          LEFT OUTER JOIN _TDAItemUserDefine AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq And G.ItemSeq = D.ItemSeq And G.MngSerl = '1000012' ) 
          OUTER APPLY (SELECT Z.BizUnit
                         FROM _TSLImpOrder AS Z 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND Z.POSeq = @POSeq
                      
                       UNION 
                       
                       SELECT Z.BizUnit
                         FROM _TSLImpOrderLog AS Z 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND Z.POSeq = @POSeq
                      ) AS H 
         WHERE H.BizUnit = 26 
    
        INSERT INTO IF_PUDelv_MES
        (
            CompanySeq,BizUnit,POSeq,PONo,POSerl,PODate,CustName, 
            ItemNo,Spec,UnitName,LotUnitQty,LotQty,WorkingTag,ProcYn, 
            ConfirmFlag,CreateTime,UpdateTime,ConfirmTime,ErrorMessage,ImpType
        )  
        SELECT CompanySeq, BizUnit, POSeq, PONo, POSerl, PODate, CustName, 
               ItemNo, Spec, UnitName, LotUnitQty, LotQty, WorkingTag, ProcYn, 
               ConfirmFlag, CreateTime, UpdateTime, ConfirmTime, ErrorMessage, ImpType 
          FROM #IF_PUDelv_MES  
    END -- MES �ݿ� end 
    
    
    -- DELETE                                                                                                        
    IF EXISTS (SELECT 1 FROM #TPUORDPO WHERE WorkingTag = 'D' AND Status = 0 )          
    BEGIN          
        -- �����Ƿڸ�����        
        DELETE _TPUORDPO          
          FROM _TPUORDPO AS A        
                JOIN #TPUORDPO AS B ON A.CompanySeq = @CompanySeq AND A.POSeq = B.POSeq        
         WHERE B.WorkingTag = 'D'         
           AND B.Status = 0          
        
        IF @@ERROR <> 0 RETURN        
        
        -- �����Ƿ�ǰ��        
        DELETE _TPUORDPOItem         
          FROM _TPUORDPOItem AS A        
                JOIN #TPUORDPO AS B ON A.CompanySeq = @CompanySeq AND A.POSeq = B.POSeq        
         WHERE B.WorkingTag = 'D'         
           AND B.Status = 0          
                 
        IF @@ERROR <> 0 RETURN        
              
        -- ����invoice ������      
        DELETE _TSLImpOrder          
          FROM _TSLImpOrder AS A        
              JOIN #TPUORDPO AS B ON A.CompanySeq = @CompanySeq AND A.POSeq = B.POSeq        
         WHERE B.WorkingTag = 'D'         
           AND B.Status = 0          
        
        IF @@ERROR <> 0 RETURN        
    END          
    
    

    
    
    SELECT * FROM #TPUORDPO         
          
RETURN     
go
begin tran 
exec KPXCM_SSLImportOrderDelete @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <POSeq>38519256</POSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031398,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025120

select * From IF_PUDelv_MES


rollback