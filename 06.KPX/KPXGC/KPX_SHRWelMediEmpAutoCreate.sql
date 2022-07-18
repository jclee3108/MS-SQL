  
IF OBJECT_ID('KPX_SHRWelMediEmpAutoCreate') IS NOT NULL   
    DROP PROC KPX_SHRWelMediEmpAutoCreate  
GO  
  
-- v2014.12.02  
  
-- �Ƿ���û- �Ƿ�񳻿� �ڵ����� by ����õ   
CREATE PROC KPX_SHRWelMediEmpAutoCreate  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    CREATE TABLE #KPX_THRWelMediEmp( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelMediEmp'   
    IF @@ERROR <> 0 RETURN    
    
    -- üũ1, �����۾��� ����Ǿ����ϴ�. (�Ƿ�񳻿����)
    UPDATE A
       SET Result = '�����۾��� ����Ǿ����ϴ�. (�Ƿ�񳻿����)', 
           Status = 1234, 
           MessageType = 1234
      FROM #KPX_THRWelMediEmp AS A 
      JOIN KPX_THRWelMediEmp  AS B ON ( B.CompanySeq = @CompanySeq AND B.WelMediSeq = A.WelMediSeq AND (B.PbSeq <> 0 OR B.PbYM <> '') ) 
     WHERE Status = 0 
       AND IsCfm = '0' 
    -- üũ1, END 
    
    DECLARE @MAXSeq     INT,
            @ItemSeq    INT 
    
    SELECT @MaxSeq = (SELECT MAX(WelMediEmpSeq) FROM KPX_THRWelMediEmp WHERE CompanySeq = @CompanySeq) 
    SELECT @ItemSeq = (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE COmpanySeq = @CompanySeq AND EnvSeq = 10 AND EnvSerl = 1)
    
    --SELECT @IsCfm 
    
    --return 
    
    IF (SELECT TOP 1 IsCfm FROM #KPX_THRWelMediEmp) = '1'
    BEGIN 
        INSERT INTO KPX_THRWelMediEmp
        (
            CompanySeq,WelMediEmpSeq,YY,RegSeq,BaseDate,
            EmpSeq,CompanyAmt,ItemSeq,PbYM,PbSeq,
            WelMediSeq,LastUserSeq,LastDateTime
        )
        SELECT @CompanySeq, ISNULL(@MaxSeq,0) + 1, A.YY, A.RegSeq, A.BaseDate, 
               A.EmpSeq, A.ComAmt, @ItemSeq, '', 0, 
               A.WelMediSeq, @UserSeq, GETDATE()
          FROM #KPX_THRWelMediEmp AS A 
         WHERE A.Status = 0 
    END 
    ELSE
    BEGIN
        
        UPDATE A 
           SET WorkingTag = 'D' 
          FROM #KPX_THRWelMediEmp AS A 
         WHERE A.Status = 0 
          
        -- �α� �����    
        DECLARE @TableColumns NVARCHAR(4000)    
        
        -- Master �α�   
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THRWelMediEmp')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_THRWelMediEmp'    , -- ���̺��        
                      '#KPX_THRWelMediEmp'    , -- �ӽ� ���̺��        
                      'WelMediSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
        
        DELETE B 
          FROM #KPX_THRWelMediEmp AS A 
          JOIN KPX_THRWelMediEmp  AS B ON ( B.CompanySeq = @CompanySeq AND B.WelMediSeq = A.WelMediSeq ) 
         WHERE A.Status = 0 
        
        
    END 
    
    SELECT * FROM #KPX_THRWelMediEmp  
    
    RETURN  
GO 
begin tran 
exec KPX_SHRWelMediEmpAutoCreate @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <IsCfm>0</IsCfm>
    <ComAmt>1990</ComAmt>
    <WelMediSeq>25</WelMediSeq>
    <YY>2014</YY>
    <RegSeq>1</RegSeq>
    <BaseDate>20141210</BaseDate>
    <EmpSeq>2028</EmpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026386,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022105
rollback 


--delete from KPX_THRWelMediEmp 