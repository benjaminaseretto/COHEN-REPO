 


----- TEMPORALES



IF OBJECT_ID ('tempdb..##TAX_AMOUNT_APP') IS NOT NULL
DROP TABLE ##TAX_AMOUNT_APP ;


SELECT AAA.INVOICE_ID, AAA.TAX_AMOUNT_APPLIED

into ##TAX_AMOUNT_APP
FROM
(SELECT aid3.INVOICE_ID as INVOICE_ID, sum(aid3.amount) as TAX_AMOUNT_APPLIED
  FROM STAGING..EBS_ap_invoice_distributions_all aid3 join 
STAGING..EBS_AP_INVOICE_LINES_ALL AILL
  on( aid3.invoice_id = AILL.INVOICE_ID)
  where aid3.invoice_line_number = AILL.LINE_NUMBER
  AND ((aid3.line_type_lookup_code IN ('REC_TAX','NONREC_TAX')
      and aid3.prepay_distribution_id IN (SELECT aid11.invoice_distribution_id
                       FROM STAGING..EBS_ap_invoice_distributions_all aid11 join STAGING..EBS_AP_INVOICE_DISTRIBUTIONS_all AIDD11
                     on( aid11.invoice_id = AIDD11.INVOICE_ID)
                     where aid11.invoice_line_number = AIDD11.INVOICE_LINE_NUMBER)
      ) OR
      (aid3.line_type_lookup_code IN ('TIPV','TRV','TERV')
       and aid3.related_id IN (SELECT invoice_distribution_id
                   FROM STAGING..EBS_ap_invoice_distributions_all aid22
                   WHERE aid22.invoice_id = aid3.invoice_id
                   AND aid22.invoice_line_number = aid3.invoice_line_number
                   AND aid22.line_type_lookup_code IN ('REC_TAX','NONREC_TAX')
                   AND aid22.prepay_distribution_id IN
                                   (SELECT aid4.invoice_distribution_id
                                             FROM STAGING..EBS_ap_invoice_distributions_all aid4 join STAGING..EBS_AP_INVOICE_DISTRIBUTIONS_all AAD1
                                 on( aid4.invoice_id = AAD1.INVOICE_ID)
                                 where aid4.invoice_line_number = AAD1.INVOICE_LINE_NUMBER)
								 )
                          ) ) group by aid3.INVOICE_ID ) AAA
;

-----



IF OBJECT_ID ('tempdb..##PREPAY_AMOUNT_APP') IS NOT NULL
DROP TABLE ##PREPAY_AMOUNT_APP ;


SELECT EEE.INVOICE_ID, EEE.PREPAY_AMOUNT_APPLIED

INTO ##PREPAY_AMOUNT_APP
FROM
(SELECT aid1.INVOICE_ID as INVOICE_ID,
	sum(aid1.amount)as PREPAY_AMOUNT_APPLIED
	FROM STAGING..EBS_ap_invoice_distributions_all aid1  join 
	STAGING..EBS_AP_INVOICE_LINES_ALL AIL 
	  on( aid1.invoice_id = AIL.INVOICE_ID ) 
	 where aid1.invoice_line_number = AIL.LINE_NUMBER  
	  AND aid1.line_type_lookup_code = 'PREPAY'
	  AND aid1.prepay_distribution_id IN (SELECT aid2.invoice_distribution_id
						   FROM STAGING..EBS_ap_invoice_distributions_all aid2  join STAGING..EBS_AP_INVOICE_DISTRIBUTIONS_all AIDD1
						 on( aid2.invoice_id = AIDD1.INVOICE_ID)
						 AND aid2.invoice_line_number = AIDD1.INVOICE_LINE_NUMBER
								 ) 
	group by aid1.INVOICE_ID ) EEE
	;

