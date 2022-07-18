IF OBJECT_ID('KPXLS_SPDSFCGoodInSave') IS NOT NULL 
    DROP PROC KPXLS_SPDSFCGoodInSave
GO 

-- v2016.01.12 

-- �����԰����� LotMaster �԰����� update ���� �߰� by ����õ 
/************************************************************
��  �� - �����԰�����
�ۼ��� - 2008�� 10�� 25�� 
�ۼ��� - ������
UPDATE :: �˻�� ������ ������� �����Ƿ�, ������ ����-> �԰�� �� ����ǵ��� �ּ�ó��  :: 12.05.21 BY �輼ȣ
       :: �ڵ��԰�� �Ѿ������� OldQty �� �������൥���� �������ֵ���                 :: 12.05.21 BY �輼ȣ
          (����->�԰� �������൥���� �������� ����TR�� ������ ����/���� �ǹǷ�)    
************************************************************/
CREATE PROC KPXLS_SPDSFCGoodInSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  

AS    

    -- ����              
    CREATE TABLE #SComSourceDailyBatch    
    (  
        ToTableName   NVARCHAR(100),  
        ToSeq         INT,  
        ToSerl        INT,  
        ToSubSerl     INT,  
        FromTableName NVARCHAR(100),  
        FromSeq       INT,  
        FromSerl      INT,  
        FromSubSerl   INT,  
        ToQty         DECIMAL(19,5),  
        ToStdQty      DECIMAL(19,5),  
        ToAmt         DECIMAL(19,5),  
        ToVAT         DECIMAL(19,5),  
        FromQty       DECIMAL(19,5),  
        FromSTDQty    DECIMAL(19,5),  
        FromAmt       DECIMAL(19,5),  
        FromVAT       DECIMAL(19,5)  
    )  

    DECLARE @EmpSeq     INT

    SELECT @EmpSeq = dbo._FCOMGetEmpSeqByCompany(@CompanySeq, @UserSeq)

    IF ISNULL(@EmpSeq,0) = 0 SELECT @EmpSeq = 0 -- �۱⿬ �߰� 20091228 


    IF @WorkingTag <> 'AutoGoodIn'
    BEGIN
        -- ���� ����Ÿ ��� ����
        CREATE TABLE #TPDSFCGoodIn (WorkingTag NCHAR(1) NULL)  
        EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDSFCGoodIn'     
        IF @@ERROR <> 0 RETURN    
    END


    EXEC _SCOMLog  @CompanySeq,
                   @UserSeq, 
                   '_TPDSFCGoodIn',
                   '#TPDSFCGoodIn',
                   'GoodInSeq',
                   'CompanySeq,GoodInSeq,FactUnit,InDate,WHSeq,GoodItemSeq,UnitSeq,ProdQty,StdProdQty,UnitPrice,Amt,FlowDate,InDeptSeq,
                    EmpSeq,WorkOrderSeq,WorkReportSeq,WorkSerl,QCSeq,RealLotNo,SerialNoFrom,Remark,PJTSeq,WBSSeq,LastUserSeq,LastDateTime'


    -- ������ ������ ���񽺸� ȣ�� �ϴٺ��� ���� ������ �߻��Ѵ�.
    -- ���൥���Ϳ��� �߻��ϴ� ������ ġ�����̹Ƿ� �����ͼ��񽺴�� SPȣ��� �����Ѵ�. 2009.09.26 ������
    -- ���࿬�����(�����˻� => �����԰�)  


    -- �˻�� ������ ������� �����Ƿ�, ������ ����-> �԰�� �� ����ǵ��� �ּ�ó�� -- 12.05.21 BY �輼ȣ
--    INSERT INTO #SComSourceDailyBatch  
--    SELECT '_TPDSFCGoodIn', A.GoodInSeq, 0, 0,   
--           '_TPDQCTestReport', B.QCSeq, 0, 0,  
--           A.ProdQty, A.StdProdQty, 0,   0,  
--           B.ReqInQty, 0, 0,   0
--      FROM #TPDSFCGoodIn            AS A  
--           JOIN _TPDQCTestReport    AS B ON A.WorkReportSeq = B.SourceSeq
--                                        AND B.SourceType = '3'
--                                        AND B.CompanySeq = @CompanySeq
--     WHERE A.WorkingTag IN ('U','D')  
--       AND A.Status = 0  
--
--    IF @@ERROR <> 0      
--    BEGIN      
--        RETURN      
--    END    


