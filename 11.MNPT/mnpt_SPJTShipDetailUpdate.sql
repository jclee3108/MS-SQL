IF OBJECT_ID('mnpt_SPJTShipDetailUpdate') IS NOT NULL 
    DROP PROC mnpt_SPJTShipDetailUpdate
GO 

-- �����System Update (����,����,����) 

-- v2017.12.04 by����õ 
CREATE PROC mnpt_SPJTShipDetailUpdate
    @CompanySeq     INT 
AS 
    
    -- ERP ������ ����,����,���� �����͸� �����System�� �ݿ��Ѵ�.
    UPDATE A
       SET A.ATA = B.InDateTime, 
           A.ATB = B.ApproachDateTime, 
           A.ATD = B.OutDateTime
      FROM OPENQUERY(mokpo21, 'SELECT * FROM DVESSEL ') AS A 
      JOIN mnpt_TPJTShipDetail                          AS B ON ( B.CompanySeq = @CompanySeq 
                                                              AND B.IFShipCode = A.VESSEL 
                                                              AND LEFT(B.ShipSerlNo,4) = A.VES_YY 
                                                              AND CONVERT(INT,RIGHT(B.ShipSerlNo,3)) = A.VES_SEQ 
                                                                ) 
     WHERE A.ATA <> B.InDateTime          -- �����Ͻ�
        OR A.ATB <> B.ApproachDateTime    -- ����Ͻ� 
        OR A.ATD <> B.OutDateTime         -- �����Ͻ� 
    

RETURN 

GO 

