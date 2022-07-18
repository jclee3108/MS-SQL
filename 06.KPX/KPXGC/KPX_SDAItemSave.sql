
IF OBJECT_ID('KPX_SDAItemSave') IS NOT NULL 
    DROP PROC KPX_SDAItemSave
GO 

-- v2014.11.04 

-- ǰ����(�⺻_��������)���� by����õ
/*************************************************************************************************  
  ��  �� - ǰ��⺻ ����  
  �ۼ��� - 2008.6. : CREATED BY ���ظ�     
  ������ - 2009.9.8  ��³� 
  �������� - _TDAItem ���̺� LaunchDate(�������)�÷� �߰�
 *************************************************************************************************/  
 CREATE PROCEDURE KPX_SDAItemSave
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
   
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS  
     DECLARE @docHandle          INT,  
             @MaxSeq             INT,  
             @ItemSeq            INT,
             @ItemName           NVARCHAR(200),
             @TrunName           NVARCHAR(200)
      -- ����Ÿ ��� ����  
     CREATE TABLE #KPX_TDAItem (WorkingTag NCHAR(1) NULL)  
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TDAItem'  
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
     EXEC _SCOMLog  @CompanySeq   ,  
                    @UserSeq      ,  
                    'KPX_TDAItem', -- �����̺��  
                    '#KPX_TDAItem', -- �������̺��  
                    'ItemSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                    'CompanySeq,ItemSeq,ItemName,TrunName,ItemNo,AssetSeq,SMStatus,ItemSName,ItemEngName,ItemEngSName,Spec,SMABC,UnitSeq,DeptSeq,EmpSeq,ModelSeq,SMInOutKind,LastUserSeq,LastDateTime,IsInherit,RegUserSeq,RegDateTime, LaunchDate, PgmSeq'      
                    ,'', @PgmSeq
    

     -- DELETE    
     IF EXISTS (SELECT 1 FROM #KPX_TDAItem WHERE WorkingTag = 'D' AND Status = 0  )  
     BEGIN  
         DELETE KPX_TDAItem
           FROM #KPX_TDAItem AS A  
                JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                AND B.ItemSeq     = A.ItemSeq
          WHERE A.WorkingTag = 'D' AND Status = 0
     
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END  
          DELETE KPX_TDAItemClass
           FROM #KPX_TDAItem AS A  
                JOIN KPX_TDAItemClass AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                     AND B.ItemSeq = A.ItemSeq
          WHERE A.WorkingTag = 'D' AND Status = 0
     
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END  
          DELETE KPX_TDAItemUnit
           FROM #KPX_TDAItem AS A  
                JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                     AND B.ItemSeq = A.ItemSeq
          WHERE A.WorkingTag = 'D' AND Status = 0
     
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END  
          DELETE KPX_TDAItemUnitModule
           FROM #KPX_TDAItem AS A  
                JOIN KPX_TDAItemUnitModule AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                          AND B.ItemSeq = A.ItemSeq
          WHERE A.WorkingTag = 'D' AND Status = 0
     
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END  
          DELETE KPX_TDAItemUnitSpec
           FROM #KPX_TDAItem AS A  
                JOIN KPX_TDAItemUnitSpec AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                        AND B.ItemSeq = A.ItemSeq
          WHERE A.WorkingTag = 'D' AND Status = 0
     
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END  
         
         -- �˻�
         DELETE _TPDBaseItemQCType
           FROM #KPX_TDAItem AS A  
                JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                          AND B.ItemSeq    = A.ItemSeq
          WHERE A.WorkingTag = 'D' AND Status = 0
         
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END  
        
        
        -- ǰ�� Ȯ�� ���� 
        DELETE B 
          FROM #KPX_TDAItem         AS A 
          JOIN KPX_TDAItem_Confirm  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.ItemSeq ) 
         WHERE A.Status = 0 
           AND A.WorkingTag = 'D' 
        
        IF @@ERROR <> 0  RETURN
        
     END
    
     --------------------------------------------------------------------
    -- ���ش��� ���� ��, ���� ����ȯ��/�Ӽ����� ���� 20130604 �ڼ�ȣ �߰�
     --------------------------------------------------------------------
      IF EXISTS ( SELECT 1 
                   FROM #KPX_TDAItem      AS A
                        JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                        AND A.ItemSeq    = B.ItemSeq
                  WHERE A.WorkingTag = 'U' 
                    AND A.Status = 0
                    AND A.UnitSeq <> B.UnitSeq )
     BEGIN       
          -- �α����̺� �����
         EXEC _SCOMLog  @CompanySeq       ,  
                        @UserSeq          ,  
                        'KPX_TDAItemUnit'    , -- �����̺��  
                        '#KPX_TDAItem'        , -- �������̺��
                        'ItemSeq, UnitSeq', -- Ű   
                        'CompanySeq, ItemSeq, UnitSeq, BarCode, ConvNum, ConvDen, TransConvQty, LastUserSeq, LastDateTime'  
     
         DELETE KPX_TDAItemUnit
           FROM #KPX_TDAItem           AS A  
                 JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                     AND B.ItemSeq    = A.ItemSeq
          WHERE A.WorkingTag = 'U' AND A.Status = 0
      
         IF @@ERROR <> 0 RETURN  
          DELETE KPX_TDAItemUnitModule
           FROM #KPX_TDAItem                AS A  
                JOIN KPX_TDAItemUnitModule AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                          AND B.ItemSeq    = A.ItemSeq
          WHERE A.WorkingTag = 'U' AND A.Status = 0
          IF @@ERROR <> 0 RETURN 
          DELETE KPX_TDAItemUnitSpec
           FROM #KPX_TDAItem              AS A  
                JOIN KPX_TDAItemUnitSpec AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                        AND B.ItemSeq    = A.ItemSeq
          WHERE A.WorkingTag = 'U' AND A.Status = 0
          IF @@ERROR <> 0 RETURN 
      END
  
     -- Update    
     IF EXISTS (SELECT 1 FROM #KPX_TDAItem WHERE WorkingTag = 'U' AND Status = 0  )  
     BEGIN   
         UPDATE KPX_TDAItem  
            SET  ItemName = ISNULL(A.ItemName,''),
                 TrunName = ISNULL(A.TrunName,''),
                 ItemNo = ISNULL(A.ItemNo,''),
                 AssetSeq = ISNULL(A.AssetSeq,0),
                 SMStatus = ISNULL(A.SMStatus, 0),
                 ItemSName = ISNULL(A.ItemSName, ''),
                 ItemEngName = ISNULL(A.ItemEngName, ''),
                 ItemEngSName = ISNULL(A.ItemEngSName, ''),
                 Spec = ISNULL(A.Spec, ''),
                 SMABC = ISNULL(A.SMABC, 0),
                 UnitSeq = ISNULL(A.UnitSeq,0),
                 DeptSeq = ISNULL(A.DeptSeq,0),
                 EmpSeq = ISNULL(A.EmpSeq,0),
                 ModelSeq = ISNULL(A.ModelSeq,0),
                 SMInOutKind = ISNULL(A.SMInOutKind, 0),
                 IsInherit = ISNULL(A.IsInherit,''),
                 LaunchDate = ISNULL(A.LaunchDate, ''),
                 LastUserSeq  = @UserSeq,
                 LastDateTime = GETDATE()
           FROM #KPX_TDAItem A  
                JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                AND B.ItemSeq = A.ItemSeq
          WHERE A.WorkingTag = 'U' AND A.Status = 0
    
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END  
          UPDATE KPX_TDAItemClass
            SET  UMajorItemClass = LEFT(A.UMItemClassS,4),
                 UMItemClass  = ISNULL(A.UMItemClassS,0),
                 LastUserSeq  = @UserSeq,
                 LastDateTime = GETDATE()
           FROM #KPX_TDAItem AS A  
                JOIN KPX_TDAItemClass AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                     AND B.ItemSeq     = A.ItemSeq
          WHERE A.WorkingTag = 'U' AND A.Status = 0
            AND B.UMajorItemClass IN (2001,2004)
  
         UPDATE #KPX_TDAItem
            SET LastUser = (SELECT ISNULL(UserName,'') FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq),
                LastDate = CONVERT(NCHAR(8),GETDATE(),112),
                ItemSeqOLD = ItemSeq
          WHERE WorkingTag = 'U' AND Status = 0 
  
         --INSERT INTO _TDAItemClass(  
         --       CompanySeq,  
         --       ItemSeq,  
         --       UMajorItemClass,  
         --       UMItemClass,  
         --       LastUserSeq,  
         --       LastDateTime)  
         --SELECT   
         --       @CompanySeq,    
         --       ISNULL(A.ItemSeq,0),
         --       LEFT(B.UMItemClass,4),
         --       ISNULL(B.UMItemClass,0),
         --       @UserSeq,  
         --       GETDATE()  
         --  FROM #KPX_TDAItem AS A 
         --       LEFT OUTER JOIN _TDAItemClass AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
         --                                                       AND A.ItemSeq    = B.ItemSeq
         --                                                       AND B.UMajorItemClass IN (2001,2004)
         -- WHERE WorkingTag = 'U' AND Status = 0   
         --   AND ISNULL(B.ItemSeq, 0) = 0
            
         -- �ּ�ó�� 20101229 ��ȿ��
         -- ���������� ���� 20110811 ���ؽ� 
         INSERT INTO KPX_TDAItemClass(  
                CompanySeq,  
                ItemSeq,  
                UMajorItemClass,  
                UMItemClass,  
                LastUserSeq,  
                LastDateTime, 
                PgmSeq)  
         SELECT   
                @CompanySeq,    
                ISNULL(A.ItemSeq,0),
                LEFT(A.UMItemClassS,4),
                ISNULL(A.UMItemClassS,0),
                @UserSeq,  
                GETDATE(), 
                @PgmSeq
           FROM #KPX_TDAItem AS A 
                LEFT OUTER JOIN KPX_TDAItemClass AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                                AND A.ItemSeq    = B.ItemSeq
                                                                AND B.UMajorItemClass IN (2001,2004)
          WHERE WorkingTag = 'U' AND Status = 0   
            AND ISNULL(B.ItemSeq, 0) = 0
          IF @@ERROR <> 0      
         BEGIN      
             RETURN      
         END      
  --         IF NOT EXISTS (SELECT 1 FROM #KPX_TDAItem A 
 --                                      JOIN _TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
 --                                                                          AND A.ItemSeq = B.ItemSeq
 --                                                                          AND A.UnitSeq = B.UnitSeq)
 --         BEGIN
 --             INSERT INTO _TDAItemUnit(
 --                 CompanySeq,
 --                 ItemSeq,
 --                 UnitSeq,
 --                 BarCode,
 --                 ConvNum,
 --                 ConvDen,
 --                 LastUserSeq,
 --                 LastDateTime)
 --             SELECT 
 --                 @CompanySeq,
 --                 ItemSeq,
 --                 UnitSeq,
 --                 '',
 --                 1,
 --                 1,
 --                 @UserSeq,  
 --                 GETDATE()
 --               FROM #KPX_TDAItem   
 --              WHERE WorkingTag = 'U' AND Status = 0 
 --     
 --             IF @@ERROR <> 0    
 --             BEGIN    
 --                 RETURN    
 --             END     
 --         END
     END  
      -- INSERT    
     IF EXISTS (SELECT 1 FROM #KPX_TDAItem WHERE WorkingTag = 'A' AND Status = 0  )  
     BEGIN  
          INSERT INTO KPX_TDAItem(  
              CompanySeq,
              ItemSeq,
              ItemName,
              TrunName,
              ItemNo,
              AssetSeq,
              SMStatus,
              ItemSName,
              ItemEngName,
              ItemEngSName,
              Spec,
              SMABC,
              UnitSeq,
              DeptSeq,
              EmpSeq,
              ModelSeq,
              SMInOutKind,
              IsInherit,
              LaunchDate,
              RegUserSeq,
              RegDateTime,
              LastUserSeq,
              LastDateTime, 
              PgmSeq )
         SELECT
              @CompanySeq,
              ISNULL(ItemSeq,0),
              ISNULL(ItemName,''),
              ISNULL(TrunName,''),
              ISNULL(ItemNo,''),
              ISNULL(AssetSeq,0),
              ISNULL(SMStatus, 0),
              ISNULL(ItemSName, ''),
              ISNULL(ItemEngName, ''),
              ISNULL(ItemEngSName, ''),
              ISNULL(Spec, 0),
              ISNULL(SMABC, 0),
              ISNULL(UnitSeq,0),
              ISNULL(DeptSeq,0),
              ISNULL(EmpSeq,0),
              ISNULL(ModelSeq,0),
              ISNULL(SMInOutKind, 0),
              ISNULL(IsInherit,''),
              ISNULL(LaunchDate, ''),
              @UserSeq,
              GETDATE(),
              @UserSeq,
              GETDATE(), 
              @PgmSeq
           FROM #KPX_TDAItem   
          WHERE WorkingTag = 'A' AND Status = 0 
   
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END 
          INSERT INTO KPX_TDAItemClass(
              CompanySeq,
              ItemSeq,
              UMajorItemClass,
              UMItemClass,
              LastUserSeq,
              LastDateTime)
         SELECT 
              @CompanySeq,  
              ISNULL(ItemSeq,0),
              LEFT(UMItemClassS,4),
              ISNULL(UMItemClassS,0),
              @UserSeq,
              GETDATE()
           FROM #KPX_TDAItem   
          WHERE WorkingTag = 'A' AND Status = 0 
          IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END     
          UPDATE #KPX_TDAItem
            SET RegUser  = (SELECT ISNULL(UserName,'') FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq),
                RegDate  = CONVERT(NCHAR(8),GETDATE(),112),
                LastUser = '',
                LastDate = '',
                ItemSeqOLD = ItemSeq              
          WHERE WorkingTag = 'A' AND Status = 0 
  
 --         IF NOT EXISTS (SELECT 1 FROM #KPX_TDAItem A 
 --                                      JOIN _TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
 --                                                                          AND A.ItemSeq = B.ItemSeq
 --                                                                          AND A.UnitSeq = B.UnitSeq)
 --         BEGIN
 --             INSERT INTO _TDAItemUnit(
 --                 CompanySeq,
 --                 ItemSeq,
 --                 UnitSeq,
 --                 BarCode,
 --                 ConvNum,
 --                 ConvDen,
 --                 LastUserSeq,
 --                 LastDateTime)
 --             SELECT 
 --                 @CompanySeq,
 --                 ItemSeq,
 --                 UnitSeq,
 --                 '',
 --                 1,
 --                 1,
 --                 @UserSeq,  
 --                 GETDATE()
 --               FROM #KPX_TDAItem   
 --              WHERE WorkingTag = 'A' AND Status = 0 
 --     
 --             IF @@ERROR <> 0    
 --             BEGIN    
 --                 RETURN    
 --             END     
 --         END
        
        -- ǰ�� Ȯ�������� ����
        CREATE TABLE #TCOMConfirmCreate ( TABLENAME NVARCHAR(20), CfmSeq INT, CfmSerl INT, CfmSubSerl INT )
        INSERT INTO #TCOMConfirmCreate
        SELECT DISTINCT 'KPX_TDAItem', ItemSeq, 0, 0
          FROM #KPX_TDAItem
         WHERE Status = 0
        
        EXEC _SCOMConfirmCreateSub @CompanySeq, '#TCOMConfirmCreate', 'TABLENAME', 'CfmSeq', 'CfmSerl', 'CfmSubSerl', @UserSeq, 1021310 -- ǰ����(KPX)
        
    END      
    
     SELECT *  
       FROM #KPX_TDAItem  
   
 RETURN  
GO
begin tran 
exec KPX_SDAItemSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <ItemSeq>1051539</ItemSeq>
    <ItemName>test1111</ItemName>
    <ItemNo>test1111</ItemNo>
    <Spec />
    <TrunName>TEST1111</TrunName>
    <AssetName>��ǰ</AssetName>
    <AssetSeq>15</AssetSeq>
    <UnitName>EA</UnitName>
    <UnitSeq>2</UnitSeq>
    <SMABC>2002001</SMABC>
    <SMStatus>2001001</SMStatus>
    <SMInOutKind>8007001</SMInOutKind>
    <DeptName />
    <DeptSeq>0</DeptSeq>
    <EmpName />
    <EmpSeq>0</EmpSeq>
    <ModelName />
    <ModelSeq>0</ModelSeq>
    <STDItemName />
    <ItemSName />
    <ItemEngName />
    <ItemEngSName />
    <ItemClassLName>test5</ItemClassLName>
    <ItemClassMName>1111</ItemClassMName>
    <ItemClassSName>TEST</ItemClassSName>
    <UMItemClassS>2001040</UMItemClassS>
    <IsInherit>0</IsInherit>
    <RegUser>����õ</RegUser>
    <RegDate>20141105</RegDate>
    <LastUser />
    <LastDate xml:space="preserve">        </LastDate>
    <ItemSeqOLD>1051539</ItemSeqOLD>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025570,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021310
select * from KPX_TDAItem_Confirm where cfmseq = 1051539
rollback 