package Get::Article::Currency;

# OSI CODES
our @CODES = qw(
   RUB AFN EUR ALL
   GBP DZD AOA ARS
   AMD AUD AZN BDT
   BYN INR BOB USD
   BWP BRL SGD BIF
   CAD CLP CNY COP
   CDF NZD CRC CZK
   DOP EGP ZAR ETB
   FJD GMD GEL GHS
   GTQ GNF GYD HTG
   HNL HUF ISK IDR
   IRR IQD ILS JMD
   JPY KZT KES KPW
   KRW KWD KGS LAK
   LYD CHF MGA MWK
   MYR MRU MUR MXN
   MDL MNT MAD MZN
   MMK NIO NGN MKD
   TRY NOK PKR PGK
   PYG PEN PHP PLN
   RON RWF WST RSD
   SCR SLE SBD SOS
   SSP LKR SDG SRD
   SEK SYP TWD TJS
   TZS THB TOP TTD
   TND TMT UGX UAH
   UYU UZS VUV VES
   VED VND YER ZMW
);

# CURRENCY SYMBOLS
our $SYMBOLS = {
               '₲'    => [qw(PYG)],
               DEN    => [qw(MKD)],
               Ar     => [qw(MGA)],
               Lei    => [qw(MDL RON)],
               '₴'    => [qw(UAH)],
               Br     => [qw(BYN ETB)],
               '£'    => [qw(GBP)],
               UM     => [qw(MRU)],
               '₵'    => [qw(GHS)],
               Bs     => [qw(BOB)],
               Lek    => [qw(ALL)],
               'Bs.S' => [qw(VES)],
               '¥'    => [qw(CNY JPY)],
               '₸'    => [qw(KZT)],
               '৳'    => [qw(BDT)],
               D      => [qw(GMD)],
               '₹'    => [qw(INR)],
               DIN    => [qw(RSD)],
               '₺'    => [qw(TRY)],
               Le     => [qw(SLE)],
               G      => [qw(HTG)],
               Fr     => [qw(BIF CDF GNF CHF RWF)],
               '₼'    => [qw(AZN)],
               '₽'    => [qw(RUB)],
               VT     => [qw(VUV)],
               Ft     => [qw(HUF)],
               '₾'    => [qw(GEL)],
               Leu    => [qw(MDL RON)],
               K      => [qw(MWK MMK PGK ZMW)],
               L      => [qw(HNL)],
               'R$'   => [qw(BRL)],
               DA     => [qw(DZD)],
               P      => [qw(BWP)],
               Q      => [qw(GTQ)],
               'T$'   => [qw(TOP)],
               Ks     => [qw(MMK)],
               Re     => [qw(MUR PKR SCR LKR)],
               R      => [qw(ZAR)],
               '֏'    => [qw(AMD)],
               '؋'    => [qw(AFN)],
               kr     => [qw(ISK NOK SEK)],
               DH     => [qw(MAD)],
               Mt     => [qw(MZN)],
               Sh     => [qw(KES SOS TZS UGX)],
               Rl     => [qw(IRR YER)],
               Kz     => [qw(AOA)],
               SSP    => [qw(SSP)],
               'S/'   => [qw(PEN)],
               ID     => [qw(IQD)],
               Rp     => [qw(IDR)],
               Rs     => [qw(MUR PKR SCR LKR)],
               KD     => [qw(KWD)],
               'zł'   => [qw(PLN)],
               '$'    => [qw(ARS AUD USD SGD CAD CLP COP NZD DOP FJD GYD JMD MXN WST SBD SRD TWD TTD UYU)],
               DT     => [qw(TND)],
               LD     => [qw(LYD)],
               LE     => [qw(EGP)],
               'Kč'   => [qw(CZK)],
               '₡'    => [qw(CRC)],
               Shs    => [qw(KES SOS TZS UGX)],
               m      => [qw(TMT)],
               'C$'   => [qw(NIO)],
               '₦'    => [qw(NGN)],
               Rls    => [qw(IRR YER)],
               'Bs.D' => [qw(VED)],
               '฿'    => [qw(THB)],
               LS     => [qw(SDG SYP)],
               '₩'    => [qw(KPW KRW)],
               '₪'    => [qw(ILS)],
               '₫'    => [qw(VND)],
               '€'    => [qw(EUR)],
               '₭'    => [qw(LAK)],
               '₮'    => [qw(MNT)],
               RM     => [qw(MYR)],
               som    => [qw(KGS)],
               soum   => [qw(UZS)],
               SM     => [qw(TJS)],
               '₱'    => [qw(PHP)],
              };
