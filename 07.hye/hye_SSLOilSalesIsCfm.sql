 
IF OBJECT_ID('hye_SSLOilSalesIsCfm') IS NOT NULL   
    DROP PROC hye_SSLOilSalesIsCfm  
GO  
  
-- v2016.11.04 
  
-- �������Ǹ�����-���� by ����õ
CREATE PROC hye_SSLOilSalesIsCfm  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- ��ȸ����   
            @BizUnit    INT, 
            @StdDate    NCHAR(8), 
            @StdYM      NCHAR(6), 
            @IsCfm      NCHAR(1) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizUnit     = ISNULL( BizUnit, 0 ),  
           @StdDate     = ISNULL( StdDate, '' ),  
           @StdYM       = ISNULL( StdYM  , '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock15', @xmlFlags )       
      WITH (
            BizUnit    INT,       
            StdDate    NCHAR(8),      
            StdYM      NCHAR(6)       
           )    
    
    
    -- üũ 
    SELECT @IsCfm = IsCfm 
      FROM hye_TSLOilSalesIsCfm AS A 
     WHERE A.Companyseq = @CompanySeq 
       AND A.BizUnit = @BizUnit 
       AND A.StdYMDate = CASE WHEN @StdDate = '' THEN @StdYM ELSE @StdDate END 
    
    SELECT @IsCfm = ISNULL(@IsCfm,'0')

    IF @WorkingTag = 'C' -- ���� 
    BEGIN
        IF @IsCfm = '1' 
        BEGIN
            SELECT '�̹� ������ �Ϸ�Ǿ� �ֽ��ϴ�.' AS Result, 9999 Status, @IsCfm AS IsCfm 
            RETURN 
        END 
    END 
    ELSE IF @WorkingTag = 'CC' -- ���� ��� 
    BEGIN
        IF @IsCfm = '0' 
        BEGIN
            SELECT '�̹� ������Ұ� �Ϸ�Ǿ� �ֽ��ϴ�.' AS Result, 9999 Status, @IsCfm AS IsCfm 
            RETURN 
        END 
    END 




    IF EXISTS (
                SELECT 1 
                  FROM hye_TSLOilSalesIsClose 
                 WHERE BizUnit = @BizUnit
                   AND StdYMDate = CASE WHEN @StdDate = '' THEN @StdYM ELSE @StdDate END 
                   AND IsClose = '1' 
              ) 
    BEGIN 
        SELECT '������ ���� �Ǿ� ó�� �� �� �����ϴ�.' AS Result, 9999 AS Status, 9 AS IsClose
        RETURN 
    END 


    -- �ݿ� 
    IF @WorkingTag = 'C' -- ���� 
    BEGIN
        
        IF @StdYM = '' -- ������ 
        BEGIN 
                
            INSERT INTO hye_TSLOilSalesIsCfm 
            (
                CompanySeq, BizUnit, StdYMDate, IsCfm, CfmDate, 
                LastUserSeq, LastDateTime, PgmSeq 
            )
            SELECT @CompanySeq, @BizUnit, @StdDate, '0', '', 
                   @UserSeq, GETDATE(), @PgmSeq 
             WHERE NOT EXISTS (SELECT 1 FROM hye_TSLOilSalesIsCfm WHERE CompanySeq = @CompanySeq AND BizUnit = @BizUnit AND StdYMDate = @StdDate)

            UPDATE A 
               SET IsCfm = '1', 
                   CfmDate = CONVERT(NCHAR(8),GETDATE(),112)
              FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdDate
             
            SELECT A.IsCfm, 0 AS Status 
              FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdDate

        END 
        ELSE IF @StdDate = '' -- ������ 
        BEGIN 
            INSERT INTO hye_TSLOilSalesIsCfm 
            (
                CompanySeq, BizUnit, StdYMDate, IsCfm, CfmDate, 
                LastUserSeq, LastDateTime, PgmSeq 
            )
            SELECT @CompanySeq, @BizUnit, @StdYM, '0', '', 
                   @UserSeq, GETDATE(), @PgmSeq 
             WHERE NOT EXISTS (SELECT 1 FROM hye_TSLOilSalesIsCfm WHERE CompanySeq = @CompanySeq AND BizUnit = @BizUnit AND StdYMDate = @StdYM)

            UPDATE A 
               SET IsCfm = '1', 
                   CfmDate = CONVERT(NCHAR(8),GETDATE(),112)
              FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdYM
            
             SELECT A.IsCfm, 0 AS Status 
               FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdYM

        END 

    END 
    ELSE IF @WorkingTag = 'CC' -- ���� ��� 
    BEGIN

        IF @StdYM = '' -- ���������
        BEGIN 
            UPDATE A 
               SET IsCfm = '0', 
                   CfmDate = ''
              FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdDate
             
             SELECT A.IsCfm, 0 AS Status 
               FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdDate

        END 
        ELSE IF @StdDate = '' -- ���������
        BEGIN 
            UPDATE A 
               SET IsCfm = '0', 
                   CfmDate = ''
              FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdYM
        
             SELECT A.IsCfm, 0 AS Status 
               FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdYM

        END 
    END 
    

    RETURN  
GO 

begin tran 
exec hye_SSLOilSalesIsCfm @xmlDocument=N'<ROOT>
  <DataBlock15>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock15</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <IsCfm>0</IsCfm>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock15>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730148,@WorkingTag=N'C',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730008
rollback 


