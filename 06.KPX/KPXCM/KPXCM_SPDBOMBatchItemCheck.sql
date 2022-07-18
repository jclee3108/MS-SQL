IF OBJECT_ID('KPXCM_SPDBOMBatchItemCheck') IS NOT NULL 
    DROP PROC KPXCM_SPDBOMBatchItemCheck
GO 

-- v2015.09.16 

/*************************************************************************************************  
  FORM NAME           -       FrmPDBOMBatch  
  DESCRIPTION         -     ���պ�  
  CREAE DATE          -       2008.05.30      CREATE BY: ����  
  LAST UPDATE  DATE   -       2008.06.11         UPDATE BY: ����  
                              2009.09.09         UPDATE BY �۰��  
                            :: ����, Overage, ����Է�, ���ޱ��� �߰�  
                              2011.04.30         UPDATE BY ������  
                            :: ���ļ���, ���������, ���������� �߰�  
         2014.04.09         UPDATE BY ���й�
         �ű� �ߺ����� ��� �� KPXCM_TPDBOMBatchItem ���̺� �����Ͱ� ��� üũ ���ϰ� �Ǿ�,Companyseq�� �������� �̵�
         �ߺ����� ���� �Ͽ� Check ���� �߰� -- ����� 2014.05.22
 *************************************************************************************************/  
   
 CREATE PROCEDURE KPXCM_SPDBOMBatchItemCheck  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS  
     DECLARE @docHandle   INT,  
             @Serl        INT,  
             @MessageSeq  INT,  
             @MessageType INT,  
             @Status      INT,  
             @Results     NVARCHAR(250),  
             @Results2    NVARCHAR(250) ,
             @EnvValue    NCHAR(1) 
   
     -- BatchItem�� ���� ���� �������� ����  
     CREATE TABLE #KPXCM_TPDBOMBatchItem (WorkingTag NCHAR(1) NULL)  
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TPDBOMBatchItem'  
   
     IF @@ERROR <> 0 RETURN  
     
     --- BOM �����ߺ� ��� ȯ�漳�� ---
     EXEC dbo._SCOMEnv @CompanySeq,6206,0,@@PROCID,@EnvValue OUTPUT      
       
       
     IF @EnvValue = '0'
     BEGIN  
     -------------------------------------------  
     -- ���� üũ  
     -------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           31                 , -- @1�� @2 ���� Ŀ�� �մϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%�մ�%' AND LanguageSeq = 1)  
                           @LanguageSeq       ,   
                           232, '������'      , -- SELECT * FROM _TCADictionary WHERE Word like '%������%'  
                           191, '������'  
     UPDATE #KPXCM_TPDBOMBatchItem  
        SET Result        = @Results,  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #KPXCM_TPDBOMBatchItem   
      WHERE DateFr     >= DateTo  
        AND Status     = 0  
        AND WorkingTag IN ('A', 'U')   
       
     -- �������� Master�� ����/������ ���̿� �־�� �Ѵ�.      
     -------------------------------------------  
     -- ���� üũ  
     -------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results2    OUTPUT,  
                           1293               , -- @1�� @2��(��) Ȯ���ϼ���.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%Ȯ��%' AND LanguageSeq = 1)  
                           @LanguageSeq       ,   
                           5477, '����ǰ'     , -- SELECT * FROM _TCADictionary WHERE Word like '%������%'  
                           222, '������'  
       
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           1106               , -- @1�� �߸��Ǿ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%����%' AND LanguageSeq = 1)  
                           @LanguageSeq       ,   
                           222, '������'        -- SELECT * FROM _TCADictionary WHERE Word like '%������%'  
                           
     UPDATE #KPXCM_TPDBOMBatchItem  
        SET Result        = @Results + ' ' + @Results2,  
            MessageType   = @MessageType,  
            Status        = @Status  
     FROM #KPXCM_TPDBOMBatchItem  AS A  
            JOIN KPXCM_TPDBOMBatch AS B ON A.BatchSeq = B.BatchSeq  
      WHERE B.CompanySeq = @CompanySeq  
        AND (A.DateFr    < B.DateFr OR A.DateTo > B.DateTo)  
        AND A.Status     = 0  
        AND A.WorkingTag IN ('A', 'U')  
       
     -- ���� BatchSeq���� ��������� �����ϰ� �������� �ߺ��Ǹ� �ȵȴ�.  
     -------------------------------------------  
     -- �ߺ��� ���� üũ  
     -------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           1107               , -- �ش� @1��(��) ������ ��ϵ� @2��(��) �ߺ��˴ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%�ߺ�%' AND LanguageSeq = 1)  
                           @LanguageSeq       ,   
                           222, '������'      , -- SELECT * FROM _TCADictionary WHERE Word like '%������%'  
                           222, '������'  
     UPDATE A  
        SET Result        = @Results,  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #KPXCM_TPDBOMBatchItem                 AS A  
            LEFT OUTER JOIN #KPXCM_TPDBOMBatchItem AS B ON A.BatchSeq   = B.BatchSeq  
                                                 AND A.ItemSeq    = B.ItemSeq  
                                                 AND A.IDX_NO     <> B.IDX_NO  
                                                 AND B.WorkingTag IN ('A', 'U')  
                                                 AND A.ProcSeq    = B.ProcSeq  
            LEFT OUTER JOIN KPXCM_TPDBOMBatchItem AS C ON A.BatchSeq   = C.BatchSeq  
                                                 AND A.ItemSeq    = C.ItemSeq  
                                                 AND A.Serl       <> C.Serl  
                                                 AND A.ProcSeq    = C.ProcSeq  
                                                 AND C.CompanySeq = @CompanySeq
      WHERE A.Status = 0  
        AND A.WorkingTag IN ('A', 'U')  
        --AND C.CompanySeq = @CompanySeq  ���й�20140409: �ű� �ߺ����� ��� �� KPXCM_TPDBOMBatchItem ���̺� �����Ͱ� ��� üũ ���ϰ� �Ǿ�,�������� �̵�
        AND (A.DateFr BETWEEN B.DateFr AND B.DateTo OR A.DateTo BETWEEN B.DateFr AND B.DateTo   
             OR A.DateFr BETWEEN C.DateFr AND C.DateTo OR A.DateTo BETWEEN C.DateFr AND C.DateTo)  
     END  
     -- ���� ����ǰ���� ��������� �����ϰ� �������� �ߺ��Ǹ� �ȵȴ�.  
     -------------------------------------------  
     -- �ߺ��� ���� üũ  
     -------------------------------------------  
     /*����ǰ�� �����ϵ� �ߺ�üũ�� �ϰ� ���絵 ����ǰ�� ������ �ȿ����� ������ �Ǳ� ������ üũ�� ���� �ʾƵ� �ɰ� ����.*/ -- sypark 20120516  
       
     -- �����ȹ���� ����� �����Ͱ� �����ϸ� ���� �Ұ�  
     -------------------------------------------  
     -- �ߺ��� ���� üũ  
     -------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           1044               , -- ���� �۾��� ����Ǿ ����,������ �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%����%' AND LanguageSeq = 1)  
                           @LanguageSeq         
                             
     UPDATE #KPXCM_TPDBOMBatchItem  
        SET Result        = REPLACE(@Results, '����,', ''),  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #KPXCM_TPDBOMBatchItem      AS A  
            JOIN _TPDMPSWorkOrder AS B ON A.BatchSeq    = B.BatchSeq  
      WHERE A.Status     = 0  
        AND A.WorkingTag = 'D'  
        AND B.CompanySeq = @CompanySeq  
        AND NOT EXISTS (SELECT 1 FROM KPXCM_TPDBOMBatchItem WHERE CompanySeq = B.CompanySeq AND BatchSeq = A.BatchSeq AND Serl <> A.Serl)  
           
     -- ���μ���  
     SELECT @Serl = ISNULL((SELECT MAX(A.Serl) FROM KPXCM_TPDBOMBatchItem AS A WITH(NOLOCK)  
                                                    JOIN #KPXCM_TPDBOMBatchItem AS B WITH(NOLOCK) ON A.BatchSeq = B.BatchSeq  
                                              WHERE A.CompanySeq = @CompanySeq), 0)  
   
     UPDATE #KPXCM_TPDBOMBatchItem SET Serl = @Serl+DataSeq  
      WHERE WorkingTag = 'A' AND Status = 0  
          
     SELECT * FROM #KPXCM_TPDBOMBatchItem AS KPXCM_TPDBOMBatchItem  
   
 RETURN  
 /*************************************************************************************************/