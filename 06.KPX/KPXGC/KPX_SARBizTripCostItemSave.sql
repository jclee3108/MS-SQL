  
IF OBJECT_ID('KPX_SARBizTripCostItemSave') IS NOT NULL   
    DROP PROC KPX_SARBizTripCostItemSave  
GO  
  
-- v2015.01.08  
  
-- ���������ǰ�Ǽ�-SS1���� by ����õ   
CREATE PROC KPX_SARBizTripCostItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TARBizTripCostCardCfm (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TARBizTripCostCardCfm'   
    IF @@ERROR <> 0 RETURN    
    
    -- �α� �����    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master �α�   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TARBizTripCostCardCfm')    
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TARBizTripCostCardCfm WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        IF @WorkingTag = 'Del'
        BEGIN
        
            EXEC _SCOMLog @CompanySeq   ,        
                          @UserSeq      ,        
                          'KPX_TARBizTripCostCardCfm'    , -- ���̺��        
                          '#KPX_TARBizTripCostCardCfm'    , -- �ӽ� ���̺��        
                          'BizTripSeq'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                          @TableColumns , '', @PgmSeq  -- ���̺� ��� �ʵ�� 
                
            DELETE B   
              FROM #KPX_TARBizTripCostCardCfm AS A   
              JOIN KPX_TARBizTripCostCardCfm AS B ON ( B.CompanySeq = @CompanySeq AND A.BizTripSeq = B.BizTripSeq )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        
        END 
        ELSE 
        BEGIN 
            
            EXEC _SCOMLog @CompanySeq   ,        
                          @UserSeq      ,        
                          'KPX_TARBizTripCostCardCfm'    , -- ���̺��        
                          '#KPX_TARBizTripCostCardCfm'    , -- �ӽ� ���̺��        
                          'BizTripSeq,CARD_CD,APPR_DATE,APPR_SEQ,APPR_No,CANCEL_YN'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                          @TableColumns , 'BizTripSeq,CardNo,ApprDate,ApprSeq,ApprNo,CANCEL_YN', @PgmSeq  -- ���̺� ��� �ʵ��  
        
            DELETE B   
              FROM #KPX_TARBizTripCostCardCfm AS A   
              JOIN KPX_TARBizTripCostCardCfm AS B ON ( B.CompanySeq = @CompanySeq 
                                                   AND B.BizTripSeq = A.BizTripSeq 
                                                   AND B.CARD_CD = A.CardNo
                                                   AND B.APPR_DATE = A.ApprDate 
                                                   AND B.APPR_SEQ = A.ApprSeq
                                                   AND B.APPR_No = A.ApprNo
                                                     )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        
        END 

          
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TARBizTripCostCardCfm WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        
        SELECT @TableColumns = dbo._FGetColumnsForLog('_TSIAFebCardCfm')    
        
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      '_TSIAFebCardCfm'    , -- ���̺��        
                      '#KPX_TARBizTripCostCardCfm'    , -- �ӽ� ���̺��        
                      'CARD_CD,APPR_DATE,APPR_SEQ,APPR_NO,CANCEL_YN'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , 'CardNo,ApprDate,ApprSeq,ApprNo,CANCEL_YN', @PgmSeq  -- ���̺� ��� �ʵ��  
        
        UPDATE B   
           SET SupplyAmt  = A.SupplyAmt ,    -- ���ް���
               AccSeq     = A.AccSeq,    -- �����ڵ�
               Remark     = A.Remark,    -- ���1
               EmpSeq     = A.EmpSeq,    -- ���
               CustSeq    = A.CustSeq,    -- �ŷ�ó�ڵ�
               CCtrSeq    = A.CCtrSeq,    -- �ڽ�Ʈ����
               DeptSeq    = A.DeptSeq,    -- �μ�
               IsDefine   = A.IsDefine,
               ModDate    = A.ModDate,
               EvidSeq    = A.EvidSeq,
               VatSel     = A.VatSel,
               UMCardKind = A.UMCardKind,
               OppAccSeq  = A.CrAccSeq,    -- ������
               VatAccSeq  = CASE WHEN ISNULL(A.VatSel,'') = '' THEN 0 ELSE A.AddTaxAccSeq END,    -- �ΰ�������
               CardSeq    = A.CardSeq,
               TaxUnit      = A.TaxUnit, 
               TIP_AMT      = A.TIP_AMT, 
               UMCostType   = A.UMCostType, 
               LastUserSeq  = @UserSeq,
               LastDateTime = GETDATE(),
               CostAmtDr    = ISNULL(A.CostAmtDr,0),
               NotVatAmt    = ISNULL(A.NotVatAmt,0),
               NotVatSel    = ISNULL(A.NotVatSel,''),
               RemSeq       = ISNULL(A.RemSeq,0), 
               RemValueSeq  = ISNULL(A.RemValueSeq,0),
               DisSupplyAmt = ISNULL(A.DisSupplyAmt,0),
               IsNonVat     = ISNULL(A.IsNonVat, 0),
               PJTSeq       = ISNULL(A.PJTSeq, 0),
        
               Dummy1  = A.Dummy1 ,
               Dummy2  = A.Dummy2 ,
               Dummy3  = A.Dummy3 ,
               Dummy4  = A.Dummy4 ,
               Dummy5  = A.Dummy5 ,
               Dummy6  = A.Dummy6 ,
               Dummy7  = A.Dummy7 ,
               Dummy8  = A.Dummy8 ,
               Dummy9  = A.Dummy9 ,
               Dummy10 = A.Dummy10
        
          FROM #KPX_TARBizTripCostCardCfm AS A   
          JOIN _TSIAFebCardCfm AS B ON ( B.CompanySeq = @CompanySeq 
                                      AND B.CARD_CD = A.CardNo
                                      AND B.APPR_DATE = A.ApprDate 
                                      AND B.APPR_SEQ = A.ApprSeq
                                      AND B.APPR_No = A.ApprNo 
                                      AND B.CANCEL_YN = A.CANCEL_YN
                                        )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TARBizTripCostCardCfm WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TARBizTripCostCardCfm  
        (   
            CompanySeq, BizTripSeq, CARD_CD, APPR_DATE, APPR_SEQ, 
            APPR_No, CANCEL_YN, LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.BizTripSeq, A.CardNo, A.ApprDate, A.ApprSeq, 
               A.ApprNo, A.CANCEL_YN, @UserSeq, GETDATE() 
          FROM #KPX_TARBizTripCostCardCfm AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
        SELECT @TableColumns = dbo._FGetColumnsForLog('_TSIAFebCardCfm')    
        
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      '_TSIAFebCardCfm'    , -- ���̺��        
                      '#KPX_TARBizTripCostCardCfm'    , -- �ӽ� ���̺��        
                      'CARD_CD,APPR_DATE,APPR_SEQ,APPR_NO,CANCEL_YN'   , -- CompanySeq�� ������ Ű( Ű�� �������� ���� , �� ���� )        
                      @TableColumns , 'CardNo,ApprDate,ApprSeq,ApprNo,CANCEL_YN', @PgmSeq  -- ���̺� ��� �ʵ��  
        
        UPDATE B   
           SET SupplyAmt  = A.SupplyAmt ,    -- ���ް���
               AccSeq     = A.AccSeq,    -- �����ڵ�
               Remark     = A.Remark,    -- ���1
               EmpSeq     = A.EmpSeq,    -- ���
               CustSeq    = A.CustSeq,    -- �ŷ�ó�ڵ�
               CCtrSeq    = A.CCtrSeq,    -- �ڽ�Ʈ����
               DeptSeq    = A.DeptSeq,    -- �μ�
               IsDefine   = A.IsDefine,
               ModDate    = A.ModDate,
               EvidSeq    = A.EvidSeq,
               VatSel     = A.VatSel,
               UMCardKind = A.UMCardKind,
               OppAccSeq  = A.CrAccSeq,    -- ������
               VatAccSeq  = CASE WHEN ISNULL(A.VatSel,'') = '' THEN 0 ELSE A.AddTaxAccSeq END,    -- �ΰ�������
               CardSeq    = A.CardSeq,
               TaxUnit      = A.TaxUnit, 
               TIP_AMT      = A.TIP_AMT, 
               UMCostType   = A.UMCostType, 
               LastUserSeq  = @UserSeq,
               LastDateTime = GETDATE(),
               CostAmtDr    = ISNULL(A.CostAmtDr,0),
               NotVatAmt    = ISNULL(A.NotVatAmt,0),
               NotVatSel    = ISNULL(A.NotVatSel,''),
               RemSeq       = ISNULL(A.RemSeq,0), 
               RemValueSeq  = ISNULL(A.RemValueSeq,0),
               DisSupplyAmt = ISNULL(A.DisSupplyAmt,0),
               IsNonVat     = ISNULL(A.IsNonVat, 0),
               PJTSeq       = ISNULL(A.PJTSeq, 0),
        
               Dummy1  = A.Dummy1 ,
               Dummy2  = A.Dummy2 ,
               Dummy3  = A.Dummy3 ,
               Dummy4  = A.Dummy4 ,
               Dummy5  = A.Dummy5 ,
               Dummy6  = A.Dummy6 ,
               Dummy7  = A.Dummy7 ,
               Dummy8  = A.Dummy8 ,
               Dummy9  = A.Dummy9 ,
               Dummy10 = A.Dummy10
        
          FROM #KPX_TARBizTripCostCardCfm AS A   
          JOIN _TSIAFebCardCfm AS B ON ( B.CompanySeq = @CompanySeq 
                                      AND B.CARD_CD = A.CardNo
                                      AND B.APPR_DATE = A.ApprDate 
                                      AND B.APPR_SEQ = A.ApprSeq
                                      AND B.APPR_No = A.ApprNo 
                                      AND B.CANCEL_YN = A.CANCEL_YN
                                        )   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    END     
    
    SELECT * FROM #KPX_TARBizTripCostCardCfm   
      
    RETURN  
GO 
begin tran 
exec KPX_SARBizTripCostItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AccName>�����Ļ��� ���Ĵ�</AccName>
    <AccSeq>532</AccSeq>
    <AccSeqOld>532</AccSeqOld>
    <AddTaxAccNameOld>�ΰ�����ޱ�</AddTaxAccNameOld>
    <AddTaxAccSeq>64</AddTaxAccSeq>
    <AddTaxAccSeqOld>64</AddTaxAccSeqOld>
    <APPR_BUY_SEQ>0</APPR_BUY_SEQ>
    <APPR_TIME xml:space="preserve">            </APPR_TIME>
    <ApprAmt>30000.00000</ApprAmt>
    <ApprDate>20080805</ApprDate>
    <ApprNo>75868955</ApprNo>
    <ApprSeq>3</ApprSeq>
    <ApprTax>0.00000</ApprTax>
    <APPRTOT>0.00000</APPRTOT>
    <BizUnit>2</BizUnit>
    <BizUnitName>����-����</BizUnitName>
    <CANCEL_YN>1</CANCEL_YN>
    <CancelYN>��</CancelYN>
    <CardCustName>���೪����</CardCustName>
    <CardCustSeq>6312</CardCustSeq>
    <CardName>�̿��׽�Ʈ</CardName>
    <CardNo>4336927028349406</CardNo>
    <CardSeq>59</CardSeq>
    <CCtrName />
    <CCtrSeq>0</CCtrSeq>
    <CHAIN_TYPE xml:space="preserve">  </CHAIN_TYPE>
    <ChainBizNo>4110987438</ChainBizNo>
    <ChainName>������������</ChainName>
    <ChainType>��Ȯ��       </ChainType>
    <ChannelName>�̻���-���¸���</ChannelName>
    <ChannelSeq>8004003</ChannelSeq>
    <ComOrPriv>4019001</ComOrPriv>
    <ComOrPrivName>����</ComOrPrivName>
    <CostAmtDr>31264.00000</CostAmtDr>
    <CrAccName>�����ޱ�</CrAccName>
    <CrAccSeq>223</CrAccSeq>
    <CURAMT>0.00000</CURAMT>
    <CustName>������������</CustName>
    <CustSeq>12682</CustSeq>
    <DayOfTheWeek>ȭ����</DayOfTheWeek>
    <DeptName />
    <DeptSeq>0</DeptSeq>
    <DisSupplyAmt>0.00000</DisSupplyAmt>
    <Dummy1 />
    <Dummy10 />
    <Dummy2 />
    <Dummy3 />
    <Dummy4 />
    <Dummy5 />
    <Dummy6>0.00000</Dummy6>
    <Dummy7>0.00000</Dummy7>
    <Dummy8 />
    <Dummy9 />
    <EmpName>����õ</EmpName>
    <EmpSeq>2028</EmpSeq>
    <EvidName>�ſ�ī��</EvidName>
    <EvidSeq>3</EvidSeq>
    <HALBU>0                   </HALBU>
    <IsCustSave>1</IsCustSave>
    <IsDefine>0</IsDefine>
    <IsDisVatYN>0</IsDisVatYN>
    <IsEmpSave>1</IsEmpSave>
    <IsNonVat>0</IsNonVat>
    <LastDateTime>2015-01-08T14:20:56</LastDateTime>
    <LastUserName />
    <LastUserSeq>50322</LastUserSeq>
    <MASTER />
    <MCCCODE />
    <MCCNAME />
    <MCodeHelpParams>2014||||</MCodeHelpParams>
    <MCodeHelpSeq>40031</MCodeHelpSeq>
    <MERCHADDR1 />
    <MERCHADDR2 />
    <MERCHCESSDATE xml:space="preserve">          </MERCHCESSDATE>
    <MERCHZIPCODE xml:space="preserve">      </MERCHZIPCODE>
    <ModDate>20150104</ModDate>
    <NotVatAmt>0.00000</NotVatAmt>
    <NotVatSel>0</NotVatSel>
    <PJTName xml:space="preserve"> </PJTName>
    <PJTSeq>0</PJTSeq>
    <ProcType>��ó��     </ProcType>
    <PURDATE xml:space="preserve">        </PURDATE>
    <Remark />
    <RemName>�����Ļ��񼼸�</RemName>
    <RemSeq>2014</RemSeq>
    <RemValue />
    <RemValueSeq>0</RemValueSeq>
    <Sel>0</Sel>
    <SERVTYPEYN xml:space="preserve"> </SERVTYPEYN>
    <SlipId>0</SlipId>
    <SlipSeq>0</SlipSeq>
    <STTL_DATE xml:space="preserve">        </STTL_DATE>
    <SupplyAmt>-12636.00000</SupplyAmt>
    <TAXTYPE />
    <TaxUnit>0</TaxUnit>
    <TaxUnitName />
    <TIP_AMT>0.00000</TIP_AMT>
    <TotalAmt>30000.00000</TotalAmt>
    <UMCardKind>4004002</UMCardKind>
    <UMCardKindName>��Ƽī��</UMCardKindName>
    <UMCostType>0</UMCostType>
    <UMCostTypeName />
    <UpdateVat>42636.00000</UpdateVat>
    <VatSel>1</VatSel>
    <VatSttlItem>�ΰ�����ޱ�</VatSttlItem>
    <VatYN>1</VatYN>
    <BizTripSeq>6</BizTripSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027319,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022816
rollback 