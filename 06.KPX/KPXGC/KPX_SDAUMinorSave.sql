
IF OBJECT_ID('KPX_SDAUMinorSave') IS NOT NULL 
    DROP PROC KPX_SDAUMinorSave
GO  

-- v2014.12.01 

-- �������� by����õ

/***********************************************************
  ��  �� - ��������Ǳ�Ÿ�ڵ�(�Һз�) ����
  �ۼ��� - 2008.7.30 :
  �ۼ��� - CREATEd by �ű�ö
  ������ - 
 ************************************************************/
  -- SP�Ķ���͵�
 CREATE PROCEDURE KPX_SDAUMinorSave
     @xmlDocument NVARCHAR(MAX)   ,    -- : ȭ���� ������ XML������ ����
     @xmlFlags    INT = 0         ,    -- : �ش� XML������ Type
     @ServiceSeq  INT = 0         ,    -- : ���� ��ȣ
     @WorkingTag  NVARCHAR(10)= '',    -- : WorkingTag
     @CompanySeq  INT = 1         ,    -- : ȸ�� ��ȣ
     @LanguageSeq INT = 1         ,    -- : ��� ��ȣ
     @UserSeq     INT = 0         ,    -- : ����� ��ȣ
     @PgmSeq      INT = 0              -- : ���α׷� ��ȣ
  AS
      -- ���� ������ ��� ����
     CREATE TABLE #TDAUMinor (WorkingTag NCHAR(1) NULL)
      -- �ӽ� ���̺� ������ �÷��� �߰��ϰ�, XML�����κ����� ���� INSERT�Ѵ�.
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TDAUMinor'
      IF @@ERROR <> 0
     BEGIN
         RETURN    -- ������ �߻��ϸ� ����
     END
  
  
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
     EXEC _SCOMLog  @CompanySeq ,
                    @UserSeq    ,
                    '_TDAUMinor',    -- �����̺��
                    '#TDAUMinor',    -- �������̺��
                    'MinorSeq'  ,    -- Ű�� �������� ���� , �� �����Ѵ�.
                    'CompanySeq, MinorSeq, MajorSeq, MinorName, MinorSort, Remark, WordSeq, LastUserSeq, LastDateTime, IsUse'    -- �����̺��� �÷���
  
    
    IF EXISTS (SELECT TOP 1 1 FROM #TDAUMinor WHERE WorkingTag = 'D' AND Status = 0)
    BEGIN
        EXEC _SCOMLog  @CompanySeq      ,
                        @UserSeq         ,
                        '_TDAUMinorValue',    -- �����̺��
                        '#TDAUMinor'     ,    -- �������̺��
                        'MinorSeq'       ,    -- Ű�� �������� ���� , �� �����Ѵ�.
                        'CompanySeq, MinorSeq, Serl, MajorSeq, ValueSeq, ValueText, LastUserSeq, LastDateTime'    -- �����̺��� �÷���
      END
    
      -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT
      -- DELETE
     IF EXISTS (SELECT TOP 1 1 FROM #TDAUMinor WHERE WorkingTag = 'D' AND Status = 0)
     BEGIN
          -- ������ ����
         DELETE _TDAUMinorValue
            FROM _TDAUMinorValue AS A JOIN #TDAUMinor AS B ON (A.MajorSeq = B.MajorSeq
                                                         AND  A.MinorSeq = B.MinorSeq)
           WHERE (B.WorkingTag = 'D' AND B.Status = 0)
            --AND  A.CompanySeq = @CompanySeq
  
  
          -- ������ ����
         DELETE _TDAUMinor
            FROM _TDAUMinor AS A JOIN #TDAUMinor AS B ON (A.MajorSeq = B.MajorSeq
                                                    AND  A.MinorSeq = B.MinorSeq)
           WHERE (B.WorkingTag = 'D' AND B.Status = 0)
            --AND  A.CompanySeq = @CompanySeq
  
  
          IF @@ERROR <> 0
         BEGIN
             RETURN    -- ������ �߻��ϸ� ����
         END
      END
  
  
   
     -- UPDATE
     IF EXISTS (SELECT TOP 1 1 FROM #TDAUMinor WHERE WorkingTag = 'U' AND Status = 0)
     BEGIN
          UPDATE _TDAUMinor
             SET MinorName    = B.MinorName, MinorSort = B.MinorSort, Remark      = B.Remark,    -- �Һз���, ����    , ���  ,
                IsUse        = B.IsUse    , WordSeq   = B.WordSeq  , LastUserSeq = @UserSeq,    -- ��뿩��, �����ڵ�, �۾���,
                LastDateTime = GETDATE()                                                        -- �۾��Ͻ�
            FROM _TDAUMinor AS A JOIN #TDAUMinor AS B ON (A.MajorSeq = B.MajorSeq
                                                    AND  A.MinorSeq = B.MinorSeq)
           WHERE (B.WorkingTag = 'U' AND B.Status = 0)
            --AND A.CompanySeq = @CompanySeq
  
  
          IF @@ERROR <> 0
         BEGIN
             RETURN    -- ������ �߻��ϸ� ����
         END
      END
  
  
      -- INSERT
     IF EXISTS (SELECT TOP 1 1 FROM #TDAUMinor WHERE WorkingTag = 'A' AND Status = 0)
        AND @WorkingTag <> 'D'   --��Ʈ�����Ҷ� �ƹ��͵� ���� �������� WorkingTag�� A�ΰ��� ���ö��� �ִ�
     BEGIN
          INSERT _TDAUMinor (CompanySeq, MinorSeq , MajorSeq   ,
                            MinorName , MinorSort, Remark     ,
                            Isuse     , WordSeq  , LastUserSeq,
            LastDateTime)
          SELECT DISTINCT
                B.CompanySeq          AS CompanySeq , ISNULL(MinorSeq ,  0) AS MinorSeq ,
                ISNULL(MajorSeq ,  0) AS MajorSeq   , ISNULL(MinorName, '') AS MinorName,
                ISNULL(MinorSort, '') AS MinorSort  , ISNULL(Remark   , '') AS Remark   ,
                '1'                   AS IsUse      , ISNULL(WordSeq  ,  0) AS WordSeq  ,
                @UserSeq              AS LastUserSeq, GETDATE()             AS LastDateTime
            FROM #TDAUMinor AS A 
            JOIN _TCACompany AS B ON ( 1 = 1 ) 
           WHERE (WorkingTag = 'A' AND Status = 0)
  
  
          IF @@ERROR <> 0
         BEGIN
             RETURN    -- ������ �߻��ϸ� ����
         END
    END
    
    SELECT * FROM #TDAUMinor    -- Output
    
    RETURN
GO 

begin tran 
exec KPX_SDAUMinorSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>0</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ROW_IDX>0</ROW_IDX>
    <MajorSeq>9016</MajorSeq>
    <MinorName>ttt</MinorName>
    <MinorSeq>9016001</MinorSeq>
    <MinorSort>1</MinorSort>
    <Remark />
    <WordSeq>0</WordSeq>
    <RowNum>0</RowNum>
    <IsUse>0</IsUse>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <ROW_IDX>1</ROW_IDX>
    <MajorSeq>9016</MajorSeq>
    <MinorName>ttt1</MinorName>
    <MinorSeq>9016002</MinorSeq>
    <MinorSort>2</MinorSort>
    <Remark />
    <WordSeq>0</WordSeq>
    <RowNum>1</RowNum>
    <IsUse>0</IsUse>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026339,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020436

--select * from _TDAUMinor where majorseq = 9016 
rollback 