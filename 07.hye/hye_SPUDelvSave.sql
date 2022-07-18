IF OBJECT_ID('hye_SPUDelvSave') IS NOT NULL 
    DROP PROC hye_SPUDelvSave
GO 

-- v2016.09.29 

-- ���ų�ǰ�Է�_���� by����õ 
/************************************************************  
��  �� - ���ų�ǰ����
�ۼ��� - 2008�� 8�� 20��   
�ۼ��� - �뿵��  
UPDATE :: ���ų�ǰ������ '��ǰ������ȣ(DelvMngNo)' �׸� �߰� :: 11.04.25 BY �輼ȣ
UPDATE :: ������ ǰ�������� �Բ� �����صǹǷ� ���ų�ǰǰ�����̺� ���� �α׸� ���⵵�� ���� :: 12.07.25 BY ��³�
************************************************************/     
CREATE PROC hye_SPUDelvSave     
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
  
    -- PgmSeq �۾� 2014�� 07�� 20�� �ϰ� �۾��մϴ�. (���� ����ȭ �Ǹ� ��������) 
    IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelv' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
    BEGIN
           ALTER TABLE _TPUDelv ADD PgmSeq INT NULL
    END 

    IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelvLog' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
    BEGIN
           ALTER TABLE _TPUDelvLog ADD PgmSeq INT NULL
    END  
    
    -- PgmSeq �۾� 2014�� 07�� 20�� �ϰ� �۾��մϴ�. (���� ����ȭ �Ǹ� ��������) 
    IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelvItem' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
    BEGIN
           ALTER TABLE _TPUDelvItem ADD PgmSeq INT NULL
    END 

    IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPUDelvItemLog' AND A.xtype = 'U' AND B.Name = 'PgmSeq')
    BEGIN
           ALTER TABLE _TPUDelvItemLog ADD PgmSeq INT NULL
    END  
      
   -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)      
    EXEC _SCOMLog   @CompanySeq       ,      
                    @UserSeq          ,      
                    '_TPUDelv', -- �����̺��      
                    '#TPUDelv'    , -- �������̺��      
                    'DelvSeq'    , -- Ű�� �������� ���� , �� �����Ѵ�.       
                    'CompanySeq,DelvSeq,BizUnit,DelvNo,SMImpType,
                     DelvDate,DeptSeq,EmpSeq,CustSeq,CurrSeq,
                     ExRate,SMDelvType,Remark,IsPJT,SMStkType,
                     IsReturn,LastUserSeq,LastDateTime,PgmSeq'
                     ,'',@PgmSeq    
     
--    EXEC dbo._SCOMEnv @CompanySeq,6500,@UserSeq,@@PROCID,@QCAutoIn OUTPUT
  
--    IF @QCAutoIn = '1'
--    BEGIN
--        -------------------
--        --�԰����࿩��-----
--        -------------------
--        CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))    
--          
--        CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsDelvIn NCHAR(1))            
--    
--        CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))      
--    
--        CREATE TABLE #OrderTracking(IDX_NO INT, Qty DECIMAL(19,5), POCurAmt DECIMAL(19,5))
--    
--        INSERT #TMP_PROGRESSTABLE     
--        SELECT 1, '_TPUDelvInItem'               -- �����԰�
--
--        -- ���ų�ǰ
--        INSERT INTO #Temp_Order(OrderSeq, OrderSerl, IsDelvIn)    
--        SELECT  A.DelvSeq, A.DelvSerl, '2'    
--          FROM #TPUDelv AS A WITH(NOLOCK)  
--               JOIN _TPUDelvItem AS B ON A.DelvSeq    = B.DelvSeq
--                                     AND B.CompanySeq = @CompanySeq   
--         WHERE A.WorkingTag IN ('U')
--           AND A.Status = 0
--           AND B.SMQCType NOT IN( '6035002', '6035003', '6035004', '6035005', '6035006' ) 
--
--        EXEC _SCOMProgressTracking @CompanySeq, '_TPUDelvItem', '#Temp_Order', 'OrderSeq', '', ''           
--        
--        INSERT INTO #OrderTracking    
--        SELECT IDX_NO,    
--               SUM(CASE IDOrder WHEN 1 THEN Qty     ELSE 0 END),    
--               SUM(CASE IDOrder WHEN 1 THEN Amt     ELSE 0 END)   
--          FROM #TCOMProgressTracking    
--         GROUP BY IDX_No    
--
--        UPDATE #Temp_Order 
--          SET IsDelvIn = '1'
--         FROM  #Temp_Order AS A  JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No
--        -----------------------
--        --�԰����࿩��END------
--        -----------------------
--    END  
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
                    IsReturn,LastUserSeq,LastDateTime,MakerSeq,SourceSeq,SourceSerl, PgmSeq'    
                    ,'', @PgmSeq

      
        DELETE _TPUDelv        
          FROM _TPUDelv       AS A WITH(NOLOCK)      
                JOIN #TPUDelv AS B WITH(NOLOCK) ON A.CompanySeq  = @CompanySeq     
                                                  AND A.DelvSeq     = B.DelvSeq       
         WHERE B.WorkingTag = 'D'       
           AND B.Status = 0        
               
        IF @@ERROR <> 0 RETURN      
    
        DELETE _TPUDelvItem        
          FROM _TPUDelvItem   AS A WITH(NOLOCK)      
                JOIN #TPUDelv AS B WITH(NOLOCK) ON A.CompanySeq = @CompanySeq     
                                                   AND A.DelvSeq  = B.DelvSeq       
         WHERE B.WorkingTag = 'D'       
           AND B.Status = 0        
               
        IF @@ERROR <> 0 RETURN  
        
        DELETE _TPUDelv_Confirm        
          FROM _TPUDelv_Confirm   AS A WITH(NOLOCK)      
                JOIN #TPUDelv    AS B ON A.CompanySeq = @CompanySeq     
                                     AND A.CfmSeq  = B.DelvSeq       
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
--                IsPJT        = B.IsPJT        ,
                SMStkType    = B.SMStkType    ,
                IsReturn     = B.IsReturn     ,
                LastUserSeq   =  @UserSeq       ,  
                LastDateTime  =  GETDATE()    ,  
                DelvMngNo     = B.DelvMngNo   ,          -- 11.04.25 �輼ȣ �߰�
                PgmSeq        = @PgmSeq
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
                             IsReturn      ,LastUserSeq   ,LastDateTime  ,DelvMngNo     ,PgmSeq                   -- 11.04.25 �輼ȣ �߰�
                                )    
        SELECT  @CompanySeq   ,DelvSeq       ,BizUnit       ,DelvNo        ,SMImpType     ,
                DelvDate      ,DeptSeq       ,EmpSeq        ,CustSeq       ,CurrSeq       ,
                ExRate        ,SMDelvType    ,Remark        ,IsPJT         ,SMStkType     ,
                IsReturn      ,@UserSeq    ,   GETDATE()    ,DelvMngNo     ,@PgmSeq                          -- 11.04.25 �輼ȣ �߰�
              FROM #TPUDelv        
             WHERE WorkingTag = 'A' AND Status = 0        
                   
        IF @@ERROR <> 0 RETURN      
    END      
            
     
    
    Select * FROM #TPUDelv      
      
RETURN