
IF OBJECT_ID('DTI_SSLReceiptConsignDescSave') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignDescSave
GO 

-- v2014.05.21 

-- ����Ź�Ա��Է�_DTI(����Ź��������) by����õ
 CREATE PROCEDURE DTI_SSLReceiptConsignDescSave    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS 
    DECLARE @docHandle      INT   
    
    CREATE TABLE #DTI_TSLReceiptConsignDesc (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#DTI_TSLReceiptConsignDesc'   
    IF @@ERROR <> 0 RETURN   
    
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   'DTI_TSLReceiptConsignDesc', -- �����̺��  
                   '#DTI_TSLReceiptConsignDesc', -- �������̺��  
                   'ReceiptSeq, ReceiptSerl' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                   'CompanySeq,ReceiptSeq,ReceiptSerl,UMReceiptKind,SMDrOrCr,CurAmt,DomAmt,BankSeq,BankAccSeq,CustSeq,Remark,LastUserSeq,LastDateTime,PgmSeq',
                   '',  
                   @PgmSeq  
    
    -- DELETE                                                                                                  
    IF EXISTS (SELECT 1 FROM #DTI_TSLReceiptConsignDesc WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE A    
          FROM DTI_TSLReceiptConsignDesc    AS A  
          JOIN #DTI_TSLReceiptConsignDesc   AS B ON ( A.ReceiptSeq = B.ReceiptSeq AND A.ReceiptSerl = B.ReceiptSerl )
          WHERE A.CompanySeq = @CompanySeq 
            AND B.WorkingTag = 'D' 
            AND B.Status = 0 
    END     
    
    -- Update                                                                                                   
    IF EXISTS (SELECT 1 FROM #DTI_TSLReceiptConsignDesc WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN     
        UPDATE A     
           SET UMReceiptKind    = B.UMReceiptKind,   
               SMDrOrCr         = B.SMDrOrCr,   
               CurAmt           = B.CurAmt,   
               DomAmt           = B.DomAmt,   
               BankSeq          = B.BankSeq,   
               BankAccSeq       = B.BankAccSeq,   
               CustSeq          = ISNULL(B.CustSeq,0), 
               Remark           = B.Remark, 
               LastUserSeq      = @UserSeq,  
               LastDateTime     = GETDATE(),  
               PgmSeq           = @PgmSeq 
          FROM DTI_TSLReceiptConsignDesc    AS A   
          JOIN #DTI_TSLReceiptConsignDesc   AS B ON ( A.ReceiptSeq = B.ReceiptSeq AND A.ReceiptSerl = B.ReceiptSerl ) 
         WHERE B.WorkingTag = 'U'   
           AND B.Status = 0  
           AND A.CompanySeq = @CompanySeq  
        
        IF @@ERROR <> 0 RETURN     
    END   
    
    -- INSERT                                                                                                    
    IF EXISTS (SELECT 1 FROM #DTI_TSLReceiptConsignDesc WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        -- ���� INSERT    
        INSERT INTO DTI_TSLReceiptConsignDesc (
                                               CompanySeq  ,ReceiptSeq     ,ReceiptSerl    ,UMReceiptKind  ,SMDrOrCr   ,
                                               CurAmt      ,DomAmt         ,BankSeq        ,BankAccSeq     ,CustSeq    ,
                                               Remark      ,LastUserSeq    ,LastDateTime   ,PgmSeq 
                                              )
        SELECT @CompanySeq ,ReceiptSeq     ,ReceiptSerl    ,UMReceiptKind  ,SMDrOrCr         ,
               CurAmt      ,DomAmt         ,BankSeq        ,BankAccSeq     ,ISNULL(CustSeq,0),
               Remark      ,@UserSeq       ,GETDATE()      ,@PgmSeq 
          FROM #DTI_TSLReceiptConsignDesc    
         WHERE WorkingTag = 'A' 
           AND Status = 0    
        
        IF @@ERROR <> 0 RETURN 
    END 
    
    SELECT * FROM #DTI_TSLReceiptConsignDesc   
    
    RETURN
GO
exec DTI_SSLReceiptConsignDescSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ReceiptSeq>9</ReceiptSeq>
    <ReceiptSerl>1</ReceiptSerl>
    <UMReceiptKind>8017001</UMReceiptKind>
    <DomAmt>50000.00000</DomAmt>
    <BankSeq>91</BankSeq>
    <BankAccSeq>1030</BankAccSeq>
    <Remark />
    <CurAmt>50000.00000</CurAmt>
    <SMDrOrCr>1</SMDrOrCr>
    <DrOrCrName>����</DrOrCrName>
    <ReceiptKindName>������-��������</ReceiptKindName>
    <BankName>�츮���� ����</BankName>
    <SlipSeq>3479801</SlipSeq>
    <AccSeqDr>632</AccSeqDr>
    <AccSeqCr>0</AccSeqCr>
    <AccNameDr>������-��������</AccNameDr>
    <AccNameCr />
    <BankAccNo>1005-100-147404</BankAccNo>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022863,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1019203