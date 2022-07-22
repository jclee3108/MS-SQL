IF OBJECT_ID('hencom_SPUSubContrCalcDataCreate') IS NOT NULL 
    DROP PROC hencom_SPUSubContrCalcDataCreate
GO 

-- v2017.03.22 

-- ���ܺ��ҿ���, �ű��߰� ����
/************************************************************  
 ��  �� - ������-���޿�ݺ�����_hencom : �������ڷ����  
 �ۼ��� - 20151008  
 �ۼ��� - ������  
************************************************************/  
  
CREATE PROC dbo.hencom_SPUSubContrCalcDataCreate
 @xmlDocument    NVARCHAR(MAX) ,              
 @xmlFlags     INT  = 0,              
 @ServiceSeq     INT  = 0,              
 @WorkingTag     NVARCHAR(10)= '',                    
 @CompanySeq     INT  = 1,              
 @LanguageSeq INT  = 1,              
 @UserSeq     INT  = 0,              
 @PgmSeq         INT  = 0           
      
AS          
   
 DECLARE @docHandle      INT,  
      @WorkDate           NCHAR(8) ,  
            @DeptSeq            INT  ,  
   @IsLentPayUse    nchar(1),  
   @UMSCCalcType int,  
   @SCInfoSeq int,  
   @IsDayPay  nchar(1)  
  
  
    CREATE TABLE #hencom_TPUSubContrCalc (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPUSubContrCalc'  
    
    select @DeptSeq = max(deptseq), @WorkDate = max(workdate)  
      from #hencom_TPUSubContrCalc  
  
  
 if exists (select 1 from hencom_TPUSubContrCalc where CompanySeq = @CompanySeq  
                   and WorkDate = @WorkDate   
                and DeptSeq = @DeptSeq )  
 begin  
  UPDATE #hencom_TPUSubContrCalc   
     SET Status = 999,        
      result = '�̹� ������ �ڷᰡ �ֽ��ϴ�. ���� �� �۾��ϼ���.'       
    FROM #hencom_TPUSubContrCalc   
   where deptseq = @DeptSeq  
     and workdate = @workdate  
  
  select * from #hencom_TPUSubContrCalc  
  return  
 end  
  
  
 if ( select count(*) from hencom_TIFProdWorkReportclose  
      where companyseq = @CompanySeq  
      and workdate = @WorkDate  
      and deptseq = @DeptSeq   ) < 1   
 begin  
  UPDATE #hencom_TPUSubContrCalc   
     SET Status = 999,        
      result = '�۾��� ���� �����Ͱ� �����ϴ�. Ȯ�� �� �۾��ϼ���.'       
    FROM #hencom_TPUSubContrCalc   
   where deptseq = @DeptSeq  
     and workdate = @workdate  
  
  select * from #hencom_TPUSubContrCalc  
  return  
 end  

 if ( select count(*) from hencom_TIFProdWorkReportCloseSum  
      where companyseq = @CompanySeq  
      and workdate = @WorkDate  
      and deptseq = @DeptSeq   ) < 1   
 begin  
  UPDATE #hencom_TPUSubContrCalc   
     SET Status = 999,        
      result = '�����ڷ�����ó���� �Ϸ���� �ʾҽ��ϴ�. Ȯ�� �� �۾��ϼ���.'       
    FROM #hencom_TPUSubContrCalc   
   where deptseq = @DeptSeq  
     and workdate = @workdate  
  
  select * from #hencom_TPUSubContrCalc  
  return  
 end    
  
  
 select @IsLentPayUse = IsLentCarPrice,  
        @IsDayPay = OracleKey  
   from hencom_TDADeptAdd  
     where companyseq = @CompanySeq  
    and deptseq = @Deptseq  
  
 set @IsLentPayUse = isnull( @IsLentPayUse, '0')  
 set @IsDayPay = isnull( @IsDayPay, '0')  
 --if @IsLentPayUse = '1' and   
 --begin  
 -- UPDATE #hencom_TPUSubContrCalc   
 --    SET Status = 999,        
 --     result = '�������޺����뿩�ΰ� �������� �ʾҽ��ϴ�. ����Ұ������� ������ �� �����ϼ���.'       
 --   FROM #hencom_TPUSubContrCalc   
 --  where deptseq = @DeptSeq  
 --    and workdate = @workdate  
  
 -- select * from #hencom_TPUSubContrCalc  
 -- return  
 --end  
   
 select @UMSCCalcType = UMSCCalcType, @SCInfoSeq = SCInfoSeq  
   from hencom_VPUubContrBasDate  
     where CompanySeq = @CompanySeq  
    and deptseq = @DeptSeq  
    and @WorkDate between StartDate and EndDate   
  
 set @UMSCCalcType = isnull( @UMSCCalcType, 0)  
  
 if @UMSCCalcType = 0  
 begin  
  UPDATE #hencom_TPUSubContrCalc   
     SET Status = 999,        
      result = '�������޺���������� ��ϵ��� �ʾҽ��ϴ�. �������޺������������ ������ �� �����ϼ���.'       
    FROM #hencom_TPUSubContrCalc   
   where deptseq = @DeptSeq  
     and workdate = @workdate  
  
  select * from #hencom_TPUSubContrCalc  
  return  
 end  
  
