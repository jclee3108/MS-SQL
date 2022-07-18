IF OBJECT_ID('KPXCM_SLGInOutDailyBatch_MES') IS NOT NULL    
    DROP PROC KPXCM_SLGInOutDailyBatch_MES
GO 

-- v2015.09.23 KPXCM MES ��


-- v2012.09.20   
   
 /*    
 CREATE TABLE _TLGInOutDaily    
 (    
     CompanySeq  INT   NOT NULL,     
     InOutSeq  INT   NOT NULL,     
     BizUnit  INT   NOT NULL,     
     InOutNo  NCHAR(12)   NOT NULL,     
     FactUnit  INT   NOT NULL,     
     ReqBizUnit  INT   NOT NULL,     
     DeptSeq  INT   NOT NULL,     
     EmpSeq  INT   NOT NULL,     
     InOutDate  NCHAR(8)   NOT NULL,     
     WCSeq  INT   NOT NULL,     
     ProcSeq  INT   NOT NULL,     
     CustSeq  INT   NOT NULL,     
     OutWHSeq  INT   NOT NULL,     
     InWHSeq  INT   NOT NULL,     
     DVPlaceSeq  INT   NOT NULL,     
     IsTrans  NCHAR(1)   NOT NULL,     
     IsCompleted  NCHAR(1)   NOT NULL,     
     CompleteDeptSeq  INT   NOT NULL,     
     CompleteEmpSeq  INT   NOT NULL,     
     CompleteDate  NCHAR(8)   NOT NULL,     
     InOutType  INT   NOT NULL,     
     InOutDetailType  INT   NOT NULL,     
     Remark  NVARCHAR(200)   NOT NULL,     
     Memo  NVARCHAR(200)   NOT NULL,     
     LastUserSeq  INT   NULL,     
     LastDateTime  DATETIME   NULL    
 )    
     
 */    
 /*************************************************************************************************        
  ��  �� - �����Master ����        
  �ۼ��� - 2008.10 : CREATED BY ����ȯ        
     
 exec _SLGInOutDailyBatch @xmlDocument=N'<ROOT><DataBlock1 WorkingTag="A" IDX_NO="1" Status="0" DataSeq="1" Selected="1" TABLE_NAME="DataBlock1" Result="" InOutSeq="122992" InOutNo="200811110004" BizUnit="1" InOutType="121"     
 InOutDate="20081111" DeptSeq="54" EmpSeq="245"> </DataBlock1></ROOT>',@xmlFlags=0,@ServiceSeq=2619,@WorkingTag=N'U',@CompanySeq=8,@LanguageSeq=1,@UserSeq=674,@PgmSeq=1378    
 *************************************************************************************************/        
 CREATE PROC KPXCM_SLGInOutDailyBatch_MES
     @xmlDocument    NVARCHAR(MAX),        
     @xmlFlags       INT = 0,        
     @ServiceSeq     INT = 0,        
     @WorkingTag     NVARCHAR(10)= '',        
         
     @CompanySeq     INT = 1,        
     @LanguageSeq    INT = 1,        
     @UserSeq        INT = 0,        
     @PgmSeq         INT = 0        
 AS        
     DECLARE @docHandle        INT      
       
     -- ���� ����Ÿ ��� ����        
     CREATE TABLE #TLGInOutDailyBatch (WorkingTag NCHAR(1) NULL)        
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TLGInOutDailyBatch'        
      CREATE TABLE #TLGInOutMonth    
     (      
         InOut           INT,    
         InOutYM         NCHAR(6),    
         WHSeq           INT,    
         FunctionWHSeq   INT,    
         ItemSeq         INT,    
         UnitSeq         INT,    
         Qty             DECIMAL(19, 5),    
         StdQty          DECIMAL(19, 5),    
         ADD_DEL         INT    
     )    
   
     CREATE TABLE #TLGInOutMinusCheck    
     (      
         WHSeq           INT,    
         FunctionWHSeq   INT,    
         ItemSeq         INT  
     )    
   
     CREATE TABLE #TLGInOutMonthLot  
     (      
         InOut           INT,    
         InOutYM         NCHAR(6),    
         WHSeq           INT,    
         FunctionWHSeq   INT,    
         LotNo           NVARCHAR(30),  
         ItemSeq         INT,    
         UnitSeq         INT,    
         Qty             DECIMAL(19, 5),    
         StdQty          DECIMAL(19, 5),    
         ADD_DEL         INT    
     )    
   
     SELECT @WorkingTag = WorkingTag FROM #TLGInOutDailyBatch    
         
     IF  @WorkingTag In ('D', 'U')    
     BEGIN    
         EXEC _SLGInOutDailyDELETE @CompanySeq    
     END    
   
     IF  @WorkingTag In ('U', 'A')    
     BEGIN    
         -- ���⼭ LotNo���� ǰ���ε� �ƴѸ� ���� ȣ������   
         -- _TLGInOutLotSub ���̺� Lot������ �̷�������� ������ ���� üũ������ ���� ����   
         -- ���⼭ #TLGInOutDailyItem ���̺� ����üũ�� �� �ϰ� �������� �ش� ����,�޽����� #TLGInOutDailyBatch���̺� �����ϰ� ����   
         EXEC _SLGInOutDailyINSERT @CompanySeq -- _TLGInOutStock, _TLGInOutLotStock  
     END        
       
     -- ������ '-'��� üũ�� �Ͽ� ������ �߻� ������ ���� return   
     -- ���� ���� �ܰ���� Ż ������ ����, �ӵ� ���Ͽ�   
     IF EXISTS ( SELECT TOP 1 1 FROM #TLGInOutDailyBatch WHERE Status <> 0 )   
     BEGIN   
      SELECT * FROM #TLGInOutDailyBatch  
         RETURN  
     END   
       
     -- Lot������   
     EXEC _SLGWHStockUPDATE @CompanySeq -- _TLGWHStock   
     EXEC _SLGLOTStockUPDATE @CompanySeq -- _TLGLotStock   
   
     IF @PgmSeq <> 5376 -- ���Կ�������� (-)���üũ ����  
        AND NOT(@PgmSeq = 2038 AND @WorkingTag = 'D') -- ������Ʈ��������� '����'�� (-)���üũ ����  
     AND @PgmSeq <> 7022        -- ������Ʈ�����ǰ��� ���� - ���üũ ���� 20110216 ������  
     BEGIN  
         EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch', @LanguageSeq  
           
         -- ������ '-'��� üũ�� �Ͽ� ������ �߻� ������ ���� return   
         -- ���� ���� �ܰ���� Ż ������ ����, �ӵ� ���Ͽ�   
         IF EXISTS ( SELECT TOP 1 1 FROM #TLGInOutDailyBatch WHERE Status <> 0 )   
         BEGIN   
             SELECT * FROM #TLGInOutDailyBatch  
             RETURN  
         END   
           
         EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyBatch', @LanguageSeq  
     END  
   
    DECLARE @Status INT   
      
    SELECT @Status = (SELECT MAX(Status) FROM #TLGInOutDailyBatch )  
      
    RETURN @Status  