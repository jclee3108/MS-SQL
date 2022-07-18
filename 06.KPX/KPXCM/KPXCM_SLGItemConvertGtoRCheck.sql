IF OBJECT_ID('KPXCM_SLGItemConvertGtoRCheck') IS NOT NULL 
    DROP PROC KPXCM_SLGItemConvertGtoRCheck
GO

-- v2016.05.25 

-- KPXCM�� ���� by����õ 
/************************************************************
 ��  �� - ������-��ǰ ������üó��(����ι���)_KPX : Ȯ��
 �ۼ��� - 20150817
 �ۼ��� - ������
 ������ - 
************************************************************/
CREATE PROC dbo.KPXCM_SLGItemConvertGtoRCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS   

    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250),
            @XmlData     NVARCHAR(MAX)
  
    CREATE TABLE #KPX_TLGItemConvertGtoR (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TLGItemConvertGtoR'

    CREATE TABLE #KPX_TLGItemConvertGtoRItem (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TLGItemConvertGtoRItem'

    
    --�� ����ι��� ���� ���� üũ 
    -- ��� ����ι��� ��ǰ ���� üũ
    -- �԰� ����ι��� ���� ���� üũ
	EXEC dbo._SCOMMessage @MessageType OUTPUT,    
						  @Status      OUTPUT,    
						  @Results     OUTPUT,    
						  2                  , -- @1 @2��(��) ���� �Ǿ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%����%')    
						  @LanguageSeq       ,     
						  0,'',   -- SELECT * FROM _TCADictionary WHERE Word like '%����%'    
						  7161, '����'    

    UPDATE A
	   SET A.Status = @Status,      -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.      
		   A.Result = REPLACE(@Results, '@1', '����ι�('+B.BizUnitName+')'),
		   A.MessageType = @MessageType 
      FROM #KPX_TLGItemConvertGtoR AS A JOIN _TDABizUnit AS B WITH(NOLOCK) ON A.InBizUnit = B.BizUnit AND B.CompanySeq  = @CompanySeq
                                        JOIN _TCOMClosingYM AS C WITH(NOLOCK) ON A.InBizUnit = C.UnitSeq AND C.CompanySeq   = @CompanySeq
                                                                             AND LEFT(A.InOutDate,6) = C.ClosingYM
                                                                             AND C.ClosingSeq       = 69    --����
                                                                             AND C.IsClose      = '1'
                                                                             AND C.DtlUnitSeq = 1
     WHERE A.Status = 0

    --���� �����̺�� join
    UPDATE A
	   SET A.Status = @Status,      -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.      
		   A.Result = REPLACE(@Results, '@1', '����ι�('+B.BizUnitName+')'),
		   A.MessageType = @MessageType 
      FROM #KPX_TLGItemConvertGtoR AS A JOIN KPX_TLGItemConvertGtoR AS A2 WITH(NOLOCK) ON A2.CompanySeq = @CompanySeq AND A.ConvertSeq  = A2.ConvertSeq
                                        JOIN _TDABizUnit AS B WITH(NOLOCK) ON A2.InBizUnit = B.BizUnit AND B.CompanySeq  = @CompanySeq
                                        JOIN _TCOMClosingYM AS C WITH(NOLOCK) ON A2.InBizUnit = C.UnitSeq AND C.CompanySeq   = @CompanySeq
                                                                             AND LEFT(A2.InOutDate,6) = C.ClosingYM
                                                                             AND C.ClosingSeq       = 69    --����
                                                                             AND C.IsClose      = '1'
                                                                             AND C.DtlUnitSeq = 1
     WHERE A.Status = 0


    UPDATE A
	   SET A.Status = @Status,      -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.      
		   A.Result = REPLACE(@Results, '@1', '����ι�('+B.BizUnitName+')'),
		   A.MessageType = @MessageType 
      FROM #KPX_TLGItemConvertGtoR AS A JOIN _TDABizUnit AS B WITH(NOLOCK) ON A.OutBizUnit = B.BizUnit AND B.CompanySeq  = @CompanySeq
                                        JOIN _TCOMClosingYM AS C WITH(NOLOCK) ON A.OutBizUnit = C.UnitSeq AND C.CompanySeq   = @CompanySeq
                                                                             AND LEFT(A.InOutDate,6) = C.ClosingYM
                                                                             AND C.ClosingSeq       = 69    --����
                                                                             AND C.IsClose      = '1'
                                                                             AND C.DtlUnitSeq = 2
     WHERE A.Status = 0

    --���� �����̺�� join
    UPDATE A
	   SET A.Status = @Status,      -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.      
		   A.Result = REPLACE(@Results, '@1', '����ι�('+B.BizUnitName+')'),
		   A.MessageType = @MessageType 
      FROM #KPX_TLGItemConvertGtoR AS A JOIN KPX_TLGItemConvertGtoR AS A2 WITH(NOLOCK) ON A2.CompanySeq = @CompanySeq AND A.ConvertSeq  = A2.ConvertSeq
                                        JOIN _TDABizUnit AS B WITH(NOLOCK) ON A2.OutBizUnit = B.BizUnit AND B.CompanySeq  = @CompanySeq
                                        JOIN _TCOMClosingYM AS C WITH(NOLOCK) ON A2.OutBizUnit = C.UnitSeq AND C.CompanySeq   = @CompanySeq
                                                                             AND LEFT(A2.InOutDate,6) = C.ClosingYM
                                                                             AND C.ClosingSeq       = 69    --����
                                                                             AND C.IsClose      = '1'
                                                                             AND C.DtlUnitSeq = 2
     WHERE A.Status = 0

     
    --������ ����ι��� ��� ���� ó��
    UPDATE A
	   SET A.Status = @Status,      -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.      
		   A.Result = '������ ����ι��� �ԷµǾ����ϴ�.',
		   A.MessageType = @MessageType 
      FROM #KPX_TLGItemConvertGtoR AS A 
     WHERE A.Status = 0
       AND A.WorkingTag IN ('A','U')
       AND A.InBizUnit = A.OutBizUnit

    --������ ǰ���� ��� ���� ó��
    UPDATE A
	   SET A.Status = @Status,      -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.      
		   A.Result = '������ ǰ���� �ԷµǾ����ϴ�.',
		   A.MessageType = @MessageType 
      FROM #KPX_TLGItemConvertGtoRItem AS A 
     WHERE A.Status = 0
       AND A.WorkingTag IN ('A','U')
       AND A.ItemSeq = A.ConvertItemSeq
    
    /* 
    -- ��üó�� ǰ���� LotNo�� �����մϴ�. LotMaster�� Ȯ�� �Ͻñ� �ٶ��ϴ�. 
    UPDATE A 
       SET A.Status = 1234,
		   A.Result = '��üó�� ǰ���� LotNo�� �����մϴ�. LotMaster�� Ȯ�� �Ͻñ� �ٶ��ϴ�. ',
		   A.MessageType = 1234 
      FROM #KPX_TLGItemConvertGtoRItem AS A 
     WHERE EXISTS (SELECT 1 FROM _TLGLotMaster WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ConvertItemSeq AND LotNo = A.ConvertLotNo) 
       AND A.WorkingTag IN ( 'U', 'A' ) 
       AND A.Status = 0 
    */
    
    IF EXISTS(SELECT 1 FROM #KPX_TLGItemConvertGtoR WHERE Status <> 0) OR EXISTS(SELECT 1 FROM #KPX_TLGItemConvertGtoRItem WHERE Status <> 0)
    BEGIN
        SELECT * FROM #KPX_TLGItemConvertGtoR 
        SELECT * FROM #KPX_TLGItemConvertGtoRItem
        RETURN    
    END
    

    --ȯ�漳��_kpx�� �ִ� ����а��� �޾Ƽ� �־���
    DECLARE @InKindDetail INT,
            @OutKindDetail INT
            
    SELECT  @InKindDetail = 0,
            @OutKindDetail  = 0
            
    SELECT @InKindDetail = EnvValue 
      FROM KPX_TCOMEnvItem WITH(NOLOCK)
     WHERE CompanySeq   = @CompanySeq
       AND EnvSeq = 46  --��ǰ ������ü �԰�����

    SELECT @OutKindDetail = EnvValue 
      FROM KPX_TCOMEnvItem WITH(NOLOCK)
     WHERE CompanySeq   = @CompanySeq
       AND EnvSeq = 47  --��ǰ ������ü �������


     UPDATE #KPX_TLGItemConvertGtoR                            
        SET InSeq = C.InSeq ,
            InNo    = C.InNo                         
       FROM #KPX_TLGItemConvertGtoR AS A       
       JOIN KPX_TLGItemConvertGtoR  AS B ON B.CompanySeq =@CompanySeq AND A.ConvertSeq = B.ConvertSeq 
      CROSS APPLY (SELECT TOP 1 InSeq  , InNo   
                     FROM KPX_TLGItemConvertGtoRItem AS Z     
                    WHERE  Z.ConvertSeq = B.ConvertSeq    
                   ) AS C     
      WHERE  A.WorkingTag IN ('D','U')        
        AND  A.Status = 0   
    
     UPDATE #KPX_TLGItemConvertGtoR                            
        SET OutSeq = C.OutSeq ,
            OutNo   = C.OutNo                        
       FROM #KPX_TLGItemConvertGtoR AS A       
       JOIN KPX_TLGItemConvertGtoR  AS B ON B.CompanySeq =@CompanySeq AND A.ConvertSeq = B.ConvertSeq 
      CROSS APPLY (SELECT TOP 1 OutSeq, OutNo    
                     FROM KPX_TLGItemConvertGtoRItem AS Z     
                    WHERE  Z.ConvertSeq = B.ConvertSeq    
                   ) AS C     
      WHERE  A.WorkingTag IN ('D','U')        
        AND  A.Status = 0  
            
    CREATE TABLE #Temp11 (WorkingTag NCHAR(1) NULL)                             
     EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#Temp11'               
              
    -- M ��üó��(��Ÿ��� : 30)                   
         SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,                   
                                                           A.IDX_NO,                   
                                                           A.DataSeq,                   
                                                           1 AS Selected,                   
                                                           0 AS Status,                   
                                                           ISNULL(A.OutSeq,0) AS InOutSeq,           
                                                           A.OutBizUnit AS BizUnit,                   
                                                           A.OutNo AS InOutNo,                   
                                                           A.DeptSeq AS DeptSeq,            
                                                           A.EmpSeq AS EmpSeq,                   
                                                           A.InOutDate,                   
                                                           A.InWHSeq AS InWHSeq,                   
                                                           A.OutWHSeq AS OutWHSeq,            
                                                           30 AS InOutType                   
                                                       FROM #KPX_TLGItemConvertGtoR AS A                   
                                                                
                                                      FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS                     
                             ))                   
                         
 
         INSERT INTO #Temp11                   
          EXEC _SLGInOutDailyCheck                  
               @xmlDocument  = @XmlData,                     
               @xmlFlags     = 2,                     
               @ServiceSeq   = 2619,                     
               @WorkingTag   = '',                     
               @CompanySeq   = @CompanySeq,                     
               @LanguageSeq  = 1,                     
               @UserSeq      = @UserSeq,                     
               @PgmSeq       = @PgmSeq              
              
           

     
       UPDATE A          
          SET A.OutSeq = B.InOutSeq,
              A.OutNo   = B.InOutNo,   
              A.Status    = B.Status     ,
              A.MessageType = B.MessageType ,
              A.Result     = B.Result                  
         FROM #KPX_TLGItemConvertGtoR AS A          
         JOIN #Temp11 AS B ON  A.IDX_NO = B.IDX_NO        
    
    
    IF EXISTS(SELECT 1 FROM #KPX_TLGItemConvertGtoR WHERE Status <> 0)
    BEGIN
        SELECT * FROM #KPX_TLGItemConvertGtoR 
        SELECT * FROM #KPX_TLGItemConvertGtoRItem
        RETURN    
    END
    
    --�ʱ�ȭ
        DELETE FROM #Temp11
        SELECT @XmlData = ''
-- M ��üó��(�����Ÿ�԰� : 41)                   
         SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,                   
                                                           A.IDX_NO,                   
                                                           A.DataSeq,                   
                                                           1 AS Selected,                   
                                                           0 AS Status,                   
                                                           ISNULL(A.InSeq,0) AS InOutSeq,           
                                                           A.InBizUnit AS BizUnit,                   
                                                           A.InNo AS InOutNo,                   
                                                           A.DeptSeq AS DeptSeq,                   
                                                           A.EmpSeq AS EmpSeq,                   
                                                           A.InOutDate,                   
                                                           A.InWHSeq AS InWHSeq,                   
                                                           A.OutWHSeq AS OutWHSeq,            
                                                           41 AS InOutType                   
                                                       FROM #KPX_TLGItemConvertGtoR AS A                   
                                                                
                                                      FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS                     
                             ))                   
                         
 
         INSERT INTO #Temp11                   
          EXEC _SLGInOutDailyCheck                  
               @xmlDocument  = @XmlData,                     
               @xmlFlags     = 2,                     
               @ServiceSeq   = 2619,                     
               @WorkingTag   = '',                     
               @CompanySeq   = @CompanySeq,                     
               @LanguageSeq  = 1,                     
               @UserSeq      = @UserSeq,                     
               @PgmSeq       = @PgmSeq              
              
     
       UPDATE A          
          SET A.InSeq   = B.InOutSeq,
              A.InNo    = B.InOutNo  ,   
              A.Status    = B.Status     ,
              A.MessageType = B.MessageType ,
              A.Result     = B.Result                    
         FROM #KPX_TLGItemConvertGtoR AS A          
         JOIN #Temp11 AS B ON  A.IDX_NO = B.IDX_NO      
    
    IF EXISTS(SELECT 1 FROM #KPX_TLGItemConvertGtoR WHERE Status <> 0)
    BEGIN
        SELECT * FROM #KPX_TLGItemConvertGtoR 
        SELECT * FROM #KPX_TLGItemConvertGtoRItem
        RETURN    
    END    
    
---- guide : �� �� 'Ű ����', '���࿩�� üũ', '�������� üũ', 'Ȯ������ üũ' ���� üũ������ �ֽ��ϴ�.
----guide : '������ Ű ����' --------------------------
    DECLARE @MaxSeq INT,
            @Count  INT,
            @InOutDate  NCHAR(8),
            @InOutNo    NVARCHAR(200)
            
    SELECT @Count = Count(1) FROM #KPX_TLGItemConvertGtoR WHERE WorkingTag = 'A' AND Status = 0
    if @Count >0 
    BEGIN
        SELECT @InOutDate = InOutDate FROM #KPX_TLGItemConvertGtoR     
        
        EXEC dbo._SCOMCreateNo 'SITE', 'KPX_TLGItemConvertGtoR', @CompanySeq, 0, @InOutDate, @InOutNo OUTPUT  
    
        EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'KPX_TLGItemConvertGtoR','ConvertSeq',@Count --rowcount  
        
          UPDATE #KPX_TLGItemConvertGtoR             
             SET ConvertSeq  = @MaxSeq + DataSeq   ,
                 InOutNo     = @InOutNo
           WHERE WorkingTag = 'A'            
             AND Status = 0 
    END  
    
    --#KPX_TLGItemConvertGtoRItem �� �ݿ�
    IF EXISTS (SELECT 1 ConvertSeq FROM #KPX_TLGItemConvertGtoR)
    BEGIN 
        UPDATE #KPX_TLGItemConvertGtoRItem
          SET ConvertSeq = (SELECT TOP 1 ConvertSeq FROM #KPX_TLGItemConvertGtoR),
              OutWHSeq  = (SELECT TOP 1 OutWHSeq FROM #KPX_TLGItemConvertGtoR),
              InWHSeq   = (SELECT TOP 1 InWHSeq FROM #KPX_TLGItemConvertGtoR),
              InSeq = (SELECT TOP 1 InSeq FROM #KPX_TLGItemConvertGtoR),
              OutSeq = (SELECT TOP 1 OutSeq FROM #KPX_TLGItemConvertGtoR),
              InNo = (SELECT TOP 1 InNo FROM #KPX_TLGItemConvertGtoR),
              OutNo = (SELECT TOP 1 OutNo FROM #KPX_TLGItemConvertGtoR)          
    END 
          
           
           
    --DataBlock2
      CREATE TABLE #Temp3 (WorkingTag NCHAR(1) NULL)                                 
      EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock2', '#Temp3'               

         
      --��Ÿ���(30)
      SELECT @XmlData = '' 
      SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,                       
                                                           A.IDX_NO,                       
                                                           A.DataSeq,                       
                                                           1 AS Selected,                       
                                                           0 AS Status,                       
                                                           A.OutSeq AS InOutSeq,                       
                                                           A.OutSerl AS InOutSerl,                       
                                                           30 AS InOutType,                 
                                                           --A.ItemSeq AS ItemSeq,              
                                                           A.UnitSeq AS UnitSeq ,                   
                                    A.ItemSeq AS ItemSeq,                       
                                                           A2.OutBizUnit AS BizUnit,                       
                                                           '' AS InOutNo,              
                                                           A.LotNo AS LotNo,              
                                                           A2.DeptSeq AS DeptSeq,                       
                                                           A2.EmpSeq AS EmpSeq,                       
                                                           A2.InOutDate,                       
                                                           A.InWHSeq AS InWHSeq,                       
                                                           A.OutWHSeq AS OutWHSeq,                    
                                                           A.UnitSeq AS OriUnitSeq,                
                                                           A.OutQty AS Qty,                       
                                                           A.OutQty AS OriQty,                 
                                                           A.STDUnitQty AS STDQty,                    
                                                           A.ItemSeq As OriItemSeq,              
                                                           A.STDUnitQty AS OriSTDQty,                       
                                                           8023003 AS InOutKind,    --��Ÿ���                     
                                                           A.LotNo AS OriLotNo,                       
                                                           ----A.RealLotNo AS LotNo,                       
                                                           ISNULL(@OutKindDetail,0) AS InOutDetailKind,                   
                                                           0 AS Amt                       
                                                       FROM #KPX_TLGItemConvertGtoRItem AS A LEFT OUTER JOIN #KPX_TLGItemConvertGtoR AS A2 ON A.ConvertSeq = A2.ConvertSeq
                                                       LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )                                                                            
                                                      FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS                         
                                                       ))                       
                               
               
         INSERT INTO #Temp3                      
         EXEC KPXCM_SLGInOutDailyItemCheck                   
              @xmlDocument  = @XmlData,                         
              @xmlFlags     = 2,                         
              @ServiceSeq   = 2619,                         
              @WorkingTag   = '',                         
              @CompanySeq   = @CompanySeq,                         
              @LanguageSeq  = 1,                         
              @UserSeq      = @UserSeq,                         
              @PgmSeq       = @PgmSeq                  
               
                 
--select '#Temp3', * from #Temp3                  
                     
          UPDATE A            
            SET  A.OutSerl = B.InOutSerl  ,
                 A.Status    = B.Status     ,
                 A.MessageType = B.MessageType ,
                 A.Result     = B.Result   
           FROM  #KPX_TLGItemConvertGtoRItem AS A            
           JOIN  #Temp3 AS B ON  A.IDX_NO = B.IDX_NO              

    IF EXISTS(SELECT 1 FROM #KPX_TLGItemConvertGtoRItem WHERE Status <> 0)
    BEGIN
        SELECT * FROM #KPX_TLGItemConvertGtoR 
        SELECT * FROM #KPX_TLGItemConvertGtoRItem
        RETURN    
    END
            
    --�����Ÿ�԰�(41)
        --�ʱ�ȭ
      DELETE FROM #Temp3
      SELECT @XmlData = '' 
      SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT A.WorkingTag,                       
                                                           A.IDX_NO,                       
                                                           A.DataSeq,                       
                                                           1 AS Selected,                       
                                                           0 AS Status,                       
                                                           A.InSeq AS InOutSeq,                       
                                                           A.InSerl AS InOutSerl,                       
                                                           41 AS InOutType,                 
                                                           --A.ItemSeq AS ItemSeq,              
                                                           A.ConvertUnitSeq AS UnitSeq ,                   
                                                           A.ConvertItemSeq AS ItemSeq,                       
                                                           A2.InBizUnit AS BizUnit,                       
                                                           '' AS InOutNo,              
                                                           A.ConvertLotNo AS LotNo,              
                                                           A2.DeptSeq AS DeptSeq,                       
                                                           A2.EmpSeq AS EmpSeq,                       
                                                           A2.InOutDate,                       
                                                           A.InWHSeq AS InWHSeq,                       
                                                           A.OutWHSeq AS OutWHSeq,                    
                                                           A.UnitSeq AS OriUnitSeq,                
                                                           A.ConvertQty AS Qty,                       
                                                           A.OutQty AS OriQty,                 
                                                           A.ConvertSTDUnitQty AS STDQty,                    
                                                           A.ItemSeq As OriItemSeq,              
                                                           A.ConvertSTDUnitQty AS OriSTDQty,                       
                                                           8023004 AS InOutKind,    --��Ÿ�԰�                     
                                                           A.LotNo AS OriLotNo,                       
                                                           ----A.RealLotNo AS LotNo,                       
                                                           ISNULL(@InKindDetail,0) AS InOutDetailKind,                   
                                                           0 AS Amt                       
                                                       FROM #KPX_TLGItemConvertGtoRItem AS A LEFT OUTER JOIN #KPX_TLGItemConvertGtoR AS A2 ON A.ConvertSeq = A2.ConvertSeq
                                                       LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )                                                                            
                                                      FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS                         
                                                       ))                       
                               
               
         INSERT INTO #Temp3                      
         EXEC KPXCM_SLGInOutDailyItemCheck                   
              @xmlDocument  = @XmlData,                  
              @xmlFlags     = 2,                         
              @ServiceSeq   = 2619,                         
              @WorkingTag   = '',                         
              @CompanySeq   = @CompanySeq,                         
              @LanguageSeq  = 1,                         
              @UserSeq      = @UserSeq,                         
              @PgmSeq       = @PgmSeq                  
               
                 
                  
                     
          UPDATE A            
            SET  A.InSerl = B.InOutSerl  ,
                 A.Status    = B.Status     ,
                 A.MessageType = B.MessageType ,
                 A.Result     = B.Result   
           FROM  #KPX_TLGItemConvertGtoRItem AS A            
           JOIN  #Temp3 AS B ON  A.IDX_NO = B.IDX_NO           
    
    
    
    IF EXISTS(SELECT 1 FROM #KPX_TLGItemConvertGtoRItem WHERE Status <> 0)
    BEGIN
        SELECT * FROM #KPX_TLGItemConvertGtoR 
        SELECT * FROM #KPX_TLGItemConvertGtoRItem
        RETURN    
    END

    SELECT @MaxSeq  = 0,
           @Count   = 0 

    SELECT @Count = Count(1) FROM  #KPX_TLGItemConvertGtoRItem    WHERE WorkingTag = 'A' AND Status = 0
    if @Count >0 
    BEGIN
      SELECT @MaxSeq =ISNULL( Max(A.ConvertSerl),0)
        FROM KPX_TLGItemConvertGtoRItem         AS A
             JOIN #KPX_TLGItemConvertGtoRItem    AS B ON  A.ConvertSeq = B.ConvertSeq
       WHERE A.CompanySeq  = @CompanySeq 
         AND B.WorkingTag = 'A'            
         AND B.Status = 0 
          
      UPDATE #KPX_TLGItemConvertGtoRItem                
         SET ConvertSerl  = @MaxSeq + DataSeq   
       WHERE WorkingTag = 'A'            
         AND Status = 0 
    END             
           
                           
    SELECT * FROM #KPX_TLGItemConvertGtoR 
    SELECT * FROM #KPX_TLGItemConvertGtoRItem
RETURN
GO
begin tran 
exec KPXCM_SLGItemConvertGtoRCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemName>Lotǰ��1_����õ</ItemName>
    <ItemNo>Lotǰ��1_����õ</ItemNo>
    <Spec />
    <UnitName>Kg</UnitName>
    <OutQty>1</OutQty>
    <STDUnitName>Kg</STDUnitName>
    <STDUnitQty>1</STDUnitQty>
    <LotNo>qwer22</LotNo>
    <Remark />
    <ConvertItemName>Lot_�ٽ��ѹ��׽�Ʈ_����õ</ConvertItemName>
    <ConvertItemNo>Lot_�ٽ��ѹ��׽�ƮNo_����õ</ConvertItemNo>
    <ConvertItemSpec />
    <ConvertUnitName>EA</ConvertUnitName>
    <ConvertQty>1</ConvertQty>
    <ConvertSTDUnitName>EA</ConvertSTDUnitName>
    <ConvertSTDUnitQty>1</ConvertSTDUnitQty>
    <ConvertLotNo>�ٽ��ѹ�_Lot1</ConvertLotNo>
    <ConvertRemark />
    <ConvertSeq>18</ConvertSeq>
    <ConvertSerl>1</ConvertSerl>
    <ItemSeq>27367</ItemSeq>
    <UnitSeq>2</UnitSeq>
    <STDUnitSeq>2</STDUnitSeq>
    <ConvertItemSeq>1052403</ConvertItemSeq>
    <ConvertUnitSeq>4</ConvertUnitSeq>
    <ConvertSTDUnitSeq>4</ConvertSTDUnitSeq>
    <InSeq>100002558</InSeq>
    <InSerl>1</InSerl>
    <InNo>201605250009</InNo>
    <OutSeq>100002557</OutSeq>
    <OutSerl>1</OutSerl>
    <OutNo>201605250008</OutNo>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037198,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030471
rollback 