CREATE TABLE #hencom_TPUSubContrSource  
(  
    --------------------------------     ���嵥����  
 CompanySeq      int,          
 WorkDate  nvarchar(8),         
 DeptSeq   int,                
 UMOutType  int,          
 Rotation  decimal(19,5),     
 PJTSeq   int,   
    MesKey   nvarchar(30),              
 UMCarClass  int,       
 SubContrCarSeq int,         
 OutQty   decimal(19,5),   
 ProdQty decimal(19,5),      
 InvCreDateTime  datetime,  
 GoodItemSeq     int,  
 IsOwnCar        nchar(1),  
 ------------------------------------- ����������  
 UMOTType           int,    
 OTAmt              decimal(19,5),  
 CostSeq            int,  
 SubContrCalcRegSeq int,   
 isLentSumData   nchar(1),  
 RealDistance decimal(19,5),   -- ���������� GPS���� 1 ������ realdistance �ƴϸ� �����߰������� �Ÿ�   
 UMDistanceDegree int,  
 UMSCCalcType    int,  
   MinPresLoadCapa decimal(19,5),  
 IsPreserve      nchar(1),  
 ApplyQty        decimal(19,5),  
 Price           decimal(19,5),   
 Amt             decimal(19,5)  ,
 DeliCustSeq     int 
)  
  
CREATE TABLE #hencom_TPUSubContrSourceDet  
(  
    CompanySeq    INT   ,   
    SubContrCarSeq  INT   ,   
 SubContrCalcRegSeq int,  
    MesKey     nvarchar(30)     
)  
   
  
 insert #hencom_TPUSubContrSource ( CompanySeq,          
          WorkDate,         
          DeptSeq,                
          UMOutType,         
          Rotation,     
          PJTSeq,   
          MesKey,              
          UMCarClass,       
          SubContrCarSeq,         
          OutQty,       
		  ProdQty,  
          UMSCCalcType,  
          isLentSumData,  
          InvCreDateTime,  
          GoodItemSeq,  
          IsOwnCar,
		  DeliCustSeq )  
   select m.CompanySeq,          
    isnull(m.WorkDate,''),         
    isnull(m.DeptSeq,0),                
    isnull(m.UMOutType,0),         
    isnull(m.Rotation,0),     
    isnull(m.PJTSeq,0),   
    isnull(m.MesKey,''),              
    isnull(car.UMCarClass,0),       
    isnull(m.SubContrCarSeq,0),         
    isnull(m.OutQty,0),         
    isnull(m.ProdQty,0),         
    isnull(@UMSCCalcType,0),  
    '0',  
    m.InvCreDateTime,  
    m.GoodItemSeq,  
    isnull(( select ValueText  from _tdauminorvalue  where MinorSeq = car.UMCarClass and serl = 1000001 ),'0') ,
	car.CustSeq as DeliCustSeq
     from hencom_TIFProdWorkReportclose as m  
left outer join V_mstm_UMOutType as a on a.CompanySeq = m.CompanySeq  
                                     and a.MinorSeq = m.UMOutType  
