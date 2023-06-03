package Get::Article::Currency;

# OSI CODES
our %CODES = map { $_ => 1 } qw(
   RUB AFN EUR ALL GBP DZD AOA XCD ARS AMD AWG SHP AUD AZN BSD BHD
   BDT BBD BYN BZD XOF BMD BTN INR BOB USD BAM BWP BRL BND SGD BGN
   BIF KHR XAF CAD CVE KYD CLP CNY COP KMF CDF NZD CRC CUP ANG CZK
   DKK DJF DOP EGP ERN SZL ZAR ETB FKP FJD XPF GMD GEL GHS GIP GTQ
   GNF GYD HTG HNL HKD HUF ISK IDR IRR IQD ILS JMD JPY JOD KZT KES
   KPW KRW KWD KGS LAK LBP LSL LRD LYD CHF MOP MGA MWK MYR MVR MRU
   MUR MXN MDL MNT MAD MZN MMK NAD NPR NIO NGN MKD TRY NOK OMR PKR
   PAB PGK PYG PEN PHP PLN QAR RON RWF WST STN SAR RSD SCR SLE SBD
   SOS LKR SDG SRD SEK SYP TWD TJS TZS THB TOP TTD TND TMT UGX UAH
   AED UYU UZS VUV VES VED VND YER ZMW
);

# CURRENCY SYMBOLS
our %SYMBOLS = (
   'C$'   => ['NIO'],
   '₱'    => ['PHP'],
   '₵'    => ['GHS'],
   '₼'    => ['AZN'],
   '₺'    => ['TRY'],
   'MOP$' => ['MOP'],
   'Bs.D' => ['VED'],
   'B/'   => ['PAB'],
   '៛'    => ['KHR'],
   '₴'    => ['UAH'],
   '₽'    => ['RUB'],
   '₪'    => ['ILS'],
   '₩'    => [qw(KPW KRW)],
   '₸'    => ['KZT'],
   '£'    => [qw(GBP SHP FKP GIP)],
   '₭'    => ['LAK'],
   '؋'    => ['AFN'],
   '฿'    => ['THB'],
   'T$'   => ['TOP'],
   '€'    => ['EUR'],
   '₹'    => ['INR'],
   '₾'    => ['GEL'],
   'Kč'   => ['CZK'],
   '¥'    => [qw(CNY JPY)],
   'S/'   => ['PEN'],
   'R$'   => ['BRL'],
   '₡'    => ['CRC'],
   'zł'   => ['PLN'],
   '৳'    => ['BDT'],
   '₫'    => ['VND'],
   '₦'    => ['NGN'],
   'ƒ'    => [qw(AWG ANG)],
   '֏'    => ['AMD'],
   '$'    => [
        qw(
           XCD ARS AUD BSD BBD BZD
           BMD USD BND SGD CAD CVE
           KYD CLP COP NZD CUP DOP
           FJD GYD HKD JMD LRD MXN
           NAD WST SBD SRD TWD TTD
           UYU
        )
   ],
   'Bs.S' => ['VES'],
   '₮'    => ['MNT'],
   '₲'    => ['PYG'],
);
