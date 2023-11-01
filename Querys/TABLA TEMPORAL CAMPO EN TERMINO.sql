IF OBJECT_ID ('TEMPDB..##UNION_INVOICE_COMEX_TMP')
IS NOT NULL
	DROP TABLE ##UNION_INVOICE_COMEX_TMP;
SELECT
	INVOICE_ID						id_factura_cd,
	VENDOR_ID						id_proveedor_cd,
	CREATION_DATE					fecha_creacion_nu,
	TERMS_ID						id_termino_cd,
	'FACTURA'						flag_documento_fl,
	PAYMENT_STATUS_FLAG				flag_estado_aprobacion_fl,
	INVOICE_DATE					fecha_documento_nu,
	INVOICE_AMOUNT					monto_documento_nu,
	INVOICE_RECEIVED_DATE			fecha_recepcion_documento
INTO ##UNION_INVOICE_COMEX_TMP
FROM STAGING..EBS_AP_INVOICES_ALL
WHERE CANCELLED_DATE IS NULL
UNION ALL
SELECT
	FACTURA_ID						id_factura_cd,
	VENDOR_ID						id_proveedor_cd,
	CREATION_DATE					fecha_creacion_nu,
	'10000'							id_termino_cd,
	'COMEX'							flag_documento_fl,
	'N'								flag_estado_aprobacion_fl,
	FECHA_FACTURA					fecha_documento_nu,
	TOTAL_FACTURA					monto_documento_nu,
	NULL							fecha_recepcion_documento
FROM STAGING..EBS_XX_IM_EMBARQUE_FACTURAS_ALL
WHERE FACTURA_EXPORTADA_AP = 'N';


IF OBJECT_ID ('TEMPDB..##TEMPORAL')
IS NOT NULL
	DROP TABLE ##TEMPORAL;
SELECT
	uict.id_factura_cd,
	uict.id_proveedor_cd,
	uict.flag_documento_fl,
	uict.flag_estado_aprobacion_fl,
	uict.fecha_documento_nu,
	uict.monto_documento_nu,
	uict.fecha_recepcion_documento,
	uict.id_termino_cd,
	MIN(atl.DUE_DAYS)			dias_pendientes_nu,
	MIN(atl.DUE_DAYS)			dias_pendientes_min_nu,
	MAX(atl.DUE_DAYS)			dias_pendientes_max_nu,
	CASE WHEN uict.flag_documento_fl = 'FACTURA' THEN	MIN(aila.ACCOUNTING_DATE)	
	ELSE NULL					END AS fecha_contabilizacion_nu
INTO ##TEMPORAL
FROM ##UNION_INVOICE_COMEX_TMP uict
LEFT JOIN STAGING..EBS_AP_TERMS_LINES atl 
ON (uict.id_termino_cd = atl.TERM_ID)
LEFT JOIN STAGING..EBS_AP_INVOICE_LINES_ALL aila
ON (uict.id_factura_cd = aila.INVOICE_ID)
INNER JOIN STAGING..EBS_AP_SUPPLIERS s
ON (uict.id_proveedor_cd = s.VENDOR_ID)
GROUP BY 
	uict.id_factura_cd,
	uict.id_proveedor_cd,
	uict.flag_documento_fl,
	uict.flag_estado_aprobacion_fl,
	uict.fecha_documento_nu,
	uict.monto_documento_nu,
	uict.fecha_recepcion_documento,
	uict.id_termino_cd
order by uict.flag_documento_fl,uict.id_factura_cd;

--------------------------------------------------PAYMENT SCHEDULES----------------------------------------------------------------------------

IF OBJECT_ID ('TEMPDB..##VENCIMIENTO_TMP')
IS NOT NULL
	DROP TABLE ##VENCIMIENTO_TMP;
SELECT
	INVOICE_ID				id_factura_cd,
	max(DUE_DATE)					FECHA_VENCIMIENTO,
	SUM(GROSS_AMOUNT)				MONTO_VENCIMIENTO,
	SUM(AMOUNT_REMAINING)			AMOUNT_REMAINING,
	HOLD_FLAG
INTO ##VENCIMIENTO_TMP
FROM STAGING..EBS_AP_PAYMENT_SCHEDULES_ALL
group by INVOICE_ID, HOLD_FLAG
ORDER BY INVOICE_ID;


IF OBJECT_ID ('TEMPDB..##VENCIMIENTO_FACTURA_TMP')
IS NOT NULL
	DROP TABLE ##VENCIMIENTO_FACTURA_TMP;
