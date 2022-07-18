
IF OBJECT_ID('KPXCM_SSEChemicalsListCheckCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEChemicalsListCheckCHE
GO 

-- v2015.06.22 

-- ����Ʈ�� ���� by����õ 

/************************************************************
  ��  �� - ������-ȭ�й���ǰ�����_capro : üũ
  �ۼ��� - 20110602
  �ۼ��� - �����
 ************************************************************/
 CREATE PROC dbo.KPXCM_SSEChemicalsListCheckCHE
  @xmlDocument    NVARCHAR(MAX),  
  @xmlFlags       INT     = 0,  
  @ServiceSeq     INT     = 0,  
  @WorkingTag     NVARCHAR(10)= '',  
  @CompanySeq     INT     = 2,  
  @LanguageSeq    INT     = 1,  
  @UserSeq        INT     = 0,  
  @PgmSeq         INT     = 0 
  AS   
   DECLARE @MessageType        INT,
          @Status             INT,
          @Count              INT,
          @Seq                INT,
          @Results            NVARCHAR(250)
    
    CREATE TABLE #KPXCM_TSEChemicalsListCHE (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TSEChemicalsListCHE'
   
  -----------------------------
  ---- �ʼ��Է� üũ
  -----------------------------
  
  -----------------------------
  ---- �ߺ����� üũ
  -----------------------------  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                           @LanguageSeq       ,   
                           0,''
     UPDATE #KPXCM_TSEChemicalsListCHE
        SET Result        = @Results,
            MessageType   = @MessageType,
            Status        = @Status
       FROM #KPXCM_TSEChemicalsListCHE AS A JOIN ( SELECT S.ItemSeq, S.Content
                                              FROM (
                                                    SELECT A1.ItemSeq, A1.Content
                                                      FROM #KPXCM_TSEChemicalsListCHE AS A1  
                                                     WHERE A1.WorkingTag IN ('A', 'U')
                                                       AND A1.Status = 0
                                                    UNION ALL
                                                    SELECT A1.ItemSeq, A1.Content
                                                      FROM KPXCM_TSEChemicalsListCHE AS A1 WITH(NOLOCK)
                                                     WHERE A1.CompanySeq = @CompanySeq
                                                       AND A1.ChmcSeq NOT IN (SELECT ChmcSeq 
                                                                                FROM #KPXCM_TSEChemicalsListCHE
                                                                               WHERE WorkingTag IN ('U', 'D')
                                                                                 AND Status = 0)
                                                   ) AS S
                                             GROUP BY S.ItemSeq, S.Content
                                             HAVING COUNT(1) > 1
                                           ) AS B ON A.ItemSeq   = B.ItemSeq
                                                 AND A.Content = B.Content
  
 -- guide : �� �� 'Ű ����', '���࿩�� üũ', '�������� üũ', 'Ȯ������ üũ' ���� üũ������ �ֽ��ϴ�.
      -------------------------------------------  
     -- INSERT ��ȣ�ο�(�� ������ ó��)  
     -------------------------------------------  
     SELECT @Count = COUNT(1) FROM #KPXCM_TSEChemicalsListCHE WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)
     IF @Count > 0  
     BEGIN    
        -- Ű�������ڵ�κ� ����    
         EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TSEChemicalsListCHE', 'ChmcSeq', @Count  
         -- Temp Talbe �� ������ Ű�� UPDATE  
         UPDATE #KPXCM_TSEChemicalsListCHE 
            SET ChmcSeq = @Seq + DataSeq
          WHERE WorkingTag = 'A'  
            AND Status = 0
     END    
   SELECT * FROM #KPXCM_TSEChemicalsListCHE 
  
 RETURN