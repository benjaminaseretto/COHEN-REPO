
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
    COUNT(DISTINCT CASE WHEN estado_pago_fl = 'Y' AND pago_fc <= GETDATE() THEN comprobante_cd END) AS Facturas_pagadas
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
ORDER BY pago_fc DESC;


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


Select * from ##SCHEDULES_AND_PAYMENTS;

