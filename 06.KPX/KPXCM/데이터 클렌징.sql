begin tran

--�۾���û�������(�Ϲ�), �۾��Ϸ�Ȯ��ó��(�Ϲ�)
DELETE FROM _TEQWorkOrderReqMasterCHE
DELETE FROM _TEQWorkOrderReqMasterCHELog
DELETE FROM _TEQWorkOrderReqItemCHE
DELETE FROM _TEQWorkOrderReqItemCHELog


--�۾��������(�Ϲ�)
DELETE FROM _TEQWorkOrderReceiptMasterCHE
DELETE FROM _TEQWorkOrderReceiptMasterCHELog
DELETE FROM _TEQWorkOrderReceiptItemCHE
DELETE FROM _TEQWorkOrderReceiptItemCHELog

--�۾��������(�Ϲ�)


DELETE FROM _TEQWorkOrderReceiptMasterCHE
DELETE FROM _TEQWorkOrderReceiptMasterCHELog
DELETE FROM _TEQWorkOrderReceiptItemCHE
DELETE FROM _TEQWorkOrderReceiptItemCHELog



--���������Ⱓ���
DELETE FROM KPXCM_TEQYearRepairPeriodCHE
DELETE FROM KPXCM_TEQYearRepairPeriodCHELog



--����������û���
DELETE FROM KPXCM_TEQYearRepairReqRegCHE
DELETE FROM KPXCM_TEQYearRepairReqRegCHELog
DELETE FROM KPXCM_TEQYearRepairReqRegItemCHE
DELETE FROM KPXCM_TEQYearRepairReqRegItemCHELog


--���������������
DELETE FROM KPXCM_TEQYearRepairReceiptRegCHE
DELETE FROM KPXCM_TEQYearRepairReceiptRegCHELog
DELETE FROM KPXCM_TEQYearRepairReceiptRegItemCHE
DELETE FROM KPXCM_TEQYearRepairReceiptRegItemCHELog


--���������������
DELETE FROM KPXCM_TEQYearRepairResultRegCHE
DELETE FROM KPXCM_TEQYearRepairResultRegCHELog
DELETE FROM KPXCM_TEQYearRepairResultRegItemCHE
DELETE FROM KPXCM_TEQYearRepairResultRegItemCHELog


--���˳������
DELETE FROM KPX_TEQCheckReport
DELETE FROM KPX_TEQCheckReportLog

--����˱����������
DELETE FROM _TEQExamCorrectEditCHE
DELETE FROM _TEQExamCorrectEditCHELog

--����˻��ȹ�������
DELETE FROM KPXCM_TEQRegInspectChg
DELETE FROM KPXCM_TEQRegInspectChgLog

--����˻系�����
DELETE FROM KPXCM_TEQRegInspectRst
DELETE FROM KPXCM_TEQRegInspectRstLog


--������������û��� �� Ȯ�� �ʿ�
DELETE FROM KPX_TLGInOutReqAdd
DELETE FROM KPX_TLGInOutReqAddLog
--_TLGInOutReq
--_TLGInOutReqLog
--_TLGInOutReqItem
--_TLGInOutReqItemLog

--�������������	�� Ȯ�� �ʿ�
DELETE FROM KPX_TLGInOutDailyAdd
DELETE FROM KPX_TLGInOutDailyAddLog
--_TLGInOutDaily
--_TLGInOutDailyLog


--������
DELETE FROM KPXCM_TEQChangeRequestCHE
DELETE FROM KPXCM_TEQChangeRequestCHELog
DELETE FROM KPXCM_TEQChangeRequestCHE_Confirm
DELETE FROM KPXCM_TEQChangeRequestCHE_ConfirmLog

--�����������
DELETE FROM KPXCM_TEQChangeRequestRecv
DELETE FROM KPXCM_TEQChangeRequestRecvLog
DELETE FROM KPXCM_TEQChangeRequestRecv_Confirm
DELETE FROM KPXCM_TEQChangeRequestRecv_ConfirmLog

--������������
DELETE FROM KPXCM_TEQTaskOrderCHE
DELETE FROM KPXCM_TEQTaskOrderCHELog
DELETE FROM KPXCM_TEQTaskOrderCHE_Confirm
DELETE FROM KPXCM_TEQTaskOrderCHE_ConfirmLog


--������������
DELETE FROM KPXCM_TEQChangeFinalReport
DELETE FROM KPXCM_TEQChangeFinalReportLog


--Utility�Ϻ���뷮���
DELETE FROM KPXCM_TPDProcBusiUtilityReg
DELETE FROM KPXCM_TPDProcBusiUtilityRegLog

--Utility����������
DELETE FROM KPXCM_TPDUtilityMonAcc
DELETE FROM KPXCM_TPDUtilityMonAccLog

rollback tran