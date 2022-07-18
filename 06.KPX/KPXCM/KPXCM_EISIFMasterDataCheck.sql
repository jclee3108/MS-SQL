
IF OBJECT_ID('KPXCM_EISIFMasterDataCheck') IS NOT NULL 
    DROP PROC KPXCM_EISIFMasterDataCheck
GO 

-- v2015.06.18 
  
-- �ڵ�ȭ���� ���� üũ by �ڻ���   ����: ����õ     
CREATE PROC KPXCM_EISIFMasterDataCheck      
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,       
    @WorkingTag     NVARCHAR(10)= '',      
    @CompanySeq     INT = 1,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS       
    DECLARE @MessageType    INT,      
            @Status         INT,      
            @Results        NVARCHAR(250),    
            @YYMM           NCHAR(6)    
      
    CREATE TABLE #TEISIFMasterData( WorkingTag NCHAR(1) NULL )        
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TEISIFMasterData'       
    IF @@ERROR <> 0 RETURN         
      
    SELECT @YYMM = YYMM FROM #TEISIFMasterData    
          
    ---------------------------------------------------------------  
    -- üũ1, �������� ����ó���� �����ʾҽ��ϴ�.   
    ---------------------------------------------------------------  
    IF EXISTS( SELECT 1    
                 FROM _TDAAccUnit A   
                 LEFT OUTER JOIN (          
                                    SELECT A.CompanySeq,CostUnit AS AccUnit,IsClosing    
                                      FROM _TESMCProdClosing A   
                                      LEFT OUTER JOIN _TESMDCostKey  B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                                                   AND A.CostKeySeq = B.CostKeySeq     
                                                                                   AND B.SMCostMng = 5512001    
                                     WHERE A.CompanySeq = @CompanySeq    
                                       AND B.CostYM=@YYMM    
                                 ) AA ON A.CompanySeq = AA.CompanySeq    
                                     AND A.AccUnit = AA.AccUnit    
                WHERE A.CompanySeq = @CompanySeq   
                  AND AA.IsClosing IS NULL   
                  AND A.AccUnit NOT IN(8,9)    
             )     
    
    BEGIN    
        UPDATE #TEISIFMasterData    
           SET Result = '�������� ����ó���� �����ʾҽ��ϴ�.',   
               Status = 1234,     
               MessageType = 1234   
             
    END     
    ---------------------------------------------------------------  
    -- üũ1, END   
    ---------------------------------------------------------------  
      
    ---------------------------------------------------------------  
    -- üũ2, �ѿ��� ����ó���� �����ʾҽ��ϴ�.  
    ---------------------------------------------------------------  
    IF EXISTS( SELECT 1    
                 FROM _TDAAccUnit AS A   
                 LEFT OUTER JOIN (          
                                  SELECT A.CompanySeq,ProfCostUnit AS AccUnit,IsClosing    
                                    FROM _TESMCProfClosing A LEFT OUTER JOIN _TESMDCostKey  B WITH(NOLOCK)    
                                            ON A.CompanySeq = B.CompanySeq    
                                           AND A.CostKeySeq = B.CostKeySeq     
                                           AND B.SMCostMng =5512001    
                                   WHERE A.CompanySeq = @CompanySeq    
                                     AND B.CostYM = @YYMM    
                                 ) AA ON A.CompanySeq = AA.CompanySeq    
                                     AND A.AccUnit = AA.AccUnit    
                WHERE A.CompanySeq = @CompanySeq   
                  AND AA.IsClosing IS NULL   
                  AND A.AccUnit NOT IN(8,9)   
             )     
    BEGIN    
        UPDATE #TEISIFMasterData    
           SET Result = '�ѿ��� ����ó���� �����ʾҽ��ϴ�.',   
               Status = 1234,   
               MessageType = 1234   
         WHERE Status = 0    
    END    
    ---------------------------------------------------------------  
    -- üũ2, END   
    ---------------------------------------------------------------  
      
   SELECT * FROM #TEISIFMasterData    
    
    
     RETURN   