SELECT 
	t.id_factura_cd,
	t.flag_documento_fl,
	vt.FECHA_VENCIMIENTO		fecha_vencimiento_nu,
	vt.MONTO_VENCIMIENTO		monto_vencimiento_nu,
	vt.AMOUNT_REMAINING			monto_remanente_nu,
	vt.HOLD_FLAG				flag_retencion_fl,
	NULL						fecha_vencimiento_inferido_nu,
	NULL						monto_documento_inferido_nu
INTO ##VENCIMIENTO_FACTURA_TMP
FROM ##TEMPORAL t
INNER JOIN ##VENCIMIENTO_TMP vt ON t.id_factura_cd = vt.id_factura_cd
where t.flag_documento_fl = 'FACTURA'
ORDER BY t.id_factura_cd;


IF OBJECT_ID ('TEMPDB..##VENCIMIENTO_COMEX_TMP')
IS NOT NULL
	DROP TABLE ##VENCIMIENTO_COMEX_TMP;
SELECT
	t.id_factura_cd,
	t.flag_documento_fl,
	NULL														fecha_vencimiento_nu,
	NULL														monto_vencimiento_nu,
	NULL														monto_remanente_nu,
	'N'															flag_retencion_fl,
	DATEADD(DAY, t.dias_pendientes_nu, t.fecha_documento_nu)	fecha_vencimiento_inferido_nu,
	CASE WHEN t.monto_documento_nu IS NULL THEN 0
	ELSE t.monto_documento_nu					END AS			monto_documento_inferido_nu
	
INTO ##VENCIMIENTO_COMEX_TMP
FROM ##TEMPORAL t
WHERE t.flag_documento_fl = 'COMEX'
ORDER BY id_factura_cd;


IF OBJECT_ID ('TEMPDB..##UNION_VENCIMIENTO_TMP')
IS NOT NULL
	DROP TABLE ##UNION_VENCIMIENTO_TMP;
SELECT
	*
INTO ##UNION_VENCIMIENTO_TMP
FROM ##VENCIMIENTO_FACTURA_TMP
UNION ALL
SELECT
	*
FROM ##VENCIMIENTO_COMEX_TMP;

IF OBJECT_ID ('TEMPDB..##PAYMENT_SCHEDULES')
IS NOT NULL
	DROP TABLE ##PAYMENT_SCHEDULES;
select
	id_factura_cd,
	flag_documento_fl,
	CASE WHEN fecha_vencimiento_nu IS NULL THEN fecha_vencimiento_inferido_nu
	ELSE fecha_vencimiento_nu												END AS	fecha_vencimiento_nu,
	CASE WHEN monto_vencimiento_nu IS NULL THEN monto_documento_inferido_nu
	ELSE monto_vencimiento_nu												END AS	monto_vencimiento_nu,
	CASE WHEN monto_remanente_nu IS NULL THEN 0
	ELSE monto_remanente_nu													END AS	monto_remanente_nu,
	flag_retencion_fl
INTO ##PAYMENT_SCHEDULES
from ##UNION_VENCIMIENTO_TMP
order by flag_documento_fl,id_factura_cd;

IF OBJECT_ID ('TEMPDB..##TEMPORAL_DOCUMENTO')
IS NOT NULL
	DROP TABLE ##TEMPORAL_DOCUMENTO;
select
	id_factura_cd,
	flag_documento_fl,
	MAX(fecha_vencimiento_nu)		max_fecha_vencimiento_nu,
	flag_retencion_fl
INTO ##TEMPORAL_DOCUMENTO
from ##PAYMENT_SCHEDULES
GROUP BY id_factura_cd, flag_documento_fl, flag_retencion_fl
order by id_factura_cd, flag_documento_fl



IF OBJECT_ID ('TEMPDB..##TEMPORAL_2')
IS NOT NULL
	DROP TABLE ##TEMPORAL_2;
select
	t.id_factura_cd,
	t.flag_documento_fl,
	t.flag_estado_aprobacion_fl,
	t.id_proveedor_cd,
	t.fecha_documento_nu,
	t.monto_documento_nu,
	t.fecha_recepcion_documento,
	t.id_termino_cd,
	t.dias_pendientes_nu,
	t.dias_pendientes_min_nu,
	t.dias_pendientes_max_nu,
	t.fecha_contabilizacion_nu,
	td.max_fecha_vencimiento_nu,
	td.flag_retencion_fl
