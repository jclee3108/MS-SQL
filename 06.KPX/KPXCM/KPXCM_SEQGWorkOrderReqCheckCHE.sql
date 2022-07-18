IF OBJECT_ID('KPXCM_SEQGWorkOrderReqCheckCHE') IS NOT NULL 
    DROP PROC KPXCM_SEQGWorkOrderReqCheckCHE
GO 

-- v2015.07.21 

-- ������-�۾���ûMaster : üũ(�Ϲ�) - KPXCM������ ���� by����õ 
CREATE PROC KPXCM_SEQGWorkOrderReqCheckCHE
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS
    DECLARE @Count       INT,
            @Seq         INT,
            @Date        NCHAR(8),
            @MaxNo       NVARCHAR(20),
            @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250),
            --@MIWONO      NCHAR(2),
            @WONUM       INT,
            @ProgType    INT,
            @DeptSeq     INT, 
            @AccUnitSeq  INT
              
    -- ���� ����Ÿ ��� ����      
    CREATE TABLE #_TEQWorkOrderReqMasterCHE (WorkingTag NCHAR(1) NULL)       
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQWorkOrderReqMasterCHE'      
    IF @@ERROR <> 0 RETURN      
    
    -----------------------------        
    ---- ������� üũ        
    -----------------------------          
    SELECT @ProgType     = A.ProgType        
      FROM _TEQWorkOrderReqMasterCHE AS A        
      JOIN #_TEQWorkOrderReqMasterCHE AS B ON ( A.WOReqSeq = B.WOReqSeq )                                 
     WHERE A.CompanySeq = @CompanySeq        
       AND B.Status = 0      
       AND B.WorkingTag IN ('U','D')      
    
    IF @ProgType <>  20109001        
    BEGIN        
                   
        SELECT @Results ='�۾� �������� �����Դϴ�. �������� �Ұ�!'        

        UPDATE #_TEQWorkOrderReqMasterCHE            
           SET Result        = @Results,             
               MessageType   = 99999,             
               Status        = 99999        
          FROM _TEQWorkOrderReqMasterCHE AS A        
          JOIN #_TEQWorkOrderReqMasterCHE AS B ON (  A.WOReqSeq = B.WOReqSeq )             
    END      
    
    -----------------------------        
    ---- �۾���û �μ�üũ        
    -----------------------------        
             
    SELECT @Count = COUNT(1)       
      FROM #_TEQWorkOrderReqMasterCHE AS B      
      JOIN ( SELECT S1.ValueSeq      
              FROM _TDAUMinorValue  AS S1      
              JOIN _TDAUMinor       AS S2 ON S1.CompanySeq = S2.CompanySeq AND S1.MinorSeq = S2.MinorSeq AND S1.Serl = 1000001 
             WHERE S1.MajorSeq = 20105      
               AND S1.CompanySeq = @Companyseq
           ) AS S ON B.DeptSeq = S.ValueSeq      
     WHERE B.Status = 0      
       AND B.WorkingTag IN ('A')       
                
    IF @Count = 0       
    BEGIN        
        UPDATE #_TEQWorkOrderReqMasterCHE 
           SET Result         = '�۾����к� �۾���ȣ�� �������� �ʽ��ϴ�.,W/O ���� �Ұ�!',             
               MessageType   = 99999,             
               Status        = 99999        
          FROM #_TEQWorkOrderReqMasterCHE AS B      
         WHERE B.Status = 0      
           AND B.WorkingTag IN ('A')            
    END      
    
    --WONO  ����      
    SELECT @Count = COUNT(1) FROM #_TEQWorkOrderReqMasterCHE WHERE WorkingTag = 'A' AND Status = 0        
    IF @Count > 0      
    BEGIN         
    
        
        DECLARE @WONo       NVARCHAR(100), 
                @MaxSerl    INT 
        
        
        SELECT @WONo = ISNULL(D.ValueText,'') + ISNULL(C.ValueText,'') + '-' + RIGHT(A.ReqDate,6) + '-' 
          FROM #_TEQWorkOrderReqMasterCHE           AS A 
          LEFT OUTER JOIN _TDAUMinorValue           AS B ON ( B.CompanySeq = @CompanySeq AND B.MajorSeq = 1011352 AND B.Serl = 1000001 AND B.ValueSeq = A.AccUnitSeq ) 
          LEFT OUTER JOIN _TDAUMinorValue           AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MinorSeq AND C.Serl = 1000002 ) 
          LEFT OUTER JOIN _TDAUMinorValue           AS D ON ( D.CompanySeq = @CompanySeq 
                                                          AND D.MinorSeq = (CASE WHEN @PgmSeq = 1025722 THEN 1011353002 ELSE 1011353001 END) 
                                                          AND D.Serl = 1000001 
                                                            ) 
            

        SELECT @MaxSerl = ISNULL(MAX(CONVERT(INT,RIGHT(WONo,3))),0)
          FROM _TEQWorkOrderReqMasterCHE 
         WHERE CompanySeq = @CompanySeq 
           AND WONo LIKE @WONo + '%'
    
        UPDATE A 
           SET WONo = @WONo + RIGHT('000' + CONVERT(NVARCHAR(10),@MaxSerl + DataSeq),3)
          FROM #_TEQWorkOrderReqMasterCHE AS A 
    
    END       
    
    -------------------------------------------        
    -- INSERT ��ȣ�ο�(�� ������ ó��)        
    -------------------------------------------        
    SELECT @Count = COUNT(1) FROM #_TEQWorkOrderReqMasterCHE WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)      
    IF @Count > 0        
    BEGIN          
        -- Ű�������ڵ�κ� ����          
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TEQWorkOrderReqMasterCHE', 'WOReqSeq', @Count        
        -- Temp Talbe �� ������ Ű�� UPDATE        
        UPDATE #_TEQWorkOrderReqMasterCHE       
           SET WOReqSeq = @Seq + DataSeq      
         WHERE WorkingTag = 'A'        
           AND Status = 0        
    
    END        
    
    SELECT * FROM #_TEQWorkOrderReqMasterCHE      
    
    RETURN
GO
begin tran 
exec KPXCM_SEQGWorkOrderReqCheckCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <WOReqSeq>0</WOReqSeq>
    <ReqDate>20150721</ReqDate>
    <DeptSeq>1300</DeptSeq>
    <EmpSeq>2028</EmpSeq>
    <WorkType>20104005</WorkType>
    <ReqCloseDate>20150721</ReqCloseDate>
    <WorkContents>asdgasdgasdgasdg</WorkContents>
    <WONo />
    <AccUnitSeq>2</AccUnitSeq>
    <FileSeq>0</FileSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030987,@WorkingTag=N'A',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025832


rollback 

