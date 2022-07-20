IF OBJECT_ID('mnpt_SSIEBillFwdMailInitQuery') IS NOT NULL 
    DROP PROC mnpt_SSIEBillFwdMailInitQuery
GO 

-- v2018.02.09 
CREATE PROC mnpt_SSIEBillFwdMailInitQuery
    @xmlDocument    NVARCHAR(MAX) ,
    @xmlFlags       INT = 0,
    @ServiceSeq     INT = 0,
    @WorkingTag     NVARCHAR(10)= '',
    @CompanySeq     INT = 1,
    @LanguageSeq    INT = 1,
    @UserSeq        INT = 0,
    @PgmSeq         INT = 0
AS
	--DECLARE @CLOCK datetime
	--SELECT @CLOCK = getdate()
    DECLARE @docHandle      INT,
            @BillSeq        INT,            --���ݰ�꼭��ȣ(����ÿ� �ش�Ǹ� ��ȸ�Ͽ� ���̺� ��´�)
            @SenderEmail    NVARCHAR(200), 
            @Email          NVARCHAR(200)
            
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
    SELECT  @BillSeq		= ISNULL(BillSeq,	0),
            @SenderEmail	= ISNULL(SenderEmail,  ''),
            @Email	        = ISNULL(Email,  '')
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    WITH (  
            BillSeq         INT,
            SenderEmail     NVARCHAR(200),
            Email           NVARCHAR(200)
         )
    
    SELECT @Email AS Email, -- ���޹޴��� ����� �̸���
           @SenderEmail AS SenderEmail, -- ������-�̸���
           (SELECT TOP 1 FileName FROM MNPTCommon.._TCAAttachFileData WHERE AttachFileSeq = A.FileSeq) AS MailTitle, 
           A.FileSeq
      FROM _TSLBill AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.BillSeq = @BillSeq 
    
	RETURN
--go
--begin tran 
--exec mnpt_SSIEBillFwdMailInitQuery @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <Status>0</Status>
--    <DataSeq>1</DataSeq>
--    <Selected>1</Selected>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--    <IsChangedMst>0</IsChangedMst>
--    <BillNo />
--    <BillSeq>515</BillSeq>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=13820150,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=13820133
--rollback 