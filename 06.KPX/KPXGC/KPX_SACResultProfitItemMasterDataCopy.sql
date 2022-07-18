  
IF OBJECT_ID('KPX_SACResultProfitItemMasterDataCopy') IS NOT NULL   
    DROP PROC KPX_SACResultProfitItemMasterDataCopy  
GO  
  
-- v2014.12.20  
  
-- �������ͻ�ǰ������- ���������� ���� by ����õ   
CREATE PROC KPX_SACResultProfitItemMasterDataCopy  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    CREATE TABLE #KPX_TACResultProfitItemMaster( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACResultProfitItemMaster'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A 
       SET WorkingTag = 'D' 
      FROM #KPX_TACResultProfitItemMaster AS A 
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TACResultProfitItemMaster')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TACResultProfitItemMaster'    , -- ���̺��        
                  '#KPX_TACResultProfitItemMaster'    , -- �ӽ� ���̺��        
                  'StdDate'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                  @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ��   
    
    DELETE B
      FROM #KPX_TACResultProfitItemMaster AS A 
      JOIN KPX_TACResultProfitItemMaster  AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate = A.StdDate ) 
    
    DECLARE @MaxStdDate NCHAR(8), 
            @StdDate    NCHAR(8) 
    
    SELECT @MaxStdDate = MAX(ISNULL(StdDate,'')) FROM KPX_TACResultProfitItemMaster WHERE CompanySeq = @CompanySeq 
    SELECT @StdDate = StdDate FROM #KPX_TACResultProfitItemMaster 
    
    -- ������ȸ   
    SELECT Z.MinorName AS UMHelpComName, 
           A.UMHelpCom, 
           A.FundSeq, 
           B.FundName, 
           B.FundCode, 
           C.MinorName AS FundKindSName,   
           D.MinorName AS FundKindMName,   
           F.MinorName AS FundKindLName,   
           L.MinorName AS FundKindName,   
           B.TitileName, 
           A.CancelDate, 
           A.CancelAmt, 
           A.CancelResultAmt, 
           A.AllCancelDate, 
           A.AllCancelAmt, 
           A.AllCancelResultAmt, 
           A.SplitDate, 
           A.SliptAmt, 
           A.ResultReDate, 
           A.ResultReAmt, 
           A.ResultAmt, 
           A.Remark1, 
           A.Remark2, 
           A.Remark3 
    
      FROM KPX_TACResultProfitItemMaster       AS A 
      LEFT OUTER JOIN KPX_TACFundMaster     AS B ON ( B.CompanySeq = @CompanySeq AND B.FundSeq = A.FundSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS Z ON ( Z.CompanySeq = @CompanySeq AND Z.MinorSeq = A.UMHelpCom ) 
      LEFT OUTER JOIN _TDAUMinor            AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.FundKindS )   
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = B.FundKindM )   
      LEFT OUTER JOIN _TDAUMinorValue       AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 )   
      LEFT OUTER JOIN _TDAUMinor            AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.ValueSeq )   
      LEFT OUTER JOIN _TDAUMinorValue       AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = F.MinorSeq AND K.Serl = 1000002 )   
      LEFT OUTER JOIN _TDAUMinor            AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = K.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.StdDate = @MaxStdDate
    
    RETURN  
    
    
