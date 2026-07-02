class AppConstants {
  static const String appName = 'Second Brain';
  static const String channelOverlay = 'com.secondbrain/overlay';
  static const String channelCapture = 'com.secondbrain/capture';
  static const String channelStorage = 'com.secondbrain/storage';

  static const List<String> blockedApps = [
    // Indian banking
    'com.snapwork.hdfc', 'com.hdfc.hdfcnetbanking',
    'com.axis.mobile', 'com.axis.netbanking',
    'com.sbi.lotusintouch', 'com.sbi.SBIFreedomPlus',
    'com.icici.mobileservices', 'com.icici.netbanking',
    'com.kotak.mobile', 'com.kotak.live',
    'com.yesbank.mobile', 'com.yesbank.yesmobile',
    'com.idbi.mobile', 'com.idbi.payments',
    'com.indusind.mobile', 'com.indusind.indusnet',
    'com.unionbank.mobile', 'com.bankofbaroda.mobile',
    'com.canarabank.mobile', 'com.pnbmobile',
    // UPI/Wallets
    'com.google.android.apps.nbu.paisa.user', 'net.one97.paytm',
    'com.phonepe.app', 'in.amazon.mShop.android.shopping',
    'com.freecharge', 'com.mobikwik_new',
    'com.olacabs.olacards', 'com.payzapp',
    // International banking
    'com.chase.sprint.android', 'com.usaa.mobile.android',
    'com.wf.wellsfargomobile', 'com.bofa.mobile',
    'com.citi.citimobile', 'com.capitalone.mobile',
    'com.barclays.android', 'com.hsbc.hsbcuk',
    'com.natwest.mobile', 'com.tsb.mobile',
    'com.santander.app', 'uk.co.halifax.mobile',
    'com.lloydsbank.mobile', 'com.virginmoney.uk',
    // Password managers
    'com.lastpass.lpandroid', 'com.dashlane',
    'com.1password', 'com.agilebits.onepassword',
    'com.bitwarden', 'com.bitwarden.mobile',
    'com.enpass.android', 'com.keepass.android',
    'com.keeppass.safe', 'com.nordpass.android',
    // Payment platforms
    'com.paypal.android.p2pmobile', 'com.stripe',
    'com.squareup.square', 'com.block.square',
    'com.venmo', 'com.cashapp',
    'com.revolut.revolut', 'com.transferwise.android',
    'com.monzo.android', 'com.starlingbank.android',
    // Cryptocurrency exchanges
    'com.coinbase.android', 'com.binance.dev',
    'com.kraken.www', 'com.gemini.android',
    'com.crypto.exchange', 'com.blockchain',
  ];

  static const int maxCaptureWidth = 1080;
}
