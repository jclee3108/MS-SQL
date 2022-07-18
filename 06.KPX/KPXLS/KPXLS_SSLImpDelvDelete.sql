IF OBJECT_ID('KPXLS_SSLImpDelvDelete') IS NOT NULL 
    DROP PROC KPXLS_SSLImpDelvDelete
GO 

-- v2016.02.26 

-- LotNo Master ���� �߰� by����õ 

/*********************************************************************************************************************  
    ȭ��� : ��ü����
    SP Name: _SSLImpDelvDelete  
    �ۼ��� :     
    ������ :   
********************************************************************************************************************/  
  
CREATE PROCEDURE KPXLS_SSLImpDelvDelete
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
    CREATE TABLE #TUIImpDelv (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TUIImpDelv'    
  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   '_TUIImpDelv', -- �����̺��
                   '#TUIImpDelv', -- �������̺��  
                   'DelvSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                   'CompanySeq,DelvSeq,BizUnit,DelvDate,CustSeq,DelvNo,PermitSeq,BLSeq,InvoiceSeq,PaymentSeq,POSeq,EmpSeq,DeptSeq,
                    CurrSeq,ExRate,Remark,LastUserSeq,LastDateTime,SMImpKind'

                    
    EXEC _SCOMDeleteLog  @CompanySeq   ,  
                         @UserSeq      ,  
                         '_TUIImpDelvItem', -- �����̺��
                         '#TUIImpDelv', -- �������̺��  
                         'DelvSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                         'CompanySeq,DelvSeq,DelvSerl,ItemSeq,UnitSeq,Qty,Price,CurAmt,DomAmt,WHSeq,LotNo,FromSerl,ToSerl,ProdDate,STDUnitSeq,
                          STDQty,LastUserSeq,LastDateTime,OKCurAmt,OKDomAmt,AccSeq,VATAccSeq,OppAccSeq,SlipSeq,IsCostCalc,PJTSeq,WBSSeq,MakerSeq,Remark'
                    
    EXEC _SCOMDeleteLog  @CompanySeq   ,  
                         @UserSeq      ,  
                         '_TUIImpDelvCostDiv', -- �����̺��
                         '#TUIImpDelv', -- �������̺��  
                         'DelvSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                         'CompanySeq,DelvCostSeq,DelvCostDate,DelvSeq,AccDeptSeq,AccEmpSeq,Remark,SlipSeq,LastUserSeq,LastDateTime'


    EXEC _SCOMDeleteLog  @CompanySeq   ,  
                         @UserSeq      ,  
                         '_TUIImpDelvCostDivItem', -- �����̺��
                         '#TUIImpDelv', -- �������̺��  
                         'DelvSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                         'CompanySeq,DelvCostSeq,DelvSeq,DelvSerl,ExpenseSeq,ExpenseSerl,CurrSeq,ExRate,CurAmt,DomAmt,Remark,LastUserSeq,LastDateTime'

    

    -- DELETE                                                                                                  
    IF EXISTS (SELECT 1 FROM #TUIImpDelv WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        -- LotNo Master ���� 
        DELETE Z 
          FROM _TLGLotMaster AS Z 
          JOIN ( 
                SELECT B.ItemSeq, B.LotNo 
                  FROM #TUIImpDelv AS A 
                  JOIN _TUIImpDelvItem AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
                 WHERE A.WorkingTag = 'D' 
                   AND A.Status = 0 
               ) AS Y ON ( Y.LotNo = Z.LotNo AND Y.ItemSeq = Z.ItemSeq ) 
         WHERE Z.CompanySeq = @CompanySeq 
        
        -- Delv������
        DELETE _TUIImpDelv    
          FROM _TUIImpDelv AS A  
                JOIN #TUIImpDelv AS B ON A.CompanySeq = @CompanySeq AND A.DelvSeq = B.DelvSeq  
         WHERE B.WorkingTag = 'D'   
           AND B.Status = 0    
  
        IF @@ERROR <> 0 RETURN  
  
        -- Delv������
        DELETE _TUIImpDelvItem   
          FROM _TUIImpDelvItem AS A  
                JOIN #TUIImpDelv AS B ON A.CompanySeq = @CompanySeq AND A.DelvSeq = B.DelvSeq  
         WHERE B.WorkingTag = 'D'   
           AND B.Status = 0    
           
        IF @@ERROR <> 0 RETURN  


        DELETE _TUIImpDelvCostDiv   
          FROM _TUIImpDelvCostDiv AS A  
                JOIN #TUIImpDelv AS B ON A.CompanySeq = @CompanySeq AND A.DelvSeq = B.DelvSeq  
         WHERE B.WorkingTag = 'D'   
           AND B.Status = 0    
           
        IF @@ERROR <> 0 RETURN  


        DELETE _TUIImpDelvCostDivItem   
          FROM _TUIImpDelvCostDivItem AS A  
                JOIN #TUIImpDelv AS B ON A.CompanySeq = @CompanySeq AND A.DelvSeq = B.DelvSeq  
         WHERE B.WorkingTag = 'D'   
           AND B.Status = 0    
           
        IF @@ERROR <> 0 RETURN  
        
    END    
        
    SELECT * FROM #TUIImpDelv
    
    RETURN
GO


