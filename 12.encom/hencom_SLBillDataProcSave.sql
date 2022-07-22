IF OBJECT_ID('hencom_SLBillDataProcSave') IS NOT NULL 
    DROP PROC hencom_SLBillDataProcSave
GO 

-- v2017.03.20 
/************************************************************
 ��  �� - ������-���ݰ�꼭�ϰ�����_hencom : ����
 �ۼ��� - 20170131
 �ۼ��� - ������
************************************************************/
CREATE PROC hencom_SLBillDataProcSave
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0  
AS   
	
	CREATE TABLE #hencom_TSLPreBillExceptData (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TSLPreBillExceptData'     
	IF @@ERROR <> 0 RETURN  
    
    ------------------------------------------------------------------------------------------------
    -- üũ1, ������ �߻����� ���� ���� �����մϴ�.
    ------------------------------------------------------------------------------------------------
    UPDATE A
       SET Result = '������ �߻����� ���� ���� �����մϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TSLPreBillExceptData             AS A 
      LEFT OUTER JOIN hencom_VInvoiceReplaceItem    AS B ON ( B.CompanySeq = @CompanySeq 
                                                          AND (case when B.SourceTableSeq = 1000057 then B.SumMesKey 
                                                                    when B.SourceTableSeq = 1268 then B.InvoiceSeq 
                                                                    else B.ReplaceRegSeq 
                                                                    end
                                                              ) = A.Seq
                                                          AND (case when B.SourceTableSeq = 1000057 then B.SumMesKey 
                                                                    when B.SourceTableSeq = 1268 then B.InvoiceSerl 
                                                                    else B.ReplaceRegSerl 
                                                                    end 
                                                              ) = A.Serl 
                                                          AND B.SourceTableSeq = A.TableSeq ) 
     WHERE A.Status = 0 
       AND ( ISNULL(B.SalesSeq,0) = 0 OR ISNULL(B.InvoiceSeq,0) = 0 ) 
    ------------------------------------------------------------------------------------------------
    -- üũ1, END 
    ------------------------------------------------------------------------------------------------

    
    IF EXISTS (SELECT 1 FROM #hencom_TSLPreBillExceptData WHERE Status <> 0) 
    BEGIN 
        SELECT * FROM #hencom_TSLPreBillExceptData 
        RETURN 
    END 

	
	-- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
	EXEC _SCOMLog  @CompanySeq   ,
   				   @UserSeq      ,
   				   'hencom_TSLPreBillExceptData', -- �����̺��
   				   '#hencom_TSLPreBillExceptData', -- �������̺��
   				   'PreBillExceptRegSeq  ' , -- Ű�� �������� ���� , �� �����Ѵ�. 
   				   'CompanySeq,PreBillExceptRegSeq,StdYM,TableSeq,Seq,Serl,Remark,LastUserSeq,LastDateTime        '
	DELETE hencom_TSLPreBillExceptData
		FROM #hencom_TSLPreBillExceptData A 
			JOIN hencom_TSLPreBillExceptData B ON b.TableSeq  = A.TableSeq 
			                                  and B.seq = a.Seq
											  and b.serl = a.serl 
											  and b.CompanySeq = @CompanySeq
		WHERE B.CompanySeq  = @CompanySeq
		and a.umdatakind = '0'
			   
		IF @@ERROR <> 0  RETURN
	update a
	   set WorkingTag = 'A'
	  from #hencom_TSLPreBillExceptData as a
	  left outer join hencom_TSLPreBillExceptData as b ON b.TableSeq  = A.TableSeq 
			                                  and B.seq = a.Seq
											  and b.serl = a.serl 
											  and b.CompanySeq = @CompanySeq
     where a.umdatakind = '1'    
	   and a.PreBillExceptRegSeq = 0
	                          
	
							     
	if exists ( select 1 from #hencom_TSLPreBillExceptData where  umdatakind = '1' and WorkingTag = 'A')
	begin
		--�ڵ����μ��� ���� SP��
		declare @Seq int, @Count int
		SELECT @Count = COUNT(1) FROM #hencom_TSLPreBillExceptData WHERE umdatakind = '1' and WorkingTag = 'A'
			-- Ű�������ڵ�κ� ����          
		EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'hencom_TSLPreBillExceptData', 'PreBillExceptRegSeq', @Count        
			-- Temp Talbe �� ������ Ű�� UPDATE        
		UPDATE #hencom_TSLPreBillExceptData        
			SET PreBillExceptRegSeq = @Seq + DataSeq        
			WHERE umdatakind = '1'    and WorkingTag = 'A'
			 
		INSERT INTO hencom_TSLPreBillExceptData (CompanySeq,PreBillExceptRegSeq,StdYM,TableSeq,Seq,Serl,Remark,LastUserSeq,LastDateTime ) 
		SELECT @CompanySeq,PreBillExceptRegSeq,StdYM,TableSeq,Seq,Serl,Remark,@UserSeq,GETDATE()         
			FROM #hencom_TSLPreBillExceptData AS A   
			WHERE a.umdatakind = '1' and WorkingTag = 'A'
		IF @@ERROR <> 0 RETURN
	end
	update #hencom_TSLPreBillExceptData
	   set WorkingTag = 'U'
	SELECT * FROM #hencom_TSLPreBillExceptData 
RETURN

go 
begin tran 
exec hencom_SLBillDataProcSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMDataKind>1</UMDataKind>
    <TableSeq>1000057</TableSeq>
    <Seq>242443</Seq>
    <Serl>242443</Serl>
    <PreBillExceptRegSeq>0</PreBillExceptRegSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <StdYM>201702</StdYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511045,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032706
rollback 