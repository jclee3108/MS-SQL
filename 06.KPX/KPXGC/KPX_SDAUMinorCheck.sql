
IF OBJECT_ID('KPX_SDAUMinorCheck') IS NOT NULL 
    DROP PROC KPX_SDAUMinorCheck
GO 

-- v2014.12.01 

-- by����õ
/***********************************************************
  ��  �� - ��������Ǳ�Ÿ�ڵ�(�Һз�) üũ
  �ۼ��� - 2008.7.30 :
  �ۼ��� - CREATEd by �ű�ö
  ������ - 
 ************************************************************/
  -- SP�Ķ���͵�
 CREATE PROCEDURE KPX_SDAUMinorCheck
     @xmlDocument NVARCHAR(MAX)   ,    -- : ȭ���� ������ XML������ ����
     @xmlFlags    INT = 0         ,    -- : �ش� XML������ Type
     @ServiceSeq  INT = 0         ,    -- : ���� ��ȣ
     @WorkingTag  NVARCHAR(10)= '',    -- : WorkingTag
     @CompanySeq  INT = 1         ,    -- : ȸ�� ��ȣ
     @LanguageSeq INT = 1         ,    -- : ��� ��ȣ
     @UserSeq     INT = 0         ,    -- : ����� ��ȣ
     @PgmSeq      INT = 0              -- : ���α׷� ��ȣ
  AS
      -- ����� ������ �����Ѵ�.
     DECLARE @Count       INT,
             @Seq         INT,
             @MessageType INT,
             @Status      INT,
             @Results     NVARCHAR(250)
  
  
      -- ���� ������ ��� ����
     CREATE TABLE #TDAUMinor (WorkingTag NCHAR(1) NULL)
      -- �ӽ� ���̺� ������ �÷��� �߰��ϰ�, XML�����κ����� ���� INSERT�Ѵ�.
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TDAUMinor'
      IF @@ERROR <> 0
     BEGIN
         RETURN    -- ������ �߻��ϸ� ����
     END
  
  
   
     -------------------------------------------  
     -- INSERT ��ȣ�ο�(�� ������ ó��)  
     -------------------------------------------  
     SELECT @Count = COUNT(DISTINCT RowNum) FROM #TDAUMinor WHERE (WorkingTag = 'A' AND Status = 0)
      IF(@Count > 0)
     BEGIN
  
     --1)���� Minor���� ���ڸ� ���Ѱ��� 999���� �Ѵ��� Ȯ���Ѵ�
      DECLARE @ChkSeq     INT,
             @MaxMinorSeq INT,
             @CurrSeq    INT,
             @PreCntSeq  INT,
             @NewCntSeq  INT,
             @MaxSeq     INT,
             @MajorLen   INT,
             @MinorLen  INT
              
      SELECT @ChkSeq     = CONVERT(INT,RIGHT('9999999999',len(max(MinorSeq)) - Len(MajorSeq))),
             @MaxMinorSeq= CONVERT(INT, RIGHT(max(minorseq),len(max(MinorSeq)) - Len(MajorSeq)) + @Count),
             @CurrSeq    = max(minorseq),
             @MajorLen   = LEN(MajorSeq),
             @MinorLen   = LEN(MAX(MinorSeq) - LEN(MajorSeq))
       FROM _TDAUMInor A
      WHERE A.CompanySeq = @CompanySeq
        AND EXISTS (SELECT *
                     FROM #TDAUMinor
                    WHERE MajorSeq = A.MajorSeq
                  )
             group by majorseq
             
     IF @ChkSeq < @MaxMinorSeq
     BEGIN
         --���� ��� ���� ��ȣ��� ���� ��ȣ�븦 Ȯ���Ѵ�.
        --1)������ȣ�� ���
           IF @MajorLen+4 >10 
          BEGIN
             --Ű �ڸ��� �ʰ�  �̻� ��� �Ұ���
             -------------------------------------------
             EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                   @Status      OUTPUT,
                                   @Results     OUTPUT,
                                   1028                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                                   @LanguageSeq       , 
                                   0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%Ȱ������%'
             UPDATE #TDAUMinor
                SET Result        = @Results,  
                    MessageType   = @MessageType,  
                    Status        = @Status   
             WHERE (WorkingTag = 'A' AND Status = 0)
             
          END
        
             UPDATE #TDAUMinor
                SET MinorSeq = ISNULL(@CurrSeq, A.MajorSeq * 1000) + (SELECT COUNT(*)
                                                                    FROM (SELECT DISTINCT RowNum
                                                                            FROM #TDAUMinor
                                                                           WHERE (WorkingTag = 'A' AND Status = 0)
                                                                         ) AS X
                                                                   WHERE X.RowNum <= A.RowNum
                      
                                                                 )
               FROM #TDAUMinor AS A
              WHERE (A.WorkingTag =  'A' AND A.Status = 0)
              SELECT @MaxSeq = (SELECT MAX(MinorSeq)
                              FROM _TDAUMinor AS A  
                             WHERE A.CompanySeq = @CompanySeq  
                               AND EXISTS (SELECT *
                                             FROM #TDAUMinor
                                            WHERE MajorSeq *10 = A.MajorSeq
                                          )
                           )
  
             UPDATE #TDAUMinor
                SET MinorSeq = ISNULL(@MaxSeq, A.MajorSeq * 10000) + (SELECT COUNT(*)
                                                                    FROM (SELECT DISTINCT RowNum
                                                                            FROM #TDAUMinor
                                                                           WHERE (WorkingTag = 'A' AND Status = 0)
                                                                             AND MinorSeq  > MajorSeq *1000 + @ChkSeq
                                                                         ) AS X
                                                                   WHERE X.RowNum <= A.RowNum
                                                                    
                                                                 )
               FROM #TDAUMinor AS A
             WHERE (A.MinorSeq  > A.MajorSeq *1000 + @ChkSeq)
              AND (A.WorkingTag = 'A' AND A.Status = 0)
  
         --2)���ο� ��ȣ�� ���
     END 
     ELSE
     BEGIN
          --2)�����ʴ°�� ������ ����  
             IF @MinorLen - @MajorLen > 3
             BEGIN
              
                 SELECT @Seq = (SELECT MAX(MinorSeq)
                                  FROM _TDAUMinor AS A  
                                 WHERE A.CompanySeq = @CompanySeq  
                                   AND EXISTS (SELECT *
                                                 FROM #TDAUMinor
                                                WHERE MajorSeq * 10 = A.MajorSeq 
                                              )
                               )
                  SELECT @MaxSeq = (SELECT MAX(MinorSeq)
                                  FROM _TDAUMinor AS A  
                                 WHERE A.CompanySeq = @CompanySeq  
                                   AND EXISTS (SELECT *
                                                 FROM #TDAUMinor
                                                WHERE MajorSeq = A.MajorSeq 
                                              )
                               )
                  IF ISNULL(@MaxSeq,0) > ISNULL(@Seq,0)
                  SELECT @Seq = @MaxSeq
                    
                  UPDATE #TDAUMinor
                    SET MinorSeq = ISNULL(@Seq, A.MajorSeq * 10000) + (SELECT COUNT(*)
                                                                        FROM (SELECT DISTINCT RowNum
                                                                                FROM #TDAUMinor
                                                                               WHERE (WorkingTag = 'A' AND Status = 0)
                                                                             ) AS X
                                                                       WHERE X.RowNum <= A.RowNum
                                                                     )
                   FROM #TDAUMinor AS A
                   WHERE (A.WorkingTag = 'A' AND A.Status = 0)
                  
             END  
             ELSE
             BEGIN
                 SELECT @Seq = (SELECT MAX(MinorSeq)
                                  FROM _TDAUMinor AS A  
                                 WHERE A.CompanySeq = @CompanySeq  
                                   AND EXISTS (SELECT *
                                                 FROM #TDAUMinor
                                                WHERE MajorSeq = A.MajorSeq
                                              )
                               )
  
                 UPDATE #TDAUMinor
                    SET MinorSeq = ISNULL(@Seq, A.MajorSeq * 1000) + (SELECT COUNT(*)
                                                                        FROM (SELECT DISTINCT RowNum
                                                                                FROM #TDAUMinor
                                                                               WHERE (WorkingTag = 'A' AND Status = 0)
                                                                             ) AS X
                                                                       WHERE X.RowNum <= A.RowNum
                                                                     )
                   FROM #TDAUMinor AS A
                  WHERE (A.WorkingTag = 'A' AND A.Status = 0)
             END
       
     END
       
  
  --         UPDATE #TDAUMinor  
 --            SET MinorSeq = @Seq + DataSeq  
 --          WHERE WorkingTag = 'A'  
 --            AND Status = 0
      END
  
  
      SELECT * FROM #TDAUMinor    -- Output
  RETURN