left outer join  hencom_VPUContrCarInfo as car on car.CompanySeq = m.CompanySeq
                                            and car.SubContrCarSeq = m.SubContrCarSeq
											and m.workdate between car.StartDate and car.EndDate
    where m.companyseq = @CompanySeq  
   and m.workdate = @WorkDate  
   and m.deptseq = @DeptSeq    
   and isNull(m.Rotation, 1) <> 0 -- 2017.01.23 ���� �߰����� / ȸ������ 0�϶��� ���޿� �ݿ����� ����.
  
   --  select meskey ,ISDATE( left(workdate,4) + '-' + substring(WorkDate,5,2) + '-' + right(workdate,2) + ' ' + left(InvPrnTime,2) + ':' + substring(InvPrnTime,3,2) + ':' + right(InvPrnTime,2))
   --from hencom_TIFProdWorkReportclose
   --where ISDATE( left(workdate,4) + '-' + substring(WorkDate,5,2) + '-' + right(workdate,2) + ' ' + left(InvPrnTime,2) + ':' + substring(InvPrnTime,3,2) + ':' + right(InvPrnTime,2)) = 0
  
  --select *  from _tdauminorvalue  where MinorSeq = 8030002  
 --   drop table hencom_TIFProdWorkReportclose20151019  
 --   select *  
 --into  hencom_TIFProdWorkReportclose20151019  
 --from hencom_TIFProdWorkReportclose where workdate = '20151013'  
  
 --select * from hencom_TIFProdWorkReportclose  
 --insert hencom_TIFProdWorkReportclose  
 --select *,1,getdate() from hencom_TIFProdWorkReportclose20151019  
  
 if @IsLentPayUse = '1'  
  begin  
   delete from #hencom_TPUSubContrSource  
         where IsOwnCar = '0'  
  
   insert #hencom_TPUSubContrSource ( CompanySeq,          
            WorkDate,         
            DeptSeq,                
            UMOutType,         
            Rotation,      
            PJTSeq,   
            MesKey,               
            UMCarClass,       
            SubContrCarSeq,                     
			OutQty,         
			ProdQty,         
            isLentSumData,  
  
            RealDistance,   
            MinPresLoadCapa,  
            IsPreserve,  
            applyqty,
			DeliCustSeq )  
    select max(m.CompanySeq),          
     max(isnull(m.WorkDate,'')),         
     max(isnull(m.DeptSeq,0)),                
     max(isnull(m.UMOutType,0)),         
     sum(isnull(m.Rotation,0) ),     
     max(isnull(m.PJTSeq,0)),   
     max(isnull(m.MesKey,'')),              
     max(isnull(car.UMCarClass,0)),       
     isnull(m.SubContrCarSeq,0),         
     sum( isnull( m.OutQty ,0) ),         
     sum( isnull( m.ProdQty ,0) ),         
     '1',  
     sum(case car.IsGpsApply when '1' then m.RealDistance else pjt.ShuttleDistance end),  
     max(car.MinPresLoadCapa),  
     max(car.IsPreserve),  
     sum(case car.IsPreserve when '1' then car.MinPresLoadCapa else isnull(m.OutQty ,0) end),
	 max(car.CustSeq) as DeliCustSeq
     from hencom_TIFProdWorkReportclose as m  
left outer join  hencom_VPUContrCarInfo as car on car.CompanySeq = m.CompanySeq
                                            and car.SubContrCarSeq = m.SubContrCarSeq
											and m.workdate between car.StartDate and car.EndDate
  left outer join  hencom_TPJTProjectAdd as pjt on pjt.CompanySeq = @CompanySeq  
                                                and pjt.PJTSeq = m.PJTSeq  
  left outer join  V_mstm_UMOutType as a on a.CompanySeq = m.CompanySeq  
                                        and a.MinorSeq = m.UMOutType  
    where m.companyseq = @CompanySeq  
        and m.workdate = @WorkDate  
      and m.deptseq = @DeptSeq    
      and isnull(( select ValueText  from _tdauminorvalue  where MinorSeq = car.UMCarClass and serl = 1000001 ),'0') = '0'  
	  and isNull(m.Rotation, 1) <> 0
    group by isnull(m.SubContrCarSeq,0)  
  
  
  
    -- ���ҵ� ����, �ű��߰��� ������ �ʵ��� �Ѵ�.
    SELECT DISTINCT LEFT(A.MesKey,19) AS MesKey
      INTO #PartiontMeskey
      FROM hencom_TIFProdWorkReportClose AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEN(A.MesKey) > 19 



   insert #hencom_TPUSubContrSourceDet ( CompanySeq, SubContrCarSeq, MesKey )  
   select m.CompanySeq, m.SubContrCarSeq, m.MesKey  
     from hencom_TIFProdWorkReportclose as m  