INTO ##TEMPORAL_2
from ##TEMPORAL t
LEFT JOIN ##TEMPORAL_DOCUMENTO td ON (t.id_factura_cd = td.id_factura_cd) AND (t.flag_documento_fl = td.flag_documento_fl)
order by flag_documento_fl,id_factura_cd


------------------------------------------------------------CHECKS---------------------------------------------------------------------------------
IF OBJECT_ID ('TEMPDB..##CHECKS')
IS NOT NULL
	DROP TABLE ##CHECKS;
SELECT
	t2.id_factura_cd,
	t2.flag_documento_fl,
	apipa.CHECK_ID				id_cheque_cd,
	apipa.AMOUNT				monto_cheque_documento_nu,
	aca.CREATION_DATE			fecha_creacion_cheque_documento_nu,
	aca.CHECK_DATE				fecha_cheque_documento_nu
INTO ##CHECKS
FROM ##TEMPORAL_2 t2
LEFT JOIN STAGING..EBS_AP_INVOICE_PAYMENTS_ALL apipa ON (t2.id_factura_cd = apipa.INVOICE_ID)
INNER JOIN STAGING..EBS_AP_CHECKS_ALL aca ON (apipa.CHECK_ID = aca.CHECK_ID)
WHERE apipa.REVERSAL_FLAG != 'Y' AND t2.flag_documento_fl = 'FACTURA'
order by t2.id_factura_cd;


--------------------------------------------------------PREPAYS-----------------------------------------------------------------------------

IF OBJECT_ID ('TEMPDB..##PREPAYS_TMP')
IS NOT NULL
	DROP TABLE ##PREPAYS_TMP;
SELECT
	t2.id_factura_cd,
	t2.flag_documento_fl,
	p.ACCOUNTING_DATE			fecha_anticipo_documento_nu,
	P.PREPAY_AMOUNT_APPLIED		monto_anticipo_documento_nu
INTO ##PREPAYS_TMP
FROM ##TEMPORAL_2 t2
LEFT JOIN ##PREPAYS p ON (t2.id_factura_cd = p.INVOICE_ID)
where t2.flag_documento_fl = 'FACTURA'
order by t2.id_factura_cd;


----------------------------------------------------------AWT-------------------------------------------------------------------------------

IF OBJECT_ID ('TEMPDB..##RETENCION_TMP')
IS NOT NULL
	DROP TABLE ##RETENCION_TMP;
SELECT
	INVOICE_ID						id_factura_cd,
	'FACTURA'						flag_documento_fl,
	CREATION_DATE					fecha_retencion_documento_nu,
	AMOUNT							monto_retencion_documento_nu
INTO ##RETENCION_TMP
FROM STAGING..EBS_AP_INVOICE_LINES_ALL 
WHERE LINE_TYPE_LOOKUP_CODE = 'AWT'
order by INVOICE_ID;

--------------------------------------------------SCHEDULES_AND_PAYMENTS-------------------------------------------------------------------------

IF OBJECT_ID ('TEMPDB..##SCHEDULES_AND_PAYMENTS')
IS NOT NULL
	DROP TABLE ##SCHEDULES_AND_PAYMENTS;
SELECT
	id_factura_cd,
	flag_documento_fl,
	NULL													id_cheque_cd,
	CONVERT(DATE,fecha_vencimiento_nu)						fecha_vencimiento_nu,
	DATEADD(DAY, -4, CONVERT(DATE,fecha_vencimiento_nu))	fecha_ajustada_vencimiento_pago_nu,
	NULL													fecha_creacion_vencimiento_pago_nu,
	monto_vencimiento_nu * (-1)								monto_vencimiento_pago_nu,
	2														orden_vencimiento_pago_nu,
	'VENCIMIENTO'											tipo_vencimiento_pago_tx
INTO ##SCHEDULES_AND_PAYMENTS
FROM ##PAYMENT_SCHEDULES
UNION ALL
SELECT
	id_factura_cd,
	flag_documento_fl,
	id_cheque_cd,
	CONVERT(DATE,fecha_cheque_documento_nu)						fecha_vencimiento_nu,
	CONVERT(DATE,fecha_cheque_documento_nu)						fecha_ajustada_vencimiento_pago_nu,
	CONVERT(DATE,fecha_creacion_cheque_documento_nu)			fecha_creacion_vencimiento_pago_nu,
	monto_cheque_documento_nu									monto_vencimiento_pago_nu,
	1															orden_vencimiento_pago_nu,
	'PAGO'														tipo_vencimiento_pago_tx			