---------------------------------------------------------------------------------------------------------------------------  
    -- ���࿬�����(������� => �����԰�)      
    -- (�ڵ��԰� �� ���� _SPDSFCWorkReportSave���� �Ѿ�� Old������ ���� �־��ش� : ����TR�� ������ �̹� ����/���� �Ǿ����Ƿ�)      -- 12.05.21 BY �輼ȣ
---------------------------------------------------------------------------------------------------------------------------
    INSERT INTO #SComSourceDailyBatch      
    SELECT '_TPDSFCGoodIn', A.GoodInSeq, 0, 0, '_TPDSFCWorkReport', A.WorkReportSeq,           
           0, 0, C.ProdQty, C.StdProdQty, 0,   0,    
           ISNULL(B.OKQty, 0), ISNULL(B.StdUnitOKQty, 0),
--           CASE WHEN @WorkingTag = 'AutoGoodIn' THEN A.OldOKQty        ELSE B.OKQty END,      -- ����Ʈ�� ���� ���񽺹� SP������ �̶� �ּ�ó�� -- 12.06.29 BY �輼ȣ 
--           CASE WHEN @WorkingTag = 'AutoGoodIn' THEN A.OldStdUnitOKQty ELSE B.StdUnitOKQty END, -- ����Ʈ�� ���� ���񽺹� SP������ �̶� �ּ�ó��  -- 12.06.29 BY �輼ȣ 
           0,   0    
      FROM #TPDSFCGoodIn                         AS A      
           JOIN _TPDSFCGoodIn                    AS C ON A.GoodInSeq = C.GoodInSeq
                                                     AND @CompanySeq =  C.CompanySeq
            LEFT OUTER JOIN _TPDSFCWorkReport    AS B ON A.WorkReportSeq = B.WorkReportSeq    
                                                     AND B.CompanySeq = @CompanySeq    
     WHERE A.WorkingTag IN ('U','D')           
       AND A.Status = 0    
       AND NOT EXISTS (SELECT 1 FROM #SComSourceDailyBatch WHERE ToSeq = A.GoodInSeq)  
    

    IF @@ERROR <> 0      
    BEGIN      
        RETURN      
    END    
  
    -- ���࿬��  
    EXEC _SComSourceDailyBatch 'D', @CompanySeq, @UserSeq  
    IF @@ERROR <> 0 RETURN  

---------------------------------------------------------------------------------------------------------------------------  


  




    -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT

    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #TPDSFCGoodIn WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        DELETE _TPDSFCGoodIn
          FROM _TPDSFCGoodIn   AS A 
            JOIN #TPDSFCGoodIn AS B ON A.GoodInSeq = B.GoodInSeq
         WHERE B.WorkingTag = 'D' 
           AND B.Status = 0
           AND A.CompanySeq  = @CompanySeq
        IF @@ERROR <> 0  RETURN


		-- ���� �뿪�� ���� 2010. 9. 6 hkim
		DECLARE @OutsourcingType NVARCHAR(100)
		
		EXEC dbo._SCOMEnv @CompanySeq,6513,@UserSeq,@@PROCID,@OutsourcingType OUTPUT

		IF @OutsourcingType = '1' -- '1' �����԰����, '0' �����������
		BEGIN 
			IF EXISTS (SELECT 1 FROM _TPDSFCOutsourcingCostItem AS A 
									 JOIN #TPDSFCGoodIn			AS B ON A.WorkReportSeq = B.GoodInSeq 
							   WHERE A.CompanySeq = @CompanySeq 
								 AND B.Status	  = 0
								 AND B.WorkingTag = 'D')
			BEGIN
				DELETE _TPDSFCOutsourcingCostItem  
				  FROM _TPDSFCOutsourcingCostItem	AS A 
					   JOIN #TPDSFCGoodIn			AS B ON A.WorkReportSeq = B.GoodInSeq 
				 WHERE A.CompanySeq = @CompanySeq 
				   AND B.Status		= 0
				   AND B.WorkingTag = 'D'			
			END		
		END							     								
    END  


    -- �԰�����   (�ڵ��԰��� ����ڰ� �ȵ����°�� �α��� ������� �־��ش�. )
    UPDATE #TPDSFCGoodIn
       SET EmpSeq = @EmpSeq
     WHERE WorkingTag IN ('A','U')  
       AND Status = 0  
       AND EmpSeq = 0 

    
    UPDATE A
       SET InDeptSeq = B.DeptSeq
      FROM #TPDSFCGoodIn                        AS A 
        JOIN dbo._FDAGetDept(@CompanySeq,0,'')  AS B ON A.EmpSeq = B.EmpSeq
     WHERE A.WorkingTag IN ('A','U')  
       AND A.Status = 0  
       AND A.InDeptSeq = 0 


    -- ���ش������� ����
    -- 2012. 1. 9 hkim ���ش��� ���� �Ҽ��� �����ؼ� ó���ǵ��� �߰�
    DECLARE @ItemEnvSeq     INT

    EXEC dbo._SCOMEnv @CompanySeq,8,@UserSeq,@@PROCID,@ItemEnvSeq OUTPUT  
    
    UPDATE T
       SET StdProdQty = CASE WHEN N.SMDecPointSeq = 1003002 THEN ROUND(T.ProdQty   * (CASE WHEN ISNULL(ConvDen,0) = 0 THEN 1 ELSE ConvNum / ConvDen END ), @ItemEnvSeq, @ItemEnvSeq + 1)  
                                   WHEN N.SMDecPointSeq = 1003003 THEN ROUND(T.ProdQty   * (CASE WHEN ISNULL(ConvDen,0) = 0 THEN 1 ELSE ConvNum / ConvDen END) + CAST(4 AS DECIMAL(19, 5)) / POWER(10, (@ItemEnvSeq + 1)), @ItemEnvSeq)     
                                   ELSE ROUND(T.ProdQty   * (CASE WHEN ISNULL(ConvDen,0) = 0 THEN 1 ELSE ConvNum / ConvDen END ), @ItemEnvSeq) END     --T.ProdQty * (CASE WHEN ISNULL(ConvDen,0) = 0 THEN 1 ELSE ConvNum / ConvDen END )
      FROM #TPDSFCGoodIn                   AS T
           LEFT OUTER JOIN _TDAItemUnit    AS U ON T.GoodItemSeq = U.ItemSeq
                                               AND T.UnitSeq = U.UnitSeq
                                               AND @CompanySeq = U.CompanySeq
           LEFT OUTER JOIN _TDAUnit        AS N ON N.CompanySeq  = @CompanySeq                                                            
                                               AND T.UnitSeq = N.UnitSeq
     
    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #TPDSFCGoodIn WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN

        UPDATE _TPDSFCGoodIn
           SET  FactUnit            = B.FactUnit            ,
                InDate              = B.InDate              ,
                WHSeq               = B.WHSeq               ,
                GoodItemSeq         = B.GoodItemSeq         ,
                UnitSeq             = B.UnitSeq             ,
                ProdQty             = B.ProdQty             ,
                StdProdQty          = B.StdProdQty          ,
                FlowDate            = B.FlowDate            ,
                InDeptSeq           = B.InDeptSeq           ,
                EmpSeq              = CASE WHEN ISNULL(B.EmpSeq,0) > 0 THEN B.EmpSeq ELSE @EmpSeq END               ,
                WorkOrderSeq        = B.WorkOrderSeq        ,
                WorkReportSeq       = B.WorkReportSeq       ,
                WorkSerl            = B.WorkSerl            ,
                QCSeq               = B.QCSeq               ,
                RealLotNo           = B.RealLotNo           ,
                SerialNoFrom        = B.SerialNoFrom        ,
                Remark              = ISNULL(B.Remark, '')  ,
                LastUserSeq         = @UserSeq              ,
                LastDateTime        = GETDATE()             ,
                IsWorkOrderEnd      = B.IsWorkOrderEnd      -- 2010.11.19 ������ �߰�. �۾���������ŭ �����԰����� ���ߴ��� �ش������� �Ϸ�� �����Ѵ�.
          FROM _TPDSFCGoodIn   AS A 
            JOIN #TPDSFCGoodIn AS B ON A.GoodInSeq = B.GoodInSeq
         WHERE B.WorkingTag = 'U' 
           AND B.Status = 0    
           AND A.CompanySeq  = @CompanySeq  
        IF @@ERROR <> 0  RETURN
    END   


    -- INSERT
    IF EXISTS (SELECT 1 FROM #TPDSFCGoodIn WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO _TPDSFCGoodIn 
                   (CompanySeq          ,GoodInSeq              ,FactUnit               ,InDate                 ,WHSeq              ,
                    GoodItemSeq         ,UnitSeq                ,ProdQty                ,StdProdQty             ,UnitPrice          ,
                    Amt                 ,FlowDate               ,InDeptSeq              ,EmpSeq                 ,WorkOrderSeq       ,
                    WorkReportSeq       ,WorkSerl               ,QCSeq                  ,RealLotNo              ,SerialNoFrom       ,
                    Remark              ,PJTSeq                 ,WBSSeq                 ,LastUserSeq            ,LastDateTime       ,
                    IsWorkOrderEnd)
            SELECT  @CompanySeq         ,A.GoodInSeq            ,A.FactUnit             ,A.InDate               ,A.WHSeq             ,
                    A.GoodItemSeq       ,A.UnitSeq              ,A.ProdQty              ,A.StdProdQty           ,ISNULL(A.UnitPrice,0),
                    ISNULL(A.Amt,0)     ,ISNULL(A.FlowDate,'')  ,A.InDeptSeq            ,CASE WHEN ISNULL(A.EmpSeq,0) > 0 THEN A.EmpSeq ELSE @EmpSeq END ,A.WorkOrderSeq      , 
                    A.WorkReportSeq     ,ISNULL(A.WorkSerl,0)   ,ISNULL(A.QCSeq,0)      ,A.RealLotNo            ,A.SerialNoFrom      , 
                    ISNULL(A.Remark,'') ,W.PJTSeq               ,W.WBSSeq               , @UserSeq              ,GETDATE()           ,
                    ISNULL(A.IsWorkOrderEnd, '0')
              FROM #TPDSFCGoodIn        AS A   
                JOIN _TPDSFCWorkReport  AS W WITH(NOLOCK) ON A.WorkReportSeq = W.WorkReportSeq
                                                         AND W.CompanySeq = @CompanySeq
             WHERE A.WorkingTag = 'A' AND A.Status = 0    
        IF @@ERROR <> 0 RETURN
    END   


    TRUNCATE TABLE #SComSourceDailyBatch  
    
    ------------------------------------------------------------------------------------------
    -- LotNo Master �԰����� Update ���� �߰� 
    ------------------------------------------------------------------------------------------
    UPDATE A
       SET RegDate = B.InDate
      FROM _TLGLotMaster AS A 
      JOIN #TPDSFCGoodIn AS B ON ( B.GoodItemSeq = A.ItemSeq AND B.RealLotNo = A.LotNo ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.WorkingTag IN ( 'A', 'U' ) 
    ------------------------------------------------------------------------------------------
    -- LotNo Master �԰����� Update ���� �߰�,END 
    ------------------------------------------------------------------------------------------
    
    

    -- �˻�� ������ ������� �����Ƿ�, ������ ����-> �԰�� �� ����ǵ��� �ּ�ó�� -- 12.05.21 BY �輼ȣ
--    INSERT INTO #SComSourceDailyBatch  
--    SELECT '_TPDSFCGoodIn', A.GoodInSeq, 0, 0,   
--           '_TPDQCTestReport', B.QCSeq, 0, 0,  
--           A.ProdQty, A.StdProdQty, 0,   0,  
--           B.ReqInQty, 0, 0,   0
--      FROM #TPDSFCGoodIn            AS A  
--           JOIN _TPDQCTestReport    AS B ON A.WorkReportSeq = B.SourceSeq
--                                        AND B.SourceType = '3'
--                                        AND B.CompanySeq = @CompanySeq
--     WHERE A.WorkingTag IN ('A','U')
--       AND A.Status = 0  


    -- ���࿬��(������� => �����԰�)  
    INSERT INTO #SComSourceDailyBatch  
    SELECT '_TPDSFCGoodIn', A.GoodInSeq, 0, 0,   
           '_TPDSFCWorkReport', B.WorkReportSeq, 0, 0,  
           A.ProdQty, A.StdProdQty, 0,   0,  
           B.OKQty, B.StdUnitOKQty, 0,   0
      FROM #TPDSFCGoodIn            AS A  
           JOIN _TPDSFCWorkReport   AS B ON A.WorkReportSeq = B.WorkReportSeq
                                        AND B.CompanySeq = @CompanySeq
     WHERE A.WorkingTag IN ('A','U')
       AND A.Status = 0  
       AND NOT EXISTS (SELECT 1 FROM #SComSourceDailyBatch WHERE ToSeq = A.GoodInSeq)


    -- ���࿬��  
    EXEC _SComSourceDailyBatch 'A', @CompanySeq, @UserSeq  
    IF @@ERROR <> 0 RETURN    

    IF @WorkingTag <> 'AutoGoodIn'
    BEGIN
        SELECT * FROM #TPDSFCGoodIn   
    END

    RETURN    
/*******************************************************************************************************************/
GO


