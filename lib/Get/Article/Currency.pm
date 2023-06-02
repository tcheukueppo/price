package Get::Article::Currency;

# OSI CODES
@CODES = qw(
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
$SYMBOLS = {
   do {
      map { $_ => 0 } qw(
         Le Q
         DH D
         QR Rf
         R m
         Rs Dh
         Leu Lei
         VT E
         Bs K
         soum Fr
         KM DT
         G Lev
         LL LE
         ID Rl
         LS Nu
         RO Shs
         Ft Sh
         Ar Db
         KD UM
         Br LD
         SM P
         kr Ks
         som L
         Kz DIN
         Lek Re
         JD BD
         DA Nkf
         Dhs Mt
         M Rp
         RM DEN
         Rls
      );
   },
   map { $_ => 1 } (
      'C$',   '₱',
      '₵',    '₼',
      '₺',    'MOP$',
      'Bs.D', 'B/',
      '៛',    '₴',
      '₽',    '₪',
      '₩',    '₸',
      '£',    '₭',
      '؋',    '฿',
      'T$',   '€',
      '₹',    '₾',
      'Kč',   '¥',
      'S/',   'R$',
      '₡',    'zł',
      '৳',    '₫',
      '₦',    'ƒ',
      '֏',    '$',
      'Bs.S', '₮',
      '₲'
                   ),
           };
