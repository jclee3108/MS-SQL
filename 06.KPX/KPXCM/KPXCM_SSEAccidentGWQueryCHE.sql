
IF OBJECT_ID('KPXCM_SSEAccidentGWQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEAccidentGWQueryCHE
GO 

-- v2015.06.24 

-- ��������� GW Query by����õ 
  CREATE PROC dbo.KPXCM_SSEAccidentGWQueryCHE
      @xmlDocument    NVARCHAR(MAX),
      @xmlFlags       INT             = 0,
      @ServiceSeq     INT             = 0,
      @WorkingTag     NVARCHAR(10)    = '',
      @CompanySeq     INT             = 1,
      @LanguageSeq    INT             = 1,
      @UserSeq        INT             = 0,
      @PgmSeq         INT             = 0
  AS
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
    
    DECLARE @docHandle      INT,
            @AccidentSeq    INT,
            @AccidentSerl   NCHAR(1)
    
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
  
    SELECT @AccidentSeq    = ISNULL(AccidentSeq, ''),
           @AccidentSerl   = ISNULL(AccidentSerl, '')
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (
            AccidentSeq    INT,
            AccidentSerl   NCHAR(1) 
           )
    
    SELECT A.AccidentSeq, 
           A.AccidentSerl, 
           A.AccidentName, -- ����Ī 
           A.AccidentNo, -- ����ȣ 
           J.EmpName AS ReporterName, -- ������� 
           A.InvestFrDate + ' ~ ' + A.InvestToDate AS InvestDate, -- �����Ͻ�
           C.EmpName AS EmpName, -- ����� 
           STUFF(STUFF(A.AccidentDate,5,0,'-'),8,0,'-') AS AccidentDate, -- ������� 
           B.DeptName, 
           A.AccidentArea, -- �������
           CASE WHEN A.AccidentClass = 20036001 THEN '�� ȭ����    �� ���߻��    �� ������    �� ���ػ��    �� �������' 
                WHEN A.AccidentClass = 20036002 THEN '�� ȭ����    �� ���߻��    �� ������    �� ���ػ��    �� �������'
                WHEN A.AccidentClass = 20036003 THEN '�� ȭ����    �� ���߻��    �� ������    �� ���ػ��    �� �������'
                WHEN A.AccidentClass = 20036004 THEN '�� ȭ����    �� ���߻��    �� ������    �� ���ػ��    �� �������'
                WHEN A.AccidentClass = 20036005 THEN '�� ȭ����    �� ���߻��    �� ������    �� ���ػ��    �� �������' 
                ELSE '�� ȭ����    �� ���߻��    �� ������    �� ���ػ��    �� �������' 
                END AS AccidentClassName, -- ���з�
           
           CASE WHEN A.AccidentType = 20037001 THEN '�� ����ȭ��    �� �ǹ�ȭ��    �� �Ϲ�ȭ��    �� ����  �� ���δ���    �� �ܺδ���' 
                WHEN A.AccidentType = 20037002 THEN '�� ����ȭ��    �� �ǹ�ȭ��    �� �Ϲ�ȭ��    �� ����  �� ���δ���    �� �ܺδ���' 
                WHEN A.AccidentType = 20037003 THEN '�� ����ȭ��    �� �ǹ�ȭ��    �� �Ϲ�ȭ��    �� ����  �� ���δ���    �� �ܺδ���' 
                WHEN A.AccidentType = 20037004 THEN '�� ����ȭ��    �� �ǹ�ȭ��    �� �Ϲ�ȭ��    �� ����  �� ���δ���    �� �ܺδ���' 
                WHEN A.AccidentType = 20037005 THEN '�� ����ȭ��    �� �ǹ�ȭ��    �� �Ϲ�ȭ��    �� ����  �� ���δ���    �� �ܺδ���' 
                WHEN A.AccidentType = 20037005 THEN '�� ����ȭ��    �� �ǹ�ȭ��    �� �Ϲ�ȭ��    �� ����  �� ���δ���    �� �ܺδ���' 
                ELSE '�� ����ȭ��    �� �ǹ�ȭ��    �� �Ϲ�ȭ��    �� ����    �� ���δ���    �� �ܺδ���' 
                END AS AccidentTypeName, -- �������  
           
           CASE WHEN A.AccidentGrade = 1011148001 THEN '�� ��������    �� ������    �� ������    �� �������    �� �������    �� �߶����' 
                WHEN A.AccidentGrade = 1011148002 THEN '�� ��������    �� ������    �� ������    �� �������    �� �������    �� �߶����' 
                WHEN A.AccidentGrade = 1011148003 THEN '�� ��������    �� ������    �� ������    �� �������    �� �������    �� �߶����' 
                WHEN A.AccidentGrade = 1011148004 THEN '�� ��������    �� ������    �� ������    �� �������    �� �������    �� �߶����' 
                WHEN A.AccidentGrade = 1011148005 THEN '�� ��������    �� ������    �� ������    �� �������    �� �������    �� �߶����' 
                WHEN A.AccidentGrade = 1011148006 THEN '�� ��������    �� ������    �� ������    �� �������    �� �������    �� �߶����' 
                ELSE '�� ��������    �� ������    �� ������    �� �������    �� �������    �� �߶����' 
                END AS AccidentGrade1, -- ���κз�1 
                
           CASE WHEN A.AccidentGrade = 1011148007 THEN '�� �������    �� �浹���    �� ���ϡ��񷡻��    �� �ر����������    �� �������    �� �߶����' 
                WHEN A.AccidentGrade = 1011148008 THEN '�� �������    �� �浹���    �� ���ϡ��񷡻��    �� �ر����������    �� �������    �� �߶����' 
                WHEN A.AccidentGrade = 1011148009 THEN '�� �������    �� �浹���    �� ���ϡ��񷡻��    �� �ر����������    �� �������    �� �߶����' 
                WHEN A.AccidentGrade = 1011148010 THEN '�� �������    �� �浹���    �� ���ϡ��񷡻��    �� �ر����������    �� �������    �� �߶����' 
                WHEN A.AccidentGrade = 1011148011 THEN '�� �������    �� �浹���    �� ���ϡ��񷡻��    �� �ر����������    �� �������    �� �߶����' 
                WHEN A.AccidentGrade = 1011148012 THEN '�� �������    �� �浹���    �� ���ϡ��񷡻��    �� �ر����������    �� �������    �� �߶����' 
                ELSE '�� �������    �� �浹���    �� ���ϡ��񷡻��    �� �ر����������    �� �������    �� �߶����' 
                END AS AccidentGrade2, -- ���κз�2 

           CASE WHEN A.AreaClass = 20039001 THEN '�� �系       �� ���' 
                WHEN A.AreaClass = 20039001 THEN '�� �系       �� ���' 
                ELSE '�� �系       �� ���'  
                END AS AreaClassName, -- ����� ����
            
           CASE WHEN A.DOW = 20040001 THEN '�� ��    �� �ϵ�    �� ��    �� ����    �� ��    �� ����    �� ��    �� �ϼ�'
                WHEN A.DOW = 20040002 THEN '�� ��    �� �ϵ�    �� ��    �� ����    �� ��    �� ����    �� ��    �� �ϼ�'
                WHEN A.DOW = 20040003 THEN '�� ��    �� �ϵ�    �� ��    �� ����    �� ��    �� ����    �� ��    �� �ϼ�'
                WHEN A.DOW = 20040004 THEN '�� ��    �� �ϵ�    �� ��    �� ����    �� ��    �� ����    �� ��    �� �ϼ�'
                WHEN A.DOW = 20040005 THEN '�� ��    �� �ϵ�    �� ��    �� ����    �� ��    �� ����    �� ��    �� �ϼ�'
                WHEN A.DOW = 20040006 THEN '�� ��    �� �ϵ�    �� ��    �� ����    �� ��    �� ����    �� ��    �� �ϼ�'
                WHEN A.DOW = 20040007 THEN '�� ��    �� �ϵ�    �� ��    �� ����    �� ��    �� ����    �� ��    �� �ϼ�'
                WHEN A.DOW = 20040008 THEN '�� ��    �� �ϵ�    �� ��    �� ����    �� ��    �� ����    �� ��    �� �ϼ�'
                ELSE '�� ��    �� �ϵ�    �� ��    �� ����    �� ��    �� ����    �� ��    �� �ϼ�'
                END AS DOWName, -- ǳ�� 
                
           CASE WHEN A.Weather = 20041001 THEN '�� ����    �� �帲    �� ��    �� ��    �� �ҳ���    �� õ�չ���    �� �Ȱ�'
                WHEN A.Weather = 20041002 THEN '�� ����    �� �帲    �� ��    �� ��    �� �ҳ���    �� õ�չ���    �� �Ȱ�'
                WHEN A.Weather = 20041003 THEN '�� ����    �� �帲    �� ��    �� ��    �� �ҳ���    �� õ�չ���    �� �Ȱ�'
                WHEN A.Weather = 20041004 THEN '�� ����    �� �帲    �� ��    �� ��    �� �ҳ���    �� õ�չ���    �� �Ȱ�'
                WHEN A.Weather = 20041005 THEN '�� ����    �� �帲    �� ��    �� ��    �� �ҳ���    �� õ�չ���    �� �Ȱ�'
                WHEN A.Weather = 20041006 THEN '�� ����    �� �帲    �� ��    �� ��    �� �ҳ���    �� õ�չ���    �� �Ȱ�'
                WHEN A.Weather = 20041007 THEN '�� ����    �� �帲    �� ��    �� ��    �� �ҳ���    �� õ�չ���    �� �Ȱ�'
                ELSE '�� ����    �� �帲    �� ��    �� ��    �� �ҳ���    �� õ�չ���    �� �Ȱ�'
                END AS WeatherName, -- ����   
                
           A.WV, -- ǳ�� 
           A.LeakMatName, -- ���⹰���� 
           A.LeakMatQty, -- ���ⷮ 
           A.AccidentEqName, -- ������ 
           A.AccidentOutline, -- ����� 
           A.AccidentCause, -- ������  
           A.MngRemark, -- ��ġ���� 
           A.AccidentInjury, -- ������� 
           A.PreventMeasure, -- �����å 
           REPLACE ( REPLACE ( REPLACE ( (SELECT RealFileName 
                                            FROM KPXERPCommon.DBO._TCAAttachFileData 
                                           WHERE AttachFileSeq = A.FileSeq 
                                          FOR XML AUTO, ELEMENTS
                                         ),'</RealFileName></KPXDEVCommon.DBO._TCAAttachFileData><KPXERPCommon.DBO._TCAAttachFileData><RealFileName>',' , '
                                       ), '<KPXERPCommon.DBO._TCAAttachFileData><RealFileName>',''
                             ), '</RealFileName></KPXERPCommon.DBO._TCAAttachFileData>', ''
                   ) AS RealFileName -- ÷���ڷ� 
      FROM KPXCM_TSEAccidentCHE     AS A 
      LEFT OUTER JOIN _TDADept      AS B ON A.CompanySeq = B.CompanySeq AND A.DeptSeq = B.DeptSeq
      LEFT OUTER JOIN _TDAEmp       AS C ON A.CompanySeq = C.CompanySeq AND A.EmpSeq = C.EmpSeq
      LEFT OUTER JOIN _TDAEmp       AS J ON A.CompanySeq = J.CompanySeq AND A.ReporterSeq = J.EmpSeq
     WHERE A.CompanySeq   = @CompanySeq
       AND (@AccidentSerl = '' or   A.AccidentSerl = @AccidentSerl )-- ('1' : ���߻�������, '2' : ���������)
       AND (@AccidentSeq   = 0  OR A.AccidentSeq   = @AccidentSeq) 
    
    RETURN

 go

exec KPXCM_SSEAccidentGWQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <AccidentSerl>2</AccidentSerl>
    <AccidentSeq>1</AccidentSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030103,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1025154
