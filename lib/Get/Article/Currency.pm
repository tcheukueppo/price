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
   Ft     => ['HUF'],
   Sh     => [qw(KES SOS TZS UGX)],
   Ar     => ['MGA'],
   'C$'   => ['NIO'],
   Db     => ['STN'],
   '₱'    => ['PHP'],
   '₵'    => ['GHS'],
   KD     => ['KWD'],
   UM     => ['MRU'],
   Br     => [qw(BYN ETB)],
   Le     => ['SLE'],
   Q      => ['GTQ'],
   DH     => ['MAD'],
   D      => ['GMD'],
   QR     => ['QAR'],
   Rf     => ['MVR'],
   '₼'    => ['AZN'],
   R      => ['ZAR'],
   m      => ['TMT'],
   Dh     => ['AED'],
   '₺'    => ['TRY'],
   Leu    => [qw(MDL RON)],
   'MOP$' => ['MOP'],
   'Bs.D' => ['VED'],
   Lei    => [qw(MDL RON)],
   VT     => ['VUV'],
   E      => ['SZL'],
   'B/'   => ['PAB'],
   '៛'    => ['KHR'],
   '₴'    => ['UAH'],
   Bs     => ['BOB'],
   K      => [qw(MWK MMK PGK ZMW)],
   LE     => ['EGP'],
   ID     => ['IQD'],
   Rl     => [qw(IRR SAR YER)],
   '₽'    => ['RUB'],
   '₪'    => ['ILS'],
   LS     => [qw(SDG SYP)],
   Nu     => ['BTN'],
   RO     => ['OMR'],
   '₩'    => [qw(KPW KRW)],
   Shs    => [qw(KES SOS TZS UGX)],
   '₸'    => ['KZT'],
   '£'    => [qw(GBP SHP FKP GIP)],
   '₭'    => ['LAK'],
   soum   => ['UZS'],
   '؋'    => ['AFN'],
   '฿'    => ['THB'],
   'T$'   => ['TOP'],
   '€'    => ['EUR'],
   Fr     => [qw(XOF BIF XAF KMF CDF DJF XPF GNF CHF RWF)],
   KM     => ['BAM'],
   DT     => ['TND'],
   G      => ['HTG'],
   '₹'    => ['INR'],
   Lev    => ['BGN'],
   '₾'    => ['GEL'],
   'Kč'   => ['CZK'],
   LD     => ['LYD'],
   '¥'    => [qw(CNY JPY)],
   SM     => ['TJS'],
   P      => ['BWP'],
   'S/'   => ['PEN'],
   kr     => [qw(DKK ISK NOK SEK)],
   Ks     => ['MMK'],
   'R$'   => ['BRL'],
   '₡'    => ['CRC'],
   'zł'   => ['PLN'],
   som    => ['KGS'],
   L      => [qw(SZL HNL LSL)],
   '৳'    => ['BDT'],
   '₫'    => ['VND'],
   DIN    => ['RSD'],
   '₦'    => ['NGN'],
   'ƒ'    => [qw(AWG ANG)],
   Lek    => ['ALL'],
   Re     => [qw(MUR NPR PKR SCR LKR)],
   JD     => ['JOD'],
   BD     => ['BHD'],
   '֏'    => ['AMD'],
   DA     => ['DZD'],
   Dhs    => ['AED'],
   '$'    => [
      qw(
        XCD ARS AUD BSD
        BBD BZD BMD USD
        BND SGD CAD CVE
        KYD CLP COP NZD
        CUP DOP FJD GYD
        HKD JMD LRD MXN
        NAD WST SBD SRD
        TWD TTD UYU
        )
   ],
   Mt     => ['MZN'],
   M      => ['LSL'],
   'Bs.S' => ['VES'],
   Rp     => ['IDR'],
   RM     => ['MYR'],
   DEN    => ['MKD'],
   Rls    => [qw(IRR SAR YER)],
   Rs     => [qw(MUR NPR PKR SCR LKR)],
   Kz     => ['AOA'],
   LL     => ['LBP'],
   Nkf    => ['ERN'],
   '₮'    => ['MNT'],
   '₲'    => ['PYG'],
};