left outer join  hencom_VPUContrCarInfo as car on car.CompanySeq = m.CompanySeq
                                            and car.SubContrCarSeq = m.SubContrCarSeq
											and m.workdate between car.StartDate and car.EndDate

    where m.companyseq = @CompanySeq  
      and m.workdate = @WorkDate  
      and m.deptseq = @DeptSeq    
      and isnull(( select ValueText  from _tdauminorvalue  where MinorSeq = car.UMCarClass and serl = 1000001 ),'0') = '0'
	  and isNull(m.Rotation, 1) <> 0  
      and not exists (select 1 from #PartiontMeskey where MesKey = m.MesKey) -- �߰� 2017.03.13
  
  
  
  end  


  
  --      --- �������� ������Ʈ  
  --update m  
  --   set m.UMCarClass = c.UMCarClass  
  --  from #hencom_TPUSubContrSource as m  
  --  join hencom_TPUSubContrCar as c on c.CompanySeq = @CompanySeq  
  --                                 and c.SubContrCarSeq = m.SubContrCarSeq  
  
  update m  
  set m.IsPreserve = car.IsPreserve
  from #hencom_TPUSubContrSource as m  
left outer join  hencom_VPUContrCarInfo as car on car.CompanySeq = m.CompanySeq
                                            and car.SubContrCarSeq = m.SubContrCarSeq
											and m.workdate between car.StartDate and car.EndDate
  
  update m  
  set m.IsPreserve = '0'
  from #hencom_TPUSubContrSource as m 
  join _TDAUMinorValue as mi on mi.CompanySeq = @CompanySeq
                            and mi.MinorSeq = m.umouttype
							and mi.serl = 2013
							and mi.ValueText = '1'
  
   
  --- ���� �ǰŸ�(gps���� ������ �Ÿ� �ƴϸ� �����߰������� ����Ÿ�), �ҷ���������, �ҷ��������ؿ뷮, ������� ������Ʈ  
  update m  
     set m.RealDistance = case car.IsGpsApply when '1' then work.RealDistance else pjt.ShuttleDistance end,  
         m.MinPresLoadCapa = car.MinPresLoadCapa,  
      m.applyqty = case m.IsPreserve when '1' then car.MinPresLoadCapa else m.outqty end  
    from #hencom_TPUSubContrSource as m  
left outer join  hencom_VPUContrCarInfo  as car on car.CompanySeq = m.CompanySeq
                                            and car.SubContrCarSeq = m.SubContrCarSeq
											and m.workdate between car.StartDate and car.EndDate
   left outer join  hencom_TPJTProjectAdd as pjt on pjt.CompanySeq = @CompanySeq  
                                                and pjt.PJTSeq = m.PJTSeq  
   left outer join hencom_TIFProdWorkReportclose as work on work.CompanySeq = @CompanySeq  
                                                        and work.MesKey = m.MesKey  
         where m.isLentSumData = '0'  
    


  ------------------------------------------- �������� ������Ʈ  
  update m  
  set m.UMDistanceDegree = (select max(UMDistanceDegree) from hencom_TPUSubContrBasicSectionInfo  
              where CompanySeq = @CompanySeq  
       and SCInfoSeq = @SCInfoSeq  
       and distance = maxd.maxdistance )  
    from #hencom_TPUSubContrSource as m  
  left outer join (  
          select m.MesKey,  
           m.RealDistance,  
           ( select min(distance)   
            from hencom_TPUSubContrBasicSectionInfo   
              where CompanySeq = @CompanySeq  
             and SCInfoSeq = @SCInfoSeq  
             and distance >= m.RealDistance ) as maxdistance             from #hencom_TPUSubContrSource as m   
      ) as maxd on maxd.MesKey = m.MesKey  
  
        where m.isLentSumData = '0'  
  
  
  --------------------------------------- ������ ��� ���ذŸ��� �ǰ��� �ϴ� ���ϴ� ������Ʈ  
   update #hencom_TPUSubContrSource  
      set UMSCCalcType =  case @IsDayPay when '1' then    case when m.Rotation >= dept.MinRotation then 1011612004 else 1011612005 end  -- �ϴ�/���ϴ�  
                                               else    1011612006               end  -- ��ȸ����  
   from #hencom_TPUSubContrSource as m  
   left outer join hencom_TDADeptAdd as dept on dept.companyseq = @CompanySeq  
                                               and dept.DeptSeq = m.DeptSeq  
        where m.isLentSumData = '1'   
    

    -- ����(���Ϸ�) ��� ���Ϸ����� ������Ʈ 
    SELECT UMSCCalcType, Price
      INTO #UMSCCalcType
      FROM hencom_VPUSubContrBasicInfoLentDate AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.UMCarClass = 8030009 
       AND @WorkDate BETWEEN A.StartDate AND A.EndDate
    
    update a
       set UMSCCalcType = b.UMSCCalcType
      from #hencom_TPUSubContrSource    as a 
      join #UMSCCalcType                as b on ( 1 = 1 ) 
     where a.UMCarClass = 8030009 
    


  ------------------------------- ���� �ܰ� �� �ݾ�����  
            update m  
      set m.price = i.price  
     from #hencom_TPUSubContrSource as m  
   left outer join _TDAUMinorValue as v on v.CompanySeq = @CompanySeq  
                                       and v.minorseq = m.UMOutType  
            and v.serl = 2009  
   left outer join hencom_TPUSubContrBasicSectionInfo as i on i.CompanySeq = @CompanySeq  
                                                          and i.SCInfoSeq = @SCInfoSeq  
                and i.UMDistanceDegree = m.UMDistanceDegree  
                and i.UMOutType = v.valueseq  
             where m.isLentSumData = '0'  

---------------------------------------------------------------  
--select m.InvCreDateTime,   
  --     isnull(( select UMOTType   from hencom_TPUCarOT   
--                                where CompanySeq = @CompanySeq   
--                      and UMCarClass = m.umcarclass   
--                   and deptseq = m.deptseq  
--                   and right('0' + convert(nvarchar(100), datepart(hour,m.InvCreDateTime)),2) + right('0' + convert(nvarchar(100), datepart(mi,m.InvCreDateTime)),2)   between OutTimeFr and outtimeto  
--                 ),0),  
         
--       isnull(( select CurAmt    from hencom_TPUCarOT   
--                                where CompanySeq = @CompanySeq   
--                      and UMCarClass = m.umcarclass   
--                   and deptseq = m.deptseq   
--                   and right('0' + convert(nvarchar(100), datepart(hour,m.InvCreDateTime)),2) + right('0' + convert(nvarchar(100), datepart(mi,m.InvCreDateTime)),2)   between OutTimeFr and outtimeto  
--                 ),0)  
--     from #hencom_TPUSubContrSource as m  
--    where m.isLentSumData = '0'  
  
--return  
        
  ------------------------���� �ݾװ�� - ���޺�������ؿ� ���� �ܰ� * ȸ���� or ������� or �Ÿ� �� �����  


  if @UMSCCalcType = 1011612001 -- ���޺�������� ȸ����  
  begin  
      update m  
      set amt = m.price * Rotation ,  
     umottype = isnull(( select UMOTType    from hencom_VPUCarOTDate   
                                where CompanySeq = @CompanySeq   
								   and @WorkDate between startdate and enddate
                      and UMCarClass = m.umcarclass   
                   and deptseq = m.deptseq  
                   and right('0' + convert(nvarchar(100), datepart(hour,m.InvCreDateTime)),2) + right('0' + convert(nvarchar(100), datepart(mi,m.InvCreDateTime)),2)   between OutTimeFr and outtimeto  
                 ),0),  
               
       OTAmt  = isnull(( select CurAmt    from hencom_VPUCarOTDate   
                        where CompanySeq = @CompanySeq   
								   and @WorkDate between startdate and enddate
                      and UMCarClass = m.umcarclass   
                   and deptseq = m.deptseq   
                   and right('0' + convert(nvarchar(100), datepart(hour,m.InvCreDateTime)),2) + right('0' + convert(nvarchar(100), datepart(mi,m.InvCreDateTime)),2)   between OutTimeFr and outtimeto  
                 ),0)  
         
     from #hencom_TPUSubContrSource as m  
    where m.isLentSumData = '0'  
   
  end  
  else if @UMSCCalcType = 1011612002 --- ��ݷ�    
  begin  
      update m  
      set amt = m.price * ApplyQty * m.Rotation,   
     umottype = case m.Rotation when 0 then 0 else  
       
isnull(( select UMOTType  from hencom_VPUCarOTDate   
                                 where CompanySeq = @CompanySeq   
                        and UMCarClass = m.umcarclass   
                                   and deptseq = m.deptseq  
								   and @WorkDate between startdate and enddate
                   and right('0' + convert(nvarchar(100), datepart(hour,m.InvCreDateTime)),2) + right('0' + convert(nvarchar(100), datepart(mi,m.InvCreDateTime)),2)   between OutTimeFr and outtimeto  
                 ),0)  
                 end,  
                  
       OTAmt  = case m.Rotation when 0 then 0 else    
        isnull(( select CurAmt    from hencom_VPUCarOTDate   
												where CompanySeq = @CompanySeq   
									 and UMCarClass = m.umcarclass   
								   and  deptseq = m.deptseq  
								   and @WorkDate between startdate and enddate
                   and right('0' + convert(nvarchar(100), datepart(hour,m.InvCreDateTime)),2) + right('0' + convert(nvarchar(100), datepart(mi,m.InvCreDateTime)),2)   between OutTimeFr and outtimeto  
                 ),0)  
                                end      
     from #hencom_TPUSubContrSource as m  
    where m.isLentSumData = '0'  
  
  end  
  else    ------- �Ÿ�  
  begin  
      update m  
      set amt = m.price * RealDistance * m.Rotation,  
     umottype =   case m.Rotation when 0 then 0 else     
                  isnull(( select UMOTType  from hencom_VPUCarOTDate   
                                where CompanySeq = @CompanySeq   
								   and @WorkDate between startdate and enddate
                      and UMCarClass = m.umcarclass   
                   and deptseq = m.deptseq  
                     and right('0' + convert(nvarchar(100), datepart(hour,m.InvCreDateTime)),2) + right('0' + convert(nvarchar(100), datepart(mi,m.InvCreDateTime)),2)   between OutTimeFr and outtimeto  
                 ),0)  
                end,  
                  
       OTAmt  =   case m.Rotation when 0 then 0 else     
                  isnull(( select CurAmt    from hencom_VPUCarOTDate   
                                where CompanySeq = @CompanySeq   
								   and @WorkDate between startdate and enddate
                      and UMCarClass = m.umcarclass  
                   and deptseq = m.deptseq  
                   and right('0' + convert(nvarchar(100), datepart(hour,m.InvCreDateTime)),2) + right('0' + convert(nvarchar(100), datepart(mi,m.InvCreDateTime)),2)   between OutTimeFr and outtimeto  
                 ),0)  
                end  
                  
     from #hencom_TPUSubContrSource as m  
    where m.isLentSumData = '0'  
  end  

  --------------------------------------------- ���� �ϴ� ���ϴ� �ܰ� �� �ݾ�����  
  ----------- �������޺� ������ ��ȸ�������� �ӽ÷� ���� �׽�Ʈ ��  
  --update #hencom_TPUSubContrSource  
  --   set umsccalctype = 1011612006  
  --       where meskey = '201510120007'  
  
  
 update m  
       set m.price = bi.price, m.amt = case bi.IsCalcQty when '1' then bi.price * m.Rotation else  bi.price end  
     from #hencom_TPUSubContrSource as m  
              join hencom_VPUSubContrBasicInfoLentDate as bi on bi.CompanySeq = @CompanySeq  
                                                            and m.WorkDate between bi.StartDate and bi.EndDate  
     and bi.UMSCCalcType = M.UMSCCalcType  
               and bi.UMCarClass = m.UMCarClass  
               and bi.DeptSeq = m.DeptSeq  
               and isnull(bi.IsDetPrice,'') <>'1'  
    where  m.isLentSumData = '1'  
  
  --------------------------------------------- ���� ��ȸ���� �ܰ� �� �ݾ�����  
             update m                           
       set m.price = dt.price, m.amt = case bi.IsCalcQty when '1' then dt.price * m.Rotation else  dt.price end  
     from #hencom_TPUSubContrSource as m  
              join hencom_VPUSubContrBasicInfoLentDate as bi on bi.CompanySeq = @CompanySeq  
               and m.WorkDate between bi.StartDate and bi.EndDate  
               and bi.UMSCCalcType = M.UMSCCalcType                 and bi.UMCarClass = m.UMCarClass  
               and bi.DeptSeq = m.DeptSeq  
               and isnull(bi.IsDetPrice,'') ='1'  
              join hencom_TPUSubContrBasicInfoLentDet as dt on dt.CompanySeq = @CompanySeq  
                                                   and dt.SCBILSeq = bi.SCBILSeq  
                 and dt.Rotation =  case when (  select max(Rotation)   
                       from hencom_TPUSubContrBasicInfoLentDet  
                         where companyseq = @CompanySeq  
                        and SCBILSeq = bi.SCBILSeq) >= m.Rotation then m.Rotation  
                      else  (  select max(Rotation)   
                       from hencom_TPUSubContrBasicInfoLentDet  
                         where companyseq = @CompanySeq  
                        and SCBILSeq = bi.SCBILSeq) end       
  
     --join ( select SCBILSeq,  
     --  Rotation,  
     --  price,  
     --         from hencom_TPUSubContrBasicInfoLentDet ) as dt  
  
    where m.isLentSumData = '1'  
    

    -- ���޺����걸�� : ���Ϸ� �ϰ�� �ܰ� �� �ݾ�����(�ܰ�*�������)
    UPDATE A 
       SET Price = B.Price, 
           Amt = A.ApplyQty * B.Price
      FROM #hencom_TPUSubContrSource    AS A 
      JOIN #UMSCCalcType                AS B ON ( 1 = 1 ) 
    WHERE A.UMSCCalcType = 1011612007
      AND A.isLentSumData = '1'  
    

    ------------------------------------------------- ��ǥó���� ���� ����׸���  
          update #hencom_TPUSubContrSource  
       set costseq = case isLentSumData when 1 then 506 else 505 end  
  
          
  
  
  
  
 --------------------------------------------- Key���� �� ���� ���̺� �μ�Ʈ  
  
    DECLARE @MaxSeq INT,  
            @Count  INT   
    SELECT @Count = Count(1) FROM #hencom_TPUSubContrSource   
    IF @Count >0   
    BEGIN  
  EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'hencom_TPUSubContrCalc ','SubContrCalcRegSeq',@Count --rowcount    
  
   update m  
      set m.SubContrCalcRegSeq = k.SubContrCalcRegSeq       
     from #hencom_TPUSubContrSource as m  
     join ( select meskey,@MaxSeq + row_number() over (order by UMSCCalcType, MesKey ) as SubContrCalcRegSeq  
      from #hencom_TPUSubContrSource ) as K on K.MesKey = m.MesKey            
  
   update m  
         set m.SubContrCalcRegSeq = s.SubContrCalcRegSeq  
   from #hencom_TPUSubContrSourceDet as m  
   join #hencom_TPUSubContrSource as s on s.SubContrCarSeq = m.SubContrCarSeq  
  
  
  
   insert hencom_TPUSubContrCalc ( CompanySeq,SubContrCalcRegSeq,WorkDate,DeptSeq,UMDistanceDegree,UMSCCalcType,UMCarClass,  
                                   SubContrCarSeq,MinPresLoadCapa,IsPreserve,OutQty,ApplyQty,Rotation,RealDistance,UMOutType,  
                                   Price,Amt,CostSeq,MesKey,Remark,LastUserSeq,LastDateTime,  IsLentSumData, InvCreDateTime, 
								   PJTSeq, GoodItemSeq, UMOTType, OTAmt, AddPayAmt, DeductionAmt, DeliCustSeq,ProdQty )  
   select CompanySeq,SubContrCalcRegSeq,WorkDate,DeptSeq,UMDistanceDegree,UMSCCalcType,UMCarClass,  
                      SubContrCarSeq,MinPresLoadCapa,IsPreserve,OutQty,ApplyQty,Rotation,RealDistance,UMOutType,  
          isnull(Price,0),isnull(Amt,0),CostSeq,MesKey,'',@UserSeq ,getdate(), IsLentSumData, InvCreDateTime, 
		                            PJTSeq,GoodItemSeq, UMOTType, isnull(OTAmt,0) ,0,0, DeliCustSeq,ProdQty
              from #hencom_TPUSubContrSource  
  
     insert hencom_TPUSubContrCalcLentDet ( CompanySeq,SubContrCalcRegSeq,MesKey )  
     select CompanySeq,SubContrCalcRegSeq,MesKey from #hencom_TPUSubContrSourceDet  
  
    END     
  
 select * from #hencom_TPUSubContrCalc   
       
   
  
RETURN

go
begin tran 
exec hencom_SPUSubContrCalcDataCreate @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <DeptSeq>43</DeptSeq>
    <DetpNm>���</DetpNm>
    <WorkDate>20170208</WorkDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032463,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026877
rollback 