
SELECT
    comprobante_cd,
    comprobante_tx,
    proveedor_tx,
	proveedor_cd,
    proveedor_categoria_tx,
    proveedor_sitio_original_tx,
    organizacion_tx,
	pago_fc,
    AVG(DATEDIFF(day, recibido_fc, pago_fc)) AS Plazo_pago,
    COUNT(DISTINCT CASE WHEN estado_pago_fl = 'Y' AND pago_fc <= GETDATE() THEN comprobante_cd END) AS facturas_pagadas
FROM BT_Listado_Comprobantes
WHERE
    estado_pago_fl = 'Y'
    AND pago_fc <= GETDATE()
    AND recibido_fc <= GETDATE()
GROUP BY
    comprobante_cd,
    comprobante_tx,
    proveedor_tx, 
    proveedor_categoria_tx,
    proveedor_sitio_original_tx,
	pago_fc,
	proveedor_cd,
    organizacion_tx
ORDER BY  facturas_pagadas ASC;


SELECT
    A.comprobante_cd,
    A.comprobante_tx,
    A.proveedor_tx,
    A.proveedor_nu,
    A.proveedor_categoria_tx,
    A.proveedor_sitio_original_tx,
    A.organizacion_tx,
    A.pago_fc,
    A.recibido_fc,
    AVG(DATEDIFF(day, A.recibido_fc, A.pago_fc)) AS plazo_pago,
    B.monto_vencimiento_pago_nu,
	SUM(monto_vencimiento_pago_nu) AS saldo_monto_vencimiento_pago,
    COUNT(DISTINCT id_factura_cd) AS total_facturas,
    COUNT(DISTINCT CASE WHEN tipo_vencimiento_pago_tx = 'PAGO' AND monto_vencimiento_pago_nu >= 0 THEN id_factura_cd END) AS facturas_pagadas,
    COUNT(DISTINCT CASE WHEN tipo_vencimiento_pago_tx = 'PAGO' AND monto_vencimiento_pago_nu >= 0 THEN id_factura_cd END) * 100.0 / COUNT(DISTINCT id_factura_cd) AS Porcentaje_pago
FROM BT_Listado_Comprobantes A
LEFT JOIN ##SCHEDULES_AND_PAYMENTS B ON A.comprobante_cd = B.id_factura_cd 
WHERE
    A.estado_pago_fl = 'Y'
    AND A.pago_fc <= GETDATE()
    AND A.recibido_fc <= GETDATE()
GROUP BY
    A.comprobante_cd,
    A.comprobante_tx,
    A.proveedor_tx,
    A.proveedor_nu,
    A.proveedor_categoria_tx,
    A.proveedor_sitio_original_tx,
    A.organizacion_tx,
    A.recibido_fc,
    A.pago_fc,
	B.monto_vencimiento_pago_nu
ORDER BY A.pago_fc DESC;


DECLARE @FECHA DATE = GETDATE();

SELECT
    A.comprobante_cd,
    A.comprobante_tx,
    A.proveedor_tx,
    A.proveedor_nu,
    A.proveedor_categoria_tx,
    A.proveedor_sitio_original_tx,
    A.organizacion_tx,
    A.pago_fc,
    A.recibido_fc,
    AVG(DATEDIFF(DAY, A.recibido_fc, A.pago_fc)) AS plazo_pago,
    B.monto_vencimiento_pago_nu,
    SUM(monto_vencimiento_pago_nu) AS saldo_monto_vencimiento_pago,
    COUNT(DISTINCT id_factura_cd) AS total_facturas,
    COUNT(DISTINCT CASE WHEN tipo_vencimiento_pago_tx = 'PAGO' AND monto_vencimiento_pago_nu >= 0 THEN id_factura_cd END) AS facturas_pagadas,
    COUNT(DISTINCT CASE WHEN tipo_vencimiento_pago_tx = 'PAGO' AND monto_vencimiento_pago_nu >= 0 THEN id_factura_cd END) * 100.0 / COUNT(DISTINCT id_factura_cd) AS Porcentaje_pago,
    SUM(CASE WHEN estado_pago_fl = 'Y' AND pago_fc = @FECHA THEN CONVERT(NUMERIC(10,2), Porcentaje_pago) ELSE 0 END) AS EN_TERMINO
FROM BT_Listado_Comprobantes A
LEFT JOIN ##SCHEDULES_AND_PAYMENTS B ON A.comprobante_cd = B.id_factura_cd 
WHERE
    A.estado_pago_fl = 'Y'
    AND A.pago_fc <= @FECHA
    AND A.recibido_fc <= @FECHA
GROUP BY
    A.comprobante_cd,
    A.comprobante_tx,
    A.proveedor_tx,
    A.proveedor_nu,
    A.proveedor_categoria_tx,
    A.proveedor_sitio_original_tx,
    A.organizacion_tx,
    A.recibido_fc,
    A.pago_fc,
    B.monto_vencimiento_pago_nu
ORDER BY A.pago_fc DESC;

DECLARE @FECHA DATE = GETDATE();

SELECT
    A.comprobante_cd,
    A.comprobante_tx,
    A.proveedor_tx,
    A.proveedor_nu,
    A.proveedor_categoria_tx,
    A.proveedor_sitio_original_tx,
    A.organizacion_tx,
    A.pago_fc,
    A.recibido_fc,
    AVG(DATEDIFF(DAY, A.recibido_fc, A.pago_fc)) AS plazo_pago,
    B.monto_vencimiento_pago_nu,
    SUM(monto_vencimiento_pago_nu) AS saldo_monto_vencimiento_pago,
    COUNT(DISTINCT id_factura_cd) AS total_facturas,
    COUNT(DISTINCT CASE WHEN tipo_vencimiento_pago_tx = 'PAGO' AND monto_vencimiento_pago_nu >= 0 THEN id_factura_cd END) AS facturas_pagadas,
    COUNT(DISTINCT CASE WHEN tipo_vencimiento_pago_tx = 'PAGO' AND monto_vencimiento_pago_nu >= 0 THEN id_factura_cd END) * 100.0 / COUNT(DISTINCT id_factura_cd) AS Porcentaje_pago,
    SUM(CASE WHEN estado_pago_fl = 'Y' AND pago_fc = @FECHA THEN (COUNT(DISTINCT CASE WHEN tipo_vencimiento_pago_tx = 'PAGO' AND monto_vencimiento_pago_nu >= 0 THEN id_factura_cd END) * 100.0 / COUNT(DISTINCT id_factura_cd))ELSE 0 END AS EN_TERMINO
FROM BT_Listado_Comprobantes A
LEFT JOIN ##SCHEDULES_AND_PAYMENTS B ON A.comprobante_cd = B.id_factura_cd 
WHERE
    A.estado_pago_fl = 'Y'
    AND A.pago_fc <= @FECHA
    AND A.recibido_fc <= @FECHA
GROUP BY
    A.comprobante_cd,
    A.comprobante_tx,
    A.proveedor_tx,
    A.proveedor_nu,
    A.proveedor_categoria_tx,
    A.proveedor_sitio_original_tx,
    A.organizacion_tx,
    A.recibido_fc,
    A.pago_fc,
    B.monto_vencimiento_pago_nu
ORDER BY A.pago_fc DESC;
