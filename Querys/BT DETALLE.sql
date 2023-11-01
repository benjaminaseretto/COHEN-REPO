SELECT * FROM BT_Listado_Comprobantes
WHERE comprobante_cd = 1360711;

SELECT
    comprobante_cd,
    comprobante_tx,
    proveedor_tx,
    proveedor_cd,
    proveedor_categoria_tx,
    proveedor_sitio_original_tx,
    organizacion_tx,
    estado_pago_fl,
    CAST(pago_fc AS DATE) pago_fc,
	CAST(condicion_pago_fc AS DATE) condicion_pago_fc,
    CAST(recibido_fc AS DATE) recibido_fc,
    CAST(retencion_vencimiento_fc AS DATE) retencion_vencimiento_fc,
    AVG(DATEDIFF(day, CAST(recibido_fc AS DATE),CAST(pago_fc AS DATE))) AS Plazo_pago,
    CASE WHEN estado_pago_fl = 'Y' AND CAST(pago_fc AS DATE) <= CAST(retencion_vencimiento_fc AS DATE) THEN 1 ELSE 0 END AS en_termino,
    CASE WHEN estado_pago_fl = 'Y' AND CAST(pago_fc AS DATE) > CAST(retencion_vencimiento_fc AS DATE) THEN 1 ELSE 0 END AS fuera_de_termino,
	COUNT(DISTINCT CASE WHEN estado_pago_fl = 'Y' AND pago_fc <= GETDATE() THEN comprobante_cd END) AS facturas_pagadas,
    CASE WHEN estado_pago_fl = 'Y' AND CAST(pago_fc AS DATE) <= CAST(retencion_vencimiento_fc AS DATE) THEN 1 * importe_vl ELSE 0 END AS en_termino_args,
    CASE WHEN estado_pago_fl = 'Y' AND CAST(pago_fc AS DATE) > CAST(retencion_vencimiento_fc AS DATE) THEN 1 * importe_vl ELSE 0 END AS fuera_de_termino_args,
    SUM(CASE WHEN estado_pago_fl = 'Y' AND CAST(pago_fc AS DATE) <= CAST(retencion_vencimiento_fc AS DATE) THEN 1 * importe_vl ELSE 0 END) + SUM(CASE WHEN estado_pago_fl = 'Y' AND CAST(pago_fc AS DATE) > CAST(retencion_vencimiento_fc AS DATE) THEN 1 * importe_vl ELSE 0 END) AS total_en_ars
FROM
    BT_Listado_Comprobantes
WHERE
    estado_pago_fl = 'Y'
    AND pago_fc <= GETDATE()
    AND recibido_fc <= GETDATE()
	
GROUP BY
    comprobante_cd,
    comprobante_tx,
    proveedor_tx,
    proveedor_cd,
    proveedor_categoria_tx,
    proveedor_sitio_original_tx,
    organizacion_tx,
    estado_pago_fl,
    pago_fc,
    importe_vl,
	condicion_pago_fc,
	recibido_fc,
    retencion_vencimiento_fc
ORDER BY
    pago_fc DESC;