FROM ##CHECKS
WHERE id_cheque_cd IS NOT NULL
UNION ALL
SELECT
	id_factura_cd,
	flag_documento_fl,
	NULL														id_cheque_cd,
	CONVERT(DATE,fecha_anticipo_documento_nu)					fecha_vencimiento_nu,
	DATEFROMPARTS(1900, 1, 1)									fecha_ajustada_vencimiento_pago_nu,
	CONVERT(DATE,fecha_anticipo_documento_nu)					fecha_creacion_vencimiento_pago_nu,
	monto_anticipo_documento_nu									monto_vencimiento_pago_nu,
	0															orden_vencimiento_pago_nu,
	'ANTICIPO'													tipo_vencimiento_pago_tx
FROM ##PREPAYS_TMP
WHERE monto_anticipo_documento_nu IS NOT NULL
UNION ALL
SELECT
	id_factura_cd,
	flag_documento_fl,
	NULL														id_cheque_cd,
	CONVERT(DATE,fecha_retencion_documento_nu)					fecha_vencimiento_nu,
	CONVERT(DATE,fecha_retencion_documento_nu)					fecha_ajustada_vencimiento_pago_nu,
	CONVERT(DATE,fecha_retencion_documento_nu)					fecha_creacion_vencimiento_pago_nu,
	monto_retencion_documento_nu * (-1)							monto_vencimiento_pago_nu,
	1															orden_vencimiento_pago_nu,
	'RETENCION'													tipo_vencimiento_pago_tx
FROM ##RETENCION_TMP;



SELECT
    id_factura_cd,
	monto_vencimiento_pago_nu,
	id_cheque_cd,
	orden_vencimiento_pago_nu,
	tipo_vencimiento_pago_tx,
	fecha_ajustada_vencimiento_pago_nu,
	fecha_vencimiento_nu,
	monto_vencimiento_pago_nu,
    SUM(monto_vencimiento_pago_nu) AS saldo_monto_vencimiento_pago
FROM
    ##SCHEDULES_AND_PAYMENTS
WHERE
    id_factura_cd = 1298343
	--id_cheque_cd = 680679
GROUP BY
    id_factura_cd,
	id_cheque_cd,
	monto_vencimiento_pago_nu,
	orden_vencimiento_pago_nu,
	tipo_vencimiento_pago_tx,
	fecha_ajustada_vencimiento_pago_nu,
	fecha_vencimiento_nu,
	monto_vencimiento_pago_nu
ORDER BY fecha_ajustada_vencimiento_pago_nu DESC;



SELECT
    t1.comprobante_cd,
    t1.comprobante_tx,
    t1.proveedor_tx,
    t1.proveedor_cd,
    t1.proveedor_categoria_tx,
    t1.proveedor_sitio_original_tx,
    t1.organizacion_tx,
    t1.estado_pago_fl,
    CAST(t1.pago_fc AS DATE) AS pago_fc,
    CAST(t1.condicion_pago_fc AS DATE) AS condicion_pago_fc,
    CAST(t1.recibido_fc AS DATE) AS recibido_fc,
    CAST(t1.retencion_vencimiento_fc AS DATE) AS retencion_vencimiento_fc,
    AVG(DATEDIFF(day, CAST(t1.recibido_fc AS DATE), CAST(t1.pago_fc AS DATE))) AS Plazo_pago,
    CASE WHEN t1.estado_pago_fl = 'Y' AND CAST(t1.pago_fc AS DATE) <= CAST(t1.retencion_vencimiento_fc AS DATE) THEN 1 ELSE 0 END AS en_termino,
    CASE WHEN t1.estado_pago_fl = 'Y' AND CAST(t1.pago_fc AS DATE) > CAST(t1.retencion_vencimiento_fc AS DATE) THEN 1 ELSE 0 END AS fuera_de_termino,
    COUNT(DISTINCT CASE WHEN t1.estado_pago_fl = 'Y' AND t1.pago_fc <= GETDATE() THEN t1.comprobante_cd END) AS facturas_pagadas,
    CASE WHEN t1.estado_pago_fl = 'Y' AND CAST(t1.pago_fc AS DATE) <= CAST(t1.retencion_vencimiento_fc AS DATE) THEN 1 * t1.importe_vl ELSE 0 END AS en_termino_args,
    CASE WHEN t1.estado_pago_fl = 'Y' AND CAST(t1.pago_fc AS DATE) > CAST(t1.retencion_vencimiento_fc AS DATE) THEN 1 * t1.importe_vl ELSE 0 END AS fuera_de_termino_args,
    SUM(CASE WHEN t1.estado_pago_fl = 'Y' AND CAST(t1.pago_fc AS DATE) <= CAST(t1.retencion_vencimiento_fc AS DATE) THEN 1 * t1.importe_vl ELSE 0 END) + SUM(CASE WHEN t1.estado_pago_fl = 'Y' AND CAST(t1.pago_fc AS DATE) > CAST(t1.retencion_vencimiento_fc AS DATE) THEN 1 * t1.importe_vl ELSE 0 END) AS total_en_ars,
    t2.fecha_vencimiento_nu
