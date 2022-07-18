
IF OBJECT_ID('KPXCM_SSEDesasterCheckCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEDesasterCheckCHE
GO 

-- v2015.06.08 

-- ����Ʈȭ������ Copy by����õ 
/************************************************************  
  ��  �� - ������-���ذ���_capro : üũ  
  �ۼ��� - 20110324  
  �ۼ��� - �����  
 ************************************************************/  
 CREATE PROC dbo.KPXCM_SSEDesasterCheckCHE  
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
    
     CREATE TABLE #KPXCM_TSEDesasterCHE (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TSEDesasterCHE'  
     
  -----------------------------  
  ---- ������ �������   
  -----------------------------  
     UPDATE #KPXCM_TSEDesasterCHE  
        SET WorkingTag = 'A'  
       FROM #KPXCM_TSEDesasterCHE AS A  
      WHERE NOT EXISTS (SELECT 'X'  
                          FROM KPXCM_TSEDesasterCHE AS L1  
                         WHERE L1.CompanySeq = @CompanySeq
                           AND A.AccidentSeq = L1.AccidentSeq)  
    
   
  -- guide : �� �� 'Ű ����', '���࿩�� üũ', '�������� üũ', 'Ȯ������ üũ' ���� üũ������ �ֽ��ϴ�.  
      -------------------------------------------  
     -- INSERT ��ȣ�ο�(�� ������ ó��)  
     -------------------------------------------  
     SELECT @Count = COUNT(1) FROM #KPXCM_TSEDesasterCHE WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)
     IF @Count > 0  
     BEGIN      
        -- Ű�������ڵ�κ� ����      
         EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TSEDesasterCHE', 'InjurySeq', @Count    
         -- Temp Talbe �� ������ Ű�� UPDATE    
         UPDATE #KPXCM_TSEDesasterCHE   
            SET InjurySeq = @Seq + DataSeq  
          WHERE WorkingTag = 'A'    
            AND Status = 0  
     END      
   
  SELECT * FROM #KPXCM_TSEDesasterCHE  
    
 RETURN