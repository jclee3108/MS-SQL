
drop proc tooldata_jclee1
go 
create proc tooldata_jclee1
as 


-- �۾���û�������(�Ϲ�) 
delete from _TEQWorkOrderReqMasterCHE 
delete from _TEQWorkOrderReqItemCHE
delete from KPXCM_TEQWorkOrderReqMasterCHEIsStop 

delete from _TCOMCreateSeqMax where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxESM where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxHR where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxLG where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxPD where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxPE where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxPU where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxSI where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxSL where TableName = '_TEQWorkOrderReqMasterCHE' 

-- �۾��������(�Ϲ�), �۾��������(�Ϲ�), �۾��Ϸ�Ȯ��ó��(�Ϲ�)
delete from _TEQWorkOrderReceiptMasterCHE
delete from KPXCM_TEQWorkOrderReceiptMasterCHEAdd
delete from _TEQWorkOrderReceiptItemCHE

delete from _TCOMCreateSeqMax where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxESM where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxHR where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxLG where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxPD where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxPE where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxPU where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxSI where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxSL where TableName = '_TEQWorkOrderReceiptMasterCHE' 

-- �����Ⱓ���
delete from KPXCM_TEQYearRepairPeriodCHE 

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 


-- ����������û��� 

delete from KPXCM_TEQYearRepairReqRegCHE
delete from KPXCM_TEQYearRepairReqRegItemCHE

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 

-- ���������������
              
delete from KPXCM_TEQYearRepairReceiptRegCHE
delete from KPXCM_TEQYearRepairReceiptRegItemCHE

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 

-- ��������������� 

delete from KPXCM_TEQYearRepairResultRegCHE
delete from KPXCM_TEQYearRepairResultRegItemCHE

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 

-- ���˼����� 

delete from KPX_TEQCheckItem 

delete from _TCOMCreateSeqMax where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPX_TEQCheckItem' 

-- ���˳������

delete from KPX_TEQCheckReport

delete from _TCOMCreateSeqMax where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPX_TEQCheckReport' 

-- ����˱���������Ϲ���ȸLS 

delete from _TEQExamCorrectEditCHE 

delete from _TCOMCreateSeqMax where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxESM where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxHR where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxLG where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxPD where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxPE where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxPU where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxSI where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxSL where TableName = '_TEQExamCorrectEditCHE' 

-- ����˻缳���� 

delete from KPXCM_TEQRegInspect 

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TEQRegInspect' 

-- ����˻系����Ϲ���ȸ 

delete from KPXCM_TEQRegInspectRst 

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TEQRegInspectRst' 


-- ������������û���

delete from KPX_TLGInOutReqAdd 

delete from _TCOMCreateSeqMax where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPX_TLGInOutReqAdd' 


-- ���߻�������, ���������

delete from KPXCM_TSEAccidentCHE 
delete from KPXCM_TSEAccidentCHE_Confirm 

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TSEAccidentCHE' 

-- ���������� 
delete from KPXCM_TSEDesasterCHE

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TSEDesasterCHE' 

-- ��ȣ���ϰ�����, ��ȣ����������  

delete from _TSEBracerCHE 

delete from _TCOMCreateSeqMax where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxESM where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxHR where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxLG where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxPD where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxPE where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxPU where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxSI where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxSL where TableName = '_TSEBracerCHE' 



return 
go 
begin tran 
exec tooldata_jclee1
rollback 