FROM
    BT_Listado_Comprobantes t1
JOIN
     ##SCHEDULES_AND_PAYMENTS t2 ON t1.comprobante_cd = t2.id_factura_cd
WHERE
    t1.estado_pago_fl = 'Y'
    AND t1.pago_fc <= GETDATE()
    AND t1.recibido_fc <= GETDATE()
    AND t1.comprobante_cd = 1360711
    AND t1.pago_fc = (SELECT MIN(pago_fc) FROM BT_Listado_Comprobantes WHERE comprobante_cd = 1360711)
GROUP BY
    t1.comprobante_cd,
    t1.comprobante_tx,
    t1.proveedor_tx,
    t1.proveedor_cd,
    t1.proveedor_categoria_tx,
    t1.proveedor_sitio_original_tx,
    t1.organizacion_tx,
    t1.estado_pago_fl,
    t1.pago_fc,
    t1.importe_vl,
    t1.condicion_pago_fc,
    t1.recibido_fc,
    t1.retencion_vencimiento_fc,
    t2.fecha_vencimiento_nu
ORDER BY
    t1.pago_fc DESC;




					

IF OBJECT_ID ('TEMPDB..##DOCUMENTO_VENCIMIENTO_PAGO')
IS NOT NULL
	DROP TABLE ##DOCUMENTO_VENCIMIENTO_PAGO;
SELECT
	sap.id_factura_cd,
	sap.flag_documento_fl,
	sap.id_cheque_cd,
	sap.fecha_vencimiento_nu,
	sap.fecha_ajustada_vencimiento_pago_nu,
	sap.fecha_creacion_vencimiento_pago_nu,
	sap.monto_vencimiento_pago_nu,
	sap.orden_vencimiento_pago_nu,
	sap.tipo_vencimiento_pago_tx,
	t2.fecha_recepcion_documento,
	CASE WHEN (sap.tipo_vencimiento_pago_tx = 'VENCIMIENTO' AND t2.fecha_recepcion_documento > sap.fecha_vencimiento_nu) THEN 1
	ELSE 0													END AS flag_ingresa_vencida_vencimiento_pago_fl
INTO ##DOCUMENTO_VENCIMIENTO_PAGO
FROM ##SCHEDULES_AND_PAYMENTS sap
LEFT JOIN ##TEMPORAL_2 t2 ON ((sap.id_factura_cd = t2.id_factura_cd) AND (sap.flag_documento_fl = t2.flag_documento_fl))
ORDER BY flag_documento_fl, id_factura_cd;


IF OBJECT_ID ('TEMPDB..##TEMPORAL3')
IS NOT NULL
	DROP TABLE ##TEMPORAL3;
SELECT
	t2.id_factura_cd,
	t2.flag_documento_fl,
	t2.id_proveedor_cd,
	SUM(flag_ingresa_vencida_vencimiento_pago_fl)/COUNT(flag_ingresa_vencida_vencimiento_pago_fl)			porcentaje_vencida_nu
INTO ##TEMPORAL3
FROM ##TEMPORAL_2 t2
LEFT JOIN ##DOCUMENTO_VENCIMIENTO_PAGO dvp ON ((t2.id_factura_cd = dvp.id_factura_cd) AND (t2.flag_documento_fl = dvp.flag_documento_fl))
GROUP BY t2.id_factura_cd, t2.flag_documento_fl, t2.id_proveedor_cd;


select
	*
from ##TEMPORAL3
where id_factura_cd = 1419525;




















