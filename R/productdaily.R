#' 同步erp数据到数据中台
#'
#' @param erp_token
#' @param dms_token
#' @param FYEAR
#' @param FMONTH
#'
#' @return
#' @export
#'
#' @examples
#' productdaily_view()
productdaily_erpsync<- function(erp_token,dms_token,FYEAR,FMONTH) {


    sql=paste0("
select isnull(nullif(f.FSRCSPLITBILLNO,''),e.FBILLNO) as FSRCSPLITBILLNO,
g.FNUMBER as FmaterialNumber,
h.FSPECIFICATION as FSPECIFICATION,a.fbillno as FProductLots,b.FFINISHQTY as FFINISHQTY
from T_PRD_MORPT a
inner join T_PRD_MORPTENTRY b on a.FID=b.FID
inner join T_PRD_MORPTENTRY_LK c on b.FENTRYID=c.FENTRYID
inner join T_PRD_MOENTRY d on c.FSID=d.FENTRYID
inner join T_PRD_MO  e on d.FID=e.FID
inner join T_PRD_MOENTRY_Q  f on d.FENTRYID=f.FENTRYID
inner join T_BD_MATERIAL g on  b.FMATERIALID=g.FMATERIALID
inner join T_BD_MATERIAL_L h on g.FMATERIALID=h.FMATERIALID
where a.FPRDORGID='100073' and
year(a.FDATE)='",FYEAR,"' and month(a.FDATE)='",FMONTH,"'

             ")

  data=tsda::sql_select2(token = erp_token,sql = sql)

  data = as.data.frame(data)
  data = tsdo::na_standard(data)
  tsda::db_writeTable2(token = dms_token,table_name = 'rds_erp_src_t_productdaily_input',r_object = data,append = TRUE)

  sql_delete=paste0("delete a from rds_erp_src_t_productdaily_input a inner join
rds_erp_src_t_productdaily b on a.FProductLots=b.FProductLots
where a.FProductLots=b.FProductLots")
  tsda::sql_delete2(token =dms_token ,sql_str =sql_delete )

  sql_insert =paste0("insert into rds_erp_src_t_productdaily
select * from rds_erp_src_t_productdaily_input
                     ")
  tsda::sql_insert2(token =dms_token ,sql_str = sql_insert)

  sql_num=paste0("select count(1) from rds_erp_src_t_productdaily_input")
  data_num=tsda::sql_select2(token =dms_token ,sql = sql_num)
  data_num = as.numeric(data_num)
  msg = paste("同步了",data_num,"条数据")
  tsui::pop_notice(msg)
  sql_truncate =paste0("truncate table rds_erp_src_t_productdaily_input")
  res = tsda::sql_delete2(token = dms_token,sql_str = sql_truncate)

  return(res)

}

#' 获取日报
#'
#' @param token
#' @param
#'
#' @return
#' @export
#'
#' @examples
#' productdaily_get()
productdaily_get <- function(dms_token) {


  sql=paste0("select a.FSRCSPLITBILLNO as 生产订单号,a.FmaterialNumber as 物料编码,a.FSPECIFICATION  as 规格型号,a.FProductLots as 流水号,
c.[FProcessName] as 工序,a.FFINISHQTY as 汇报选单数量,b.FBoxQuantity as 每箱数量
,FLOOR(a.FFINISHQTY /b.FBoxQuantity) as 箱数,
a.FFINISHQTY%b.FBoxQuantity as 零头数,'' as 报废数 ,'' as 人工计时,'' as 人工补时,'' as 操作工,'' as 生产日期,'' as 输卡日期
from rds_erp_src_t_productdaily a
left join rds_t_productRouting b  on a.FmaterialNumber=b.FMaterialNumber
left join [rds_t_Routing] c on b.FRoutingNumber=c.FRoutingNumber
where  a.FProductLots not in (select FProductLots from [rds_t_productdaily_FProductLots_black])
and a.FProductLots not in(select FProductLots from [rds_t_productdaily])

             ")


  res=tsda::sql_select2(token = dms_token,sql = sql)
  return(res)

}


#' 查询数据
#'
#' @param token
#' @param FProductLots
#'
#' @return
#' @export
#'
#' @examples
#' productdaily_view()
productdaily_view <- function(dms_token,FProductLots) {

  if(FProductLots=="" )
  {sql=paste0("select FSRCSPLITBILLNO	as	生产订单	,
FmaterialNumber	as	物料编码	,
FSPECIFICATION	as	产品图号	,
FProductLots	as	产品批次	,
FProcessName	as	工序 	,
FFINISHQTY	as	实作产量	,
FBoxQuantity	as	每箱数量	,
FBoxQty	as	箱数	,
FBoxFractionQty	as	零头数	,
FScrappedQty	as	报废	,
FManualtime	as	人工计时	,
FManualstoppage	as	人工补时	,
FOperator	as	操作工	,
FProDate	as	生产日期	,
FInputDate	as	输卡日期
 from [rds_t_productdaily]
             ")}
  else{
    sql=paste0("select FSRCSPLITBILLNO	as	生产订单	,
FmaterialNumber	as	物料编码	,
FSPECIFICATION	as	产品图号	,
FProductLots	as	产品批次	,
FProcessName	as	工序 	,
FFINISHQTY	as	实作产量	,
FBoxQuantity	as	每箱数量	,
FBoxQty	as	箱数	,
FBoxFractionQty	as	零头数	,
FScrappedQty	as	报废	,
FManualtime	as	人工计时	,
FManualstoppage	as	人工补时	,
FOperator	as	操作工	,
FProDate	as	生产日期	,
FInputDate	as	输卡日期
 from [rds_t_productdaily]
 where FProductLots='",FProductLots,"'

             ")
  }

  res=tsda::sql_select2(token = dms_token,sql = sql)
  return(res)

}



#' 计时计件工资表删除
#'
#' @param token
#' @param FProductLots
#'
#' @return
#' @export
#'
#' @examples
#' productdaily_delete()
productdaily_delete <- function(dms_token,FProductLots) {
  sql=paste0(" delete  from rds_t_productdaily  where FProductLots='",FProductLots,"'
             ")
  res=tsda::sql_delete2(token = dms_token,sql_str = sql)
  return(res)

}

#' 日报表上传
#'
#' @param file_name
#' @param token
#'
#' @return
#' @export
#'
#' @examples
#' productdaily_upload()
productdaily_upload <- function(dms_token,file_name) {


  data <- readxl::read_excel(file_name,col_types =  c("text","text","text","text","text","numeric","numeric","numeric",
                                                      "numeric","numeric","numeric","numeric","text","date","date"

  ))
  data = as.data.frame(data)

  data = tsdo::na_standard(data)
  #上传服务器----------------
  tsda::db_writeTable2(token = dms_token,table_name = 'rds_t_productdaily_input',r_object = data,append = TRUE)
  sql_delete =paste0("delete a from rds_t_productdaily_input a
where a.FProductLots in(select distinct FProductLots from rds_t_productdaily)")

  tsda::sql_delete2(token = dms_token,sql_str = sql_delete)

  sql_insert =paste0("insert into  rds_t_productdaily select * from rds_t_productdaily_input")
  tsda::sql_insert2(token = dms_token,sql_str = sql_insert)
  sql_truncate =paste0("truncate table rds_t_productdaily_input")

  res=tsda::sql_delete2(token = dms_token,sql_str = sql_truncate)



  return(res)

  #end

}






